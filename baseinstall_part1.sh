#!/bin/bash
set -e  # Arrête le script si une commande échoue

echo "=== Début de baseinstall_part1 ==="
sudo pacman -Syu  
sudo pacman -S git fastfetch fio btop
paru -S google-chrome 1password anydesk-bin discord signal-desktop 
echo "=== Installation terminée avec succès ==="

