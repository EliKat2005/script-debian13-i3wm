#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  CONFIGURACIÓN DE USUARIO - DEBIAN 13 + i3wm
#  Este script configura dotfiles y archivos del usuario actual
#  NO REQUIERE sudo - Se ejecuta como usuario normal
# ─────────────────────────────────────────────────────────────────────────────

# ─── FUNCIONES AUXILIARES ───
log() { echo -e "\n\033[1;36m[Usuario] $1\033[0m"; }
error() { echo -e "\033[1;31m[ERROR] $1\033[0m" >&2; }
warn() { echo -e "\033[1;33m[AVISO] $1\033[0m"; }

# Función para hacer backup de archivo si existe
backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        if cp "$file" "$backup"; then
            log "✓ Backup creado: $backup"
        fi
    fi
}

# ─── VALIDACIONES INICIALES ───
# Verificar que NO se ejecute como root
if [[ $EUID -eq 0 ]]; then
    error "Este script NO debe ejecutarse con sudo"
    echo "ℹ️  Ejecuta: bash setup-user-config.sh"
    exit 1
fi

# Verificar que HOME esté definido
if [[ -z "${HOME:-}" ]]; then
    error "Variable HOME no está definida"
    exit 1
fi

# Verificar permisos de escritura en HOME
if [[ ! -w "$HOME" ]]; then
    error "No tienes permisos de escritura en $HOME"
    exit 1
fi

# Trap para manejo de errores
trap 'error "Script interrumpido en línea $LINENO"' ERR

log "Configurando entorno para $USER..."
log "Directorio home: $HOME"

# Crear directorios necesarios
log "Creando estructura de directorios..."

# Directorios de configuración
for dir in "$HOME/.config/i3" "$HOME/.config/i3status" "$HOME/.config/alacritty" "$HOME/.config/dunst" "$HOME/.config/mpv"; do
    if mkdir -p "$dir"; then
        [[ ! -d "$dir" ]] && warn "No se pudo crear: $dir"
    fi
done

# Directorios XDG estándar del usuario
for dir in "$HOME/Descargas" "$HOME/Documentos" "$HOME/Imágenes" "$HOME/Música" "$HOME/Vídeos" "$HOME/Escritorio" "$HOME/Plantillas" "$HOME/Público" "$HOME/Wallpapers"; do
    mkdir -p "$dir" 2>/dev/null
done

log "✓ Directorios creados"

# Configurar XDG user dirs
log "Configurando directorios XDG..."
cat > "$HOME/.config/user-dirs.dirs" <<'XDGDIRS'
XDG_DESKTOP_DIR="$HOME/Escritorio"
XDG_DOWNLOAD_DIR="$HOME/Descargas"
XDG_TEMPLATES_DIR="$HOME/Plantillas"
XDG_PUBLICSHARE_DIR="$HOME/Público"
XDG_DOCUMENTS_DIR="$HOME/Documentos"
XDG_MUSIC_DIR="$HOME/Música"
XDG_PICTURES_DIR="$HOME/Imágenes"
XDG_VIDEOS_DIR="$HOME/Vídeos"
XDGDIRS

# Deshabilitar actualización automática de directorios
cat > "$HOME/.config/user-dirs.conf" <<'XDGCONF'
enabled=False
XDGCONF

log "✓ Directorios XDG configurados"

# ─── ALACRITTY ───
log "Configurando Alacritty..."
backup_if_exists "$HOME/.config/alacritty/alacritty.toml"
cat > "$HOME/.config/alacritty/alacritty.toml" <<'ALACRITTY'
[font]
size = 10.5
[font.normal]
family = "JetBrains Mono"
style = "Regular"
[colors.primary]
background = "#0a0a0a"
foreground = "#eeeeee"
ALACRITTY
log "✓ Alacritty configurado"

# ─── BRAVE BROWSER FLAGS ───
log "Configurando aceleración de hardware para Brave..."
cat > "$HOME/.config/brave-flags.conf" <<'BRAVEFLAGS'
--enable-features=VaapiVideoDecoder,VaapiVideoEncoder
--ignore-gpu-blocklist
--enable-gpu-rasterization
--use-gl=egl
BRAVEFLAGS
log "✓ Brave configurado"

# ─── NOTIFICACIONES (DUNST) ───
log "Configurando Dunst (Notificaciones temporizadas)..."
backup_if_exists "$HOME/.config/dunst/dunstrc"
cat > "$HOME/.config/dunst/dunstrc" <<'DUNSTRC'
[global]
font = Noto Sans 10
markup = full
format = "<b>%s</b>\n%b"
sort = yes
indicate_hidden = yes
alignment = left
show_age_threshold = 60
word_wrap = yes
ignore_newline = no
width = 300
height = 200
origin = top-right
offset = 20x40
shrink = no
idle_threshold = 120
monitor = 0
follow = none
sticky_history = yes
history_length = 20
show_indicators = yes
line_height = 0
separator_height = 2
padding = 8
horizontal_padding = 8
separator_color = frame
frame_width = 2
frame_color = "#005577"

[urgency_low]
background = "#1a1a1a"
foreground = "#dddddd"
timeout = 3

[urgency_normal]
background = "#1a1a1a"
foreground = "#ffffff"
timeout = 5

[urgency_critical]
background = "#900000"
foreground = "#ffffff"
frame_color = "#ff0000"
timeout = 0
DUNSTRC
log "✓ Dunst configurado"

# ─── REPRODUCTOR MPV (HARDWARE ACCEL) ───
log "Configurando mpv..."
backup_if_exists "$HOME/.config/mpv/mpv.conf"
cat > "$HOME/.config/mpv/mpv.conf" <<'MPVCONF'
# Perfil rápido adaptado a hardware legacy
profile=fast
# Usar decodificación por hardware AMD (vaapi)
hwdec=vaapi
vo=gpu
gpu-context=x11egl
# Limitar calidad caché para ahorrar RAM
cache=yes
demuxer-max-bytes=150M
demuxer-max-back-bytes=50M
MPVCONF
log "✓ mpv configurado"

# ─── I3 CONFIG (PERSONALIZADA) ───
log "Configurando i3wm..."
backup_if_exists "$HOME/.config/i3/config"
cat > "$HOME/.config/i3/config" <<'I3CONF'
# --- VARIABLES ---
set $mod Mod4
set $term alacritty
set $browser brave-browser
set $files pcmanfm

# --- FUENTES Y SISTEMA ---
font pango:Noto Sans 10
floating_modifier $mod

# --- INICIO AUTOMÁTICO ---
exec --no-startup-id /usr/local/bin/monitor-setup
exec --no-startup-id feh --bg-fill /usr/share/images/desktop-base/default
exec --no-startup-id nm-applet
exec --no-startup-id dunst
exec --no-startup-id udiskie --tray
exec --no-startup-id numlockx on
# Arreglar cursor (sin animación de carga)
exec --no-startup-id xsetroot -cursor_name left_ptr

# --- APARIENCIA ---
default_border pixel 2
default_floating_border pixel 2
# Colores de bordes (Azul Debian)
client.focused          #005577 #005577 #ffffff #2e9ef4 #005577
client.focused_inactive #333333 #5f676a #ffffff #484e50 #5f676a
client.unfocused        #333333 #222222 #888888 #292d2e #222222
client.urgent           #2f343a #900000 #ffffff #900000 #900000

# --- WORKSPACES ---
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"

# Cambiar a workspace
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5

# Mover ventana a workspace
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5

# --- ATAJOS PRINCIPALES ---
bindsym $mod+Return exec $term

# [CAMBIO] Mod+q para cerrar ventana (Más rápido)
bindsym $mod+q kill

# [CAMBIO] Mod+Space para menú dmenu
bindsym $mod+space exec dmenu_run -nb "#000000" -nf "#ffffff" -sb "#005577" -sf "#ffffff" -fn "NotoSans-11"

bindsym $mod+w exec $browser
bindsym $mod+f exec $files
bindsym $mod+c exec $term -e btop

# --- GESTIÓN DE VENTANAS ---
bindsym $mod+h split h
bindsym $mod+v split v
bindsym $mod+Shift+f fullscreen toggle
bindsym $mod+s layout stacking
bindsym $mod+e layout toggle split
bindsym $mod+Shift+space floating toggle

# [CAMBIO] Mod+Shift+d para cambiar foco (antes era Mod+Space)
bindsym $mod+Shift+d focus mode_toggle

# --- NAVEGACIÓN ---
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# --- CONTROL DE SISTEMA ---
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m '¿Qué deseas hacer?' -B 'Apagar' 'systemctl poweroff' -B 'Reiniciar' 'systemctl reboot' -B 'Cerrar Sesión' 'i3-msg exit'"

# Captura de pantalla
bindsym Print exec scrot '%Y-%m-%d_%H-%M-%S.png' -e 'mv $f ~/ && notify-send "Captura guardada" "$f"'

# Bloqueo
bindsym $mod+l exec i3lock -c 000000

# --- CONTROL DE VOLUMEN (Sin teclas multimedia) ---
# Mod + Ctrl + Flechas
bindsym $mod+Ctrl+Up exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym $mod+Ctrl+Down exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym $mod+Ctrl+m exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle

# --- BARRA DE ESTADO ---
bar {
        status_command i3status
        position top
        tray_output primary
        strip_workspace_numbers yes
        font pango:Noto Sans 10
        colors {
            background #1a1a1a
            statusline #dddddd
            separator #666666
            focused_workspace  #005577 #005577 #ffffff
            active_workspace   #333333 #5f676a #ffffff
            inactive_workspace #333333 #222222 #888888
            urgent_workspace   #2f343a #900000 #ffffff
        }
}
I3CONF
log "✓ i3wm configurado"

# ─── I3STATUS CONFIG (AUTO-DETECT) ───
log "Configurando i3status..."
backup_if_exists "$HOME/.config/i3status/config"
cat > "$HOME/.config/i3status/config" <<'STATUS'
general {
        colors = true
        interval = 2
        color_good = "#00FF00"
        color_degraded = "#FFFF00"
        color_bad = "#FF0000"
}

order += "cpu_usage"
order += "memory"
order += "cpu_temperature 0"
order += "ethernet _first_"
order += "disk /"
order += "disk /home"
order += "tztime local"
order += "volume master"

cpu_usage {
        format = "CPU %usage"
        degraded_threshold = 80
        max_threshold = 95
}

cpu_temperature 0 {
        format = "TEMP %degrees°C"
        path = "/sys/class/hwmon/hwmon1/temp1_input"
        max_threshold = 70
}

ethernet _first_ {
        format_up = "NET %ip"
        format_down = "NET down"
}

disk "/" {
        format = " %avail"
}

disk "/home" {
        format = " %avail"
}

memory {
        format = " %used"
        threshold_degraded = "1G"
        format_degraded = "RAM < %available"
}

tztime local {
        format = " %H:%M"
}

volume master {
        format = "VOL %volume"
        format_muted = "VOL muted"
        device = "default"
}
STATUS
log "✓ i3status configurado"

# ─── CONFIGURAR GTK TEMA OSCURO ───
log "Configurando tema oscuro GTK..."
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<'GTKSETTINGS'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
GTKSETTINGS

# GTK2
cat > "$HOME/.gtkrc-2.0" <<'GTKRC2'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Noto Sans 10"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
gtk-xft-rgba="rgb"
GTKRC2
log "✓ Tema oscuro GTK configurado"

# ─── CONFIGURAR VARIABLES DE ENTORNO ───
log "Configurando variables de entorno..."
cat > "$HOME/.xsessionrc" <<'XSESSION'
# Variables de entorno para i3
export GTK_THEME=Arc-Dark
export QT_QPA_PLATFORMTHEME=gtk2
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24
XSESSION
log "✓ Variables de entorno configuradas"

# ─── RESUMEN FINAL ───
echo ""
log "✅ Configuración de usuario completada con éxito"
echo ""
echo "Directorios XDG creados:"
echo "  • $HOME/Descargas"
echo "  • $HOME/Documentos"
echo "  • $HOME/Imágenes"
echo "  • $HOME/Música"
echo "  • $HOME/Vídeos"
echo "  • $HOME/Escritorio"
echo "  • $HOME/Wallpapers"
echo ""
echo "Archivos de configuración creados:"
echo "  • $HOME/.config/i3/config"
echo "  • $HOME/.config/i3status/config"

echo "  • $HOME/.config/alacritty/alacritty.toml"
echo "  • $HOME/.config/gtk-3.0/settings.ini"
echo "  • $HOME/.gtkrc-2.0"
echo "  • $HOME/.xsessionrc"
echo "  • $HOME/.config/user-dirs.dirs"
echo ""
echo "ℹ️  Los archivos anteriores fueron respaldados con extensión .bak"
echo "ℹ️  Recarga i3 con: Mod+Shift+R o cierra sesión y vuelve a entrar"
echo ""
