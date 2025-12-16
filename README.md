/mnt/backup/nas/current/
└── CLONEZILLA/
└── DIVERS/
└── DONNEES/
└── homes/
└── LOGICIELS/
└── photo/
└── PHOTOSYNC/
└── STORAGE_ANALYZER/



backuppool
│
├─ nas_backup
│   └─ current
│       └─ (snapshots du NAS)
│
└─ cachyos_backup
    └─ current
        ├─ ROOT
        │   ├─ cos
        │   │   ├─ home      -> /mnt/cachyos_backup/current/home
        │   │   ├─ root      -> /
        │   │   ├─ varcache  -> /var/cache
        │   │   └─ varlog    -> /var/log
        │   └─ (autres sous-datasets si besoin)
        └─ (snapshots pré-pacman, rotation automatique 10 derniers)
