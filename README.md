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
