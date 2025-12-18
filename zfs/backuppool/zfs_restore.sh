zfs list -t snapshot

backuppool/nas/current@snap-2025-12-10_02-00
backuppool/nas/current@snap-2025-12-11_02-00
backuppool/nas/current@snap-2025-12-12_02-00

ls /mnt/backup/nas/current/.zfs/snapshot/

SNAP="snap-2025-12-12_02-00"
time rsync -a /mnt/backup/nas/current/.zfs/snapshot/$SNAP/photo/ /mnt/backup/nas/current/photo/

zfs rollback -r backuppool/nas/current@snap-2025-12-12_02-00

rsync -a /mnt/backup/nas/current/.zfs/snapshot/$SNAP/photo/ /tmp/restore-photo-test/

