# Script de Instalación Debian 13 + i3wm

Script automatizado para transformar una instalación base de Debian 13 en un sistema completo con i3 window manager, optimizado para **Dell Inspiron 5584**.

> � **Documentación en README.md** - Todo lo que necesitas saber

## 🖥️ Hardware Soportado

**Optimizado específicamente para:**
- **Laptop:** Dell Inspiron 5584
- **CPU:** Intel Core i7-8565U (8ª generación)
- **GPU:** Intel UHD Graphics 620
- **WiFi:** Qualcomm Atheros QCA9377 (módulo ath10k_pci)
- **RAM:** 16 GB (con ZRAM configurado al 50%)
- **Pantalla:** 15.6" 1920x1080

## ✨ Características Principales

- ✅ **Sistema:** Debian 13 (Trixie) con repositorios non-free (formato DEB822)
- ✅ **Entorno:** i3wm + Picom + Dunst + Rofi
- ✅ **Audio:** PipeWire con soporte Bluetooth completo
- ✅ **WiFi:** Optimizaciones específicas para QCA9377 (ASPM deshabilitado)
- ✅ **GPU:** Intel UHD 620 con TearFree
- ✅ **Temas:** Arc-Dark + Papirus-Dark + Noto Sans
- ✅ **Brillo:** Control automático con límites 5%-95%
- ✅ **RAM:** ZRAM al 50% (swap comprimido LZ4)
- ✅ **71 paquetes:** Sistema minimalista sin bloatware

### Aplicaciones Incluidas (71 paquetes)
- **Terminal:** Kitty
- **Navegador:** Chromium
- **Reproductor multimedia:** MPV
- **Visor PDF:** Zathura
- **Visor de imágenes:** Ristretto
- **Gestor de archivos:** PCManFM
- **Capturas de pantalla:** Flameshot
- **Calculadora:** Galculator
- **Particiones:** GParted
- **Backups:** Timeshift

### Scripts Útiles
- `/usr/local/bin/i3-brightness` - Control de brillo con límites (5%-95%)
- `/usr/local/bin/wifi-fix` - Diagnóstico y reparación WiFi QCA9377
- **Gestor archivos:** PCManFM, Ranger (TUI)
- **Multimedia:** MPV, Feh
- **PDF:** Zathura
- **Utilidades:** btop, fastfetch, flameshot, galculator
- **Sistema:** GParted, Blueman, LXAppearance, Timeshift

## 📋 Requisitos Previos

1. Instalación base de Debian 13 (netinstall recomendado)
2. Conexión a Internet funcionando
3. Acceso como usuario con privilegios sudo

## 🚀 Instalación

### 1. Descargar el script

```bash
git clone https://github.com/EliKat2005/script-debian13-i3wm.git
cd script-debian13-i3wm
```

### 2. Hacer el script ejecutable

```bash
chmod +x script-Debian13-i3wm.sh
```

### 3. Ejecutar con sudo

```bash
sudo ./script-Debian13-i3wm.sh
```

### 4. Reiniciar el sistema

```bash
sudo reboot
```

## 🎮 Instalación Opcional: GPU NVIDIA

Si tu laptop tiene GPU NVIDIA (como MX130 en el Inspiron 5584) y deseas jugar o renderizar con ella:

```bash
# Después de completar los 4 pasos anteriores y reiniciar:
sudo ./script-Nvidia-offload.sh
sudo reboot
```

**Características:**
- ✅ Instalación automática de drivers
- ✅ Librerías 32-bit para Steam/Wine
- ✅ Rendering offload (Intel por defecto, Nvidia bajo demanda)
- ✅ Control automático de energía (D3 power management)
- ✅ Compatible 100% con esta instalación

**Verificación post-instalación:**
```bash
nvidia-smi                              # Ver GPU instalada
nv glxinfo | grep NVIDIA               # Verificar offload rendering
__NV_PRIME_RENDER_OFFLOAD=1 glxinfo   # Confirmar Nvidia activa
```

**Uso en Steam:**
1. Abre Steam
2. Click derecho en juego → Propiedades
3. Parámetros de lanzamiento: `nv %command%`

## 🔧 Resolución de Problemas

### WiFi no detecta redes o aparece apagado

```bash
# Ejecutar script de diagnóstico y reparación
sudo wifi-fix
```

El script verificará módulos, rfkill, NetworkManager y reiniciará automáticamente el módulo ath10k_pci.

**Nota:** Los errores PCIe (BadDLLP, Timeout) son comunes en QCA9377 pero no afectan la funcionalidad. El script ya incluye optimizaciones ASPM.

### Monitorear temperaturas

```bash
# Primera vez: detectar sensores
sudo sensors-detect  # Responde 'YES' a todo

# Ver temperaturas
sensors
```

### Cambiar wallpaper

```bash
# Opción 1: Reemplazar el wallpaper por defecto
cp /ruta/a/tu/imagen.jpg ~/Wallpapers/default.jpg
# Recargar i3: Mod+Shift+R

# Opción 2: Editar configuración de i3
nano ~/.config/i3/config
# Busca la línea "feh --bg-fill" y cambia la ruta
```

### Control manual de brillo

```bash
# Ver brillo actual (%)
light -G

# Establecer brillo específico
light -S 50

# Aumentar/disminuir
light -A 10  # Aumentar 10%
light -U 10  # Disminuir 10%
```

## ⌨️ Atajos de Teclado Principales

### Gestión de Ventanas
- `Mod+Return` - Abrir terminal (Kitty)
- `Mod+Shift+Return` - Terminal con GPU NVIDIA
- `Mod+Space` - Lanzador de aplicaciones (Rofi)
- `Mod+Shift+Q` - Cerrar ventana
- `Mod+Shift+Space` - Ventana flotante

### Navegación
- `Mod+1-6` - Cambiar a workspace 1-6
- `Mod+Shift+1-6` - Mover ventana a workspace
- `Mod+Flechas` - Cambiar foco entre ventanas

### Aplicaciones
- `Mod+W` - Chromium
- `Mod+Shift+W` - Chromium con GPU NVIDIA
- `Mod+F` - PCManFM (gestor archivos)
- `Mod+G` - Ranger (gestor archivos terminal)
- `Mod+Shift+T` - btop (monitor sistema)
- `Print` - Captura de pantalla (Flameshot)

### Multimedia
- `XF86AudioRaiseVolume/LowerVolume` - Volumen
- `XF86AudioMute` - Silenciar
- `XF86MonBrightnessUp/Down` - Brillo (límites 5%-95%)
- `XF86AudioPlay` - Play/Pause

### Sistema
- `Mod+Shift+N` - Configurar red
- `Mod+Shift+B` - Configurar Bluetooth
- `Mod+P` - Configurar pantallas (arandr)
- `Mod+Shift+C` - Recargar configuración i3
- `Mod+Shift+R` - Reiniciar i3
- `Mod+Shift+E` - Salir de i3

### Modo Redimensionar
- `Mod+R` - Activar modo resize
- `Flechas` - Agrandar bordes
- `Shift+Flechas` - Encoger bordes
- `Escape` - Salir del modo

**Nota:** `Mod` = Tecla Windows/Super

## 📁 Scripts Útiles Instalados

- `/usr/local/bin/i3-brightness` - Control de brillo con límites (5%-95%)
- `/usr/local/bin/wifi-fix` - Diagnóstico y reparación WiFi
- `/usr/local/bin/gpu-switch` - Cambiar entre GPUs Intel/NVIDIA
- `/usr/local/bin/prime-run` - Ejecutar aplicaciones con GPU NVIDIA

## 🎨 Temas y Apariencia

- **GTK Theme:** Yaru-blue-dark
- **Icons:** Papirus-Dark
- **Font:** Noto Sans 10pt
- **i3 Bar:** Superior con información del sistema

### Barra de Estado (i3status)

Muestra:
- 🕒 Fecha y hora
- 💻 Uso de CPU
- 🚀 Memoria RAM
- 🌡️ Temperatura CPU
- 📂 Espacio en disco (/ y /home)
- 📶 WiFi (ESSID, calidad, IP)
- 🌐 Ethernet (cuando conectado)
- 🔊 Volumen
- 🔋 Batería (estado, porcentaje, tiempo restante)

## 🔋 Optimización de Batería

El script configura automáticamente:
- GPU Intel por defecto (menor consumo)
- Power management para WiFi, USB y dispositivos PCI
- NVIDIA solo bajo demanda con `prime-run`
- ZRAM para reducir swap en disco

**Duración estimada de batería:**
- Uso ligero (navegación, terminal): ~5-6 horas
- Uso medio (multimedia, desarrollo): ~3-4 horas
- Uso intenso (GPU NVIDIA activa): ~2-3 horas

## 🛠️ Personalización

### Modificar configuración de i3

```bash
nano ~/.config/i3/config
# Recargar: Mod+Shift+C
```

### Modificar barra de estado

```bash
nano ~/.config/i3/i3status.conf
# Recargar: Mod+Shift+R
```

### Cambiar fondo de pantalla

```bash
# Editar en ~/.config/i3/config la línea:
exec_always --no-startup-id feh --bg-fill /ruta/a/tu/imagen.jpg
```

### Cambiar tema GTK

```bash
lxappearance
```

## 📝 Archivos de Configuración

- `~/.config/i3/config` - Configuración i3wm
- `~/.config/i3/i3status.conf` - Barra de estado
- `~/.config/picom/picom.conf` - Compositor
- `~/.config/gtk-3.0/settings.ini` - Tema GTK
- `/etc/X11/xorg.conf.d/` - Configuración Xorg
- `/etc/NetworkManager/conf.d/` - Configuración red

## ⚠️ Notas Importantes

1. **Primera ejecución:** El script debe ejecutarse con `sudo`
2. **Reinicio necesario:** Después de la instalación, reinicia para aplicar todos los cambios
3. **Grupos de usuario:** Se añaden automáticamente: video, render, input, netdev, bluetooth
4. **WiFi Atheros:** Si no funciona inmediatamente, ejecuta `sudo wifi-fix` después del reinicio
5. **Sensores de temperatura:** Ejecuta `sudo sensors-detect` una vez para habilitar monitoreo

## 🐛 Problemas Conocidos y Soluciones

### WiFi no funciona después de suspender

```bash
sudo systemctl restart NetworkManager
# o
sudo wifi-fix
```

### Brillo no cambia con teclas Fn

```bash
# Verificar grupos del usuario
groups

# Debe incluir 'video'. Si no, ejecuta:
sudo usermod -aG video $USER
# Reloguear
```

### NVIDIA no funciona con prime-run

```bash
# Verificar instalación NVIDIA
nvidia-smi

# Verificar configuración PRIME
prime-select query

# Si falla, reinstalar drivers
sudo apt install --reinstall nvidia-driver nvidia-prime
```

## 📜 Licencia

MIT License - Uso personal y modificación libre

## 👤 Autor

**EliKat2005**
- GitHub: [@EliKat2005](https://github.com/EliKat2005)

## 🤝 Contribuciones

Este es un script de configuración personal, pero si encuentras mejoras o correcciones, siéntete libre de abrir un issue o pull request.

---

**Creado con ❤️ para Debian 13 + i3wm**
