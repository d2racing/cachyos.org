#!/bin/bash
# ==========================================
# Snapshot de cachyos
# ==========================================

DATASET="zpcachyos/ROOT/cos"
SNAPNAME="snap-$(date +'%Y%m%d-%H:%M')"

echo "Creating ZFS snapshot: ${DATASET}@${SNAPNAME}"
time sudo zfs snapshot -r zpcachyos/ROOT/cos@snap-$(date +'%Y%m%d-%H%M')
zfs list -t snapshot

