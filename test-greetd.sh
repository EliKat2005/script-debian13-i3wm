#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  SCRIPT DE PRUEBA: Migrar de lightdm a greetd+tuigreet
#  Ejecutar con: sudo bash test-greetd.sh
# ─────────────────────────────────────────────────────────────────────────────

log() { echo -e "\n\033[1;32m[Test] $1\033[0m"; }
warn() { echo -e "\033[1;33m[AVISO] $1\033[0m"; }
error() { echo -e "\033[1;31m[ERROR] $1\033[0m" >&2; }

if [[ $EUID -ne 0 ]]; then
    error "Este script requiere sudo"
    echo "Ejecuta: sudo bash test-greetd.sh"
    exit 1
fi

log "═══════════════════════════════════════════════════════"
log " TEST: Migración lightdm → greetd+tuigreet"
log "═══════════════════════════════════════════════════════"

log "1. Instalando greetd y tuigreet..."
if apt -y install greetd tuigreet; then
    log "✓ Paquetes instalados"
else
    error "Fallo al instalar greetd/tuigreet"
    exit 1
fi

log "2. Deshabilitando lightdm..."
systemctl disable lightdm.service 2>/dev/null || true
log "✓ lightdm deshabilitado (no se detendrá hasta reiniciar)"

log "3. Configurando greetd..."
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml <<'GREETDCONF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --cmd i3"
user = "greeter"
GREETDCONF

log "✓ Archivo de configuración creado: /etc/greetd/config.toml"

log "4. Habilitando greetd..."
systemctl enable greetd.service
log "✓ greetd habilitado (activará en el próximo reinicio)"

log "5. Verificando configuración..."
echo ""
echo "Estado de servicios:"
echo "  lightdm: $(systemctl is-enabled lightdm.service 2>/dev/null || echo 'disabled')"
echo "  greetd:  $(systemctl is-enabled greetd.service 2>/dev/null || echo 'disabled')"
echo ""
cat /etc/greetd/config.toml

log "═══════════════════════════════════════════════════════"
log " ✅ MIGRACIÓN COMPLETADA"
log "═══════════════════════════════════════════════════════"
echo ""
echo "🔄 Para aplicar los cambios:"
echo "   1. Guarda tu trabajo"
echo "   2. Ejecuta: sudo reboot"
echo ""
echo "📋 Comportamiento esperado:"
echo "   • Login en modo texto (TUI) con tuigreet"
echo "   • Usuario/contraseña guardados (--remember)"
echo "   • Sesión i3 recordada (--remember-session)"
echo "   • Tiempo de inicio: <2 segundos"
echo ""
echo "🔙 Para revertir (si hay problemas):"
echo "   sudo systemctl disable greetd.service"
echo "   sudo systemctl enable lightdm.service"
echo "   sudo reboot"
echo ""
