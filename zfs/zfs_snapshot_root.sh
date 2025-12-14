#!/bin/bash
# ==========================================
# Snapshot de cachyos
# ==========================================

#!/usr/bin/env bash

DATASET="zpcachyos/ROOT/cos"
SNAPNAME="snap-$(date +'%Y%m%d-%H:%M')"

echo "Creating ZFS snapshot: ${DATASET}@${SNAPNAME}"
time sudo zfs snapshot "${DATASET}@${SNAPNAME}"
