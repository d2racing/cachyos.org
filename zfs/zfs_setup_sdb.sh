#!/bin/bash

DISK="/dev/sdb"

wipefs -a $DISK
sgdisk --zap-all $DISK

zpool create -f \
  -o ashift=12 \
  backuppool \
  $DISK

zfs create backuppool/nas_backup
zfs create backuppool/nas_backup/current

zfs set mountpoint=/mnt/backup/nas_backup backuppool/nas_backup
zfs set mountpoint=/mnt/backup/nas_backup/current backuppool/nas_backup/current

# Optimisations HDD USB backup
zfs set compression=zstd backuppool
zfs set atime=off backuppool
zfs set relatime=off backuppool
zfs set xattr=sa backuppool
zfs set redundant_metadata=most backuppool

# Optimisation débit séquentiel
zfs set recordsize=1M backuppool/nas_backup
zfs set recordsize=1M backuppool/nas_backup/current

echo "WD Elements 14TB prêt pour backup ZFS ✔"
