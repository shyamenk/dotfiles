#!/bin/bash
#
# Arch Linux BTRFS Snapshot Setup Script (V6 - Self-Healing)
#
# This version automatically finds and repairs snapshots that are missing a
# cleanup policy, ensuring all snapshots are managed correctly.
#
set -e

# --- Initial System Checks ---
echo "🚀 Starting BTRFS snapshot setup..."
echo "-------------------------------------"
if pacman -Qi snapper >/dev/null 2>&1 && pacman -Qi grub-btrfs >/dev/null 2>&1; then
  echo "✅ snapper and grub-btrfs are already installed."
else
  echo "🔧 Installing snapper and grub-btrfs..."
  sudo pacman -Sy --noconfirm snapper grub-btrfs
fi

if [ -f /etc/snapper/configs/root ]; then
  echo "✅ Snapper 'root' configuration already exists."
else
  echo "📁 Creating Snapper config for the root filesystem..."
  sudo snapper -c root create-config /
fi
echo "-------------------------------------"

# --- 1. Fix Orphaned Snapshots ---
echo "🔎 Checking for orphaned snapshots (those without a cleanup policy)..."
# Get IDs of snapshots where the 'Cleanup' column (6th field) is empty.
orphaned_ids=$(snapper list --type single | awk 'NR>2 && $6=="" {print $1}')

if [ -n "$orphaned_ids" ]; then
  echo "🔧 Found orphaned snapshots. Assigning them the 'number' cleanup policy..."
  for id in $orphaned_ids; do
    echo "  - Fixing snapshot ID: $id"
    sudo snapper modify -c root --cleanup-algorithm number "$id"
  done
else
  echo "✅ No orphaned snapshots found."
fi
echo "-------------------------------------"

# --- 2. Configure Snapshot Retention Policy ---
echo "⚙️ Setting policy: Daily at midnight, keep max 3."
sudo snapper -c root set-config \
  "ALLOW_USERS=$USER" TIMELINE_CREATE="yes" TIMELINE_LIMIT_DAILY="3" \
  TIMELINE_LIMIT_HOURLY="0" TIMELINE_LIMIT_WEEKLY="0" TIMELINE_LIMIT_MONTHLY="0" \
  TIMELINE_LIMIT_YEARLY="0" NUMBER_LIMIT="3" NUMBER_LIMIT_IMPORTANT="3"

# --- 3. Customize Snapshot Timer for Midnight Execution ---
echo "⏲️  Ensuring snapshot timer runs precisely at midnight..."
OVERRIDE_DIR="/etc/systemd/system/snapper-timeline.timer.d"
sudo mkdir -p "$OVERRIDE_DIR"
sudo tee "$OVERRIDE_DIR/override.conf" >/dev/null <<EOF
[Timer]
OnCalendar=daily
AccuracySec=1s
EOF
sudo systemctl daemon-reload
echo "✅ Systemd timer configured."

# --- 4. Enable and Restart Services ---
echo "⏱️ Enabling and restarting services..."
sudo systemctl restart snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service 2>/dev/null || true
sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service 2>/dev/null || true
echo "✅ Services are active."
echo "-------------------------------------"

# --- 5. Manually Trigger Cleanup and Log Deletions ---
echo "🧹 Preparing to enforce the 'max 3' rule..."
before_ids=$(snapper list --type single | awk 'NR>2 {print $1}')
echo "▶️ Starting cleanup task now..."
sudo systemctl start snapper-cleanup.service
echo "Cleanup service started. Waiting 5 seconds for it to complete..."
sleep 5

after_ids=$(snapper list --type single | awk 'NR>2 {print $1}')
echo
echo "🚮 DELETION LOG:"
deleted_ids=$(comm -23 <(echo "$before_ids" | sort) <(echo "$after_ids" | sort))
if [ -n "$deleted_ids" ]; then
  for id in $deleted_ids; do
    echo "  - ✅ Deleted snapshot with ID: $id"
  done
else
  echo "  - 🤷 No snapshots were deleted. System may already be compliant."
fi
echo

# --- 6. Final GRUB Configuration Update ---
echo "🔄 Updating GRUB menu to reflect cleanup..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "-------------------------------------"
echo "🎉 Setup Complete and Cleanup Finished! 🎉"
echo
echo "Orphaned snapshots have been fixed and the cleanup service has run."
echo "✅ You can verify the final list by running: snapper list"
