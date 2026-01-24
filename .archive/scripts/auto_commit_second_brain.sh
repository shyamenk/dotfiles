#!/bin/bash
# Path to your Second Brain vault
VAULT_PATH="$HOME/Documents/Second Brain"

# Array of random commit messages
COMMIT_MESSAGES=(
  "Update Second Brain contents"
  "Add new thoughts and ideas"
  "Reorganize knowledge structure"
  "Refine notes and connections"
  "Integrate new learnings"
  "Enhance knowledge base"
  "Archive valuable insights"
  "Update reference materials"
  "Clean up old entries"
  "Improve categorization system"
  "Add new resources and links"
  "Document recent discoveries"
  "Consolidate related concepts"
  "Expand on existing topics"
  "Restructure information hierarchy"
)

# Navigate to the vault directory
cd "$VAULT_PATH" || {
  echo "Error: Could not navigate to vault directory"
  exit 1
}

# Check if it's a git repository
if [ ! -d .git ]; then
  echo "Error: $VAULT_PATH is not a git repository"
  exit 1
fi

# Add all changes
git add .

# Debug: Check array length
echo "Array length: ${#COMMIT_MESSAGES[@]}"

# Get a random commit message with safety check
if [ ${#COMMIT_MESSAGES[@]} -eq 0 ]; then
  echo "Error: No commit messages defined"
  exit 1
fi

RANDOM_INDEX=$((RANDOM % ${#COMMIT_MESSAGES[@]}))
COMMIT_MSG="${COMMIT_MESSAGES[$RANDOM_INDEX]}"

echo "Selected message: $COMMIT_MSG"

# Only commit if there are changes to commit
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  # Commit with the random message
  git commit -m "$COMMIT_MSG"

  # Get current branch name and push to it
  CURRENT_BRANCH=$(git branch --show-current)
  git push origin "$CURRENT_BRANCH"

  echo "Changes committed and pushed to $CURRENT_BRANCH with message: $COMMIT_MSG"
fi
