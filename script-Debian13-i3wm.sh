#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-${USER:-}}"
if [[ -z "$USER_NAME" ]]; then
  echo "No se detectó usuario sudo. Ejecuta el script con sudo: sudo $0"
  exit 1
fi
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
if [[ -z "$USER_HOME" ]]; then
  echo "No se pudo resolver el home de $USER_NAME" >&2
  exit 1
fi

log(){ echo -e "\n[+] $1"; }

# FASE 1: tareas como root
need_root(){ if [[ $EUID -ne 0 ]]; then echo "Este bloque requiere privilegios de root. Ejecuta con sudo: sudo $0"; exit 1; fi }
need_root

log "Actualizar sistema"
export DEBIAN_FRONTEND=noninteractive
#Modificación Bluetooth
apt update
apt -y full-upgrade


log "Instalar paquetes Bluetooth requeridos (BlueZ + plugins PipeWire + ofono)"
apt -y install bluez bluez-tools libspa-0.2-bluetooth ofono ofono-phonesim || {
  log "Fallo instalando paquetes bluetooth; revisa la conexión o los repos."
  exit 1
}

# Quitar módulo de Pulseaudio Bluetooth si se instaló por accidente (conflicta con PipeWire)
if dpkg -l | grep -q pulseaudio-module-bluetooth; then
  log "Eliminando pulseaudio-module-bluetooth (conflicto con PipeWire)"
  apt -y remove --purge pulseaudio-module-bluetooth || true
fi

# Asegurar carga del módulo btusb en el arranque (útil para adaptadores USB/PCI Bluetooth)
echo "btusb" > /etc/modules-load.d/btusb.conf || true

# Intentar cargarlo ahora (silencioso)
modprobe btusb 2>/dev/null || true

# Desbloquear rfkill bluetooth por si está bloqueado al inicio
rfkill unblock bluetooth || true

# Preseed para evitar prompts al instalar display manager (lightdm)
log "Preseed display manager (lightdm) para instalación no interactiva"
debconf-set-selections <<EOF
shared/default-x-display-manager select lightdm
EOF

log "Instalar paquetes base (menos recomendados para ser más ligeros)"
PKGS=(
  # Sistema base
  curl wget pciutils usbutils lshw net-tools ufw xinput mesa-utils
  wpasupplicant wireless-tools rfkill light
  acpi gvfs-backends iw udisks2
  # Paquetes base del servidor gráfico y utilidades
  xorg xserver-xorg xserver-xorg-input-libinput arandr autorandr xbindkeys
  i3-wm i3status i3lock xss-lock dunst
  kitty lxpolkit udiskie
  # Display manager
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
  # Audio (PipeWire + compat)
  pavucontrol pipewire pipewire-audio-client-libraries pipewire-pulse wireplumber playerctl
  pulseaudio-utils
  # Network
  network-manager network-manager-gnome firmware-atheros
  # RAM/ZRAM
  zram-tools
  # Brillo: usamos 'light' en la configuración de i3
  brightnessctl light
  # Varios utilitarios y formato
  xdg-user-dirs
  unzip zip tar gzip bzip2 xarchiver
  # Fuentes y temas
  fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji
  fonts-font-awesome fonts-terminus
  papirus-icon-theme yaru-theme-gtk desktop-base
  # Programas en general
  fastfetch btop cava
  zathura zathura-pdf-poppler
  chromium rofi mpv
  pcmanfm gvfs
  flameshot feh
  blueman gparted
  galculator
  ranger python3-pil
  lxappearance picom
  # Opcional: centro de software y backup
  gnome-software
  timeshift
  # Sensores / hardware
  lm-sensors
)

# Instalar con control de fallo parcial.
apt -y --no-install-recommends install "${PKGS[@]}" || (log "Fallo con --no-install-recommends; reintentando con recomendaciones" && apt -y install "${PKGS[@]}")

log "Limpieza"
apt -y autoremove

# Añadir usuario al grupo video para permitir control no-root del backlight
if ! id -nG "$USER_NAME" | grep -qw video; then
  log "Añadiendo $USER_NAME al grupo video (para controlar brillo sin sudo)"
  usermod -aG video "$USER_NAME" || true
fi

log "Habilitar servicios necesarios"
systemctl enable --now NetworkManager || true
systemctl enable --now lightdm || true
log "Asegurar servicios habilitados"
systemctl enable --now bluetooth || true


log "Configurar ZRAM"
if [[ -f /etc/default/zramswap ]]; then
  sed -i 's/^#*\s*ALGO=.*/ALGO=lz4/' /etc/default/zramswap || true
  sed -i 's/^#*\s*PERCENT=.*/PERCENT=50/' /etc/default/zramswap || true
  systemctl enable --now zramswap.service || true
else
  log "Advertencia: /etc/default/zramswap no encontrado; zram-tools puede usar otro archivo. Comprueba manualmente."
fi

log "Configurar touchpad (tap + natural scrolling)"
mkdir -p /etc/X11/xorg.conf.d
tee /etc/X11/xorg.conf.d/40-libinput.conf > /dev/null <<'EOF'
Section "InputClass"
    Identifier "libinput touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
EndSection
EOF

# SOLUCIONES AGREGADAS PARA PROBLEMAS ESPECÍFICOS

# 1. Script de control de brillo con límites mínimos y máximos
log "Creando script de control de brillo con límites (MIN=5%, MAX=95%)"
tee /usr/local/bin/i3-brightness > /dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail

DEVICE=""
MIN=5
MAX=95
STEP=10

cmd="${1:-}"

# Obtener valor actual en porcentaje con 'light'
curr=$(light -G | awk '{print int($1+0.5)}')

if [[ "$cmd" == "up" ]]; then
  new=$((curr + STEP))
  if (( new > MAX )); then new=$MAX; fi
elif [[ "$cmd" == "down" ]]; then
  new=$((curr - STEP))
  if (( new < MIN )); then new=$MIN; fi
else
  echo "Uso: $0 up|down"
  exit 1
fi

# Aplicar
light -S "$new"
echo "Brillo: ${new}%"
SH

chmod +x /usr/local/bin/i3-brightness

# 2. Forzar carga del módulo ath10k_pci al inicio (para tarjetas WiFi Atheros QCA6174)
log "Configurando carga automática del módulo ath10k_pci para WiFi"
echo "ath10k_pci" | tee /etc/modules-load.d/ath10k.conf

# Opcional: Reiniciar el módulo después de la instalación (por si hay problemas de detección)
if lsmod | grep -q ath10k_pci; then
    log "Recargando módulo ath10k_pci..."
    modprobe -r ath10k_pci 2>/dev/null || true
    modprobe ath10k_pci
else
    log "Cargando módulo ath10k_pci..."
    modprobe ath10k_pci
fi

# FASE 2: tareas como usuario no-root
log "Crear configuración de usuario en $USER_NAME"

# Ejecutar los pasos de configuración de usuario en el contexto del usuario objetivo
sudo -u "$USER_NAME" -H bash -c '
set -euo pipefail

# Habilitar servicios de usuario para PipeWire/WirePlumber (arrancarán en el login)
systemctl --user enable pipewire pipewire-pulse wireplumber || true

# Crear configuración de WirePlumber en el home del usuario para habilitar HFP/mSBC
mkdir -p "$HOME/.config/wireplumber/bluetooth.lua.d"

cat > "$HOME/.config/wireplumber/bluetooth.lua.d/50-bluez-config.lua" <<'"LUA"'
-- Habilitar HSP/HFP/mSBC y mejoras para BlueZ
bluez_monitor.properties = {
  ["bluez5.enable-hsp"] = true,
  ["bluez5.enable-hfp_hf"] = true,
  ["bluez5.enable-msbc"] = true,   -- habilitar mSBC (mejor codec para micrófono)
  ["bluez5.enable-sbc-xq"] = true
}
LUA

# Crear directorios de usuario habituales
mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/gtk-3.0"

# Reiniciar servicios de usuario para aplicar configuración ahora (no esperar relogin)
# Nota: si la sesión del usuario no está activa, systemctl --user start/restart puede fallar; aquí intentamos con tolerancia.
systemctl --user restart pipewire pipewire-pulse wireplumber || true

# Opcional: asegurarse de que ofono está habilitado en caso de usarlo para HFP (puedes quitar esta línea si no quieres ofono)
# systemctl --user enable --now ofono || true

'

# Asegurar propiedad desde root (por si algo se escribió como root)
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/wireplumber" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/i3" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/gtk-3.0" || true


# Configuración de i3
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/i3/config" > /dev/null <<'I3CFG'

I3CFG

# i3status config
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/i3/i3status.conf" > /dev/null <<'STATCFG'

STATCFG

# GTK theme
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null <<'GTKCFG'
[Settings]
gtk-theme-name=Yaru-blue-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 10
GTKCFG

log "Corregir permisos y propiedad"
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config"
chmod 700 "$USER_HOME/.config"

log "Actualizar xdg user dirs"
sudo -u "$USER_NAME" -H xdg-user-dirs-update || true

log "NOTAS POST-INSTALACIÓN:"
log " - Si quieres ver temperaturas en la barra: ejecuta 'sudo sensors-detect' y luego 'sensors'"
log " - Si el WiFi no aparece: el módulo ath10k_pci se carga automáticamente. Si persisten problemas, revisa 'dmesg | grep ath10k'"
log " - Debes reloguear o reiniciar para que la adición al grupo 'video' surta efecto"
log "Final: reinicia el equipo."

exit 0
