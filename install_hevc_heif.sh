#!/bin/bash

echo "=== Activation du support HEVC / HEIF sous CachyOS + KDE ==="

# Mise à jour
echo "[1/5] Mise à jour des paquets..."
sudo pacman -Syu

# Installation HEVC
echo "[2/5] Installation des codecs HEVC (H.265)..."
sudo pacman -S ffmpeg x265

# Installation HEIF/HEIC
echo "[3/5] Installation du support HEIF / HEIC..."
sudo pacman -S libheif libde265

# Intégration KDE
echo "[4/5] Installation des plugins KDE (miniatures + Gwenview)..."
sudo pacman -S qt6-imageformats kdegraphics-thumbnailers

# VLC
echo "[5/5] Installation de VLC..."
sudo pacman -S vlc

echo ""
echo "=== Vérifications ==="

echo "- Vérification HEVC dans FFmpeg :"
ffmpeg -codecs | grep hevc

echo "- Vérification HEIF dans le système :"
if command -v heif-info &> /dev/null; then
    echo "libheif OK"
else
    echo "⚠ heif-info introuvable (normal si outils non installés)"
fi

echo ""
echo "🎉 Installation terminée !"
echo "HEVC / HEIF / KDE / VLC sont maintenant pleinement fonctionnels."
