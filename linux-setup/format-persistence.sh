#!/usr/bin/env bash
# One-click create and format persistence.dat for Ventoy
set -euo pipefail
VENTOY_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
PERSIST="$VENTOY_DIR/persistence.dat"
SIZE_GB=20
echo "Creating ${SIZE_GB}GB persistence image..."
dd if=/dev/zero of="$PERSIST" bs=1M count=0 seek=$((SIZE_GB * 1024))
mkfs.ext4 -F -L casper-rw "$PERSIST"
echo "Done! Reboot for persistence to take effect."
