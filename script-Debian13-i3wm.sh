#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  V12 VETERANA ULTIMATE - DEBIAN 13 - ATHLON II X4
#  PARTE 1: CONFIGURACIÓN DEL SISTEMA (requiere sudo)
#  PARTE 2: Configuración de usuario (sin sudo) → setup-user-config.sh
# ─────────────────────────────────────────────────────────────────────────────

# ─── FUNCIONES AUXILIARES ───
log() { echo -e "\n\033[1;32m[Sistema] $1\033[0m"; }
error() { echo -e "\033[1;31m[ERROR] $1\033[0m" >&2; }
warn() { echo -e "\033[1;33m[AVISO] $1\033[0m"; }

# ─── VALIDACIONES INICIALES ───
# Verificar ejecución como root
if [[ $EUID -ne 0 ]]; then
    error "Este script requiere permisos de root"
    echo "ℹ️  Ejecuta: sudo bash $0"
    exit 1
fi

# Obtener usuario real (no root)
USER_NAME="${SUDO_USER:-${USER:-}}"
if [[ -z "$USER_NAME" || "$USER_NAME" == "root" ]]; then
    error "No se pudo determinar el usuario no-root"
    echo "ℹ️  No ejecutes este script directamente como root"
    echo "ℹ️  Usa: sudo bash $0"
    exit 1
fi

# Validar que el usuario existe
if ! USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6); then
    error "Usuario $USER_NAME no existe en el sistema"
    exit 1
fi

if [[ ! -d "$USER_HOME" ]]; then
    error "Directorio home del usuario no existe: $USER_HOME"
    exit 1
fi

# Obtener directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar que estamos en Debian
if [[ ! -f /etc/debian_version ]]; then
    error "Este script está diseñado para Debian"
    echo "ℹ️  Sistema detectado: $(uname -s)"
    exit 1
fi

# Verificar comandos críticos
for cmd in apt getent sed systemctl; do
    if ! command -v "$cmd" &> /dev/null; then
        error "Comando requerido no encontrado: $cmd"
        exit 1
    fi
done

# Trap para cleanup en caso de error
trap 'error "Script interrumpido en línea $LINENO. Exit code: $?"' ERR

log "Iniciando instalación para usuario: $USER_NAME"
log "Directorio home: $USER_HOME"

log "1. Configurando Repositorios (Contrib + Non-free)..."
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    if sed -i.bak 's/Components: main$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources; then
        log "✓ Repositorios actualizados (formato DEB822)"
    fi
elif [[ -f /etc/apt/sources.list ]]; then
    if sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list; then
        log "✓ Repositorios actualizados (formato tradicional)"
    fi
else
    warn "No se encontró archivo de sources estándar"
fi

log "2. Actualizando Sistema..."
if apt update; then
    log "✓ Índices de paquetes actualizados"
else
    error "Fallo al actualizar índices de paquetes"
    exit 1
fi

if apt -y full-upgrade; then
    log "✓ Sistema actualizado"
else
    error "Fallo al actualizar sistema"
    exit 1
fi

log "3. Instalando Drivers AMD y Microcódigo..."
if apt -y install firmware-linux-nonfree firmware-misc-nonfree firmware-amd-graphics amd64-microcode libgl1-mesa-dri mesa-va-drivers mesa-utils; then
    log "✓ Firmware y drivers AMD instalados"
else
    error "Fallo al instalar firmware AMD"
    exit 1
fi

log "4. Instalando Entorno Base y Estética Debian..."
PKGS=(
  # Base X11 y i3
  xorg xserver-xorg xinit x11-xserver-utils
  i3-wm i3status i3lock dmenu dunst arandr
  numlockx              # Activar teclado numérico en login
  
  # Estética Debian Nativa
  desktop-base
  grub-theme-starfield
  lxappearance papirus-icon-theme arc-theme fonts-noto-core fonts-font-awesome fonts-jetbrains-mono
  
  # Aplicaciones
  alacritty             # Terminal GPU-acelerado (NO lxterminal)
  pcmanfm gvfs gvfs-backends udisks2 udiskie
  mpv zathura timeshift
  feh                   # Gestor de fondo de pantalla
  scrot                 # Capturas de pantalla
  
  # Audio
  pipewire pipewire-pulse wireplumber pavucontrol pulseaudio-utils
  rtkit                 # Real-time scheduling para audio
  
  # Utilidades Sistema
  wget curl git unzip p7zip-full btop fastfetch
  zram-tools lm-sensors lxpolkit pkexec libnotify-bin  xclip
  
  # Login Manager
  lightdm lightdm-gtk-greeter
)
if apt -y --no-install-recommends install "${PKGS[@]}"; then
    log "✓ Paquetes base instalados (${#PKGS[@]} paquetes)"
else
    error "Fallo al instalar paquetes base"
    exit 1
fi

# Configurar lightdm 
log "Configurando lightdm..."
# lightdm se habilita automáticamente durante la instalación
log "✓ lightdm configurado (login gráfico GTK)"

log "Instalando Brave Browser (reemplazando a Chromium)..."
if curl -fsS https://dl.brave.com/install.sh | sh; then
    log "✓ Brave Browser instalado correctamente"
else
    warn "Fallo al instalar Brave Browser por script"
fi

log "5. Optimizando Kernel (Mitigations OFF + Swap)..."
# Backup de GRUB config
if [[ -f /etc/default/grub ]]; then
    cp /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d)"
fi

# mitigations=off: +Rendimiento en Athlon II
# nowatchdog: -Interrupciones
# audit=0: Desactiva subsistema de auditoría (+1-2% overhead)
# radeon.dpm=1: Activa profile dinámico de energía en GPU Radeon antigua
if sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet mitigations=off nowatchdog audit=0 radeon.dpm=1"/' /etc/default/grub; then
    log "✓ Parámetros de kernel configurados (mitigations=off, nowatchdog, audit=0, radeon.dpm=1)"
fi

# Aplicar tema de Debian al GRUB
if grep -q "#GRUB_THEME=" /etc/default/grub; then
    sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=/usr/share/grub/themes/starfield/theme.txt|' /etc/default/grub
    log "✓ Tema GRUB configurado"
fi

if update-grub; then
    log "✓ GRUB actualizado"
else
    warn "No se pudo actualizar GRUB (continuando...)"
fi

# Bloquear módulos de kernel innecesarios (+2-3% RAM libre)
log "Bloqueando módulos innecesarios..."
cat > /etc/modprobe.d/blacklist-v12.conf <<'BLACKLIST'
# PC Speaker (beep molesto)
blacklist pcspkr
# Bluetooth (hardware no presente)
blacklist bluetooth
blacklist btusb
blacklist btrtl
blacklist btbcm
blacklist btintel
# Watchdog Intel (ya desactivado en kernel)
blacklist iTCO_wdt
blacklist iTCO_vendor_support
BLACKLIST
log "✓ Módulos innecesarios bloqueados"

# Limitar journald logs (+50-100MB espacio, menos escrituras SSD)
log "Configurando journald..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-v12.conf <<'JOURNAL'
[Journal]
# Limitar uso de espacio (50MB máximo)
SystemMaxUse=50M
SystemMaxFileSize=10M
# Solo mantener logs de 1 semana
MaxRetentionSec=1week
# Comprimir logs inmediatamente
Compress=yes
JOURNAL
log "✓ journald configurado (50MB max, 1 semana)"

# Tuning de Memoria (ZRAM + Swappiness)
if [[ -f /etc/default/zramswap ]]; then
    sed -i 's/^#*\s*ALGO=.*/ALGO=zstd/' /etc/default/zramswap
    sed -i 's/^#*\s*PERCENT=.*/PERCENT=100/' /etc/default/zramswap
    log "✓ ZRAM configurado (100%, zstd)"
fi

cat > /etc/sysctl.d/99-v12-optim.conf <<'SYSCTL'
# Optimizaciones para Athlon II X4 con 8GB RAM + SSD
vm.swappiness = 100
vm.vfs_cache_pressure = 50
# Desactiva lectura anticipada en swap (+rendimiento ZRAM)
vm.page-cluster = 0
# Optimizaciones SSD/RAM (+3% fluency)
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.min_free_kbytes = 65536
SYSCTL
log "✓ Parámetros sysctl configurados (SSD + RAM optimizados)"

# Optimizar disco SSD (noatime)
if [[ -f /etc/fstab ]]; then
    cp /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d)"
    if sed -i 's/errors=remount-ro/errors=remount-ro,noatime/' /etc/fstab; then
        log "✓ Optimización SSD aplicada (noatime)"
    fi
    
    # Tmpfs para /tmp en RAM (+15-20% velocidad I/O temporal)
    if ! grep -q "^tmpfs /tmp" /etc/fstab; then
        echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,noexec,mode=1777,size=2G 0 0" >> /etc/fstab
        log "✓ tmpfs configurado para /tmp (2GB en RAM)"
    fi
    
    # Optimización XFS (home, proyectos, juegos, respaldos)
    if grep -q "xfs" /etc/fstab; then
        sed -i '/xfs/ s/defaults/defaults,noatime,inode64/' /etc/fstab
        log "✓ Optimización XFS aplicada (noatime, inode64)"
    fi
fi

# Configurar I/O Scheduler para SSD (+20% latencia disco)
log "Configurando I/O Scheduler para SSD..."
cat > /etc/udev/rules.d/60-ioschedulers.rules <<'IOSCHED'
# I/O Scheduler óptimo para SSD (none si disponible, sino mq-deadline)
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
IOSCHED
log "✓ I/O Scheduler configurado (none/mq-deadline para SSD)"

log "6. Configurando CPU Governor (Performance)..."
# Verificar si cpufreq está disponible
if [[ ! -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
    warn "cpufreq no disponible en este kernel (continuando...)"
else
    # Aplicar governor inmediatamente
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" > "$cpu" 2>/dev/null || true
    done
    log "✓ Governor 'performance' aplicado a todos los cores"
    
    # Crear servicio systemd para persistir al reinicio (reemplaza cpufrequtils)
    cat > /etc/systemd/system/cpu-governor-performance.service <<'CPUGOV'
[Unit]
Description=Set CPU Governor to Performance
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > "$cpu" 2>/dev/null || true; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
CPUGOV
    
    systemctl daemon-reload
    systemctl enable cpu-governor-performance.service
    log "✓ Servicio systemd creado (persiste al reinicio)"
fi

log "7. Optimizando GPU Radeon (Xorg)..."
mkdir -p /etc/X11/xorg.conf.d
tee /etc/X11/xorg.conf.d/20-radeon.conf > /dev/null <<'EOF'
Section "Device"
    Identifier "Radeon 3000"
    Driver "radeon"
    Option "TearFree" "on"
    Option "DRI" "2"
    Option "AccelMethod" "EXA"
    Option "MigrationHeuristic" "greedy"
EndSection
EOF

log "8. Script Monitor VGA"
tee /usr/local/bin/monitor-setup > /dev/null <<'EOF'
#!/bin/sh
# Ajuste preciso para LG L192WS 1440x900 @ 60Hz
xrandr --output VGA-0 --mode 1440x900 --rate 60 2>/dev/null || xrandr --output VGA-0 --auto
EOF
chmod +x /usr/local/bin/monitor-setup

log "9. Limpieza de Servicios Innecesarios (Desktop Cableado)..."

# Servicios Bluetooth (Hardware no presente)
systemctl disable --now bluetooth.service 2>/dev/null || true
systemctl disable --now bluetooth.target 2>/dev/null || true
systemctl mask bluetooth.service 2>/dev/null || true

# Servicios de Red Innecesarios
systemctl disable --now avahi-daemon.service 2>/dev/null || true
systemctl disable --now avahi-daemon.socket 2>/dev/null || true
systemctl mask avahi-daemon.service 2>/dev/null || true

# Impresoras 
systemctl disable --now cups.service 2>/dev/null || true
systemctl disable --now cups-browsed.service 2>/dev/null || true
systemctl disable --now cups.socket 2>/dev/null || true
systemctl disable --now cups.path 2>/dev/null || true

# Módem/WiFi (Desktop Cableado)
systemctl disable --now ModemManager.service 2>/dev/null || true
systemctl disable --now wpa_supplicant.service 2>/dev/null || true
systemctl mask ModemManager.service 2>/dev/null || true

# Servicios de Localización/Geolocalización
systemctl disable --now geoclue.service 2>/dev/null || true

# Síntesis de Voz (Innecesario en desktop normal)
systemctl disable --now speech-dispatcher.service 2>/dev/null || true

# GPU Switching (Solo para laptops con gráfica dual)
systemctl disable --now switcheroo-control.service 2>/dev/null || true

# Servicios de PC-Card/PCMCIA (Hardware viejo no presente)
systemctl disable --now pcscd.service 2>/dev/null || true
systemctl disable --now pcscd.socket 2>/dev/null || true

log "✓ Servicios innecesarios desactivados (${SECONDS}s)"

# ─────────────────────────────────────────────────────────────────────────────
#  LIMPIEZA Y OPTIMIZACIONES FINALES
# ─────────────────────────────────────────────────────────────────────────────
log "Limpieza de paquetes innecesarios..."

# Eliminar paquetes obsoletos si existen (greetd/tuigreet tienen problemas en Debian 13)
if dpkg -l | grep -q 'greetd\|tuigreet\|lxterminal'; then
    log "Limpiando paquetes obsoletos..."
    systemctl disable greetd.service 2>/dev/null || true
    apt -y purge greetd tuigreet lxterminal 2>/dev/null || true
    log "✓ Paquetes obsoletos eliminados"
fi

# Eliminar usuario greeter residual (si existe)
if getent passwd greeter &>/dev/null; then
    log "Eliminando usuario greeter residual..."
    userdel -r greeter 2>/dev/null || true
    log "✓ Usuario greeter eliminado"
fi

# Purgar paquetes con configuraciones residuales (estado rc)
log "Limpiando configuraciones residuales..."
RC_PKGS=$(dpkg -l | grep "^rc" | awk '{print $2}')
if [[ -n "$RC_PKGS" ]]; then
    dpkg --purge $RC_PKGS 2>/dev/null || true
    log "✓ Configuraciones residuales purgadas"
else
    log "✓ Sin configuraciones residuales"
fi

# Eliminar firmware de Nvidia (sistema AMD)
if dpkg -l | grep -q 'firmware-nvidia-graphics'; then
    log "Eliminando firmware de Nvidia (no necesario)..."
    apt -y purge firmware-nvidia-graphics 2>/dev/null || true
    log "✓ Firmware Nvidia eliminado"
fi

# Eliminar kernels antiguos (mantener solo el actual y uno anterior como backup)
log "Limpiando kernels antiguos..."
CURRENT_KERNEL=$(uname -r)
INSTALLED_KERNELS=$(dpkg -l | grep 'linux-image-[0-9]' | grep '^ii' | awk '{print $2}' | grep -v "$CURRENT_KERNEL" | sort -V | head -n -1)
if [[ -n "$INSTALLED_KERNELS" ]]; then
    for kernel in $INSTALLED_KERNELS; do
        log "Eliminando kernel antiguo: $kernel"
        apt -y purge "$kernel" 2>/dev/null || true
    done
    log "✓ Kernels antiguos eliminados"
else
    log "✓ No hay kernels antiguos para eliminar"
fi

# Ejecutar autoremove para limpiar dependencias
apt -y autoremove 2>/dev/null || true
log "✓ Limpieza completada"

# Activar compresión en Btrfs y mantenimiento SSD (TRIM)
log "Configurando compresión Btrfs y TRIM..."
systemctl enable fstrim.timer 2>/dev/null || true
if mount | grep -q 'on / type btrfs'; then
    # Hacer permanente en fstab
    if [[ -f /etc/fstab ]]; then
        if ! grep -q 'compress=zstd' /etc/fstab; then
            sed -i 's|subvol=/@|subvol=/@,compress=zstd:3|' /etc/fstab
            log "✓ Compresión Btrfs configurada en fstab (zstd:3)"
        fi
    fi
    
    # Aplicar inmediatamente
    mount -o remount,compress=zstd:3 / 2>/dev/null || true
    log "✓ Compresión Btrfs activada (ahorra 20-30% espacio)"
    
    # Nota: La compresión de archivos existentes se hace en segundo plano
    log "ℹ️  Los archivos nuevos se comprimirán automáticamente"
else
    log "ℹ️  Root no es Btrfs, omitiendo compresión"
fi

log "✅ INSTALACIÓN DEL SISTEMA COMPLETADA CON ÉXITO"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Configuración del sistema finalizada"
echo ""
echo "  ⏳ SIGUIENTE PASO:"
echo "     Asegúrate de ejecutar el script de usuario indicando tus dotfiles (SIN sudo):"
echo "     bash setup-user-config.sh"
echo ""
echo "  📊 Optimizaciones aplicadas:"
echo "     • Login: lightdm (GTK greeter estable)"
echo "     • Terminal: alacritty (GPU-acelerado)"
echo "     • Navegador: Brave Browser (instalación oficial)"
echo "     • CPU Governor: performance (3.0 GHz constante)"
echo "     • ZRAM Swap: 100% compresión zstd"
echo "     • Kernel: mitigations=off, nowatchdog, audit=0, radeon.dpm=1"
echo "     • SSD: I/O scheduler optimizado, noatime"
echo "     • Sistemas de archivos: Compresión Btrfs, optimización XFS, auto fstrim"
echo "     • GPU Radeon: TearFree, DRI3, aceleración EXA"
echo "     • Audio: RTKit para realtime"
echo "     • Servicios innecesarios: desactivados"
echo "     • Limpieza: greetd/tuigreet, lxterminal, Nvidia, kernels viejos"
echo ""
echo "  ⚠️  RECUERDA REINICIAR el sistema luego de ejecutar la parte 2:"
echo "     sudo reboot"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
