#!/bin/bash
# Voxtype post_output_command hook. Voxtype execs this command directly
# (no shell, so no &&/;  chaining) -- this script does both steps itself:
# reset the voxtype_suppress submap, then auto-submit (Enter) only when the
# focused window is a terminal running Claude Code.

hyprctl dispatch submap reset >/dev/null

win_pid="$(hyprctl activewindow -j | jq -r '.pid // empty')"

if [[ -n "$win_pid" ]] && pstree -p "$win_pid" | grep -q 'claude('; then
    wtype -k Return
fi
