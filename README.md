┌───────────────────────────────────────-───┐
│              HDD USB 14 TB                │
│              Pool : zpbackup              │
│                                           │
│  ┌─────────────────────────────────-───┐  │
│  │  zpbackup/nas_backup                │  │
│  │  mountpoint: /mnt/backup/nas        │  │
│  │                                     │  │
│  │  current/                           │  │
│  │   ├─ CLONEZILLA/                    │  │
│  │   ├─ DIVERS/                        │  │
│  │   ├─ DONNEES/                       │  │
│  │   ├─ homes/                         │  │
│  │   ├─ LOGICIELS/                     │  │
│  │   ├─ photo/                         │  │
│  │   ├─ PHOTOSYNC/                     │  │
│  │   └─ STORAGE_ANALYZER/              │  │
│  │                                     │  │
│  │  Snapshots ZFS                      │  │
│  │   ├─ @auto-YYYYMMDD-HHMM            │  │
│  │   └─ rotation (rsync + snapshots)   │  │
│  └──────────────────────────────────-──┘  │
│                                           │
│  ┌───────────────────────────────────-─┐  │
│  │  zpbackup/cachyos_backup            │  │
│  │  mountpoint: none                   │  │
│  │  rôle: miroir ZFS passif            │  │
│  │                                     │  │
│  │  Snapshots reçus                    │  │
│  │   ├─ @auto-YYYY-MM-DD_HH-MM         │  │
│  │   └─ incrémental ZFS send           │  │
│  └────────────────────────-────────────┘  │
└────────────────────────────-──────────────┘

┌──────────────────────────────-────────────┐
│              CachyOS (SSD)                │
│              Pool : zpcachyos             │
│                                           │
│  zpcachyos/ROOT/cos                       │
│  ├─ root      → /                         │
│  ├─ home      → /home                     │
│  ├─ varcache  → /var/cache                │
│  └─ varlog    → /var/log                  │
│                                           │
│  Snapshots locaux                         │
│  ├─ auto-2025-12-17_17-01                 │
│  ├─ auto-2025-12-17_17-03                 │
│  └─ auto-2025-12-17_17-06                 │
│                                           │
│  (snapshots pré-pacman / rollback)        │
└───────────────┬────────────────────-──────┘
                ▼
❯ zfs list 
NAME                               USED  AVAIL  REFER  MOUNTPOINT
zpbackup                          3.23T  1.19T    96K  none
zpbackup/cachyos_backup           13.3G  1.19T    96K  none
zpbackup/cachyos_backup/home      3.14G  1.19T  2.96G  none
zpbackup/cachyos_backup/root      6.29G  1.19T  5.62G  none
zpbackup/cachyos_backup/varcache  3.89G  1.19T  3.88G  none
zpbackup/cachyos_backup/varlog    5.81M  1.19T  3.54M  none
zpbackup/nas_backup               3.22T  1.19T   108K  /mnt/backup/nas_backup
zpbackup/nas_backup/current       3.22T  1.19T  3.21T  /mnt/backup/nas_backup/current
zpcachyos                         13.4G   215G    96K  none
zpcachyos/ROOT                    13.4G   215G    96K  none
zpcachyos/ROOT/cos                13.4G   215G    96K  none
zpcachyos/ROOT/cos/home           3.18G   215G  2.97G  /home
zpcachyos/ROOT/cos/root           6.32G   215G  5.64G  /
zpcachyos/ROOT/cos/varcache       3.89G   215G  3.89G  /var/cache
zpcachyos/ROOT/cos/varlog         8.22M   215G  3.59M  /var/log

❯ zfs list -t snapshot 
NAME                                                     USED  AVAIL  REFER  MOUNTPOINT
zpbackup/cachyos_backup@auto-2025-12-28_00-26              0B      -    96K  -
zpbackup/cachyos_backup@auto-2025-12-29_19-08              0B      -    96K  -
zpbackup/cachyos_backup@auto-2026-01-02_23-12              0B      -    96K  -
zpbackup/cachyos_backup@auto-2026-01-05_06-21              0B      -    96K  -
zpbackup/cachyos_backup@auto-2026-01-05_06-27              0B      -    96K  -
zpbackup/cachyos_backup/home@auto-2025-12-28_00-26      43.4M      -  2.94G  -
zpbackup/cachyos_backup/home@auto-2025-12-29_19-08      28.7M      -  2.94G  -
zpbackup/cachyos_backup/home@auto-2026-01-02_23-12      31.2M      -  2.97G  -
zpbackup/cachyos_backup/home@auto-2026-01-05_06-21      5.18M      -  2.96G  -
zpbackup/cachyos_backup/home@auto-2026-01-05_06-27         0B      -  2.96G  -
zpbackup/cachyos_backup/root@auto-2025-12-28_00-26      38.3M      -  5.62G  -
zpbackup/cachyos_backup/root@auto-2025-12-29_19-08      27.5M      -  5.62G  -
zpbackup/cachyos_backup/root@auto-2026-01-02_23-12      14.8M      -  5.62G  -
zpbackup/cachyos_backup/root@auto-2026-01-05_06-21      13.7M      -  5.62G  -
zpbackup/cachyos_backup/root@auto-2026-01-05_06-27         0B      -  5.62G  -
zpbackup/cachyos_backup/varcache@auto-2025-12-28_00-26   368K      -  3.50G  -
zpbackup/cachyos_backup/varcache@auto-2025-12-29_19-08   304K      -  3.51G  -
zpbackup/cachyos_backup/varcache@auto-2026-01-02_23-12   128K      -  3.58G  -
zpbackup/cachyos_backup/varcache@auto-2026-01-05_06-21   136K      -  3.58G  -
zpbackup/cachyos_backup/varcache@auto-2026-01-05_06-27     0B      -  3.88G  -
zpbackup/cachyos_backup/varlog@auto-2025-12-28_00-26     424K      -  3.02M  -
zpbackup/cachyos_backup/varlog@auto-2025-12-29_19-08     484K      -  3.08M  -
zpbackup/cachyos_backup/varlog@auto-2026-01-02_23-12     640K      -  3.40M  -
zpbackup/cachyos_backup/varlog@auto-2026-01-05_06-21     724K      -  3.48M  -
zpbackup/cachyos_backup/varlog@auto-2026-01-05_06-27       0B      -  3.54M  -
zpbackup/nas_backup/current@auto-2025-12-25_09-41       5.52M      -  3.10T  -
zpbackup/nas_backup/current@auto-2025-12-27_10-54       3.71M      -  3.11T  -
zpbackup/nas_backup/current@auto-2025-12-27_21-38        496K      -  3.11T  -
zpbackup/nas_backup/current@auto-2025-12-29_19-13       1.20M      -  3.11T  -
zpbackup/nas_backup/current@auto-2026-01-02_23-08        704K      -  3.11T  -
zpbackup/nas_backup/current@auto-2026-01-05_01-08          8K      -  3.21T  -
zpcachyos/ROOT/cos@auto-2025-12-28_00-26                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-29_18-51                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2025-12-29_19-08                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2026-01-02_23-00                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2026-01-02_23-12                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2026-01-05_06-21                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2026-01-05_06-25                   0B      -    96K  -
zpcachyos/ROOT/cos@auto-2026-01-05_06-27                   0B      -    96K  -
zpcachyos/ROOT/cos/home@auto-2025-12-28_00-26           3.34M      -  2.95G  -
zpcachyos/ROOT/cos/home@auto-2025-12-29_18-51           2.42M      -  2.95G  -
zpcachyos/ROOT/cos/home@auto-2025-12-29_19-08           7.25M      -  2.95G  -
zpcachyos/ROOT/cos/home@auto-2026-01-02_23-00           4.60M      -  2.95G  -
zpcachyos/ROOT/cos/home@auto-2026-01-02_23-12           27.2M      -  2.98G  -
zpcachyos/ROOT/cos/home@auto-2026-01-05_06-21           5.21M      -  2.97G  -
zpcachyos/ROOT/cos/home@auto-2026-01-05_06-25            404K      -  2.97G  -
zpcachyos/ROOT/cos/home@auto-2026-01-05_06-27            756K      -  2.97G  -
zpcachyos/ROOT/cos/root@auto-2025-12-28_00-26           14.3M      -  5.65G  -
zpcachyos/ROOT/cos/root@auto-2025-12-29_18-51            928K      -  5.65G  -
zpcachyos/ROOT/cos/root@auto-2025-12-29_19-08           1.05M      -  5.65G  -
zpcachyos/ROOT/cos/root@auto-2026-01-02_23-00           1.36M      -  5.64G  -
zpcachyos/ROOT/cos/root@auto-2026-01-02_23-12           1.55M      -  5.64G  -
zpcachyos/ROOT/cos/root@auto-2026-01-05_06-21           13.8M      -  5.64G  -
zpcachyos/ROOT/cos/root@auto-2026-01-05_06-25            472K      -  5.64G  -
zpcachyos/ROOT/cos/root@auto-2026-01-05_06-27            472K      -  5.64G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-28_00-26        120K      -  3.50G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-29_18-51         96K      -  3.50G  -
zpcachyos/ROOT/cos/varcache@auto-2025-12-29_19-08        152K      -  3.51G  -
zpcachyos/ROOT/cos/varcache@auto-2026-01-02_23-00        176K      -  3.51G  -
zpcachyos/ROOT/cos/varcache@auto-2026-01-02_23-12        128K      -  3.58G  -
zpcachyos/ROOT/cos/varcache@auto-2026-01-05_06-21        136K      -  3.58G  -
zpcachyos/ROOT/cos/varcache@auto-2026-01-05_06-25          0B      -  3.89G  -
zpcachyos/ROOT/cos/varcache@auto-2026-01-05_06-27          0B      -  3.89G  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-28_00-26          432K      -  3.06M  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-29_18-51          468K      -  3.11M  -
zpcachyos/ROOT/cos/varlog@auto-2025-12-29_19-08          476K      -  3.12M  -
zpcachyos/ROOT/cos/varlog@auto-2026-01-02_23-00          672K      -  3.30M  -
zpcachyos/ROOT/cos/varlog@auto-2026-01-02_23-12          632K      -  3.44M  -
zpcachyos/ROOT/cos/varlog@auto-2026-01-05_06-21          732K      -  3.53M  -
zpcachyos/ROOT/cos/varlog@auto-2026-01-05_06-25          552K      -  3.58M  -
zpcachyos/ROOT/cos/varlog@auto-2026-01-05_06-27          524K      -  3.59M  -


