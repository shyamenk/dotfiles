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
cd "$VAULT_PATH" || { echo "Error: Could not navigate to vault directory"; exit 1; }

# Check if it's a git repository
if [ ! -d .git ]; then
    echo "Error: $VAULT_PATH is not a git repository"
    exit 1
fi

# Add all changes
git add .

# Get a random commit message
RANDOM_INDEX=$((RANDOM % ${#COMMIT_MESSAGES[@]}))
COMMIT_MSG="${COMMIT_MESSAGES[$RANDOM_INDEX]}"

# Only commit if there are changes to commit
if git diff --cached --quiet; then
    echo "No changes to commit"
else
    # Commit with the random message
    git commit -m "$COMMIT_MSG"
    
    # Push to remote repository
    git push origin main || git push origin master
    
    echo "Changes committed and pushed with message: $COMMIT_MSG"
fi
