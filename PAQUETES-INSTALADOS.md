# 📦 Análisis de Paquetes Instalados (879 total)

Sistema: **Debian 13 Trixie** con i3wm  
Fecha: 7 de abril de 2026  
Hardware: AMD Athlon II X4 640 @ 3.0GHz, 8GB RAM, BTRFS/XFS

---

## ✅ **PAQUETES ESENCIALES (Core)**

### Sistema Base (~200 paquetes)
- **Init**: systemd, dbus, udev
- **Shell**: bash, dash, coreutils, util-linux
- **Paquetes**: apt, dpkg, debconf
- **Red**: NetworkManager, dhcpcd, curl, wget
- **Seguridad**: apparmor, gpg, sudo, passwd

### Kernel y Boot
- `linux-image-6.12.63+deb13-amd64` (kernel actual)
- `linux-image-amd64` (metapaquete)
- `grub2`, `dracut`, `btrfs-progs`

---

## 🖥️ **ENTORNO GRÁFICO (27 paquetes)**

### X11 Base
- `xorg`, `xserver-xorg`, `xinit`, `x11-xserver-utils`

### Window Manager i3
- `i3-wm` (tiling window manager)
- `i3status` (barra de estado)
- `i3lock` (bloqueador de pantalla)
- `dmenu` (lanzador de aplicaciones)
- `dunst` (notificaciones)
- `arandr` (configuración de monitores)
- `numlockx` (activar teclado numérico)
- **Nota**: No se usa compositor (ni picom ni opciones similares, para no sobrecargar la GPU) y el TearFree lo maneja el driver Radeon (EXA).

### Login Manager (ACTUAL)
- `lightdm` + `lightdm-gtk-greeter` (~80MB RAM, login gráfico)
- **Alternativa disponible**: `greetd` + `tuigreet` (~15MB RAM, login TUI)

---

## 🎨 **TEMAS Y ESTÉTICA**

### Temas GTK
- `arc-theme` (tema activo) ✅
- `papirus-icon-theme` (iconos activos) ✅
- `adwaita-icon-theme` (fallback)
- `desktop-base` (fondos de Debian)
- `grub-theme-starfield` (tema GRUB)

### Fuentes
- `fonts-noto-core` (Noto Sans) ✅
- `fonts-font-awesome` (iconos) ✅
- `fonts-dejavu-core`, `fonts-dejavu-mono`
- `fonts-quicksand`, `fonts-urw-base35`

---

## 🚀 **APLICACIONES INSTALADAS**

### Terminales
- `alacritty` (terminal principal, GPU-acelerado) ✅
- `lxterminal` ⚠️ **REDUNDANTE** (puede eliminarse)

### Navegadores
- `brave-browser` (instalado oficialmente con banderas VA-API habilitadas automáticamente) ✅

### Gestores de Archivos
- `pcmanfm` (gestor ligero con GTK) ✅
- `gvfs`, `gvfs-backends` (soporte SFTP, SMB, etc.)
- `udisks2`, `udiskie` (montaje automático USBs)

### Multimedia
- `mpv` (reproductor de video) ✅
- `zathura` (lector PDF ligero) ✅
- `feh` (visor de imágenes + fondo de pantalla) ✅
- `scrot` (capturas de pantalla) ✅
- `pavucontrol` (control de volumen) ✅

### Utilidades
- `btop` (monitor de recursos) ✅
- `fastfetch` (info del sistema) ✅
- `git`, `curl`, `wget` ✅
- `unzip`, `p7zip-full`, `7zip` ✅
- `lxappearance` (configurar temas GTK) ✅

---

## 🔊 **AUDIO (Pipewire)**

### Servidor de Audio
- `pipewire` (servidor moderno)
- `pipewire-pulse` (compatibilidad PulseAudio)
- `wireplumber` (gestor de sesión)
- `rtkit` (prioridad real-time)
- `pulseaudio-utils` (herramientas CLI)

---

## 🎮 **DRIVERS Y FIRMWARE**

### AMD Graphics
- `firmware-amd-graphics` (firmware GPU)
- `amd64-microcode` (microcódigo CPU)
- `libgl1-mesa-dri` (OpenGL)
- `mesa-va-drivers` (VA-API Video decoders)
- `mesa-utils` (herramientas)
- **Nota**: El paquete de `vulkan` fue purgado intencionalmente porque Radeon HD 3000 NO lo soporta.

### Firmware Adicional (7 paquetes)
- `firmware-linux-nonfree`
- `firmware-misc-nonfree`
- `firmware-intel-graphics` ⚠️ (no necesario en AMD)
- `firmware-intel-misc` ⚠️ (no necesario en AMD)
- `firmware-mediatek` ⚠️ (no hay hardware Mediatek)
- `firmware-realtek` (ethernet/WiFi)

---

## ⚙️ **SERVICIOS DESHABILITADOS** (librerías presentes)

### Impresoras (CUPS)
- Servicio: **Deshabilitado** ✅
- Librerías: `libcups2t64` (presente, ~5MB)
- Acción: Mantener librerías (algunas apps las requieren)

### Avahi (mDNS/Zeroconf)
- Servicio: **Deshabilitado + Masked** ✅
- Librerías: 4 paquetes (presente, ~2MB)
- Acción: Mantener librerías (GVFS las necesita)

### Bluetooth
- Servicio: **Bloqueado en kernel** ✅
- Hardware: No presente
- Paquetes: 0 (eliminado completamente)

### Otros Deshabilitados
- ModemManager (red móvil)
- wpa_supplicant (WiFi)
- geoclue (geolocalización)
- speech-dispatcher (síntesis de voz)

---

## 🧹 **PAQUETES REDUNDANTES DETECTADOS**

### Confirmados
1. **lxterminal** ⚠️ 
   - Razón: Ya tienes alacritty
   - Acción: Eliminar con `apt purge lxterminal`
   - Ahorro: ~3MB

### Firmware Innecesario
2. **firmware-intel-graphics** ⚠️
   - Razón: Sistema AMD
   - Acción: Ya se elimina automáticamente en script
   
3. **firmware-intel-misc** ⚠️
   - Razón: Sistema AMD
   - Acción: Ya se elimina automáticamente en script

4. **firmware-mediatek** ⚠️
   - Razón: No hay hardware Mediatek
   - Acción: Puede eliminarse manualmente

### Editores CLI (Opcionales)
- `nano` (18KB) - Útil para emergencias
- `vim-tiny` (1.2MB) - Útil para servidor SSH
- **Recomendación**: Mantener (peso mínimo, útiles sin X11)

---

## 📊 **RESUMEN POR CATEGORÍA**

| Categoría | Paquetes | Uso Disco | Nota |
|-----------|----------|-----------|------|
| Sistema Base | ~200 | ~1.5GB | Esencial |
| Mesa/AMD Graphics | 529 | ~300MB | OpenGL/Vulkan |
| X11 + i3wm | 27 | ~80MB | Entorno gráfico |
| Aplicaciones | 15 | ~500MB | Brave es el mayor |
| Firmware | 7 | ~100MB | AMD + Realtek |
| Audio | 8 | ~50MB | Pipewire stack |
| Temas/Fuentes | 20 | ~80MB | Arc + Papirus |
| Librerías | ~100 | ~800MB | Dependencias |
| **TOTAL** | **879** | **~3.5GB** | Sistema limpio |

---

## 🎯 **OPTIMIZACIONES APLICADAS**

### Automáticas (en script)
✅ Eliminación de firmware Nvidia  
✅ Limpieza de kernels antiguos  
✅ Compresión Btrfs (zstd:3)  
✅ Servicios innecesarios deshabilitados  

### Manuales Recomendadas
⚠️ Eliminar lxterminal: `sudo apt purge lxterminal && sudo apt autoremove`  
⚠️ Eliminar firmware Intel: `sudo apt purge firmware-intel-*`  
⚠️ Eliminar firmware Mediatek: `sudo apt purge firmware-mediatek`  

**Ahorro total estimado**: ~100-150MB

---

## 🔄 **MIGRACIÓN A greetd (Opcional)**

### Estado Actual
- **lightdm**: 3 paquetes, ~80MB RAM, login gráfico (demora 3-5s)

### Alternativa Disponible
- **greetd + tuigreet**: 2 paquetes, ~15MB RAM, login TUI (instantáneo)
- Versiones: greetd 0.10.3, tuigreet 0.9.1
- **Ahorro RAM**: ~65MB
- **Velocidad**: Login <2 segundos

### Prueba
```bash
sudo bash /tmp/test-greetd.sh
sudo reboot
```

**Reversión** (si hay problemas):
```bash
sudo systemctl disable greetd.service
sudo systemctl enable lightdm.service
sudo reboot
```

---

## 📝 **NOTAS FINALES**

1. **879 paquetes es normal** para un sistema Debian con X11+i3wm
2. **Sistema limpio**: Sin GNOME, KDE, ni servicios pesados
3. **Mesa (529 paquetes)**: Son librerías OpenGL/Vulkan, necesarias
4. **Librerías deshabilitadas**: CUPS/Avahi presentes pero inactivas (correcto)
5. **Kernel único**: Solo 1 kernel instalado + metapaquete (óptimo)

**Comparación**:
- Debian GNOME típico: ~1800 paquetes, 4-6GB
- Tu sistema i3wm: 879 paquetes, ~3.5GB ✅
- **50% más ligero que GNOME** 🎉
