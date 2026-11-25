#!/bin/bash
# Monthly snap cleanup — fixed 2026-11-25 (NNC_App docs/audit-platform/scheduled-jobs-2026-11-24.md).
# Frees disk by removing OLD (disabled) snap revisions through snap itself, which also deletes
# their files, and by emptying snapd's download cache. The old step 4 ("delete .snap files that
# are not mounted") is gone: its mount parsing matched nothing, so every month it deleted EVERY
# .snap file, the running SSM agent's included. Never delete /var/lib/snapd/snaps/*.snap by hand.
echo "=== Snap cleanup started: $(date) ==="
echo "[1/2] Removing disabled (old) snap revisions..."
snap list --all | awk '/disabled/{print $1, $3}' | while read -r name revision; do
  echo " - Removing $name (rev $revision)"
  sudo snap remove "$name" --revision="$revision"
done
echo "[2/2] Cleaning the snapd download cache..."
sudo rm -f /var/lib/snapd/cache/* 2>/dev/null
echo "=== Snap cleanup completed: $(date) ==="
