#!/bin/bash
set -e  # Arrête le script si une commande échoue

echo "=== Début de baseinstall_part1 ==="
pacman -Syu  
pacman -S git fastfetch fio btop
echo "=== Installation terminée avec succès ==="
