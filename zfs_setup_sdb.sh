#!/bin/bash

DISK="/dev/sdb"

sudo wipefs -a $DISK
sudo sgdisk --zap-all $DISK

sudo zpool create -f \
  -o ashift=12 \
  backuppool \
  $DISK

sudo zfs create backuppool/nas_backup
sudo zfs create backuppool/nas_backup/current
sudo zfs create backuppool/nas_backup/snapshots

sudo zfs set mountpoint=/mnt/backup/nas_backup backuppool/nas_backup
sudo zfs set mountpoint=/mnt/backup/nas_backup/current backuppool/nas_backup/current
sudo zfs set mountpoint=/mnt/backup/nas_backup/snapshots backuppool/nas_backup/snapshots

sudo zfs set compression=zstd backuppool
sudo zfs set atime=off backuppool


