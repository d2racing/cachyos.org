┌──────────────────────────────────────────┐
│              HDD USB 14 TB                │
│              Pool : backuppool            │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ backuppool/nas_backup               │  │
│  │  mountpoint: /mnt/backup/nas        │  │
│  │                                    │  │
│  │  current/                           │  │
│  │   ├─ CLONEZILLA/                    │  │
│  │   ├─ DIVERS/                        │  │
│  │   ├─ DONNEES/                       │  │
│  │   ├─ homes/                         │  │
│  │   ├─ LOGICIELS/                     │  │
│  │   ├─ photo/                         │  │
│  │   ├─ PHOTOSYNC/                     │  │
│  │   └─ STORAGE_ANALYZER/              │  │
│  │                                    │  │
│  │  Snapshots ZFS                      │  │
│  │   ├─ @auto-YYYYMMDD-HHMM            │  │
│  │   └─ rotation (rsync + snapshots)  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ backuppool/cachyos_backup           │  │
│  │  mountpoint: none                   │  │
│  │  rôle: miroir ZFS passif            │  │
│  │                                    │  │
│  │  Snapshots reçus                    │  │
│  │   ├─ @auto-YYYY-MM-DD_HH-MM         │  │
│  │   └─ incrémental ZFS send           │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│              CachyOS (SSD)                │
│              Pool : zpcachyos             │
│                                          │
│  zpcachyos/ROOT/cos                       │
│  ├─ root      → /                         │
│  ├─ home      → /home                     │
│  ├─ varcache  → /var/cache               │
│  └─ varlog    → /var/log                 │
│                                          │
│  Snapshots locaux                         │
│  ├─ auto-2025-12-17_17-01                │
│  ├─ auto-2025-12-17_17-03                │
│  └─ auto-2025-12-17_17-06                │
│                                          │
│  (snapshots pré-pacman / rollback)       │
└───────────────┬──────────────────────────┘
                ▼
❯ zfs list 
NAME                                 USED  AVAIL  REFER  MOUNTPOINT
backuppool                          3.01T  9.58T    96K  /backuppool
backuppool/cachyos_backup           10.9G  9.58T    96K  none
backuppool/cachyos_backup/home      2.48G  9.58T  2.38G  /home
backuppool/cachyos_backup/root      5.69G  9.58T  5.64G  /
backuppool/cachyos_backup/varcache  2.72G  9.58T  2.72G  /var/cache
backuppool/cachyos_backup/varlog     460K  9.58T   204K  /var/log
backuppool/nas_backup               3.00T  9.58T   100K  /mnt/backup/nas_backup
backuppool/nas_backup/current       3.00T  9.58T  3.00T  /mnt/backup/nas_backup/current
zpcachyos                           11.0G   218G    96K  none
zpcachyos/ROOT                      10.9G   218G    96K  none
zpcachyos/ROOT/cos                  10.9G   218G    96K  none
zpcachyos/ROOT/cos/home             2.51G   218G  2.39G  /home
zpcachyos/ROOT/cos/root             5.72G   218G  5.67G  /
zpcachyos/ROOT/cos/varcache         2.72G   218G  2.72G  /var/cache
zpcachyos/ROOT/cos/varlog            472K   218G   208K  /var/log

zfs list -t snapshot 
NAME                                                       USED  AVAIL  REFER  MOUNTPOINT
backuppool/cachyos_backup@auto-2025-12-16_23-48              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-16_23-57              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-17_00-25              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-17_00-26              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-17_16-57              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-17_17-01              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-17_17-03              0B      -    96K  -
backuppool/cachyos_backup@auto-2025-12-17_17-06              0B      -    96K  -
backuppool/cachyos_backup/home@auto-2025-12-16_23-48      19.2M      -  2.30G  -
backuppool/cachyos_backup/home@auto-2025-12-16_23-57      18.9M      -  2.30G  -
backuppool/cachyos_backup/home@auto-2025-12-17_00-25       524K      -  2.30G  -
backuppool/cachyos_backup/home@auto-2025-12-17_00-26       552K      -  2.30G  -
backuppool/cachyos_backup/home@auto-2025-12-17_16-57      1.13M      -  2.38G  -
backuppool/cachyos_backup/home@auto-2025-12-17_17-01       940K      -  2.38G  -
backuppool/cachyos_backup/home@auto-2025-12-17_17-03       856K      -  2.38G  -
backuppool/cachyos_backup/home@auto-2025-12-17_17-06         0B      -  2.38G  -
backuppool/cachyos_backup/root@auto-2025-12-16_23-48       360K      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-16_23-57       360K      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-17_00-25       232K      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-17_00-26      8.39M      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-17_16-57       112K      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-17_17-01       112K      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-17_17-03       112K      -  5.64G  -
backuppool/cachyos_backup/root@auto-2025-12-17_17-06         0B      -  5.64G  -
backuppool/cachyos_backup/varcache@auto-2025-12-16_23-48     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-16_23-57     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-17_00-25     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-17_00-26     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-17_16-57     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-17_17-01     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-17_17-03     0B      -  2.72G  -
backuppool/cachyos_backup/varcache@auto-2025-12-17_17-06     0B      -  2.72G  -
backuppool/cachyos_backup/varlog@auto-2025-12-16_23-48       0B      -   196K  -
backuppool/cachyos_backup/varlog@auto-2025-12-16_23-57       0B      -   196K  -
backuppool/cachyos_backup/varlog@auto-2025-12-17_00-25      56K      -   196K  -
backuppool/cachyos_backup/varlog@auto-2025-12-17_00-26      68K      -   196K  -
backuppool/cachyos_backup/varlog@auto-2025-12-17_16-57       0B      -   204K  -
backuppool/cachyos_backup/varlog@auto-2025-12-17_17-01       0B      -   204K  -
backuppool/cachyos_backup/varlog@auto-2025-12-17_17-03       0B      -   204K  -
backuppool/cachyos_backup/varlog@auto-2025-12-17_17-06       0B      -   204K  -
backuppool/nas_backup/current@auto-2025-12-17_11-56          0B      -  3.00T  -
zpcachyos/ROOT/cos@auto-2025-12-16_23-48                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-16_23-57                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-17_00-25                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-17_00-26                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-17_16-57                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-17_17-01                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-17_17-03                     0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-17_17-06                     0B      -    96K  -
zpcachyos/ROOT/cos/home@auto-2025-12-16_23-48             19.3M      -  2.31G  -
zpcachyos/ROOT/cos/home@auto-2025-12-16_23-57             19.0M      -  2.31G  -
zpcachyos/ROOT/cos/home@auto-2025-12-17_00-25              560K      -  2.31G  -
zpcachyos/ROOT/cos/home@auto-2025-12-17_00-26              588K      -  2.31G  -
zpcachyos/ROOT/cos/home@auto-2025-12-17_16-57             1.20M      -  2.39G  -
zpcachyos/ROOT/cos/home@auto-2025-12-17_17-01              992K      -  2.39G  -
zpcachyos/ROOT/cos/home@auto-2025-12-17_17-03              904K      -  2.39G  -
zpcachyos/ROOT/cos/home@auto-2025-12-17_17-06             1.09M      -  2.39G  -
zpcachyos/ROOT/cos/root@auto-2025-12-16_23-48              368K      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-16_23-57              368K      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-17_00-25              240K      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-17_00-26             8.40M      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-17_16-57              120K      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-17_17-01              120K      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-17_17-03              120K      -  5.67G  -
zpcachyos/ROOT/cos/root@auto-2025-12-17_17-06              320K      -  5.67G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-16_23-48            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-16_23-57            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-17_00-25            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-17_00-26            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-17_16-57            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-17_17-01            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-17_17-03            0B      -  2.72G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-17_17-06            0B      -  2.72G  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-16_23-48              0B      -   200K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-16_23-57              0B      -   200K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-17_00-25             56K      -   200K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-17_00-26             72K      -   200K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-17_16-57              0B      -   208K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-17_17-01              0B      -   208K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-17_17-03              0B      -   208K  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-17_17-06              0B      -   208K  -








