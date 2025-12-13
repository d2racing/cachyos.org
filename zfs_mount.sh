sudo systemctl enable zfs-import.target
sudo systemctl enable zfs-mount.service
sudo systemctl enable zfs-import-cache.service

sudo systemctl start zfs-import.target
sudo systemctl start zfs-mount.service

sudo zpool import
sudo zpool import backuppool

/mnt/backup/nas_backup
/mnt/backup/nas_backup/current

sudo zfs mount -a

sudo zfs unmount -a
sudo zfs unmount -R backuppool
sudo zpool export backuppool

sudo zfs unmount backuppool
sudo zpool export backuppool
