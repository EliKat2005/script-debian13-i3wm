# 📚 Índice de Documentación - Debian 13 + i3wm

## 🎯 Comienza aquí

### Para instaladores principiantes:
1. Lee: [README.md](README.md) - Descripción general del proyecto
2. Lee: [INSTALACION.md](INSTALACION.md) - Guía paso a paso
3. Ejecuta: `sudo ./script-Debian13-i3wm.sh`
4. Reinicia: `sudo reboot`

### Para usuarios con GPU NVIDIA:
Después de completar los pasos anteriores:
1. Lee: [COMPATIBILIDAD.md](COMPATIBILIDAD.md) - Verificar compatibilidad
2. Ejecuta: `sudo ./script-Nvidia-offload.sh`
3. Reinicia: `sudo reboot`

---

## 📖 Documentos Principales

### [README.md](README.md)
**Descripción:** Presentación general del proyecto
**Contenido:**
- Hardware soportado
- Características principales
- 71 aplicaciones incluidas
- Atajos de teclado i3wm
- Troubleshooting básico
- Información de mantenimiento

**Público:** Todos
**Lectura:** 5-10 minutos

---

### [INSTALACION.md](INSTALACION.md)
**Descripción:** Guía completa paso a paso de instalación
**Contenido:**
- Requisitos previos detallados
- Ejecución del script principal
- Verificaciones post-instalación
- Instalación opcional de Nvidia
- Verificaciones con Nvidia
- Atajos de teclado completos
- Workspaces predefinidos
- Optimizaciones aplicadas
- Troubleshooting avanzado
- Gaming setup

**Público:** Usuarios nuevos
**Lectura:** 15-20 minutos

---

### [COMPATIBILIDAD.md](COMPATIBILIDAD.md)
**Descripción:** Matriz técnica de compatibilidad cross-script
**Contenido:**
- Verificación de compatibilidad 100%
- Detalles técnicos por sistema (repos, paquetes, modprobe, etc.)
- Matriz de conflictos (0 encontrados)
- Secuencia recomendada de instalación
- Flujos de uso (normal vs gaming)
- Verificación post-instalación

**Público:** Usuarios técnicos, curiosos
**Lectura:** 10-15 minutos

---

### [LICENSE](LICENSE)
**Descripción:** Licencia MIT del proyecto
**Público:** Todos

---

## 🔧 Scripts de Instalación

### `script-Debian13-i3wm.sh` (1080 líneas, 36KB)
**Propósito:** Instalación base completa

**Qué instala:**
✅ Sistema Debian 13 optimizado
✅ i3wm con configuración avanzada
✅ GPU Intel UHD 620 configurada
✅ WiFi Atheros QCA9377 optimizado
✅ Audio PipeWire + Bluetooth
✅ 71 paquetes esenciales
✅ Picom compositor
✅ Dunst notificaciones
✅ ZRAM comprimido

**Tiempo:** ~20-30 minutos
**Ejecución:** `sudo ./script-Debian13-i3wm.sh`
**Reboot:** OBLIGATORIO

---

### `script-Nvidia-offload.sh` (90 líneas, ~3KB)
**Propósito:** Instalación opcional de GPU NVIDIA para gaming

**Qué instala:**
✅ Driver NVIDIA (auto-detectado)
✅ Librerías 32-bit (Steam/Wine)
✅ Soporte Vulkan
✅ Power management dinámico
✅ Wrapper offload rendering

**Tiempo:** ~5-10 minutos
**Ejecución:** `sudo ./script-Nvidia-offload.sh` (después del script principal)
**Reboot:** OBLIGATORIO
**Compatibilidad:** 100% con script principal

---

## 📁 Archivos de Configuración

### `picom.conf` (32 líneas)
**Propósito:** Configuración del compositor Picom
**Contenido:**
- Backend: GLX con vsync
- Efectos de sombra
- Reglas de opacidad (kitty, i3bar)
- Rendimiento optimizado

---

### `i3/` directorio
Contiene archivos de configuración de i3wm:

#### `i3/config` (1100+ líneas)
**Propósito:** Configuración completa de i3wm
**Características destacadas:**
- Workspace naming (1:web, 2:dev, 3:work, 4:chat, 5:media, 6:misc)
- Workspace cycling (Mod+Tab/Shift+Tab)
- Scratchpad terminal (Mod+`, Quake-style)
- Multi-monitor support (Mod+Ctrl+Arrows)
- Resize directo (Mod+Alt+Arrows)
- Integración con Picom
- Todos los atajos de teclado

#### `i3/i3status.conf` (~100 líneas)
**Propósito:** Barra de estado i3
**Información:**
- CPU usage
- Memoria RAM
- Temperatura
- Volumen
- Batería
- Fecha/hora

---

## 🚀 Flujos de Uso

### Instalación Mínima
```
PC con Debian 13 base
    ↓
Ejecutar script-Debian13-i3wm.sh
    ↓
Reboot
    ↓
Sistema completo + i3wm + Intel GPU ✅
```

### Instalación Completa (Gaming)
```
PC con Debian 13 base
    ↓
Ejecutar script-Debian13-i3wm.sh
    ↓
Reboot
    ↓
Ejecutar script-Nvidia-offload.sh
    ↓
Reboot
    ↓
Sistema gaming ready ✅
```

---

## 📊 Especificaciones

### Hardware Optimizado
- **Laptop:** Dell Inspiron 5584
- **CPU:** Intel Core i7-8565U (8 cores @ 4.6 GHz)
- **GPU Intel:** UHD Graphics 620 (primaria)
- **GPU NVIDIA:** MX130 (offload, opcional)
- **RAM:** 15.5 GB + 7.75 GB ZRAM
- **WiFi:** Qualcomm Atheros QCA9377
- **Audio:** PipeWire + Bluetooth

### Paquetes Incluidos
- **Total:** 71 (base) + 15-20 (opcional Nvidia)
- **Categorías:**
  - Terminal: Kitty
  - Navegador: Chromium
  - Multimedia: MPV, Feh
  - Documentos: Zathura, LibreOffice
  - Utilidades: Rofi, Flameshot, Timeshift
  - Herramientas: btop, GParted, Blueman
  - Entorno: i3wm, Picom, Dunst, LXAppearance

---

## ⚡ Características Destacadas

### WiFi Optimizado
Multi-layer ASPM optimization:
- GRUB: `pci=noaer pcie_aspm=off`
- Modprobe: `irq_mode=legacy`
- udev: Power control rules
- NetworkManager: Power save disable

**Resultado:** Conexión estable, PCIe errors minimizados

### i3wm Avanzado
- Workspace cycling (Tab-based navigation)
- Scratchpad terminal (Quake-style dropdown)
- Multi-monitor support
- Direct resize mode
- Named workspaces
- Modern keybindings

### GPU Hybrid (Optimus)
- Intel UHD 620: Bajo consumo, por defecto
- NVIDIA MX130: Bajo demanda, gaming
- Rendering offload automático
- No conflictos de drivers

### Audio de Calidad
- PipeWire (no PulseAudio)
- Bluetooth HSP/HFP/mSBC
- Latencia baja
- Múltiples dispositivos

---

## 🔗 Referencias Rápidas

### Comandos Útiles
```bash
# WiFi
nmcli device wifi list
sudo wifi-fix

# GPU Intel
glxinfo | grep -i renderer

# GPU NVIDIA (si instalado)
nvidia-smi
nv glxinfo | grep -i renderer

# i3wm
i3 --version
i3-msg restart

# Audio
pactl list sinks
bluetoothctl show

# Sistema
neofetch
sensors
```

### Archivos Importantes
```bash
~/.config/i3/config              # Configuración i3
~/.config/dunst/dunstrc          # Notificaciones
~/.config/kitty/kitty.conf       # Terminal
~/Wallpapers/default.jpg         # Wallpaper
/usr/local/bin/i3-brightness     # Control brillo
/usr/local/bin/wifi-fix          # Diagnóstico WiFi
/usr/local/bin/nv                # GPU wrapper (si Nvidia)
```

---

## 📋 Checklist de Instalación

- [ ] Leer README.md
- [ ] Descargar scripts
- [ ] `chmod +x script-*.sh`
- [ ] `sudo ./script-Debian13-i3wm.sh`
- [ ] Reboot
- [ ] Verificar WiFi (`nmcli device wifi list`)
- [ ] Verificar i3wm (`i3 --version`)
- [ ] Verificar GPU (`glxinfo | grep renderer`)
- [ ] (Opcional) `sudo ./script-Nvidia-offload.sh`
- [ ] (Opcional) Reboot
- [ ] (Opcional) Verificar Nvidia (`nvidia-smi`)
- [ ] ¡Disfrutar! 🎉

---

## 🆘 Necesitas Ayuda?

### Problemas Comunes

1. **WiFi no funciona**
   - Ver: [INSTALACION.md - Troubleshooting](INSTALACION.md#-troubleshooting)
   - Ejecutar: `sudo wifi-fix`

2. **Nvidia no detectada**
   - Ver: [INSTALACION.md - GPU no detectada](INSTALACION.md#-troubleshooting)
   - Ejecutar: `lspci | grep -i nvidia`

3. **i3 no responde**
   - Atajo: `Mod+Shift+r` (reload)
   - O: `i3 restart`

4. **Brillo no funciona**
   - Ver: [INSTALACION.md - Brillo](INSTALACION.md#-troubleshooting)

5. **Audio bajo o sin sonido**
   - Ver: README.md [Resolución de Problemas](README.md#-resolución-de-problemas)

### Más Información
- [INSTALACION.md](INSTALACION.md) - Guía completa
- [COMPATIBILIDAD.md](COMPATIBILIDAD.md) - Detalles técnicos
- [README.md](README.md) - Características

---

## 📄 Resumen de Archivos

```
script-debian13-i3wm/
├── README.md              ← Comienza aquí (descripción general)
├── INSTALACION.md         ← Guía paso a paso
├── COMPATIBILIDAD.md      ← Matriz técnica
├── INDICE.md              ← Este archivo
├── LICENSE                ← MIT License
├── script-Debian13-i3wm.sh      ← Script principal (1080 líneas)
├── script-Nvidia-offload.sh     ← Script GPU opcional (90 líneas)
├── picom.conf             ← Config compositor
└── i3/
    ├── config             ← Config i3wm principal
    └── i3status.conf      ← Barra de estado
```

---

## 📈 Mejoras Recientes

✅ **v2.0 (Diciembre 2025):**
- Documentación completa en 3 archivos (README + INSTALACION + COMPATIBILIDAD)
- Verificación 100% compatibilidad con script Nvidia
- Guía gaming setup
- Matriz técnica detallada
- Troubleshooting completo

✅ **Últimas optimizaciones:**
- i3 workspace naming + cycling
- Scratchpad terminal (Quake-style)
- Multi-monitor support
- Direct resize
- WiFi multi-layer optimization
- Code cleanup (1130→1080 líneas)

---

## 📞 Información del Proyecto

- **Licencia:** MIT
- **Hardware:** Dell Inspiron 5584 (generalizable)
- **OS:** Debian 13 (Trixie)
- **i3wm:** v4.23+
- **Mantenimiento:** Activo
- **Última actualización:** Diciembre 2025

---

## 🎯 Próximos Pasos

1. **Si es tu primer uso:**
   - Lee [INSTALACION.md](INSTALACION.md)
   - Ejecuta los scripts en orden

2. **Si quieres gaming:**
   - Ejecuta script principal
   - Ejecuta script Nvidia
   - Ver [INSTALACION.md - Gaming Setup](INSTALACION.md#-gaming-setup-completo)

3. **Si tienes problemas:**
   - Consulta [README.md - Troubleshooting](README.md#-resolución-de-problemas)
   - O [INSTALACION.md - Troubleshooting](INSTALACION.md#-troubleshooting)

4. **Si quieres entender todo:**
   - Lee [COMPATIBILIDAD.md](COMPATIBILIDAD.md)
   - Inspecciona los scripts
   - Modifica según necesites

---

**¡Bienvenido a Debian 13 + i3wm!** 🚀

Para comenzar: [README.md](README.md) → [INSTALACION.md](INSTALACION.md) → Scripts

---

*Generado: Diciembre 2025*
*Versión: 2.0*
*Estado: Producción ✅*
