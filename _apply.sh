#!/bin/bash

set -euo pipefail
# Create a timestamped backup of the .plandex-dev directory
echo "Creating backup of .plandex-dev directory..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR=".plandex-dev_backup_${TIMESTAMP}"

# Check if .plandex-dev directory exists
if [ -d ".plandex-dev" ]; then
  # Create backup
  cp -r .plandex-dev "${BACKUP_DIR}"
  echo "Backup created at ${BACKUP_DIR}"
else
  echo "Warning: .plandex-dev directory not found. Skipping backup."
fi

# Initialize Git repository if it doesn't exist
if [ ! -d ".git" ]; then
  echo "Initializing Git repository..."
  git init
  echo "Git repository initialized."
else
  echo "Git repository already exists."
fi

# Add all files to Git staging
echo "Adding files to Git staging..."
git add .

# Create a commit with a descriptive message
echo "Creating initial commit..."
git commit -m "Initial commit with project setup and .plandex-dev backup"

echo "Backup and Git repository setup completed successfully."

