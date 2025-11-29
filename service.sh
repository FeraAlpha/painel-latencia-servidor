#!/system/bin/sh
MODDIR=${0%/*}
SPOOF_FILE="$MODDIR/system.prop"

sleep 3

# ==============================
# 1. Aplicar as props salvas no system.prop
# ==============================
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

# ==============================
# 2. Restaurar estado do touchscreen
# ==============================
if getprop persist.fera.touch.disabled | grep -q "1"; then
    # DESATIVAR touchscreen
    for dev in /dev/input/event*; do
        if getevent -lp "$dev" 2>/dev/null | grep -qi "touch"; then
            chmod 000 "$dev" 2>/dev/null
        fi
    done
else
    # ATIVAR touchscreen
    for dev in /dev/input/event*; do
        if getevent -lp "$dev" 2>/dev/null | grep -qi "touch"; then
            chmod 660 "$dev" 2>/dev/null
        fi
    done
fi

exit 0
