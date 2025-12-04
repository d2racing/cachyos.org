#!/bin/bash
set -e  # Arrête le script si une commande échoue

echo "=== Début de baseinstall_part1 ==="

sudo pacman -Sy --noconfirm 
sudo pacman -S --noconfirm git fastfetch fio btop
sudo pacman -S --noconfirm yay
yay -S --noconfirm google-chrome 1password anydesk-bin discord signal-desktop 

echo "=== Installation terminée avec succès ==="
