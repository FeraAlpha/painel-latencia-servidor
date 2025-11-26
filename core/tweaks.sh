#!/system/bin/sh
MODDIR=${0%/*}

# ====== Cores ANSI ======
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"
BOLD="\033[1m"

ICON_ON="🟢"
ICON_OFF="🔴"
ARROW="➤"

# Paths
SPOOF_FLAG="$MODDIR/spoof_enabled"
SPOOF_FILE="$MODDIR/system.prop"
ORIG_STORE="$MODDIR/original.props"
FLAG_DIR="$MODDIR/disabled_flags"
mkdir -p "$FLAG_DIR" >/dev/null 2>&1

# =====================================================
# REBUILD SYSTEM.PROP (responsável por aplicar props)
# =====================================================
rebuild_system_prop() {
    rm -f "$SPOOF_FILE"

    # Se spoof estiver ativo → adiciona spoof Realme 15 Pro
    if [ -f "$SPOOF_FLAG" ]; then
cat >> "$SPOOF_FILE" <<EOF

# SPOOF REALME 15 PRO
ro.product.model=RMX5101
ro.product.brand=realme
ro.product.name=realme15pro
ro.product.device=RMX5101
ro.product.manufacturer=realme

EOF
    fi

    echo "# TWEAKS ATIVOS" >> "$SPOOF_FILE"

    TWEAK_LIST=(
        "vendor.usb.raw_input.enable=1"
        "persist.usb.low_latency_mode=1"
        "vendor.usb.hid.priority=2"
        "persist.vendor.usb.high_speed=1"
        "persist.vendor.usb.power=1"
        "vendor.usb.hub.boost=1"
        "vendor.usb.mouse.jitter_filter=1"
        "persist.sys.mouse.linear_response=1"
        "persist.sys.pointer.acceleration=0"
        "persist.input.pointer_jitter_smoothing=1"
        "persist.sys.input.low_latency_mode=1"
        "persist.sys.input.high_update_rate=true"
        "persist.sys.input.boost=1"
        "debug.hwui.disable_vsync=true"
        "persist.sys.gpu.low_latency=1"
        "persist.sys.gpu.frame_boost=1"
        "persist.sys.display.force_refresh=120"
        "persist.video.duplicate.display=1"
        "vendor.display.external_priority=1"
        "persist.sys.hid.busy_polling=1"
        "persist.vendor.hid.ultra_polling=1"
        "vendor.hid.input.fastpath=1"
        "persist.sys.input.filter=0"
        "persist.sys.touchpad.smooth=0"
        "persist.sys.input.resample=0"
        "persist.sys.input.dejitter=0"
        "vendor.usb.performance_mode=1"
        "persist.vendor.usb.low_latency_interrupts=1"
        "vendor.usb.max_bus_bandwidth=1"
        "persist.sys.input.dispatch_fast=1"
        "persist.sys.input.dispatch_immediate=1"
    )

    for prop in "${TWEAK_LIST[@]}"; do
        KEY=$(echo "$prop" | cut -d= -f1)
        VAL=$(echo "$prop" | cut -d= -f2)
        FLAG="$FLAG_DIR/$KEY"

        # Só ativa se a flag NÃO existir
        if [ ! -f "$FLAG" ]; then
            echo "$KEY=$VAL" >> "$SPOOF_FILE"
            setprop "$KEY" "$VAL" >/dev/null 2>&1
        fi
    done

    chmod 644 "$SPOOF_FILE"
}

# =====================================================
# Funções utilitárias
# =====================================================
read_prompt() { printf "%s" "$1"; read -r "$2"; }
press_enter() { printf "\nPressione ENTER para continuar..."; read -r _; }

check_setting() { val=$(settings get "$1" "$2"); [ "$val" = "$3" ]; }
check_prop() { val=$(getprop "$1"); [ "$val" = "$2" ]; }
icon() { if "$@"; then printf "$GREEN$ICON_ON$RESET"; else printf "$RED$ICON_OFF$RESET"; fi; }

# =====================================================
# Ativar / Desativar Tweaks
# =====================================================
ativar_tweak() {
    nome="$1"; cmd="$2"
    rm -f "$FLAG_DIR/$nome"

    if echo "$cmd" | grep -q settings; then eval "$cmd"; fi
    if echo "$cmd" | grep -q setprop;  then rebuild_system_prop; fi

    echo -e "${GREEN}✔ $nome ativado${RESET}"
}

desativar_tweak() {
    nome="$1"; cmd="$2"
    touch "$FLAG_DIR/$nome"

    if echo "$cmd" | grep -q settings; then eval "$cmd"; fi
    if echo "$cmd" | grep -q setprop;  then rebuild_system_prop; fi

    echo -e "${RED}✔ $nome desativado${RESET}"
}

# =====================================================
# SUBMENU GENÉRICO
# =====================================================
submenu_tela() {
    nome="$1"; desc="$2"; on="$3"; off="$4"

    clear
    echo -e "${CYAN}${BOLD=== $nome ===${RESET}"
    echo -e "$YELLOW$desc$RESET\n"
    echo "1) Ativar"
    echo "2) Desativar"
    echo "0) Voltar"
    read_prompt "> " op

    case "$op" in
        1) ativar_tweak "$nome" "$on" ;;
        2) desativar_tweak "$nome" "$off" ;;
        0) return ;;
    esac

    press_enter
}
