#!/bin/bash

mkdir -p /mnt/NAS
mount -t cifs //192.168.2.250/shared_folder /mnt/NAS -o username=XXXX,password=XXXX,rw,iocharset=utf8,uid=1000,gid=1000,vers=3.0

