#!/bin/bash
# Owner-approved 2026-11-25 ("reinstall the broken snaps that are needed"). Repairs core22 (the
# SSM agent's base) and snapd by installing their current store revisions from file (their old
# revisions' files were deleted by the old snap_cleanup), then drops the old disabled revisions,
# including the unused previous SSM agent revision. Runs detached; logs to the file below.
set -u
LOG=/home/ubuntu/snap_repair_20261125.log
exec >> "$LOG" 2>&1
echo "=== $(date -u +%FT%TZ) repair core22 + snapd on $(hostname)"
cd "$(mktemp -d)"
for s in core22 snapd; do
  echo "--- $s"
  if snap download "$s" >/dev/null 2>&1; then
    snap ack ./"$s"_*.assert && snap install ./"$s"_*.snap && echo "$s: installed current store revision"
  else
    echo "$s: download failed, left as it was"
  fi
done
echo "--- drop disabled revisions (old SSM agent, the broken old core22/snapd)"
snap list --all | awk '/disabled/{print $1, $3}' | while read -r name rev; do
  snap remove "$name" --revision="$rev" && echo "removed $name rev $rev"
done
systemctl reset-failed
echo "--- result"
snap list --all
snap services amazon-ssm-agent
echo "=== REPAIR DONE $(date -u +%FT%TZ)"
