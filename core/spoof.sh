#!/system/bin/sh
MODDIR=${0%/*}

SPOOF_FLAG="$MODDIR/spoof_enabled"
SPOOF_FILE="$MODDIR/system.prop"
ORIG_STORE="$MODDIR/original.props"

# Salvar props originais
save_original_props() {
    {
        echo "ro.product.model=$(getprop ro.product.model)"
        echo "ro.product.brand=$(getprop ro.product.brand)"
        echo "ro.product.name=$(getprop ro.product.name)"
        echo "ro.product.device=$(getprop ro.product.device)"
        echo "ro.product.manufacturer=$(getprop ro.product.manufacturer)"
    } > "$ORIG_STORE"
}

# Ativar spoof Realme 15 Pro
enable_spoof() {
    [ ! -f "$ORIG_STORE" ] && save_original_props
    touch "$SPOOF_FLAG"
    rebuild_system_prop

    echo -e "\033[1;32m✔ Spoof Realme 15 Pro ativado!\033[0m"
}

# Desativar
disable_spoof() {
    rm -f "$SPOOF_FLAG"
    rebuild_system_prop

    echo -e "\033[1;32m✔ Spoof desativado — valores voltarão após reboot.\033[0m"
}

spoof_status() {
    [ -f "$SPOOF_FLAG" ]
}

submenu_spoof() {
    while true; do
        clear
        echo -e "\033[1;36m=== SPOOF 120 FPS — Realme 15 Pro ===\033[0m"

        if spoof_status; then
            echo -e "\033[1;32mStatus: ATIVADO\033[0m\n"
            echo "1) Desativar spoof"
        else
            echo -e "\033[1;31mStatus: DESATIVADO\033[0m\n"
            echo "1) Ativar spoof"
        fi

        echo "0) Voltar"
        read -p "> " op

        case "$op" in
            1)
                if spoof_status; then disable_spoof; else enable_spoof; fi
                read -p "ENTER para continuar..." ;;
            0) return ;;
        esac
    done
}
