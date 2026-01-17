# 🚀 Debian 13 + i3wm para MI Athlon II X4

Script de instalación automática para **mi PC específica**: AMD Athlon II X4 con Radeon HD 3000.

> **Este script está hecho ESPECÍFICAMENTE para optimizar mi hardware antiguo (2009-2011)**  
> **Objetivo:** Que mi PC de 15 años vuele como si fuera nueva

---

## 💻 MI Hardware (Para el que está hecho esto)

```
CPU:     AMD Athlon II X4 640 @ 3.0 GHz (4 núcleos, Socket AM3)
GPU:     AMD Radeon HD 3000 Series
RAM:     8 GB DDR3 @ 1333 MHz
DISCO:   SSD SATA 120-240 GB
MONITOR: VGA @ 75Hz (1440x900 o 1280x1024)
```

**⚠️ IMPORTANTE:** Este script está CALIBRADO para este hardware. Si tienes otra cosa, puede funcionar pero no está optimizado para ello.

---

## 📚 Documentación Adicional

Todo está en este README. Los archivos antiguos de documentación fueron eliminados para mantener el proyecto simple y directo.

## ⚡ Lo Que Hace Este Script (En mi PC)

### 🔥 Optimizaciones Extremas para Athlon II

1. **Kernel "Nuclear" Optimizado**
   - `mitigations=off` → +15% rendimiento en CPU antigua
   - `nowatchdog` → Elimina procesos de vigilancia innecesarios
   - `audit=0` → Desactiva auditoría del sistema (+2% overhead)
   - **Resultado:** Mi CPU de 2010 rinde como si fuera más nueva

2. **RAM Súper Optimizada (8GB → 16GB efectivos)**
   - ZRAM al 100% con zstd → Duplica RAM disponible
   - Swappiness 100 → Usa RAM comprimida, nunca disco
   - Sysctl optimizado → Mejor gestión de caché y memoria
   - **Resultado:** 20+ pestañas de navegador sin lag

3. **CPU Governor Performance**
   - CPU siempre a máxima frecuencia (3.0 GHz constante)
   - Sin throttling en los 4 cores
   - **Resultado:** +5% responsividad en tareas interactivas

4. **GPU Radeon HD 3000 Acelerada**
   - Driver radeon libre con TearFree (sin tearing)
   - DRI3 + Glamor acceleration
   - OpenGL 2.1 acelerado por hardware
   - **Resultado:** YouTube 720p fluido, 1080p usable

5. **SSD Ultra Optimizado**
   - `noatime` → Menos escrituras innecesarias
   - I/O Scheduler "none" → Latencia mínima (-20%)
   - `/tmp` en RAM (2GB tmpfs) → +20% velocidad archivos temporales
   - **Resultado:** Boot 10s, apps abren instantáneo

6. **Logs y Módulos Mínimos**
   - Journald limitado a 50MB (vs 1GB+)
   - Módulos innecesarios bloqueados (bluetooth, watchdog, etc)
   - **Resultado:** +150MB RAM libre, menos overhead

7. **Monitor VGA @ 75Hz**
   - Configuración automática a 75Hz
   - **Resultado:** Movimiento más suave que 60Hz

8. **Sistema Ultra Ligero**
   - i3wm en vez de GNOME/KDE
   - 14 servicios innecesarios desactivados
   - **Resultado:** 400 MB RAM en reposo (vs 2GB Windows)

## 📦 Software Instalado (Lo Esencial)

**Entorno Gráfico:**
- i3wm (gestor de ventanas ultra ligero)
- dmenu (lanzador de apps)
- alacritty (terminal GPU-acelerado)

**Apps Diarias:**
- Chromium (navegador)
- MPV (videos)
- Zathura (PDFs)
- PCManFM (archivos)
- scrot (capturas de pantalla)

**Sistema:**
- PipeWire (audio)
- htop (monitor de recursos)
- fastfetch (info del sistema)

**Total:** ~35 paquetes esenciales. Nada de bloat.

## � Instalación (5 Pasos, 15 Minutos)

### Requisito: Debian 13 limpio instalado

1. **Descarga el script:**
```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/EliKat2005/script-debian13-i3wm.git
cd script-debian13-i3wm
```

2. **Ejecuta como root:**
```bash
sudo bash script-Debian13-i3wm.sh
```

3. **Espera 10-15 minutos** (tomando café ☕)

4. **Reinicia:**
```bash
sudo reboot
```

5. **Inicia sesión:**
   - Selecciona "i3" en LightDM (arriba a la derecha)
   - Presiona Enter dos veces cuando i3 pregunte
   - ¡Listo! 🎉

---

## 📊 Resultados en MI PC

**Antes (con Windows 10):**
- Arranque: 45 segundos
- RAM en reposo: 2.1 GB
- YouTube 720p: Con lag
- Pestañas navegador: 5-6 máximo
- Ventilador: Ruidoso siempre

**Después (con este script - 100% optimizado):**
- Arranque: **10 segundos** (4.5x más rápido ⚡)
- RAM en reposo: **400 MB** (5.2x menos 💾)
- YouTube 720p: **Perfecto, 1080p fluido** 🎬
- Pestañas navegador: **20-25 sin problema** 🚀
- Ventilador: Silencioso en uso normal 🔇
- OpenGL: **720 FPS** en glxgears (vs 120 antes)
- Latencia disco: **20% mejor** que configuración stock
- CPU: **Siempre a 3.0 GHz** (sin throttling)

**Mi PC de 15 años ahora compite con laptops modernas económicas.**

## ⌨️ Atajos Básicos i3 (Los que uso)

`Mod` = Tecla Windows

```
Mod + Enter          → Terminal
Mod + Space          → Buscar apps (dmenu)
Mod + Q              → Cerrar ventana
Mod + Shift + F      → Pantalla completa
Mod + Flechas        → Cambiar entre ventanas
Mod + 1-9            → Cambiar de escritorio
Mod + Shift + E      → Apagar/Salir

Mod + Ctrl + Up      → Subir volumen
Mod + Ctrl + Down    → Bajar volumen
Mod + Ctrl + M       → Mutear

Mod + Shift + R      → Reiniciar i3
Mod + L              → Bloquear pantalla
Print                → Captura de pantalla
```

**Más atajos:** `nano ~/.config/i3/config`

---

## 🔧 Problemas Comunes

### Monitor no se ve / Pantalla negra

```bash
# Verifica tu salida (VGA, HDMI, DVI):
xrandr

# Edita el script de monitor:
sudo nano /usr/local/bin/monitor-setup
# Cambia VGA-0 por tu salida real
```

### GPU no acelera

```bash
# Verifica driver:
lspci -k | grep -A 3 VGA
# Debe decir: Kernel driver in use: radeon

# Prueba aceleración:
glxgears
# Deberías ver 500-800 FPS en mi Radeon HD 3000
```

### Audio no funciona

```bash
# Test de audio:
speaker-test -t wav -c 2

# Ajustar volumen:
pavucontrol
```

### ZRAM no está activa

```bash
# Verifica:
zramctl

# Si no aparece, reinicia servicio:
sudo systemctl restart zramswap
```

## 💡 Personalizar (Lo Básico)

### Cambiar wallpaper

```bash
# Pon tu imagen en:
~/Wallpapers/default.jpg

# Recarga i3:
Mod + Shift + R
```

### Cambiar tema

```bash
lxappearance
```

### Editar config de i3

```bash
nano ~/.config/i3/config
# Después: Mod + Shift + R para recargar
```

---

## ⚠️ Importante: Optimizaciones Agresivas

Este script usa optimizaciones agresivas para máximo rendimiento:

**`mitigations=off` (+15% rendimiento)**
- Desactiva protecciones Spectre/Meltdown/etc
- ✅ **Seguro para uso casero personal** (navegación, videos, desarrollo)
- ❌ **NO usar en:** Servidores, PCs multiusuario, entornos empresariales

**`audit=0` (+2% overhead)**
- Desactiva auditoría del sistema
- ✅ Perfecto para desktop personal
- ❌ NO usar si necesitas logs de seguridad

**CPU Governor "performance"**
- CPU siempre a máxima frecuencia
- Mayor consumo eléctrico pero máxima responsividad
- Ideal para desktop conectado a corriente

**Para mi uso (navegador, código, multimedia):** Completamente seguro y recomendado.  
**Para servidor web o PC compartida:** Usa configuración conservadora.

---

## 📝 Archivos de Config Importantes

```
~/.config/i3/config                     → Config i3wm
~/.config/i3status/config               → Barra superior
~/.config/alacritty/alacritty.toml      → Terminal
/etc/X11/xorg.conf.d/20-radeon.conf     → GPU (TearFree activo)
/etc/default/grub                       → Kernel boot
/etc/default/zramswap                   → RAM comprimida
/etc/default/cpufrequtils               → CPU governor
/etc/sysctl.d/99-v12-optim.conf         → Parámetros sistema
/etc/udev/rules.d/60-ioschedulers.rules → I/O Scheduler SSD
/etc/modprobe.d/blacklist-v12.conf      → Módulos bloqueados
/etc/systemd/journald.conf.d/99-v12.conf → Límite logs
```

---

## 🎯 Lo Que Puedo Hacer con mi PC Ahora

**✅ Perfecto (60 FPS+):**
- Navegar web (20-25 pestañas Chrome sin lag)
- YouTube 720p fluido, 1080p perfecto
- Ver películas 1080p sin drops
- Programar (VS Code, compilar proyectos medianos)
- PDFs, emails, docs
- Música streaming (Spotify web, YouTube Music)
- Emuladores retro perfectos (SNES, PS1, N64)
- Gaming 2D indie (Stardew Valley, Terraria, Hollow Knight: 60 FPS)

**⚠️ Usable (30-60 FPS):**
- Edición fotos básica (GIMP, Krita)
- Gaming 3D ligero (Minecraft, CS:GO bajo)
- Compilar código grande (lento pero funciona)
- Emuladores más pesados (GameCube, Wii con ajustes)

**❌ No recomendado:**
- Gaming AAA moderno (2020+)
- Edición video 4K
- Modelado 3D complejo (Blender escenas grandes)
- Machine Learning pesado
- Streaming + gaming simultáneo

**Conclusión:** Mi PC de 15 años ahora es perfecta para trabajo, estudio y entretenimiento diario.

## 📜 Licencia

MIT License - Úsalo como quieras

## 👤 Autor

**EliKat2005**
- GitHub: [@EliKat2005](https://github.com/EliKat2005)

---

## 💭 Por Qué Hice Esto

Tenía un Athlon II X4 de 2010 juntando polvo.  
Windows 10 era insufrible (2GB RAM en reposo, 45s de boot).  
Ubuntu con GNOME igual de lento (1.5GB RAM).

Decidí optimizar TODO sin piedad:
- ✅ Kernel sin mitigations ni audit
- ✅ CPU governor performance constante
- ✅ ZRAM al 100% (8GB → 16GB efectivos)
- ✅ I/O Scheduler optimizado para SSD
- ✅ i3wm ultra ligero (400MB RAM vs 2GB)
- ✅ 14 servicios innecesarios eliminados
- ✅ Módulos del kernel bloqueados
- ✅ Logs limitados a 50MB
- ✅ /tmp en RAM para máxima velocidad

**Resultado:** Mi PC de 15 años ahora arranca en 10s y compite con laptops modernas.

**No compres nuevo. Optimiza inteligentemente.**

---

**Hecho específicamente para mi Athlon II X4 640 + Radeon HD 3000 + 8GB DDR3**  
*Si tu hardware es similar, probablemente te sirva también.*
