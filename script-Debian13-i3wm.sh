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

log "Habilitar repositorios non-free y contrib para firmware"
# Debian 13 usa formato DEB822 moderno en /etc/apt/sources.list.d/debian.sources
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
  # Backup del archivo moderno
  cp /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.backup-$(date +%Y%m%d) 2>/dev/null || true
  
  # Verificar si ya están habilitados contrib y non-free
  if ! grep -q "contrib non-free" /etc/apt/sources.list.d/debian.sources; then
    log "Añadiendo contrib y non-free a debian.sources"
    sed -i.bak 's/Components: main non-free-firmware/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
    log "Repositorios non-free habilitados en formato DEB822"
  else
    log "Repositorios non-free ya están habilitados"
  fi
elif [[ -f /etc/apt/sources.list ]]; then
  # Fallback para sistemas con sources.list tradicional
  cp /etc/apt/sources.list /etc/apt/sources.list.backup-$(date +%Y%m%d) 2>/dev/null || true
  if ! grep -q "contrib non-free" /etc/apt/sources.list; then
    sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
    log "Repositorios non-free habilitados en sources.list"
  else
    log "Repositorios non-free ya están habilitados"
  fi
else
  log "ADVERTENCIA: No se encontró debian.sources ni sources.list"
fi

log "Verificar conectividad a internet"
if ! wget -q --spider --tries=1 --timeout=3 https://deb.debian.org 2>/dev/null; then
  log "Advertencia: No hay conexión a internet. Conecta WiFi/Ethernet antes de continuar."
  log "Presiona Enter cuando estés conectado..."
  read -r
fi

log "Actualizar sistema y cache de paquetes"
export DEBIAN_FRONTEND=noninteractive
apt update
apt -y full-upgrade

log "Instalar firmware completo (Intel, Atheros WiFi, Bluetooth)"
# Firmware crítico para tu hardware específico
KERNEL_VERSION=$(uname -r)
apt -y install \
  firmware-linux-nonfree \
  firmware-misc-nonfree \
  firmware-intel-sound \
  firmware-atheros \
  firmware-realtek \
  intel-microcode || {
  log "Advertencia: Algunos paquetes de firmware no se instalaron. Continuando..."
}

# Instalar headers del kernel si están disponibles
if apt-cache show "linux-headers-$KERNEL_VERSION" &>/dev/null; then
  apt -y install "linux-headers-$KERNEL_VERSION" || log "Headers del kernel no disponibles"
else
  log "Headers para kernel $KERNEL_VERSION no encontrados en repositorios"
fi

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

# Configurar módulos de kernel para carga automática
log "Configurar carga de módulos de kernel (Bluetooth, WiFi)"

# Bluetooth
echo "btusb" > /etc/modules-load.d/btusb.conf || true

# WiFi Atheros (QCA9377 en Inspiron 5584)
echo "ath10k_pci" > /etc/modules-load.d/ath10k.conf || true

# Intel graphics
echo "i915" > /etc/modules-load.d/i915.conf || true

# Cargar módulos inmediatamente
modprobe btusb 2>/dev/null || true
modprobe ath10k_pci 2>/dev/null || true
modprobe i915 2>/dev/null || true

# Desbloquear todos los dispositivos wireless
rfkill unblock all || true

# Configurar NetworkManager para manejar todos los dispositivos
mkdir -p /etc/NetworkManager/conf.d
tee /etc/NetworkManager/conf.d/99-unmanaged-devices.conf > /dev/null <<'NMCONF'
[keyfile]
unmanaged-devices=none

[device]
wifi.scan-rand-mac-address=no
NMCONF

# Preseed para evitar prompts al instalar display manager (lightdm)
log "Preseed display manager (lightdm) para instalación no interactiva"
debconf-set-selections <<EOF
shared/default-x-display-manager select lightdm
EOF

log "Instalar paquetes esenciales"
PKGS=(
  # Sistema base y utilidades
  curl wget git pciutils usbutils
  wpasupplicant rfkill iw ethtool
  acpi udisks2 xdg-user-dirs
  
  # Servidor gráfico X11 + i3wm
  xorg xserver-xorg xserver-xorg-input-libinput
  i3-wm i3status i3lock xss-lock dunst picom
  arandr autorandr xrandr             # Gestión de pantallas (HDMI, monitores externos)
  lxpolkit udiskie
  lightdm lightdm-gtk-greeter
  
  # Audio PipeWire
  pipewire pipewire-pulse wireplumber
  pipewire-audio-client-libraries
  pavucontrol playerctl
  pulseaudio-utils                    # Utilidades pactl (compatible con PipeWire)
  
  # Red y Bluetooth
  network-manager network-manager-gnome
  blueman
  
  # Gestión de RAM
  zram-tools
  
  # Control de brillo
  light
  
  # Archivos comprimidos
  unzip zip p7zip-full rar unrar
  tar gzip bzip2 xz-utils
  xarchiver                           # Gestor gráfico de archivos comprimidos
  
  # Fuentes
  fonts-noto-core fonts-noto-color-emoji
  fonts-font-awesome fonts-dejavu
  
  # Temas e iconos
  papirus-icon-theme arc-theme
  
  # Aplicaciones principales
  kitty
  chromium                            # Navegador principal
  rofi mpv                            # Lanzador de apps y reproductor multimedia
  pcmanfm                             # Gestor de archivos
  gvfs gvfs-backends gvfs-fuse        # Soporte completo para montaje automático
  zathura zathura-pdf-poppler         # Visor de PDF minimalista
  feh flameshot                       # Fondo de pantalla y capturas de pantalla
  galculator lxappearance
  gparted timeshift
  
  # Visor de imágenes
  ristretto                           # Visor de imágenes ligero
  
  # Hardware y sensores
  lm-sensors mesa-utils
  
  # Utilidades del sistema
  neofetch                            # Info del sistema
)

# Instalar con control de fallo parcial.
apt -y --no-install-recommends install "${PKGS[@]}" || (log "Fallo con --no-install-recommends; reintentando con recomendaciones" && apt -y install "${PKGS[@]}")

log "Limpieza"
apt -y autoremove

log "Añadiendo $USER_NAME a grupos necesarios"
for group in video render input netdev bluetooth lp scanner; do
  if ! id -nG "$USER_NAME" | grep -qw "$group"; then
    usermod -aG "$group" "$USER_NAME" 2>/dev/null || true
  fi
done

log "Habilitar servicios necesarios"
systemctl enable --now NetworkManager || true
systemctl enable --now bluetooth || true
systemctl enable --now lightdm || true

# Reiniciar NetworkManager para aplicar configuración
systemctl restart NetworkManager || true


log "Configurar ZRAM (swap comprimido en RAM)"
if [[ -f /etc/default/zramswap ]]; then
  sed -i 's/^#*\s*ALGO=.*/ALGO=lz4/' /etc/default/zramswap || true
  sed -i 's/^#*\s*PERCENT=.*/PERCENT=50/' /etc/default/zramswap || true
  systemctl enable --now zramswap.service || true
else
  log "Advertencia: /etc/default/zramswap no encontrado; zram-tools puede usar otro archivo. Comprueba manualmente."
fi

log "Configurar touchpad (tap + natural scrolling) + aceleración de teclado"
mkdir -p /etc/X11/xorg.conf.d

# Touchpad
tee /etc/X11/xorg.conf.d/40-libinput.conf > /dev/null <<'EOF'
Section "InputClass"
    Identifier "libinput touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "AccelSpeed" "0.5"
    Option "DisableWhileTyping" "true"
EndSection
EOF

# Intel Graphics - Optimizaciones para UHD 620
tee /etc/X11/xorg.conf.d/20-intel.conf > /dev/null <<'EOF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
    Option "AccelMethod" "sna"
    Option "DRI" "3"
EndSection
EOF

# Configurar modprobe para Intel i915 (mejor rendimiento)
mkdir -p /etc/modprobe.d
tee /etc/modprobe.d/i915.conf > /dev/null <<'EOF'
options i915 enable_guc=2 enable_fbc=1 fastboot=1
EOF

# QCA9377 WiFi optimization - disable ASPM to prevent PCIe errors
tee /etc/modprobe.d/ath10k.conf > /dev/null <<'EOF'
options ath10k_pci irq_mode=legacy
EOF

tee /etc/modprobe.d/pcie_aspm.conf > /dev/null <<'EOF'
options pcie_aspm policy=performance
EOF

log "Configurando parámetros GRUB para optimizar WiFi QCA9377"
if grep -q "pci=noaer" /etc/default/grub; then
  log "Parámetros GRUB ya configurados"
else
  cp /etc/default/grub /etc/default/grub.backup-$(date +%Y%m%d) || true
  sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 pci=noaer pcie_aspm=off"/' /etc/default/grub
  update-grub || log "Advertencia: No se pudo actualizar GRUB. Ejecuta 'sudo update-grub' manualmente."
  log "Parámetros GRUB actualizados (pci=noaer pcie_aspm=off)"
fi

# 1. Script de control de brillo con límites mínimos y máximos
log "Creando script de control de brillo con límites (MIN=5%, MAX=95%)"
tee /usr/local/bin/i3-brightness > /dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail

# Verificar que light está instalado
if ! command -v light &>/dev/null; then
  echo "Error: 'light' no está instalado. Instala con: sudo apt install light"
  exit 1
fi

DEVICE=""
MIN=5
MAX=95
STEP=10

cmd="${1:-}"

# Obtener brillo actual
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

# 2. Script de diagnóstico WiFi mejorado
log "Creando script de diagnóstico WiFi mejorado"
tee /usr/local/bin/wifi-fix > /dev/null <<'WIFIFIX'
#!/usr/bin/env bash
# Script de diagnóstico y reparación WiFi para Atheros QCA9377
# Versión mejorada con más checks y soluciones

if [[ $EUID -ne 0 ]]; then
   echo "Este script requiere privilegios root. Ejecuta: sudo wifi-fix"
   exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  Diagnóstico y Reparación WiFi - Atheros QCA9377"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Verificar hardware
echo "[1/8] Verificando hardware WiFi..."
if lspci | grep -q "QCA9377"; then
    echo "✓ Tarjeta QCA9377 detectada"
    lspci | grep -i "QCA9377"
else
    echo "✗ No se detectó tarjeta QCA9377"
    echo "Hardware detectado:"
    lspci | grep -i network
fi
echo ""

# 2. Verificar firmware
echo "[2/8] Verificando firmware..."
if [ -d "/lib/firmware/ath10k/QCA9377" ]; then
    echo "✓ Firmware QCA9377 instalado"
    ls -lh /lib/firmware/ath10k/QCA9377/hw1.0/ 2>/dev/null || echo "  (Carpeta hw1.0 no encontrada, pero puede estar en otra versión)"
else
    echo "✗ Firmware QCA9377 NO encontrado"
    echo "  Instala: sudo apt install firmware-atheros"
fi
echo ""

# 3. Verificar módulos del kernel
echo "[3/8] Verificando módulos del kernel..."
if lsmod | grep -q "ath10k_pci"; then
    echo "✓ Módulo ath10k_pci cargado"
    lsmod | grep -E "ath10k|ath"
else
    echo "✗ Módulo ath10k_pci NO cargado"
    echo "  Intentando cargar..."
    modprobe ath10k_pci && echo "  ✓ Módulo cargado exitosamente"
fi
echo ""

# 4. Verificar rfkill
echo "[4/8] Verificando bloqueos (rfkill)..."
rfkill list all
if rfkill list | grep -A 2 "phy" | grep -q "yes"; then
    echo "⚠ WiFi bloqueado detectado. Desbloqueando..."
    rfkill unblock all
    echo "  ✓ Desbloqueado"
else
    echo "✓ Sin bloqueos detectados"
fi
echo ""

# 5. Verificar interfaz de red
echo "[5/8] Verificando interfaz de red..."
if ip link show | grep -q "wlp"; then
    echo "✓ Interfaz WiFi detectada"
    ip link show | grep "wlp" -A 1
else
    echo "✗ No se detectó interfaz WiFi (wlp*)"
fi
echo ""

# 6. Verificar errores PCIe en dmesg
echo "[6/8] Verificando errores PCIe recientes..."
ERRORS=$(dmesg | grep "ath10k_pci" | grep -c "PCIe Bus Error" 2>/dev/null || echo 0)
if [ "$ERRORS" -gt 0 ]; then
    echo "⚠ Se detectaron $ERRORS errores PCIe en dmesg"
    echo "  Esto es NORMAL en QCA9377 y no debería afectar funcionalidad"
    echo "  Últimos 3 errores:"
    dmesg | grep "ath10k_pci" | grep "PCIe Bus Error" | tail -3
else
    echo "✓ Sin errores PCIe recientes"
fi
echo ""

# 7. Aplicar reparaciones
echo "[7/8] Aplicando reparaciones..."
echo "  → Desbloqueando todos los dispositivos wireless"
rfkill unblock all

echo "  → Reiniciando módulo ath10k_pci"
if lsmod | grep -q ath10k_pci; then
    modprobe -r ath10k_pci 2>/dev/null
    sleep 2
fi
modprobe ath10k_pci
echo "  ✓ Módulo reiniciado"

echo "  → Reiniciando NetworkManager"
systemctl restart NetworkManager
sleep 3
echo "  ✓ NetworkManager reiniciado"
echo ""

# 8. Estado final
echo "[8/8] Estado final del sistema..."
nmcli device status
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "  Diagnóstico completado"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "COMANDOS ÚTILES:"
echo "  • Ver redes disponibles:    nmcli device wifi list"
echo "  • Conectar a red:           nmcli device wifi connect 'SSID' password 'PASS'"
echo "  • Ver errores PCIe:         sudo dmesg | grep ath10k | tail -20"
echo "  • Reiniciar WiFi rápido:    sudo systemctl restart NetworkManager"
echo ""
WIFIFIX

chmod +x /usr/local/bin/wifi-fix

# 2b. Script NetworkManager dispatcher para deshabilitar power save WiFi
log "Creando dispatcher NetworkManager para deshabilitar WiFi power save"
mkdir -p /etc/NetworkManager/dispatcher.d
tee /etc/NetworkManager/dispatcher.d/disable-wifi-powersave > /dev/null <<'NMDISPATCHER'
#!/bin/sh
# Deshabilitar power save en WiFi al conectar
# Mejora estabilidad en QCA9377

if [ "$2" = "up" ]; then
    # Solo para interfaces WiFi
    case "$1" in
        wlp*|wlan*)
            /usr/sbin/iw dev "$1" set power_save off 2>/dev/null || true
            logger "WiFi power save deshabilitado en $1"
            ;;
    esac
fi
NMDISPATCHER

chmod +x /etc/NetworkManager/dispatcher.d/disable-wifi-powersave

log "Configurando power management para laptop"
tee /etc/udev/rules.d/99-laptop-power.rules > /dev/null <<'POWERRULES'
ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x168c", ATTR{device}=="0x0042", ATTR{power/control}="on"
POWERRULES
udevadm control --reload-rules 2>/dev/null || true

# FASE 2: tareas como usuario no-root
log "Configuración de usuario para $USER_NAME"

# Validar que el directorio home existe y es accesible
if [[ ! -d "$USER_HOME" ]]; then
  log "ERROR: Home directory $USER_HOME no existe o no es accesible"
  exit 1
fi

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
mkdir -p "$HOME/.config/picom"
mkdir -p "$HOME/.config/dunst"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/Wallpapers"

systemctl --user restart pipewire pipewire-pulse wireplumber || true

'

# Asegurar propiedad desde root (por si algo se escribió como root)
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/wireplumber" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/i3" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/gtk-3.0" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/picom" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config/dunst" || true
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/Wallpapers" || true

# Copiar configuración de picom personalizada
log "Creando configuración de picom personalizada"
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/picom/picom.conf" > /dev/null <<'PICOMCFG'
# Picom configuration optimized for Intel UHD 620
backend = "glx"
glx-no-stencil = true
glx-copy-from-front = false
vsync = true
use-damage = false
unredir-if-possible = false

shadow = false
fading = false
blur-background = false

active-opacity = 0.99
inactive-opacity = 0.95
inactive-dim = 0.0

opacity-rule = [
  "80:class_g = 'kitty' && focused",
  "65:class_g = 'kitty' && !focused",
  "80:class_g = 'i3bar' && focused",
  "80:class_g = 'i3bar' && !focused"
];

wintypes:
{
  tooltip = { opacity = 0.9; };
  dock = { opacity = 1.0; };
  popup_menu = { opacity = 1.0; };
};

log-level = "info";
PICOMCFG

# Crear configuración de dunst (notificaciones) acorde con i3status
log "Creando configuración de dunst personalizada"
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/dunst/dunstrc" > /dev/null <<'DUNSTCFG'
[global]
    monitor = 0
    follow = mouse
    width = (0, 400)
    height = 300
    origin = top-right
    offset = 10x50
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 400
    transparency = 5
    separator_height = 2
    padding = 12
    horizontal_padding = 12
    text_icon_padding = 0
    frame_width = 2
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = Noto Sans 11
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 32
    max_icon_size = 48
    icon_path = /usr/share/icons/Papirus-Dark/48x48/status:/usr/share/icons/Papirus-Dark/48x48/devices:/usr/share/icons/Papirus-Dark/48x48/apps
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/rofi -dmenu -p dunst:
    browser = /usr/bin/chromium
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 8
    ignore_dbusclose = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

# Colores acordes con i3status (cyan/orange/red)
[urgency_low]
    background = "#0a0a0a"
    foreground = "#E6EEF3"
    frame_color = "#06B6D4"
    timeout = 5

[urgency_normal]
    background = "#0a0a0a"
    foreground = "#E6EEF3"
    frame_color = "#0FAE8C"
    timeout = 10

[urgency_critical]
    background = "#0a0a0a"
    foreground = "#FFFFFF"
    frame_color = "#EF4444"
    timeout = 0
DUNSTCFG


# Configuración de i3
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/i3/config" > /dev/null <<'I3CFG'
# Tecla modificadora (Windows/Super)
set $mod Mod4

# Tamaña de la fuente
font pango:Noto Sans 12

#####
# APLICACIONES AL INICIO (AUTOSTART)
#####

# Picom al inicio (compositor para sombras y transparencias)
exec --no-startup-id sh -c 'killall -q picom 2>/dev/null || true; sleep 0.12; picom --config ~/.config/picom/picom.conf --daemon &'

# Gestor de políticas de autenticación
exec --no-startup-id lxpolkit &

# Aplicación de red (Network Manager)
exec --no-startup-id nm-applet

# Sistema de notificaciones
exec --no-startup-id dunst

# Gestor de dispositivos USB y discos extraíbles
exec --no-startup-id udiskie --tray

# Gestor de Bluetooth
exec --no-startup-id blueman-applet

# Bloqueo de pantalla al suspender
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork

# Fondo de pantalla (asegúrate de tener una imagen en ~/Wallpapers/default.jpg)
exec_always --no-startup-id feh --bg-fill ~/Wallpapers/default.jpg

#####
# CONFIGURACIÓN DE BORDES Y VENTANAS
#####

default_border pixel 3
default_floating_border pixel 1
hide_edge_borders smart
floating_modifier Mod4

#####
# WORKSPACES
#####

set $ws1 "1:web"
set $ws2 "2:dev" 
set $ws3 "3:work"
set $ws4 "4:chat"
set $ws5 "5:media"
set $ws6 "6:misc"

#####
# ATAJOS DE TECLADO - NAVEGACIÓN Y GESTIÓN DE VENTANAS
#####

# Foco entre ventanas (flechas)
bindsym $mod+Left  focus left
bindsym $mod+Down  focus down
bindsym $mod+Up    focus up
bindsym $mod+Right focus right

# Mover ventanas entre contenedores
bindsym $mod+Shift+Left  move left
bindsym $mod+Shift+Down  move down
bindsym $mod+Shift+Up    move up
bindsym $mod+Shift+Right move right

bindsym $mod+e layout toggle split
bindsym $mod+s layout stacking
bindsym $mod+Shift+w layout tabbed
bindsym $mod+Shift+f fullscreen toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+a focus parent
bindsym $mod+Shift+q kill

#####
# WORKSPACES NAVIGATION
#####

# Navegación entre workspaces
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6

# Mover ventanas entre workspaces
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6

# Workspace cycling (back and forth)
bindsym $mod+Tab workspace next
bindsym $mod+Shift+Tab workspace prev

# Focus between displays/outputs
bindsym $mod+Ctrl+Left focus output left
bindsym $mod+Ctrl+Right focus output right

# Move workspace to output
bindsym $mod+Shift+Ctrl+Left move workspace to output left
bindsym $mod+Shift+Ctrl+Right move workspace to output right

#####
# SCRATCHPAD (FLOATING TERMINAL)
#####

# Launch scratchpad terminal
exec --no-startup-id kitty --name=scratch

# Configure scratchpad
for_window [instance="scratch"] floating enable, sticky enable, resize set 800 600, move position 560 200

# Toggle scratchpad visibility
bindsym $mod+grave scratchpad show, move position center

#####
# APPLICATIONS & SHORTCUTS
#####

bindsym $mod+Return exec --no-startup-id kitty
bindsym $mod+space exec --no-startup-id rofi -show drun -show-icons
bindsym $mod+g exec --no-startup-id kitty -e ranger
bindsym $mod+w exec --no-startup-id chromium
bindsym $mod+f exec --no-startup-id pcmanfm
bindsym $mod+Ctrl+p exec --no-startup-id mpv --player-operation-mode=pseudo-gui
bindsym $mod+Ctrl+z exec --no-startup-id zathura

#####
# HARDWARE CONTROLS
#####

set $refresh_i3status killall -SIGUSR1 i3status

bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
bindsym XF86AudioPlay exec --no-startup-id playerctl play-pause

# Control de brillo (brightnessctl)
bindsym XF86MonBrightnessUp exec --no-startup-id /usr/local/bin/i3-brightness up
bindsym XF86MonBrightnessDown exec --no-startup-id /usr/local/bin/i3-brightness down

#####
# TOOLS & UTILITIES
#####

bindsym Print exec --no-startup-id flameshot gui
bindsym XF86Calculator exec --no-startup-id galculator
bindsym $mod+p exec --no-startup-id arandr
bindsym $mod+Shift+n exec --no-startup-id nm-connection-editor
bindsym $mod+Shift+b exec --no-startup-id blueman-manager
bindsym $mod+Shift+t exec --no-startup-id kitty -e btop

#####
# FLOATING WINDOWS
#####
for_window [class="Bitwarden"] floating enable
for_window [class="stacer"] floating enable
for_window [class="GParted"] floating enable
for_window [class="gnome-software"] floating enable
for_window [class="Galculator"] floating enable
for_window [class="Blueman-manager"] floating enable
for_window [class="Nm-connection-editor"] floating enable
for_window [class="Arandr"] floating enable
for_window [title="Guardar como"] floating enable
for_window [window_role="pop-up"] floating enable
for_window [window_role="task_dialog"] floating enable

#####
# RESIZE MODE
#####

mode "resize" {
    bindsym Left resize shrink left 10 px
    bindsym Down resize grow down 10 px
    bindsym Up resize grow up 10 px
    bindsym Right resize grow right 10 px
    bindsym Shift+Left resize grow left 10 px
    bindsym Shift+Down resize shrink down 10 px
    bindsym Shift+Up resize shrink up 10 px
    bindsym Shift+Right resize shrink right 10 px
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

# Direct resize without mode (Alt modifier)
bindsym $mod+Alt+Left resize shrink width 10 px
bindsym $mod+Alt+Right resize grow width 10 px
bindsym $mod+Alt+Up resize grow height 10 px
bindsym $mod+Alt+Down resize shrink height 10 px

# Move window to scratchpad
bindsym $mod+minus move scratchpad

# i3 management
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec --no-startup-id "i3-nagbar -t warning -m 'Exit i3?' -b 'Exit' 'i3-msg exit'"

#####
# STATUS BAR
#####

bar {
    status_command i3status -c ~/.config/i3/i3status.conf
    position top
    font pango:Noto Sans, FontAwesome 11
    tray_output primary
    tray_padding 4
    separator_symbol "|"
    height 23

    colors {
        background #0a0a0a
        statusline #E6EEF3
        separator  #2A2A2A

        focused_workspace  #4fc3f7 #0a0a0a #ffffff
        active_workspace   #81c784 #0a0a0a #e0e0e0
        inactive_workspace #0a0a0a #0a0a0a #9e9e9e
        urgent_workspace   #ff9800 #0a0a0a #000000
    }
}

I3CFG

# i3status config
sudo -u "$USER_NAME" -H tee "$USER_HOME/.config/i3/i3status.conf" > /dev/null <<'STATCFG'
general {
    colors = true
    interval = 5
    output_format = "i3bar"
    color_good = "#06B6D4"
    color_degraded = "#F59E0B"
    color_bad = "#EF4444"
    separator = " "
    markup = "pango"
}

order += "tztime local"
order += "cpu_usage"
order += "memory"
order += "cpu_temperature 0"
order += "disk /"
order += "disk /home"
order += "wireless _first_"
order += "ethernet _first_"
order += "volume master"
order += "battery all"

# ---- Fecha y hora (resaltada en color distinto)
tztime local {
    format = "<span foreground=\"#0FAE8C\"><b>🕒 %a, %d %b %H:%M</b></span>"
}

# ---- CPU usage
cpu_usage {
    format = "<b>💻 %usage</b>"
    max_threshold = 75
    format_above_threshold = "<b>💻 %usage !</b>"    # color_bad aplicado por i3status
}

# ---- Memory
memory {
    format = "<b>🚀 %used/%total</b>"
    threshold_degraded = "1G"
    format_degraded = "<b>🚀 BAJA: %free</b>"         # color_degraded aplicado por i3status
}

# ---- CPU temperature (Intel i7-8565U)
cpu_temperature 0 {
    path = "/sys/class/thermal/thermal_zone0/temp"
    format = "<b>🌡️ %degrees°C</b>"
    max_threshold = 85
    format_above_threshold = "<b>🔥 %degrees°C</b>"
}

# ---- Disco /
disk / {
    format = "<b>📂 %avail</b>"
    format_not_mounted = ""
    low_threshold = 5
    threshold_type = "percentage_free"
}

# ---- Disco /home
disk /home {
    format = "<b>🏠 %avail</b>"
    format_not_mounted = ""
    low_threshold = 5
    threshold_type = "percentage_free"
}

# ---- Wireless (prioridad sobre ethernet)
wireless _first_ {
    format_up = "<b>📶 %essid %quality (%ip)</b>"
    format_down = ""
    format_quality = "%03d%s"
}

# ---- Ethernet (oculto si no está conectado)
ethernet _first_ {
    format_up = "<b>🌐 %ip (%speed)</b>"
    format_down = ""
}

# ---- Volumen
volume master {
    format = "<b>🔊 %volume</b>"
    format_muted = "<b>🔇 muted</b>"
    device = "default"
}

# ---- Batería
battery all {
    format = "<b>%status %percentage</b>"
    format_down = ""
    status_chr = "⚡"
    status_bat = "🔋"
    status_full = "✔"
    status_unk = "?"
    low_threshold = 20
    threshold_type = "percentage"
    last_full_capacity = true
}

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

# Copiar wallpaper por defecto desde el directorio del script si existe
log "Configurando wallpaper por defecto"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/wallpaper.jpg" ]] || [[ -f "$SCRIPT_DIR/wallpaper.png" ]]; then
  if [[ -f "$SCRIPT_DIR/wallpaper.jpg" ]]; then
    cp "$SCRIPT_DIR/wallpaper.jpg" "$USER_HOME/Wallpapers/default.jpg"
    log "✅ Wallpaper copiado desde $SCRIPT_DIR/wallpaper.jpg"
  elif [[ -f "$SCRIPT_DIR/wallpaper.png" ]]; then
    cp "$SCRIPT_DIR/wallpaper.png" "$USER_HOME/Wallpapers/default.jpg"
    log "✅ Wallpaper copiado desde $SCRIPT_DIR/wallpaper.png"
  fi
  chown "$USER_NAME:$USER_NAME" "$USER_HOME/Wallpapers/default.jpg"
else
  log "⚠️  No se encontró wallpaper.jpg/png en $SCRIPT_DIR"
  log "   📍 Para usar un fondo de pantalla personalizado:"
  log "      1. Coloca una imagen como wallpaper.jpg o wallpaper.png en $SCRIPT_DIR"
  log "      2. Vuelve a ejecutar el script, o"
  log "      3. Copia manualmente la imagen a ~/Wallpapers/default.jpg"
  log "   💡 En cualquier caso, puedes cambiar el fondo después con: feh --bg-fill ~/ruta/a/imagen.jpg"
fi

# Verificación final del WiFi
log "Verificación final del WiFi"
if lsmod | grep -q ath10k_pci; then
  log "✓ Módulo ath10k_pci cargado correctamente"
else
  log "⚠ Módulo ath10k_pci NO cargado. Ejecuta 'sudo modprobe ath10k_pci' después del reinicio"
fi

if [ -d "/lib/firmware/ath10k/QCA9377" ]; then
  log "✓ Firmware QCA9377 instalado"
else
  log "⚠ Firmware QCA9377 NO encontrado"
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "INSTALACIÓN COMPLETADA - Dell Inspiron 5584"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""
log "PRÓXIMOS PASOS:"
log "1. REINICIA el sistema para aplicar todos los cambios"
log "2. Después del reinicio, verifica que el WiFi funcione correctamente"
log ""
log "RESOLUCIÓN DE PROBLEMAS:"
log ""
log "📷 Para cambiar el fondo de pantalla:"
log "   1. Coloca tu imagen favorita en ~/Wallpapers/default.jpg"
log "   2. O edita ~/.config/i3/config y cambia la ruta de feh"
log "   3. Recarga i3: Mod+Shift+R"
log ""
log "💡 Configuración de Picom (transparencias):"
log "   Archivo: ~/.config/picom/picom.conf"
log "   Edita opacidades en opacity-rule según prefieras"
log ""
log "🔔 Personalizar notificaciones (dunst):"
log "   Archivo: ~/.config/dunst/dunstrc"
log "   Cambia colores, posición, fuentes, etc."
log ""
log "📡 Si el WiFi NO aparece o no detecta redes:"
log "   sudo wifi-fix"
log "   # Esto reiniciará el módulo y NetworkManager"
log ""

log "🌡️  Para monitorear temperaturas del hardware:"
log "   sudo sensors-detect      # Detectar sensores (responde 'YES' a todo)"
log "   sensors                  # Ver temperaturas actuales"
log ""
log "💡 Control de brillo:"
log "   light -G                 # Ver brillo actual"
log "   light -S 50              # Establecer brillo a 50%"
log "   # Límites: MIN=5%, MAX=95% (configurado en i3)"
log ""
log "🔋 Optimización de batería:"
log "   # Ya configurado: power management automático para WiFi/USB/PCI"
log "   # Usa Intel GPU por defecto (menor consumo)"
log ""
log "📦 Hardware detectado:"
log "   - CPU: Intel Core i7-8565U (8 cores @ 4.60 GHz)"
log "   - GPU: Intel UHD Graphics 620"
log "   - WiFi: Qualcomm Atheros QCA9377 (módulo ath10k_pci)"
log "   - RAM: 15.5 GB + ZRAM 50% (7.75 GB swap comprimido)"
log ""
log "NOTA IMPORTANTE SOBRE WIFI:"
log "   Si ves errores PCIe en dmesg (BadDLLP, Timeout), esto es normal"
log "   en el QCA9377. El script aplica optimizaciones para minimizarlos."
log "   El WiFi debería funcionar correctamente a pesar de estos mensajes."
log ""
log "SCRIPTS ÚTILES INSTALADOS:"
log "   /usr/local/bin/i3-brightness  # Control de brillo con límites"
log "   /usr/local/bin/wifi-fix       # Diagnóstico y reparación WiFi"
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "¡Disfruta tu sistema Debian 13 + i3wm optimizado!"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
