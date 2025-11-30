#!/system/bin/sh
MODDIR=${0%/*}
SPOOF_FILE="$MODDIR/system.prop"
TOUCH_LIST="$MODDIR/touch_disabled_list"
PROP="persist.fera.touch.disabled"

sleep 3

# =====================================================
# 1. Aplicar todas as props salvas no system.prop
# =====================================================
if [ -f "$SPOOF_FILE" ]; then
    while IFS= read -r line; do
        clean=$(echo "$line" | sed 's/[[:space:]]//g')
        [ -z "$clean" ] && continue
        echo "$clean" | grep -q "^#" && continue
        echo "$clean" | grep -q "=" || continue

        key=$(echo "$clean" | cut -d= -f1)
        value=$(echo "$clean" | cut -d= -f2-)
        [ -n "$key" ] && [ -n "$value" ] && setprop "$key" "$value"
    done < "$SPOOF_FILE"
fi

# =====================================================
# 2. Funções para gerenciar touchscreen
# =====================================================

touchscreen_disable() {
    rm -f "$TOUCH_LIST"
    touch "$TOUCH_LIST"

    for dev in /dev/input/event*; do
        if getevent -lp "$dev" 2>/dev/null | grep -qi "touch"; then
            chmod 000 "$dev" 2>/dev/null
            echo "$dev" >> "$TOUCH_LIST"
        fi
    done

    setprop $PROP 1
}

touchscreen_enable() {
    if [ -f "$TOUCH_LIST" ]; then
        while read -r dev; do
            [ -e "$dev" ] && chmod 660 "$dev" 2>/dev/null
        done < "$TOUCH_LIST"
        rm -f "$TOUCH_LIST"
    else
        # fallback: tenta restaurar todos os event* que sejam touchscreen
        for dev in /dev/input/event*; do
            if getevent -lp "$dev" 2>/dev/null | grep -qi "touch"; then
                chmod 660 "$dev" 2>/dev/null
            fi
        done
    fi

    setprop $PROP 0
}

# =====================================================
# 3. Aplicar o estado atual da prop (no boot)
# =====================================================

cur=$(getprop $PROP)

if [ "$cur" = "1" ]; then
    touchscreen_disable
else
    touchscreen_enable
fi

exit 0
