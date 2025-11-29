#!/system/bin/sh
MODDIR=${0%/*}

# Delay para garantir que todos os drivers foram carregados
sleep 4

# Reaplica spoof e props persistentes
if [ -f "$MODDIR/system.prop" ]; then
    resetprop -F -n "$MODDIR/system.prop"
fi

# Se o touchscreen foi desativado pelo painel
if getprop persist.fera.touch.disabled | grep -q "1"; then
    for dev in /dev/input/event*; do
        name=$(getevent -lp "$dev" 2>/dev/null | grep -i "touch" | head -n 1)
        if [ -n "$name" ]; then
            chmod 000 "$dev"
        fi
    done
fi

exit 0
