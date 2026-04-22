#!/usr/bin/env bash
# Collect URLs from pane screen + pipe-pane log, write to a temp file for display-popup
set -euo pipefail

pane_id="${1:?pane_id required}"
# Get session_id from tmux directly (display-popup doesn't expand #{} in its command arg)
session_id="$(tmux display-message -p -t "$pane_id" '#{session_id}')"

log_file="/tmp/tmux-pane-${pane_id#%}.log"
out_file="/tmp/tmux-urls-${session_id}.txt"

{
  # Full scrollback (works for regular terminal panes)
  tmux capture-pane -p -t "$pane_id" -S -
  # Current visible screen (captures alternate screen apps like Copilot CLI)
  tmux capture-pane -p -t "$pane_id"
  # pipe-pane log (captures all output including alternate screen history)
  if [[ -s "$log_file" ]]; then cat "$log_file"; fi
} | perl -nE '
  s/\x1b\][^\x1b\x07]*(?:\x07|\x1b\\)/ /g;  # OSC sequences → space
  s/\x1b\[[0-9;?]*[a-zA-Z]/ /g;              # CSI sequences → space
  s/\x1b./ /g;                               # other escape sequences → space
  s/[\x00-\x09\x0b-\x1f\x7f]/ /g;           # control chars → space
  s/\r//g;
  while (/(https?:\/\/[^\s"'"'"'`<>()\[\]{}\\]+)/g) {
    my $u = $1;
    $u =~ s/[^\x20-\x7E]+$//;   # strip trailing non-ASCII (e.g. ❯)
    $u =~ s/[.,;:!?%]+$//;      # strip trailing punctuation and bare %
    $u =~ s/%[0-9a-fA-F]?$//;   # strip incomplete percent-encoding at end
    # Truncate at percent-encoded control chars (%00-%1f, %7f = backspace etc.)
    $u =~ s/%(?:[01][0-9a-fA-F]|7[fF]).*$//i;
    $u =~ s/[.,;:!?]+$//;       # re-strip punctuation after truncation
    say $u if length($u) > 12 && $u =~ /\./
  }
' | sort -u | perl -ne '
  chomp(my $u = $_);
  push @urls, $u;
  END {
    # Remove URLs that are a strict prefix of another URL in the list
    print "$_\n" for grep {
      my $candidate = $_;
      !grep { $_ ne $candidate && index($_, $candidate) == 0 } @urls
    } @urls;
  }
' > "$out_file"
