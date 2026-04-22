function browse-github-notifications() {
  emulate -L zsh
  setopt pipefail

  local command_name='browse-github-notifications'
  local -a dependencies
  local dependency
  dependencies=(gh jq fzf column)

  for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      echo "$command_name: missing dependency: $dependency" >&2
      return 1
    fi
  done

  local tmpdir pages_file entries_file aligned_display_file selection_file
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/${command_name}.XXXXXX")" || return 1
  {
    pages_file="$tmpdir/notifications-pages.json"
    entries_file="$tmpdir/entries.jsonl"
    aligned_display_file="$tmpdir/aligned-display.txt"
    selection_file="$tmpdir/selection.tsv"

    if ! gh api --paginate --slurp 'notifications?all=false&participating=false&per_page=100' >"$pages_file"; then
      echo "$command_name: failed to fetch unread notifications" >&2
      return 1
    fi

    if ! jq -cr '
      flatten
      | map(select(.subject.url != null and (.subject.type == "Issue" or .subject.type == "PullRequest")))
      | .[]
      | {
          repo: .repository.full_name,
          reference: ((.repository.full_name | split("/") | last) + "#" + (.subject.url | split("/") | last)),
          number: (.subject.url | split("/") | last | tonumber),
          title: (.subject.title | gsub("[\t\r\n]+"; " ")),
          reason: .reason,
          type: .subject.type
        }
    ' "$pages_file" >"$entries_file"; then
      echo "$command_name: failed to parse unread notifications" >&2
      return 1
    fi

    if [[ ! -s "$entries_file" ]]; then
      echo "$command_name: no unread issue or pull request notifications" >&2
      return 0
    fi

    if ! {
      printf 'repo#issue\ttitle\treason\n'
      jq -r '
        [.reference, .title, .reason]
        | @tsv
      ' "$entries_file"
    } | column -t -s $'\t' >"$aligned_display_file"; then
      echo "$command_name: failed to format notification list" >&2
      return 1
    fi

    if ! paste -d $'\t' \
      <(tail -n +2 "$aligned_display_file") \
      <(jq -r '
        [.repo, (.number | tostring), .title, .reason, .type]
        | @tsv
      ' "$entries_file") >"$selection_file"; then
      echo "$command_name: failed to prepare notification list" >&2
      return 1
    fi

    local header _display selection selection_status title type
    local command_line
    local -a command_parts
    header="$(head -n 1 "$aligned_display_file")"
    selection="$(
      fzf \
        --reverse \
        --height=20 \
        --delimiter=$'\t' \
        --with-nth=1 \
        --header="$header" <"$selection_file"
    )"
    selection_status=$?

    if (( selection_status != 0 )); then
      if (( selection_status == 1 || selection_status == 130 )); then
        if [[ -n "${WIDGET:-}" ]]; then
          zle reset-prompt
        fi

        return 0
      fi

      echo "$command_name: failed to select a notification" >&2
      return 1
    fi

    IFS=$'\t' read -r _display repo number title reason type <<< "$selection"

    case "$type" in
      PullRequest)
        command_parts=(gh pr view "$number" -R "$repo" "$@")
        ;;
      Issue)
        command_parts=(gh issue view "$number" -R "$repo" "$@")
        ;;
      *)
        echo "$command_name: unsupported notification type: $type" >&2
        return 1
        ;;
    esac

    command_line="${(j: :)${(@q)command_parts}}"
    run-selected-command "$command_line" "${command_parts[@]}"
  } always {
    rm -rf "$tmpdir"
  }
}

alias bgn='browse-github-notifications'
zle -N browse-github-notifications
