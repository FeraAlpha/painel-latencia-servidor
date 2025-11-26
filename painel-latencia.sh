#!/system/bin/sh
MODDIR=${0%/*}

# Carregar módulos
source "$MODDIR/core/update.sh"
source "$MODDIR/core/login.sh"
source "$MODDIR/core/tweaks.sh"
source "$MODDIR/core/spoof.sh"
source "$MODDIR/core/menu.sh"
source "$MODDIR/core/boot.sh"

# Verificar atualização automática
check_update

# Iniciar login → painel
login_flow
