#!/bin/bash

DISK="/dev/sdb"

wipefs -a $DISK
sgdisk --zap-all $DISK

# Création du pool
zpool create -f -o ashift=12 backuppool $DISK

# Création des datasets pour backup normal
zfs create backuppool/nas_backup
zfs create backuppool/nas_backup/current

zfs set mountpoint=/mnt/backup/nas_backup backuppool/nas_backup
zfs set mountpoint=/mnt/backup/nas_backup/current backuppool/nas_backup/current

# Création sécurisée des datasets pour snapshot de système (cachyos_backup)
zfs create backuppool/cachyos_backup
zfs create backuppool/cachyos_backup/current
# Optionnel : si tu veux snapshotter /send
zfs create backuppool/cachyos_backup/root
zfs create backuppool/cachyos_backup/home
zfs create backuppool/cachyos_backup/varcache
zfs create backuppool/cachyos_backup/varlog

# Sécurisation des datasets système : ne jamais monter automatiquement sur /
sudo zfs set canmount=noauto backuppool/cachyos_backup/root
sudo zfs set canmount=noauto backuppool/cachyos_backup/home
sudo zfs set canmount=noauto backuppool/cachyos_backup/varcache
sudo zfs set canmount=noauto backuppool/cachyos_backup/varlog
sudo zfs set mountpoint=none backuppool/cachyos_backup

# Optimisations HDD USB backup
zfs set compression=zstd backuppool
zfs set atime=off backuppool
zfs set relatime=off backuppool
zfs set xattr=sa backuppool
zfs set redundant_metadata=most backuppool
zfs set relatime=off backuppool/nas_backup/current
zfs set xattr=sa backuppool

# Optimisation débit séquentiel
zfs set recordsize=1M backuppool
zfs set recordsize=1M backuppool/nas_backup
zfs set recordsize=1M backuppool/nas_backup/current

# Vérification finale
zfs get compression,recordsize,atime,relatime,xattr,redundant_metadata backuppool backuppool/nas_backup/current

echo "WD Elements 14TB prêt pour backup ZFS ✔"
