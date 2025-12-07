# Guía de Instalación Completa - Debian 13 + i3wm + Nvidia Offload

## 📋 Requisitos Previos

- **Laptop:** Dell Inspiron 5584 (u otro con Intel + Nvidia Optimus)
- **USB:** Debian 13 Netinst bootable
- **Usuario:** Con acceso sudo
- **Conexión:** WiFi o Ethernet funcionando en instalación base

---

## 🚀 PASO 1: Instalación Base - Debian 13 + i3wm

### Requisitos:
- Sistema Debian 13 recién instalado (usuario con sudo)
- Conexión a internet

### Ejecución:

```bash
sudo ./script-Debian13-i3wm.sh
```

### Qué instala:

- ✅ Firmware completo (Intel, Atheros WiFi, Bluetooth)
- ✅ i3wm con configuración optimizada
- ✅ PipeWire + Bluetooth
- ✅ Intel UHD 620 (drivers + optimizaciones)
- ✅ Atheros QCA9377 WiFi (multi-layer ASPM fix)
- ✅ 71 paquetes esenciales (sin bloatware)
- ✅ Picom compositor
- ✅ Dunst notificaciones
- ✅ ZRAM swap comprimido

### Tiempo estimado:
~20-30 minutos (depende de velocidad internet)

### Después de completarse:

```bash
# IMPORTANTE: REBOOT obligatorio
sudo reboot
```

---

## 🔄 Post-Instalación 1: Verificación

### Verificar que todo funciona:

```bash
# WiFi
nmcli device wifi list

# Bluetooth
bluetoothctl show

# Audio
pactl list sinks

# i3wm (dentro de i3)
i3 --version
```

---

## 🎮 PASO 2: Instalación de Nvidia GPU (Offload Gaming)

### Requisitos:
- Script base ya ejecutado y reinicios completados
- Nvidia MX130 detectada (`lspci | grep -i nvidia`)

### Ejecución:

```bash
sudo ./script-Nvidia-offload.sh
```

### Qué instala:

- ✅ Driver Nvidia correcto (detección automática)
- ✅ Librerías 32-bit para Steam/Wine
- ✅ Soporte Vulkan + OpenGL
- ✅ Power management (Dynamic Power Management)
- ✅ Wrapper script `/usr/local/bin/nv`
- ✅ Blacklist Nouveau

### Tiempo estimado:
~5-10 minutos

### Después de completarse:

```bash
# IMPORTANTE: REBOOT obligatorio
sudo reboot
```

---

## ✅ Post-Instalación 2: Verificación Nvidia

### Verificar que Nvidia funciona:

```bash
# Ver driver instalado
nvidia-smi

# Ver ICD Vulkan
ls -la /usr/share/vulkan/icd.d/

# Probar offload rendering
__NV_PRIME_RENDER_OFFLOAD=1 glxinfo | grep NVIDIA
```

---

## 🎮 Uso en Steam/Gaming

### Método 1: Steam (recomendado)

```bash
1. Abre Steam
2. Click derecho en juego → Propiedades
3. Parámetros de lanzamiento:
   nv %command%
4. Guardar y jugar
```

### Método 2: Terminal directo

```bash
nv ./juego

# O cualquier aplicación OpenGL/Vulkan
nv vulkaninfo
nv glxgears
```

---

## 🔑 Atajos de Teclado i3 (Principales)

| Atajo | Acción |
|-------|--------|
| **Mod+Tab** | Siguiente workspace |
| **Mod+Shift+Tab** | Workspace anterior |
| **Mod+grave** | Terminal flotante (scratchpad) |
| **Mod+Return** | Nueva terminal kitty |
| **Mod+space** | Lanzador rofi |
| **Mod+Alt+Arrows** | Resize rápido sin modo |
| **Mod+Ctrl+Left/Right** | Foco en monitor |
| **XF86MonBrightnessUp/Down** | Control de brillo |
| **XF86AudioRaiseVolume/LowerVolume** | Volumen |

---

## 📱 Workspaces Predefinidos

| Workspace | Nombre | Uso sugerido |
|-----------|--------|-------------|
| 1 | `1:web` | Navegador + redes |
| 2 | `2:dev` | IDE + terminal |
| 3 | `3:work` | Documentos + office |
| 4 | `4:chat` | Discord, Telegram |
| 5 | `5:media` | Multimedia + gaming |
| 6 | `6:misc` | Herramientas |

---

## ⚡ Optimizaciones Aplicadas

### WiFi (Atheros QCA9377)
- ✅ Multi-layer ASPM disable (GRUB + modprobe + udev)
- ✅ NetworkManager dispatcher para power save
- ✅ IRQ mode optimization (legacy)
- ✅ Resultado: Conexión estable, PCIe errors minimizados

### GPU Intel
- ✅ TearFree habilitado (Xorg)
- ✅ Aceleración SNA + DRI 3
- ✅ i915 GUC + FBC habilitados
- ✅ Resultado: Mejor rendimiento, eficiencia energética

### Memoria
- ✅ ZRAM 50% (7.75 GB swap comprimido con LZ4)
- ✅ Resultado: Laptop fluida incluso con RAM limitada

### Audio
- ✅ PipeWire en lugar de PulseAudio
- ✅ Bluetooth HSP/HFP/mSBC habilitado
- ✅ Resultado: Audio superior, latencia baja

---

## 🔧 Troubleshooting

### WiFi no funciona

```bash
sudo wifi-fix
# Script diagnóstico que reinicia módulos y NetworkManager
```

### Brillo muy bajo/alto

```bash
# Ver brillo actual
light -G

# Establecer a 50%
light -S 50

# Límites configurados: MIN=5%, MAX=95%
```

### Nvidia no detectada

```bash
# Verificar GPU
lspci | grep -i nvidia

# Reinstalar drivers
sudo apt reinstall nvidia-driver
sudo update-initramfs -u
sudo reboot
```

### Scratchpad no aparece

```bash
# Verificar que kitty está instalado
which kitty

# Reiniciar i3
Mod+Shift+r
```

---

## 📦 Contenido del Repositorio

```
script-debian13-i3wm/
├── script-Debian13-i3wm.sh      # Script principal (1080 líneas)
├── script-Nvidia-offload.sh     # Script GPU (90 líneas)
├── picom.conf                   # Config compositor
├── README.md                    # Documentación usuario
├── INSTALACION.md               # Esta guía
└── LICENSE (MIT)
```

---

## 📊 Especificaciones Hardware

| Componente | Specs |
|-----------|-------|
| **CPU** | Intel Core i7-8565U (8 cores @ 4.60 GHz) |
| **GPU Intel** | UHD Graphics 620 |
| **GPU Nvidia** | GeForce MX130 (Offload only) |
| **RAM** | 15.5 GB + 7.75 GB ZRAM |
| **WiFi** | Qualcomm Atheros QCA9377 |
| **Audio** | PipeWire + Bluetooth |
| **Display** | HDMI (1920x1080) |

---

## ✨ Características Post-Instalación

✅ **i3wm optimizado** con scratchpad terminal flotante
✅ **Workspace cycling** (Mod+Tab)
✅ **Multi-monitor support** (Mod+Ctrl+Arrows)
✅ **Resize directo** (Mod+Alt+Arrows)
✅ **Gaming ready** con Nvidia offload
✅ **Power efficient** (Intel GPU por defecto)
✅ **Bluetooth completo** (audio + tethering)
✅ **WiFi estable** (multi-layer optimizaciones)
✅ **Audio excelente** (PipeWire low-latency)
✅ **Sistema limpio** (71 paquetes sin bloatware)

---

## 🚀 Comandos Útiles Post-Instalación

```bash
# Control de brillo
light -G                  # Ver brillo
light -S 50              # Establecer a 50%
/usr/local/bin/i3-brightness up    # +10%
/usr/local/bin/i3-brightness down  # -10%

# Diagnóstico WiFi
sudo wifi-fix            # Diagnóstico + reparación automática

# Verificar sistema
neofetch                 # Info del sistema
sensors                  # Temperatura (después de sensors-detect)

# Control de Nvidia
nvidia-smi              # GPU info
nv glxinfo | grep -i nvidia    # Offload verification
```

---

## 📝 Notas Importantes

1. **REBOOT es obligatorio** después de cada script
2. **i3 requiere reinicio manual** (Mod+Shift+r) para cargar cambios
3. **Scratchpad terminal** aparece en workspace actual pero persiste en todos
4. **Offload Nvidia** NO instala drivers separados para X.org (solo offload)
5. **PipeWire** reemplaza PulseAudio completamente
6. **WiFi QCA9377** puede mostrar errores PCIe en dmesg (normal, optimizado)

---

## 🎮 Gaming Setup Completo

Después de ambos scripts:

```bash
# Instalar Steam
sudo apt install steam

# O Lutris para gaming avanzado
sudo apt install lutris

# Juegos en Steam/Lutris usarán Nvidia con "nv" prefix
```

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa logs: `dmesg | tail -50`
2. Diagnostica WiFi: `sudo wifi-fix`
3. Reinicia i3: `Mod+Shift+r`
4. Reinicia servicios: `sudo systemctl restart NetworkManager`
5. Full reboot: `sudo reboot`

---

**Versión:** 2.0 (Dec 2025)
**Compatibilidad:** Debian 13 (Trixie) + i3wm
**Hardware:** Dell Inspiron 5584
**Licencia:** MIT
