zfs list -t snapshot

zpbackup/nas/current@snap-2025-12-12_02-00

SNAP="snap-2025-12-12_02-00"

mkdir -p /mnt/nas/photo_restore

mount -t cifs "//192.168.2.250/photo" /mnt/nas/photo_restore -o credentials=/root/.nas-credentials,iocharset=utf8,vers=3.0,rw
rsync -a --dry-run --delete /mnt/backup/nas/current/.zfs/snapshot/$SNAP/photo/ /mnt/nas/photo_restore/


for SHARE in photo homes DONNEES; do
  mkdir -p /mnt/nas/restore_$SHARE

  mount -t cifs "//192.168.2.250/$SHARE" /mnt/nas/restore_$SHARE \
    -o credentials=/root/.nas-credentials,iocharset=utf8,vers=3.0,rw

  rsync -a --dry-run \
  /mnt/backup/nas/current/.zfs/snapshot/$SNAP/$SHARE/ \
  /mnt/nas/restore_$SHARE/

  umount /mnt/nas/restore_$SHARE
done

cp /mnt/backup/nas/current/.zfs/snapshot/$SNAP/photo/2023/vacances/img001.jpg \
/mnt/nas/photo_restore/2023/vacances/

