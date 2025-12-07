#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# INSTALL NVIDIA DRIVERS (Offload + Power Save + 32-bit Gaming Support)
# Hardware: Optimus (Intel + Nvidia MX130)
# OS: Debian 13 (Stable)
# -----------------------------------------------------------------------------

log(){ echo -e "\n[+] $1"; }

if [[ $EUID -ne 0 ]]; then
   echo "Este script requiere privilegios de root. Ejecuta: sudo $0"
   exit 1
fi

log "1. Configurando repositorios y Arquitectura de 32 bits (Gaming)"
# Habilitar multiarch (Vital para Steam y Wine)
dpkg --add-architecture i386
log "✓ Arquitectura i386 habilitada"

# Configuración de repositorios non-free (igual que antes)
if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
  if ! grep -q "contrib non-free" /etc/apt/sources.list.d/debian.sources; then
    sed -i.bak 's/Components: main non-free-firmware/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
  fi
elif [[ -f /etc/apt/sources.list ]]; then
  if ! grep -q "contrib non-free" /etc/apt/sources.list; then
    sed -i.bak 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
  fi
fi

log "2. Actualizando paquetes e instalando dependencias"
apt update
apt -y install "linux-headers-$(uname -r)" nvidia-detect firmware-misc-nonfree pkg-config libglvnd-dev

log "3. Detectando driver correcto para MX130"
DRIVER_PKG=$(nvidia-detect | grep -o "nvidia-[a-z0-9-]*driver" | head -n 1)

if [[ -z "$DRIVER_PKG" ]]; then
  log "⚠ No se detectó recomendación. Usando 'nvidia-driver' estándar."
  DRIVER_PKG="nvidia-driver"
else
  log "✓ Driver detectado: $DRIVER_PKG"
fi

# Calculamos el nombre del paquete de librerías de 32 bits basado en el driver detectado
# Ej: si driver es 'nvidia-legacy-470xx-driver', las libs son 'nvidia-legacy-470xx-driver-libs:i386'
LIB_32_PKG="${DRIVER_PKG}-libs:i386"

log "4. Instalando Driver + Librerías de 32 bits (Vulkan/OpenGL)"
log "   Paquetes: $DRIVER_PKG y $LIB_32_PKG"
# Instalamos también nvidia-vulkan-icd para asegurar soporte Vulkan
apt -y install "$DRIVER_PKG" "$LIB_32_PKG" nvidia-smi nvidia-vulkan-icd

log "5. Configurando Ahorro de Energía (Runtime D3 - Apagado de GPU)"
mkdir -p /etc/modprobe.d
tee /etc/modprobe.d/nvidia-power.conf > /dev/null <<'EOF'
options nvidia "NVreg_DynamicPowerManagement=0x02"
EOF

log "6. Bloqueando Nouveau"
tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

log "7. Creando wrapper 'nv' global"
cat <<'EOF' > /usr/local/bin/nv
#!/bin/bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
exec "$@"
EOF
chmod +x /usr/local/bin/nv

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "INSTALACIÓN GAMING READY COMPLETADA"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "1. REINICIA el sistema."
log "2. En STEAM, para usar la Nvidia en un juego:"
log "   Click derecho en el juego -> Propiedades -> Parámetros de lanzamiento:"
log "   nv %command%"
log ""
log "3. En LUTRIS / HEROIC:"
log "   Activa 'Enable Prime Render Offload' o usa el script 'nv' como wrapper."
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0