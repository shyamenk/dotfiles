#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════╗
# ║  Project Launcher for Hyprland + Wofi                          ║
# ║  Auto-categorizes projects by workspace folder structure       ║
# ║  Supports: open in terminal, editor, or run dev server         ║
# ╚══════════════════════════════════════════════════════════════════╝

WORKSPACE="$HOME/workspace"
TERMINAL="alacritty"
EDITOR_CMD="code" # change to nvim, zed, etc.

# ── Category Mapping ──────────────────────────────────────────────
# Maps top-level workspace folders to display categories + icons
declare -A CATEGORY_MAP=(
  ["amd"]="🔥 Active"
  ["amd/apps"]="🔥 Active"
  ["amd/docs"]="📖 Docs"
  ["amd/reference"]="📖 Docs"
  ["amd/archive"]="📦 Archive"
  ["laucher"]="🔥 Active"
  ["learning"]="📚 Learning"
  ["archive"]="📦 Archive"
  ["web-designs"]="🎨 Design"
  ["web-mockups"]="🎨 Design"
  ["scripts"]="🔧 Tools"
  ["ai-skills"]="🔧 Tools"
  ["data"]="🔧 Tools"
  ["developer-guide"]="📖 Docs"
)

# Fallback category for unmapped folders
DEFAULT_CATEGORY="📂 Other"

# ── Action Menu ───────────────────────────────────────────────────
ACTION_OPEN_TERMINAL=" Open in Terminal"
ACTION_OPEN_EDITOR="󰨞 Open in Editor"
ACTION_OPEN_BOTH="󱂬 Terminal + Editor"
ACTION_GIT_STATUS="󰊢 Git Status"
ACTION_DEV_SERVER="󰜫 Run Dev Server"

TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

# ── Discover Projects ────────────────────────────────────────────
discover_projects() {
  # Scan top-level dirs in workspace
  for top_dir in "$WORKSPACE"/*/; do
    [[ ! -d "$top_dir" ]] && continue
    local top_name
    top_name=$(basename "$top_dir")

    # Skip hidden dirs
    [[ "$top_name" == .* ]] && continue

    # Check if this top-level dir has a category mapping
    if [[ -n "${CATEGORY_MAP[$top_name]}" ]]; then
      local category="${CATEGORY_MAP[$top_name]}"

      # Check if the folder itself is a project
      if is_project "$top_dir"; then
        echo -e "${category}\t${top_name}\t${top_dir}" >>"$TMPFILE"
      fi

      # Also scan one level deep for sub-projects
      for sub_dir in "$top_dir"*/; do
        [[ ! -d "$sub_dir" ]] && continue
        local sub_name
        sub_name=$(basename "$sub_dir")
        [[ "$sub_name" == .* ]] && continue

        # Check sub-path mapping (e.g., amd/apps)
        local sub_key="${top_name}/${sub_name}"
        if [[ -n "${CATEGORY_MAP[$sub_key]}" ]]; then
          local sub_category="${CATEGORY_MAP[$sub_key]}"
          # Scan projects inside this mapped subfolder
          for project_dir in "$sub_dir"*/; do
            [[ ! -d "$project_dir" ]] && continue
            local proj_name
            proj_name=$(basename "$project_dir")
            [[ "$proj_name" == .* ]] && continue
            echo -e "${sub_category}\t${proj_name}\t${project_dir}" >>"$TMPFILE"
          done
        else
          # Sub-dir is a project under the top-level category
          echo -e "${category}\t${sub_name}\t${sub_dir}" >>"$TMPFILE"
        fi
      done
    else
      # Unmapped top-level dir — use default category
      if is_project "$top_dir"; then
        echo -e "${DEFAULT_CATEGORY}\t${top_name}\t${top_dir}" >>"$TMPFILE"
      fi
      # Scan sub-projects
      for sub_dir in "$top_dir"*/; do
        [[ ! -d "$sub_dir" ]] && continue
        local sub_name
        sub_name=$(basename "$sub_dir")
        [[ "$sub_name" == .* ]] && continue
        echo -e "${DEFAULT_CATEGORY}\t${sub_name}\t${sub_dir}" >>"$TMPFILE"
      done
    fi
  done
}

# ── Check if directory looks like a project ──────────────────────
is_project() {
  local dir="$1"
  [[ -f "$dir/.git/HEAD" ]] && return 0
  [[ -f "$dir/package.json" ]] && return 0
  [[ -f "$dir/sfdx-project.json" ]] && return 0
  [[ -f "$dir/Cargo.toml" ]] && return 0
  [[ -f "$dir/go.mod" ]] && return 0
  [[ -f "$dir/pyproject.toml" ]] && return 0
  [[ -f "$dir/requirements.txt" ]] && return 0
  [[ -f "$dir/Makefile" ]] && return 0
  [[ -f "$dir/pom.xml" ]] && return 0
  return 1
}

# ── Detect project type & dev command ────────────────────────────
get_dev_command() {
  local dir="$1"
  if [[ -f "$dir/sfdx-project.json" ]]; then
    echo "sf org open"
  elif [[ -f "$dir/package.json" ]]; then
    if grep -q '"dev"' "$dir/package.json" 2>/dev/null; then
      echo "npm run dev"
    elif grep -q '"start"' "$dir/package.json" 2>/dev/null; then
      echo "npm start"
    else
      echo "echo 'No dev/start script found in package.json'"
    fi
  elif [[ -f "$dir/Cargo.toml" ]]; then
    echo "cargo run"
  elif [[ -f "$dir/go.mod" ]]; then
    echo "go run ."
  elif [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/requirements.txt" ]]; then
    echo "python main.py"
  else
    echo "echo 'No dev command detected'"
  fi
}

# ── Format display with category grouping ────────────────────────
format_menu() {
  sort -t$'\t' -k1,1 -k2,2 "$TMPFILE" | awk -F'\t' '{print $1 " │ " $2}'
}

# ── Main Flow ────────────────────────────────────────────────────

discover_projects

if [[ ! -s "$TMPFILE" ]]; then
  notify-send "Project Launcher" "No projects found in $WORKSPACE"
  exit 0
fi

# Show project picker
SELECTED=$(format_menu | wofi --dmenu -i -p "  Projects" \
  --width 550 --height 450)

[[ -z "$SELECTED" ]] && exit 0

# Extract project name from selection (after " │ ")
PROJECT_NAME=$(echo "$SELECTED" | sed 's/.*│ //')

# Find the matching path
PROJECT_PATH=$(grep -F "$PROJECT_NAME" "$TMPFILE" | head -1 | cut -f3)

if [[ -z "$PROJECT_PATH" || ! -d "$PROJECT_PATH" ]]; then
  notify-send "Project Launcher" "Could not find: $PROJECT_NAME"
  exit 1
fi

# ── Action Picker ────────────────────────────────────────────────
DEV_CMD=$(get_dev_command "$PROJECT_PATH")

ACTION=$(printf '%s\n' \
  "$ACTION_OPEN_TERMINAL" \
  "$ACTION_OPEN_EDITOR" \
  "$ACTION_OPEN_BOTH" \
  "$ACTION_GIT_STATUS" \
  "$ACTION_DEV_SERVER  →  $DEV_CMD" |
  wofi --dmenu -i -p "  Action │ $PROJECT_NAME" \
    --width 500 --height 300)

[[ -z "$ACTION" ]] && exit 0

# ── Execute Action ───────────────────────────────────────────────
case "$ACTION" in
"$ACTION_OPEN_TERMINAL")
  $TERMINAL --working-directory "$PROJECT_PATH"
  ;;
"$ACTION_OPEN_EDITOR")
  $EDITOR_CMD "$PROJECT_PATH"
  ;;
"$ACTION_OPEN_BOTH")
  $TERMINAL --working-directory "$PROJECT_PATH" &
  $EDITOR_CMD "$PROJECT_PATH"
  ;;
"$ACTION_GIT_STATUS")
  $TERMINAL --working-directory "$PROJECT_PATH" -e bash -c "
      echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
      echo '  󰊢 Git Status: $(basename "$PROJECT_PATH")'
      echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
      echo ''
      git -C \"$PROJECT_PATH\" status
      echo ''
      echo '── Recent Commits ──'
      git -C \"$PROJECT_PATH\" log --oneline -10 2>/dev/null
      echo ''
      echo 'Press Enter to continue...'
      read
    "
  ;;
*"$ACTION_DEV_SERVER"*)
  $TERMINAL --working-directory "$PROJECT_PATH" -e bash -c "
      echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
      echo '  󰜫 Dev Server: $(basename "$PROJECT_PATH")'
      echo '  → $DEV_CMD'
      echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
      echo ''
      $DEV_CMD
    "
  ;;
esac
