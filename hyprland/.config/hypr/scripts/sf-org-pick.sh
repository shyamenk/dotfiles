#!/usr/bin/env bash

# Salesforce Org Picker for Hyprland (wofi)
# Requires: sf cli, jq, wofi, notify-send

# Ensure sf is in the PATH (especially for Hyprland execution environment)
export PATH="$HOME/.local/bin:$HOME/.nvm/versions/node/v24.13.0/bin:$PATH"
export SF_USE_GENERIC_UNIX_KEYCHAIN=true

# Check if sf is available
if ! command -v sf &>/dev/null; then
    notify-send "Salesforce" "Error: 'sf' command not found. Check your PATH."
    exit 1
fi

# Get list of orgs - Ignore stderr to avoid being tripped up by CLI update warnings
orgs_json=$(sf org list --json 2>/dev/null)

if [[ $? -ne 0 ]] || [[ -z "$orgs_json" ]] || [[ "$orgs_json" == "null" ]]; then
    notify-send "Salesforce" "Error: Could not retrieve org list. Make sure 'sf' is installed and you are logged in."
    exit 1
fi

# Parse orgs and format for wofi
# We'll show: Alias | Username | Status
options=$(echo "$orgs_json" | jq -r '
    .result |
    ([.nonScratchOrgs[]?, .scratchOrgs[]?, .other[]?]) | 
    unique_by(.username) |
    sort_by(.alias // .username) |
    .[] | 
    "\(.alias // "no-alias")  [\(.connectedStatus // "Unknown")]  (\(.username))"
' 2>/dev/null)

if [[ -z "$options" ]]; then
    notify-send "Salesforce" "No orgs found. Run 'sf org login web' to add one."
    exit 0
fi

# Show wofi menu
selected=$(printf '%s\n' "$options" | wofi --dmenu -i -p "Select Salesforce Org" --width 900 --height 500)

[[ -z "$selected" ]] && exit 0

# Extract the username (it is always inside the parentheses at the end)
username=$(echo "$selected" | sed -E 's/.* \((.*)\)/\1/')

# Extract the alias (it is at the beginning)
alias=$(echo "$selected" | awk '{print $1}')

# Use alias if it is not "no-alias", otherwise use username
target="$username"
[[ "$alias" != "no-alias" ]] && target="$alias"

# Ask if we should just set or also open
choice=$(printf "Set as Default\nSet & Open in Browser" | wofi --dmenu -i -p "Action for $target" --width 300 --height 200)

[[ -z "$choice" ]] && exit 0

# Set target-org (Global is usually better for system-wide picker)
if sf config set target-org "$target" --global &>/dev/null; then
    if [[ "$choice" == *"Open"* ]]; then
        notify-send "Salesforce" "Setting $target as default and opening..."
        sf org open -o "$target" &>/dev/null &
    else
        notify-send "Salesforce" "Default org set to: $target (Global)"
    fi
else
    notify-send "Salesforce" "Failed to set default org to: $target"
fi
