# Repository-local GH auth storage (.git/gh) and git identity sync from gh auth.
is_github_origin_repo() {
  local origin_url
  origin_url="$(git config --get remote.origin.url 2>/dev/null || true)"
  [[ "$origin_url" == *"github.com"* ]]
}

resolve_gh_identity() {
  local login profile_name public_email primary_verified primary_any user_line emails_status

  if ! user_line="$(gh api user --jq '[.login // "", .name // "", .email // ""] | @tsv' 2>/dev/null)"; then
    return 1
  fi
  IFS=$'\t' read -r login profile_name public_email <<<"$user_line"
  [[ -z "$login" ]] && return 1

  emails_status="ok"
  if ! primary_verified="$(gh api user/emails --jq 'map(select(.primary == true and .verified == true) | .email)[0] // empty' 2>/dev/null)"; then
    primary_verified=""
    emails_status="scope_missing"
  fi
  if ! primary_any="$(gh api user/emails --jq 'map(select(.primary == true) | .email)[0] // empty' 2>/dev/null)"; then
    primary_any=""
    emails_status="scope_missing"
  fi
  if [[ -z "$primary_verified" && -z "$primary_any" && -z "$public_email" && "$emails_status" == "ok" ]]; then
    emails_status="private_or_unset"
  fi

  printf '%s\t%s\t%s\t%s\n' "$login" "$profile_name" "${primary_verified:-${primary_any:-$public_email}}" "$emails_status"
  return 0
}

sync_git_identity_from_gh() {
  local login profile_name email emails_status current_name current_email identity_line

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  command -v gh >/dev/null 2>&1 || return 0
  is_github_origin_repo || return 0

  current_name="$(git config --local --get user.name 2>/dev/null || true)"
  current_email="$(git config --local --get user.email 2>/dev/null || true)"
  if [[ -n "$current_name" && -n "$current_email" ]]; then
    return 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated for this repository. Run 'gh auth login' to sync git identity."
    return 0
  fi

  identity_line="$(resolve_gh_identity)" || return 0
  login="${identity_line%%$'\t'*}"
  identity_line="${identity_line#*$'\t'}"
  profile_name="${identity_line%%$'\t'*}"
  email="${identity_line#*$'\t'}"
  if [[ "$email" == *$'\t'* ]]; then
    emails_status="${email#*$'\t'}"
    email="${email%%$'\t'*}"
  else
    emails_status="ok"
  fi

  [[ -n "$login" ]] || return 0

  if [[ -n "$profile_name" && "$current_name" != "$profile_name" ]]; then
    git config --local user.name "$profile_name"
    echo "Set local git user.name to '${profile_name}'."
  fi

  if [[ -n "$email" ]]; then
    if [[ "$current_email" != "$email" ]]; then
      git config --local user.email "$email"
      echo "Set local git user.email to '${email}'."
    fi
  elif [[ -z "$current_email" ]]; then
    if [[ "$emails_status" == "scope_missing" ]]; then
      echo "Warning: Could not read your GitHub email. Your gh token may be missing the 'user:email' scope. Run 'gh auth refresh -h github.com -s user:email'."
    else
      echo "Warning: Could not resolve your GitHub email. It may be private or unset on your GitHub profile."
    fi
  fi
}

set_gh_config_dir() {
  local repo_gh_config
  repo_gh_config="$(git rev-parse --path-format=absolute --git-path gh 2>/dev/null)" || repo_gh_config=""

  if [[ -n "$repo_gh_config" ]]; then
    mkdir -p "$repo_gh_config"
    export GH_CONFIG_DIR="$repo_gh_config"
    sync_git_identity_from_gh
  else
    unset GH_CONFIG_DIR
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd set_gh_config_dir
set_gh_config_dir
