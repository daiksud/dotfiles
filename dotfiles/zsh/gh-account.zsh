# Per-repository GitHub account selection backed by a central mapping file.
#
# Every account lives in gh's single user-level configuration. This plugin only
# decides which of those accounts the current directory should use, and applies
# the choice through `GH_TOKEN` so it stays scoped to this shell. `gh auth
# switch` is deliberately avoided: it moves the globally active account, so two
# terminals sitting in repositories owned by different accounts would fight.
#
# The mapping lives next to gh's own configuration and is keyed by the
# canonical `<host>/<owner>/<repo>` identity of `origin`:
#
#   {"github.com/owner/repo": {"login": "...", "name": "...", "email": "..."}}

: ${GH_ACCOUNT_MAP_FILE:="${XDG_CONFIG_HOME:-$HOME/.config}/gh/repos.json"}

typeset -g _GH_ACCOUNT_APPLIED_ID=""
typeset -g _GH_ACCOUNT_GIT_CONFIG_COUNT=0

# Normalize a remote URL into a lowercase `<host>/<owner>/<repo>` identity.
# Handles https://, ssh:// (with or without a port), git:// and scp-like
# `git@host:owner/repo` forms, with or without a trailing `.git`.
gh-account-repo-id() {
  local url="${1:-}"
  [[ -n "$url" ]] || return 1

  url="${url%%\?*}"
  url="${url%/}"
  url="${url%.git}"

  local rest="$url"
  case "$rest" in
    *://*) rest="${rest#*://}" ;;
  esac
  rest="${rest##*@}"

  local host path
  case "$rest" in
    *:*)
      host="${rest%%:*}"
      path="${rest#*:}"
      # ssh://host:port/owner/repo keeps the port ahead of the path.
      if [[ "$path" == <->/* ]]; then
        path="${path#*/}"
      fi
      ;;
    */*)
      host="${rest%%/*}"
      path="${rest#*/}"
      ;;
    *)
      return 1
      ;;
  esac

  [[ -n "$host" && "$path" == */* ]] || return 1

  local owner="${path%%/*}"
  local repo="${path#*/}"
  repo="${repo%%/*}"
  [[ -n "$owner" && -n "$repo" ]] || return 1

  printf '%s/%s/%s\n' "${host:l}" "${owner:l}" "${repo:l}"
}

gh-account-map-get() {
  local id="${1:-}" field="${2:-}"
  [[ -n "$id" && -n "$field" ]] || return 1
  [[ -f "$GH_ACCOUNT_MAP_FILE" ]] || return 1

  jq -er --arg id "$id" --arg field "$field" \
    '.[$id][$field] // empty' "$GH_ACCOUNT_MAP_FILE" 2>/dev/null
}

gh-account-map-set() {
  local id="${1:-}" login="${2:-}" name="${3:-}" email="${4:-}"
  [[ -n "$id" && -n "$login" ]] || return 1

  local dir="${GH_ACCOUNT_MAP_FILE:h}" tmp
  mkdir -p "$dir" || return 1
  [[ -f "$GH_ACCOUNT_MAP_FILE" ]] || printf '{}\n' >"$GH_ACCOUNT_MAP_FILE" || return 1

  tmp="${GH_ACCOUNT_MAP_FILE}.tmp.$$"
  if jq --arg id "$id" --arg login "$login" --arg name "$name" --arg email "$email" \
    '.[$id] = {login: $login, name: $name, email: $email}' \
    "$GH_ACCOUNT_MAP_FILE" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$GH_ACCOUNT_MAP_FILE"
  else
    rm -f "$tmp"
    return 1
  fi
}

gh-account-map-unset() {
  local id="${1:-}"
  [[ -n "$id" ]] || return 1
  [[ -f "$GH_ACCOUNT_MAP_FILE" ]] || return 0

  local tmp="${GH_ACCOUNT_MAP_FILE}.tmp.$$"
  if jq --arg id "$id" 'del(.[$id])' "$GH_ACCOUNT_MAP_FILE" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$GH_ACCOUNT_MAP_FILE"
  else
    rm -f "$tmp"
    return 1
  fi
}

# List the logins stored in gh's own configuration. GH_TOKEN has to be removed
# first, otherwise gh reports the environment token instead of the stored ones.
gh-account-logins() {
  local host="${1:-github.com}"

  command env -u GH_TOKEN gh auth status --json hosts 2>/dev/null \
    | jq -r --arg host "$host" '.hosts[$host] // [] | .[].login' 2>/dev/null
}

gh-account-token() {
  local login="${1:-}" host="${2:-github.com}"
  [[ -n "$login" ]] || return 1

  command env -u GH_TOKEN gh auth token --hostname "$host" --user "$login" 2>/dev/null
}

# Whether gh has any stored authentication for a host. Hostname suffix
# matching (e.g. requiring "github.com" or "ghe.com") cannot cover every
# possible GitHub Enterprise Server hostname, so gh-account-sync defers to
# gh's own knowledge of which hosts it is authenticated against instead.
_gh_account_host_is_known() {
  local host="${1:-}"
  [[ -n "$host" ]] || return 1

  command env -u GH_TOKEN gh auth status --hostname "$host" >/dev/null 2>&1
}

# `gh auth login` also reads GH_TOKEN, so adding an account needs a clean env.
gh-account-login() {
  command env -u GH_TOKEN -u GITHUB_TOKEN gh auth login "$@"
}

_gh_account_clear_env() {
  local i
  for ((i = 0; i < _GH_ACCOUNT_GIT_CONFIG_COUNT; i++)); do
    unset "GIT_CONFIG_KEY_${i}" "GIT_CONFIG_VALUE_${i}"
  done
  _GH_ACCOUNT_GIT_CONFIG_COUNT=0

  unset GIT_CONFIG_COUNT GH_TOKEN COPILOT_GITHUB_TOKEN GH_CONFIG_DIR
  _GH_ACCOUNT_APPLIED_ID=""
}

# Keep other accounts in allowed_signers and only upsert the current email.
_gh_account_update_allowed_signers() {
  local email="${1:-}" key_path="${2:-}"
  [[ -n "$email" && -f "$key_path" ]] || return 0

  local signers_file="$HOME/.ssh/allowed_signers"
  local tmp="${signers_file}.tmp.$$"
  local key_content
  key_content="$(<"$key_path")" || return 0

  if [[ -f "$signers_file" ]]; then
    awk -v target_email="$email" '$1 != target_email' "$signers_file" >"$tmp" || return 0
  else
    mkdir -p "${signers_file:h}" || return 0
    : >"$tmp" || return 0
  fi
  printf '%s %s\n' "$email" "$key_content" >>"$tmp"
  mv "$tmp" "$signers_file"
}

# Inject the identity as environment configuration. GIT_CONFIG_* takes
# precedence over every configuration file, so repositories that still carry
# local user.name/user.email from the previous design resolve correctly.
_gh_account_apply() {
  local id="${1:-}" login="${2:-}" name="${3:-}" email="${4:-}"
  local host="${id%%/*}"
  local token

  if ! token="$(gh-account-token "$login" "$host")" || [[ -z "$token" ]]; then
    print -u2 -- "gh-account: no stored token for '${login}'. Run 'gh-account-login' first."
    return 1
  fi

  _gh_account_clear_env

  local -a keys values
  [[ -n "$name" ]] && { keys+=(user.name); values+=("$name") }
  [[ -n "$email" ]] && { keys+=(user.email); values+=("$email") }

  local key_path="$HOME/.ssh/${login}.pub"
  if [[ -f "$key_path" ]]; then
    keys+=(user.signingkey)
    values+=("$key_path")
    _gh_account_update_allowed_signers "$email" "$key_path"
  else
    print -u2 -- "gh-account: signing key not found at ${key_path}. Skipping commit signing setup."
  fi

  local i
  for ((i = 1; i <= ${#keys}; i++)); do
    export "GIT_CONFIG_KEY_$((i - 1))=${keys[i]}"
    export "GIT_CONFIG_VALUE_$((i - 1))=${values[i]}"
  done
  _GH_ACCOUNT_GIT_CONFIG_COUNT=${#keys}
  export GIT_CONFIG_COUNT=${#keys}

  export GH_TOKEN="$token"
  export COPILOT_GITHUB_TOKEN="$token"
  _GH_ACCOUNT_APPLIED_ID="$id"
}

# Resolve the display name and commit email of a stored account.
_gh_account_identity() {
  local login="${1:-}" host="${2:-github.com}"
  local token name email

  token="$(gh-account-token "$login" "$host")" || return 1
  [[ -n "$token" ]] || return 1

  name="$(GH_TOKEN="$token" gh api user --jq '.name // ""' 2>/dev/null)"
  email="$(GH_TOKEN="$token" gh api user/emails \
    --jq 'map(select(.primary == true and .verified == true) | .email)[0] // empty' 2>/dev/null)"
  if [[ -z "$email" ]]; then
    email="$(GH_TOKEN="$token" gh api user/emails \
      --jq 'map(select(.primary == true) | .email)[0] // empty' 2>/dev/null)"
  fi
  if [[ -z "$email" ]]; then
    email="$(GH_TOKEN="$token" gh api user --jq '.email // ""' 2>/dev/null)"
  fi

  printf '%s\t%s\n' "$name" "$email"
}

_gh_account_current_id() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

  local origin
  origin="$(git config --get remote.origin.url 2>/dev/null)" || return 1
  [[ -n "$origin" ]] || return 1

  gh-account-repo-id "$origin"
}

_gh_account_is_interactive() {
  [[ -o interactive ]] || return 1
  [[ -z "${WIDGET:-}" ]] || return 1
  [[ -t 0 ]] || return 1
  [[ "${TERM:-dumb}" != "dumb" ]] || return 1
  command -v fzf >/dev/null 2>&1
}

# Choose (or re-choose) the account for the current repository.
gh-account-select() {
  local id host login identity name email

  if ! id="$(_gh_account_current_id)"; then
    print -u2 -- "gh-account: not inside a Git repository with a usable 'origin'."
    return 1
  fi
  host="${id%%/*}"

  if [[ "${1:-}" == "--forget" ]]; then
    gh-account-map-unset "$id" || return 1
    _gh_account_clear_env
    print -r -- "gh-account: removed the mapping for ${id}."
    return 0
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "gh-account: fzf is required to select an account."
    return 1
  fi

  login="$(gh-account-logins "$host" | fzf --reverse --height=20 \
    --prompt="account for ${id} > ")" || return 1
  [[ -n "$login" ]] || return 1

  if ! identity="$(_gh_account_identity "$login" "$host")"; then
    print -u2 -- "gh-account: could not read the profile of '${login}'."
    return 1
  fi
  name="${identity%%$'\t'*}"
  email="${identity#*$'\t'}"

  if [[ -z "$email" ]]; then
    print -u2 -- "gh-account: could not resolve an email for '${login}'. It may be private, or the token may lack the 'user:email' scope (gh auth refresh -h ${host} -s user:email)."
  fi

  gh-account-map-set "$id" "$login" "$name" "$email" || return 1
  _gh_account_apply "$id" "$login" "$name" "$email"
}

# Drop the local identity written by the previous per-repository design. The
# environment configuration wins anyway, so this is only for tidiness.
gh-account-cleanup-local() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

  local key
  for key in user.name user.email user.signingkey gpg.format commit.gpgsign gpg.ssh.allowedSignersFile; do
    git config --local --unset-all "$key" 2>/dev/null
  done
  print -r -- "gh-account: cleared local identity settings in $(git rev-parse --show-toplevel)."
}

gh-account-sync() {
  command -v gh >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local id host login name email

  if ! id="$(_gh_account_current_id)"; then
    _gh_account_clear_env
    return 0
  fi

  host="${id%%/*}"
  if ! _gh_account_host_is_known "$host"; then
    _gh_account_clear_env
    return 0
  fi

  [[ "$id" == "$_GH_ACCOUNT_APPLIED_ID" ]] && return 0

  if ! login="$(gh-account-map-get "$id" login)"; then
    _gh_account_clear_env
    if _gh_account_is_interactive; then
      gh-account-select
    fi
    return 0
  fi

  name="$(gh-account-map-get "$id" name)"
  email="$(gh-account-map-get "$id" email)"
  _gh_account_apply "$id" "$login" "$name" "$email"
}

alias ghu='gh-account-select'

autoload -Uz add-zsh-hook
add-zsh-hook chpwd gh-account-sync
gh-account-sync
