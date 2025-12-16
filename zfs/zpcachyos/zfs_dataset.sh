#/bin/bash

zfs create -o mountpoint=/mnt/cachyos_backup backuppool/cachyos_backup
zfs create -o mountpoint=/mnt/cachyos_backup/current backuppool/cachyos_backup/current
