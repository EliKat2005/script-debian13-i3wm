#!/usr/bin/env bash
# Fix para error 'xterm-kitty': unknown terminal type en SSH
# Ejecuta este script en el servidor (PC con Debian 13)

set -euo pipefail

echo "Instalando soporte para terminales modernos..."

# Instalar ncurses-term para soporte de términales modernos
sudo apt update
sudo apt install -y ncurses-term

echo "✓ Soporte de terminales instalado"
echo ""
echo "Ahora puedes conectar desde Kitty, Alacritty, etc. sin problemas"
