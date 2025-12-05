sudo systemctl enable zfs-import.target
sudo systemctl enable zfs-mount.service
sudo systemctl enable zfs-import-cache.service

sudo systemctl start zfs-import.target
sudo systemctl start zfs-mount.service

sudo zpool import
sudo zpool import backuppool

/mnt/backup/nas_backup
/mnt/backup/nas_backup/current
/mnt/backup/nas_backup/snapshots

sudo zfs mount -a
