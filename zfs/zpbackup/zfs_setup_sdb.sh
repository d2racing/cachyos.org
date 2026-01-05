#!/bin/bash
set -e

DISK="/dev/disk/by-id/usb-WD_Elements_14TB_XXXX"
POOL="zpbackup"

echo "⚠️  DESTROYING ALL DATA ON $DISK"
sleep 2

wipefs -a "$DISK"
sgdisk --zap-all "$DISK"

# Create pool
zpool create -f -o ashift=12 "$POOL" "$DISK"

# ---- Backup datasets ----
zfs create "$POOL/nas_backup"
zfs create "$POOL/nas_backup/current"

zfs set mountpoint=/mnt/backup/nas_backup "$POOL/nas_backup"
zfs set mountpoint=/mnt/backup/nas_backup/current "$POOL/nas_backup/current"

# ---- System snapshot datasets (never auto-mounted) ----
zfs set mountpoint=none "$POOL"
zfs create "$POOL/cachyos_backup"
zfs set mountpoint=none "$POOL/cachyos_backup"

zfs create "$POOL/cachyos_backup/current"
zfs create "$POOL/cachyos_backup/root"
zfs create "$POOL/cachyos_backup/home"
zfs create "$POOL/cachyos_backup/varcache"
zfs create "$POOL/cachyos_backup/varlog"

zfs set canmount=noauto "$POOL/cachyos_backup/root"
zfs set canmount=noauto "$POOL/cachyos_backup/home"
zfs set canmount=noauto "$POOL/cachyos_backup/varcache"
zfs set canmount=noauto "$POOL/cachyos_backup/varlog"

# ---- HDD / USB backup tuning ----
zfs set compression=zstd "$POOL"
zfs set atime=off "$POOL"
zfs set relatime=off "$POOL"
zfs set xattr=sa "$POOL"
zfs set redundant_metadata=most "$POOL"

zfs set recordsize=1M "$POOL"
zfs set recordsize=1M "$POOL/nas_backup"
zfs set recordsize=1M "$POOL/nas_backup/current"

# ---- Verification ----
zfs get compression,recordsize,atime,relatime,xattr,redundant_metadata \
  "$POOL" "$POOL/nas_backup/current"

echo "✅ WD Elements 14TB ready as ZFS backup pool ($POOL)"
