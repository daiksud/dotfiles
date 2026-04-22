#!/usr/bin/env bash
# Start pipe-pane logging for the given pane
pane_id="$1"
log_file="/tmp/tmux-pane-${pane_id#%}.log"
tmux pipe-pane -t "$pane_id" "cat >> '$log_file'"
