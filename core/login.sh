#!/system/bin/sh

MODDIR=${0%/*}
SERVER="https://painel-licenca-server.onrender.com"
LICENSE_FILE="$MODDIR/license_info"
RESET_SCRIPT="$MODDIR/reset_auto.sh"

gera_fingerprint() {
    ANDROID_ID=$(settings get secure android_id 2>/dev/null || echo "")
    SERIAL=$(getprop ro.serialno 2>/dev/null || echo "")
    MODEL=$(getprop ro.product.model 2>/dev/null || echo "")
    FP_RAW="${ANDROID_ID}-${SERIAL}-${MODEL}"

    if command -v md5sum >/dev/null 2>&1; then
        echo -n "$FP_RAW" | md5sum | awk '{print $1}'
    else
        echo -n "$FP_RAW" | tr -d ' ' | tr -d '\n'
    fi
}

reset_total_auto() {
    echo "⚠ RESET AUTOMÁTICO — LICENÇA EXPIRADA" > /dev/kmsg

    cat > "$RESET_SCRIPT" <<'EOF'
#!/system/bin/sh
settings delete secure tap_duration_threshold
settings delete secure long_press_timeout
settings delete secure multi_press_timeout
settings delete secure accessibility_auto_action_delay
settings delete global block_untrusted_touches
settings delete global restricted_device_performance
settings delete system peak_refresh_rate
settings delete system min_refresh_rate
settings delete global display_dual_output
settings delete global gamepad.latency_reduction
setprop vendor.usb.raw_input.enable 0
setprop persist.usb.low_latency_mode 0
setprop vendor.usb.hid.priority 0
setprop persist.vendor.usb.high_speed 0
setprop persist.vendor.usb.power 0
setprop vendor.usb.hub.boost 0
setprop vendor.usb.mouse.jitter_filter 0
setprop persist.sys.mouse.linear_response 0
setprop persist.sys.pointer.acceleration 1
setprop persist.input.pointer_jitter_smoothing 0
setprop persist.sys.input.low_latency_mode 0
setprop persist.sys.input.high_update_rate false
setprop persist.sys.input.boost 0
setprop debug.hwui.disable_vsync false
setprop persist.sys.gpu.low_latency 0
setprop persist.sys.gpu.frame_boost 0
setprop persist.sys.display.force_refresh 60
setprop vendor.display.external_priority 0
setprop persist.video.duplicate.display 0
rm -f "$MODDIR/license_info"
reboot
EOF

    chmod 755 "$RESET_SCRIPT"
    sh "$RESET_SCRIPT"
    exit 1
}

verifica_expiracao() {
    if [ ! -f "$LICENSE_FILE" ]; then return 0; fi
    EXP=$(cat "$LICENSE_FILE")
    NOW=$(date +%s)
    if [ "$NOW" -ge "$EXP" ]; then reset_total_auto; fi
}

verifica_expiracao

ativar_servidor() {
    USER="$1"
    PASS="$2"
    FP=$(gera_fingerprint)

    JSON="{\"username\":\"$USER\",\"password\":\"$PASS\",\"fingerprint\":\"$FP\"}"

    RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")

    if echo "$RESP" | grep -q '"status":"error"' || echo "$RESP" | grep -q '"error"'; then
        REASON=$(echo "$RESP" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
        echo -e "\033[1;31m❌ Erro: ${REASON:-Credenciais inválidas}\033[0m"
        return 1
    fi

    echo -e "\033[1;32m✔ Login aprovado!\033[0m"

    EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
    [ ! -z "$EXP" ] && echo "$EXP" > "$MODDIR/license_info"

    return 0
}

loading_bar() {
    clear
    echo -e "\n\033[1;36mCarregando Painel FERA ALPHA...\033[0m\n"
    bar=""
    max=18
    i=1
    while [ $i -le $max ]; do
        bar="${bar}█"
        pct=$(( i * 100 / max ))
        printf "\r\033[1;32m[%-18s] %d%%\033[0m" "$bar" "$pct"
        sleep 0.001
        i=$((i+1))
    done
    sleep 0.1
    clear
}

print_header() {
    clear
    cols=$(stty size | awk '{print $2}')

    t1="FERA ALPHA"
    t2="LOGIN"
    line=$(printf "%${#t1}s" | tr " " "=")

    type_anim() {
        str="$1"
        len=$(echo -n "$str" | wc -c)
        i=1
        while [ $i -le $len ]; do
            ch=$(echo -n "$str" | cut -c $i)
            printf "%s" "$ch"
            sleep 0.01
            i=$((i+1))
        done
        echo ""
    }

    total_len=$(( ${#line} + 2 + ${#t1} + 2 + ${#line} ))
    pad=$(( (cols - total_len) / 2 ))

    printf "%${pad}s"
    type_anim "\033[1;34m$line  $t1  $line\033[0m"

    printf "%$(( (cols - ${#t2}) / 2 ))s"
    type_anim "\033[1;37m$t2\033[0m"
    echo ""
}

input_login() {
    echo -e "\033[1;34m┌─ Usuário\033[0m"
    echo -n "└─> "
    read USER
    echo -e "\033[1;34m┌─ Senha\033[0m"
    echo -n "└─> "
    stty -echo
    read PASS
    stty echo
    echo ""
}

erro_login() {
    echo -e "\033[1;31m"
    echo "╔══════════════════════════════╗"
    echo "║        ❌ ACESSO NEGADO       ║"
    echo "╚══════════════════════════════╝"
    echo -e "\033[0m"
}

bem_vindo() {
    clear
    echo -e "\033[1;32m✔ Login autorizado!\033[0m"
    sleep 0.5
    clear
}
