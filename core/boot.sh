#!/system/bin/sh
MODDIR=${0%/*}

submenu_boot() {
    clear
    echo -e "\033[1;36m=== AUTO-BOOT ===\033[0m\n"

    if [ -f "$MODDIR/enable_on_boot" ]; then
        echo -e "Status: \033[1;32mATIVADO\033[0m\n"
    else
        echo -e "Status: \033[1;31mDESATIVADO\033[0m\n"
    fi

    echo "1) Ativar no boot"
    echo "2) Desativar"
    echo "3) Ativar + aplicar agora"
    echo "0) Voltar"

    read -p "> " b

    case "$b" in
        1)
            touch "$MODDIR/enable_on_boot"
            echo "✔ Auto-boot ativado"
            read -p "ENTER..." ;;
        2)
            rm -f "$MODDIR/enable_on_boot"
            echo "✔ Desativado"
            read -p "ENTER..." ;;
        3)
            touch "$MODDIR/enable_on_boot"
            sh "$0" --ativar-todos
            echo "✔ Aplicado e ativado"
            read -p "ENTER..." ;;
        0) return ;;
    esac
}
