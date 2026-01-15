#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  FIX URGENTE: Arreglar greetd que no inicia
# ─────────────────────────────────────────────────────────────────────────────

log() { echo -e "\n\033[1;32m[Fix] $1\033[0m"; }
error() { echo -e "\033[1;31m[ERROR] $1\033[0m" >&2; }

if [[ $EUID -ne 0 ]]; then
    error "Requiere sudo. Ejecuta: sudo bash fix-greetd-now.sh"
    exit 1
fi

log "Diagnosticando greetd..."

# Ver logs completos
log "Logs de greetd:"
journalctl -u greetd.service --no-pager -n 30

# Verificar usuario greeter
log "Verificando usuario greeter..."
if ! id greeter &>/dev/null; then
    log "Usuario greeter no existe, creándolo..."
    useradd -r -s /usr/sbin/nologin -d /var/lib/greetd greeter
    mkdir -p /var/lib/greetd
    chown greeter:greeter /var/lib/greetd
fi

# Resetear servicio
log "Reseteando contadores de fallo..."
systemctl reset-failed greetd.service

# Verificar permisos VT
log "Verificando permisos /dev/tty1..."
ls -la /dev/tty1

# Intentar iniciar manualmente
log "Intentando iniciar greetd..."
systemctl start greetd.service
sleep 2
systemctl status greetd.service --no-pager -l

log "Si aún falla, revirtiendo a lightdm temporalmente..."
if ! systemctl is-active --quiet greetd.service; then
    systemctl disable greetd.service
    apt -y install lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    systemctl start lightdm.service
    log "⚠️  Revertido a lightdm temporalmente. Reinicia el sistema."
fi
