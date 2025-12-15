#!/bin/bash
set -euo pipefail

POOL="backuppool"
DST="/mnt/backup/nas_backup"



# 1. Import pool (do nothing if already imported)
if ! zpool list -H -o name | grep -qx "$POOL"; then
  sudo zpool import "$POOL"
fi

# 2. Mount all datasets
sudo zfs mount -a

# 3. Hard verification (NON-NEGOTIABLE)
mountpoint -q "$DST" || {
  echo "ERROR: $DST is not mounted"
  exit 1
}

# 4. Show status (sanity check)
zpool status "$POOL"
zfs list "$POOL"

sudo zfs list -o name,canmount,mounted,mountpoint
sudo zfs get compression,recordsize,atime,relatime,xattr,redundant_metadata backuppool backuppool/nas_backup/current
