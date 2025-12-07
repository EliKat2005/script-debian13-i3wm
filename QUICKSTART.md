# ⚡ Quick Start Guide

## 🚀 En 5 Minutos

### Opción 1: Solo Debian 13 + i3wm (Recomendado para empezar)

```bash
# 1. Clonar repositorio
git clone https://github.com/EliKat2005/script-debian13-i3wm.git
cd script-debian13-i3wm

# 2. Hacer ejecutable
chmod +x script-Debian13-i3wm.sh

# 3. Instalar (requiere sudo)
sudo ./script-Debian13-i3wm.sh

# 4. Reboot obligatorio
sudo reboot

# ✅ Listo: Sistema completo + i3wm + WiFi optimizado
```

**Tiempo:** ~20-30 minutos

---

### Opción 2: Debian 13 + i3wm + Gaming NVIDIA

```bash
# Pasos 1-4 de Opción 1 (ver arriba)

# 5. Después del reboot, instalar GPU
sudo ./script-Nvidia-offload.sh

# 6. Reboot nuevamente
sudo reboot

# ✅ Listo: Sistema gaming ready con Nvidia offload
```

**Tiempo adicional:** ~5-10 minutos

---

## 🎮 Primeros Pasos en i3wm

### Abrecaras en i3
| Atajo | Acción |
|-------|--------|
| `Mod+Return` | Terminal |
| `Mod+Space` | Lanzador (aplicaciones) |
| `Mod+Shift+Q` | Cerrar ventana |
| `Mod+Tab` | Siguiente workspace |
| `Mod+Shift+Tab` | Workspace anterior |
| `Mod+` ` (grave) | Terminal flotante |

### Workspaces
```
1:web    → Navegador
2:dev    → Código/IDE
3:work   → Documentos
4:chat   → Discord/Telegram
5:media  → Videos/gaming
6:misc   → Otras cosas
```

---

## ✅ Verificaciones Post-Instalación

### Script Base (siempre)
```bash
# WiFi
nmcli device wifi list

# i3wm
i3 --version

# GPU Intel
glxinfo | grep -i renderer
```

### Con Script Nvidia (si instalaste)
```bash
# GPU Nvidia
nvidia-smi

# Offload test
nv glxinfo | grep -i renderer

# Steam con GPU
nv steam
```

---

## 🔧 Problemas Rápidos

| Problema | Solución |
|----------|----------|
| WiFi no funciona | `sudo wifi-fix` |
| Brillo bajo | `light -S 75` |
| i3 no responde | `Mod+Shift+r` |
| Sin audio | Reinicia: `sudo reboot` |
| Nvidia no detecta | `lspci \| grep -i nvidia` |

---

## 📚 Documentación Completa

- **[README.md](README.md)** - Descripción general
- **[INSTALACION.md](INSTALACION.md)** - Guía completa paso a paso
- **[COMPATIBILIDAD.md](COMPATIBILIDAD.md)** - Detalles técnicos
- **[INDICE.md](INDICE.md)** - Índice completo de archivos

---

## 🎯 Siguientes Pasos

✅ **Después de instalar:**
1. Cambia el wallpaper (copia a `~/Wallpapers/default.jpg`)
2. Personaliza i3 (edita `~/.config/i3/config`)
3. Instala más aplicaciones: `sudo apt install <paquete>`
4. Explora los atajos de teclado

✅ **Si quieres gaming:**
1. Instala Steam: `sudo apt install steam`
2. En cada juego: Click derecho → Propiedades → `nv %command%`
3. ¡Juega! 🎮

✅ **Para más info:**
1. Lee la [INSTALACION.md](INSTALACION.md) completa
2. Inspecciona `~/.config/i3/config`
3. Customiza según necesites

---

## 🚀 Eso es todo!

Tu Debian 13 + i3wm está listo. Enjoy! 🎉

Para más detalles: [INDICE.md](INDICE.md)
