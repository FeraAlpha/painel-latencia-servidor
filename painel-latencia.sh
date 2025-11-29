###############################################################################
# ===================== INÍCIO DO PAINEL ==========================
###############################################################################

# Cores
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"
ICON_ON="🟢"
ICON_OFF="🔴"

# Paths
SPOOF_FLAG="$MODDIR/spoof_enabled"
SPOOF_FILE="$MODDIR/system.prop"
FLAG_DIR="$MODDIR/disabled_flags"
mkdir -p "$FLAG_DIR" 2>/dev/null

# Funções gerais
read_prompt() { printf "%s" "$1"; read -r "$2"; }
press_enter()  { printf "\nPressione ENTER..."; read -r _; }

# Toggle universal
toggle_tweak() {
    nome="$1"; on="$2"; off="$3"

    if echo "$on" | grep -q settings; then
        ns=$(echo "$on" | awk '{print $3}')
        key=$(echo "$on" | awk '{print $4}')
        val=$(echo "$on" | awk '{print $5}')
        cur=$(settings get "$ns" "$key")
        if [ "$cur" = "$val" ]; then
            eval "$off"
        else
            eval "$on"
        fi
        return
    fi

    if echo "$on" | grep -q setprop; then
        prop=$(echo "$on" | awk '{print $2}')
        val=$(echo "$on" | awk '{print $3}')
        cur=$(getprop "$prop")
        if [ "$cur" = "$val" ]; then
            eval "$off"
        else
            eval "$on"
        fi
        return
    fi

    eval "$on"
}

# Icones de status
icon_setting() {
    ns="$1"; key="$2"; expected="$3"
    cur=$(settings get "$ns" "$key")
    [ "$cur" = "$expected" ] && printf "$GREEN$ICON_ON$RESET" || printf "$RED$ICON_OFF$RESET"
}
icon_prop() {
    key="$1"; expected="$2"
    cur=$(getprop "$key")
    [ "$cur" = "$expected" ] && printf "$GREEN$ICON_ON$RESET" || printf "$RED$ICON_OFF$RESET"
}

###############################################################################
# ===================== COMANDOS DOS TWEAKS ==========================
###############################################################################

submenu_1_on="settings put secure tap_duration_threshold 70"
submenu_1_off="settings delete secure tap_duration_threshold"

submenu_2_on="settings put secure long_press_timeout 300"
submenu_2_off="settings delete secure long_press_timeout"

submenu_3_on="settings put secure multi_press_timeout 130"
submenu_3_off="settings delete secure multi_press_timeout"

submenu_4_on="settings put secure accessibility_auto_action_delay 200"
submenu_4_off="settings delete secure accessibility_auto_action_delay"

submenu_5_on="settings put global block_untrusted_touches 0"
submenu_5_off="settings delete global block_untrusted_touches"

submenu_6_on="settings put global restricted_device_performance '0,0'"
submenu_6_off="settings delete global restricted_device_performance"

submenu_7_on="setprop vendor.usb.raw_input.enable 1"
submenu_7_off="setprop vendor.usb.raw_input.enable 0"

submenu_8_on="setprop persist.usb.low_latency_mode 1"
submenu_8_off="setprop persist.usb.low_latency_mode 0"

submenu_9_on="setprop vendor.usb.hid.priority 2"
submenu_9_off="setprop vendor.usb.hid.priority 1"

submenu_10_on="setprop persist.vendor.usb.high_speed 1"
submenu_10_off="setprop persist.vendor.usb.high_speed 0"

submenu_11_on="setprop persist.vendor.usb.power 1"
submenu_11_off="setprop persist.vendor.usb.power 0"

submenu_12_on="setprop vendor.usb.hub.boost 1"
submenu_12_off="setprop vendor.usb.hub.boost 0"

submenu_13_on="setprop vendor.usb.mouse.jitter_filter 1"
submenu_13_off="setprop vendor.usb.mouse.jitter_filter 0"

submenu_14_on="setprop persist.sys.mouse.linear_response 1"
submenu_14_off="setprop persist.sys.mouse.linear_response 0"

submenu_15_on="setprop persist.sys.pointer.acceleration 0"
submenu_15_off="setprop persist.sys.pointer.acceleration 1"

submenu_16_on="setprop persist.input.pointer_jitter_smoothing 1"
submenu_16_off="setprop persist.input.pointer_jitter_smoothing 0"

submenu_17_on="setprop persist.sys.input.low_latency_mode 1"
submenu_17_off="setprop persist.sys.input.low_latency_mode 0"

submenu_18_on="setprop persist.sys.input.high_update_rate true"
submenu_18_off="setprop persist.sys.input.high_update_rate false"

submenu_19_on="setprop persist.sys.input.boost 1"
submenu_19_off="setprop persist.sys.input.boost 0"

submenu_20_on="setprop debug.hwui.disable_vsync true"
submenu_20_off="setprop debug.hwui.disable_vsync false"

submenu_21_on="setprop persist.sys.gpu.low_latency 1"
submenu_21_off="setprop persist.sys.gpu.low_latency 0"

submenu_22_on="setprop persist.sys.gpu.frame_boost 1"
submenu_22_off="setprop persist.sys.gpu.frame_boost 0"

submenu_23_on="settings put system peak_refresh_rate 120"
submenu_23_off="settings delete system peak_refresh_rate"

submenu_24_on="setprop persist.sys.display.force_refresh 120"
submenu_24_off="setprop persist.sys.display.force_refresh 60"

submenu_25_on="setprop persist.video.duplicate.display 1"
submenu_25_off="setprop persist.video.duplicate.display 0"

submenu_26_on="setprop vendor.display.external_priority 1"
submenu_26_off="setprop vendor.display.external_priority 0"

submenu_27_on="settings put global display_dual_output 1"
submenu_27_off="settings delete global display_dual_output"

submenu_28_on="settings put global gamepad.latency_reduction 1"
submenu_28_off="settings delete global gamepad.latency_reduction"

# NOVOS 29–40
submenu_29_on="setprop persist.sys.hid.busy_polling 1"
submenu_29_off="setprop persist.sys.hid.busy_polling 0"

submenu_30_on="setprop persist.vendor.hid.ultra_polling 1"
submenu_30_off="setprop persist.vendor.hid.ultra_polling 0"

submenu_31_on="setprop vendor.hid.input.fastpath 1"
submenu_31_off="setprop vendor.hid.input.fastpath 0"

submenu_32_on="setprop persist.sys.input.filter 0"
submenu_32_off="setprop persist.sys.input.filter 1"

submenu_33_on="setprop persist.sys.touchpad.smooth 0"
submenu_33_off="setprop persist.sys.touchpad.smooth 1"

submenu_34_on="setprop persist.sys.input.resample 0"
submenu_34_off="setprop persist.sys.input.resample 1"

submenu_35_on="setprop persist.sys.input.dejitter 0"
submenu_35_off="setprop persist.sys.input.dejitter 1"

submenu_36_on="setprop vendor.usb.performance_mode 1"
submenu_36_off="setprop vendor.usb.performance_mode 0"

submenu_37_on="setprop persist.vendor.usb.low_latency_interrupts 1"
submenu_37_off="setprop persist.vendor.usb.low_latency_interrupts 0"

submenu_38_on="setprop vendor.usb.max_bus_bandwidth 1"
submenu_38_off="setprop vendor.usb.max_bus_bandwidth 0"

submenu_39_on="setprop persist.sys.input.dispatch_fast 1"
submenu_39_off="setprop persist.sys.input.dispatch_fast 0"

submenu_40_on="setprop persist.sys.input.dispatch_immediate 1"
submenu_40_off="setprop persist.sys.input.dispatch_immediate 0"

###############################################################################
# ===================== MENU INDIVIDUAL (VERSÃO CURTA) =======================
###############################################################################

menu_individual() {
    while true; do
        clear
        echo "========== TWEAKS INDIVIDUAIS =========="
        echo

        printf " %b 1) Reduz atraso do toque\n" "$(icon_setting secure tap_duration_threshold 70)"
        printf " %b 2) Diminui duração do toque longo\n" "$(icon_setting secure long_press_timeout 300)"
        printf " %b 3) Aumenta resposta a cliques múltiplos\n" "$(icon_setting secure multi_press_timeout 130)"
        printf " %b 4) Deixa ações automáticas mais rápidas\n" "$(icon_setting secure accessibility_auto_action_delay 200)"
        printf " %b 5) Permitir toques no espelhamento\n" "$(icon_setting global block_untrusted_touches 0)"
        printf " %b 6) Remove limites de desempenho\n" "$(icon_setting global restricted_device_performance '0,0')"

        printf " %b 7) Entrada USB RAW\n" "$(icon_prop vendor.usb.raw_input.enable 1)"
        printf " %b 8) USB baixa latência\n" "$(icon_prop persist.usb.low_latency_mode 1)"
        printf " %b 9) Prioridade HID\n" "$(icon_prop vendor.usb.hid.priority 2)"
        printf " %b 10) USB High Speed\n" "$(icon_prop persist.vendor.usb.high_speed 1)"
        printf " %b 11) USB Power Boost\n" "$(icon_prop persist.vendor.usb.power 1)"
        printf " %b 12) Boost no hub USB\n" "$(icon_prop vendor.usb.hub.boost 1)"
        printf " %b 13) Anti-jitter USB\n" "$(icon_prop vendor.usb.mouse.jitter_filter 1)"

        printf " %b 14) Resposta linear do mouse\n" "$(icon_prop persist.sys.mouse.linear_response 1)"
        printf " %b 15) Aceleração do mouse OFF\n" "$(icon_prop persist.sys.pointer.acceleration 0)"
        printf " %b 16) Anti-jitter do ponteiro\n" "$(icon_prop persist.input.pointer_jitter_smoothing 1)"

        printf " %b 17) Input baixa latência\n" "$(icon_prop persist.sys.input.low_latency_mode 1)"
        printf " %b 18) Input alta taxa\n" "$(icon_prop persist.sys.input.high_update_rate true)"
        printf " %b 19) Input Boost\n" "$(icon_prop persist.sys.input.boost 1)"

        printf " %b 20) VSync OFF\n" "$(icon_prop debug.hwui.disable_vsync true)"
        printf " %b 21) GPU baixa latência\n" "$(icon_prop persist.sys.gpu.low_latency 1)"
        printf " %b 22) GPU frame boost\n" "$(icon_prop persist.sys.gpu.frame_boost 1)"

        printf " %b 23) Tela interna 120Hz\n" "$(icon_setting system peak_refresh_rate 120)"
        printf " %b 24) Forçar 120Hz\n" "$(icon_prop persist.sys.display.force_refresh 120)"
        printf " %b 25) Duplicação externa\n" "$(icon_prop persist.video.duplicate.display 1)"
        printf " %b 26) Prioridade externa\n" "$(icon_prop vendor.display.external_priority 1)"
        printf " %b 27) Saída dupla de vídeo\n" "$(icon_setting global display_dual_output 1)"

        printf " %b 28) Gamepad baixa latência\n" "$(icon_setting global gamepad.latency_reduction 1)"

        echo -e "\n--------- NOVOS TWEAKS ---------"
        printf " %b 29) Polling rápido HID\n" "$(icon_prop persist.sys.hid.busy_polling 1)"
        printf " %b 30) Ultra Polling HID\n" "$(icon_prop persist.vendor.hid.ultra_polling 1)"
        printf " %b 31) Fastpath HID\n" "$(icon_prop vendor.hid.input.fastpath 1)"
        printf " %b 32) Filtro de input OFF\n" "$(icon_prop persist.sys.input.filter 0)"
        printf " %b 33) Suavização touchpad OFF\n" "$(icon_prop persist.sys.touchpad.smooth 0)"
        printf " %b 34) Reamostragem OFF\n" "$(icon_prop persist.sys.input.resample 0)"
        printf " %b 35) Dejitter OFF\n" "$(icon_prop persist.sys.input.dejitter 0)"
        printf " %b 36) Modo desempenho USB\n" "$(icon_prop vendor.usb.performance_mode 1)"
        printf " %b 37) Interrupções baixa latência\n" "$(icon_prop persist.vendor.usb.low_latency_interrupts 1)"
        printf " %b 38) Máxima largura USB\n" "$(icon_prop vendor.usb.max_bus_bandwidth 1)"
        printf " %b 39) Despacho rápido\n" "$(icon_prop persist.sys.input.dispatch_fast 1)"
        printf " %b 40) Despacho imediato\n" "$(icon_prop persist.sys.input.dispatch_immediate 1)"

        echo
        echo "⚠️  Opções especiais"
        echo "🔄 41) Reset completo (reboot)"
        echo "🎭 42) Spoof 120 FPS (Realme 15 Pro)"
        echo
        echo "0) Voltar"
        echo

        read_prompt "> " op

        case "$op" in
            1) toggle_tweak "t1" "$submenu_1_on" "$submenu_1_off" ;;
            2) toggle_tweak "t2" "$submenu_2_on" "$submenu_2_off" ;;
            3) toggle_tweak "t3" "$submenu_3_on" "$submenu_3_off" ;;
            4) toggle_tweak "t4" "$submenu_4_on" "$submenu_4_off" ;;
            5) toggle_tweak "t5" "$submenu_5_on" "$submenu_5_off" ;;
            6) toggle_tweak "t6" "$submenu_6_on" "$submenu_6_off" ;;
            7) toggle_tweak "t7" "$submenu_7_on" "$submenu_7_off" ;;
            8) toggle_tweak "t8" "$submenu_8_on" "$submenu_8_off" ;;
            9) toggle_tweak "t9" "$submenu_9_on" "$submenu_9_off" ;;
            10) toggle_tweak "t10" "$submenu_10_on" "$submenu_10_off" ;;
            11) toggle_tweak "t11" "$submenu_11_on" "$submenu_11_off" ;;
            12) toggle_tweak "t12" "$submenu_12_on" "$submenu_12_off" ;;
            13) toggle_tweak "t13" "$submenu_13_on" "$submenu_13_off" ;;
            14) toggle_tweak "t14" "$submenu_14_on" "$submenu_14_off" ;;
            15) toggle_tweak "t15" "$submenu_15_on" "$submenu_15_off" ;;
            16) toggle_tweak "t16" "$submenu_16_on" "$submenu_16_off" ;;
            17) toggle_tweak "t17" "$submenu_17_on" "$submenu_17_off" ;;
            18) toggle_tweak "t18" "$submenu_18_on" "$submenu_18_off" ;;
            19) toggle_tweak "t19" "$submenu_19_on" "$submenu_19_off" ;;
            20) toggle_tweak "t20" "$submenu_20_on" "$submenu_20_off" ;;
            21) toggle_tweak "t21" "$submenu_21_on" "$submenu_21_off" ;;
            22) toggle_tweak "t22" "$submenu_22_on" "$submenu_22_off" ;;
            23) toggle_tweak "t23" "$submenu_23_on" "$submenu_23_off" ;;
            24) toggle_tweak "t24" "$submenu_24_on" "$submenu_24_off" ;;
            25) toggle_tweak "t25" "$submenu_25_on" "$submenu_25_off" ;;
            26) toggle_tweak "t26" "$submenu_26_on" "$submenu_26_off" ;;
            27) toggle_tweak "t27" "$submenu_27_on" "$submenu_27_off" ;;
            28) toggle_tweak "t28" "$submenu_28_on" "$submenu_28_off" ;;
            29) toggle_tweak "t29" "$submenu_29_on" "$submenu_29_off" ;;
            30) toggle_tweak "t30" "$submenu_30_on" "$submenu_30_off" ;;
            31) toggle_tweak "t31" "$submenu_31_on" "$submenu_31_off" ;;
            32) toggle_tweak "t32" "$submenu_32_on" "$submenu_32_off" ;;
            33) toggle_tweak "t33" "$submenu_33_on" "$submenu_33_off" ;;
            34) toggle_tweak "t34" "$submenu_34_on" "$submenu_34_off" ;;
            35) toggle_tweak "t35" "$submenu_35_on" "$submenu_35_off" ;;
            36) toggle_tweak "t36" "$submenu_36_on" "$submenu_36_off" ;;
            37) toggle_tweak "t37" "$submenu_37_on" "$submenu_37_off" ;;
            38) toggle_tweak "t38" "$submenu_38_on" "$submenu_38_off" ;;
            39) toggle_tweak "t39" "$submenu_39_on" "$submenu_39_off" ;;
            40) toggle_tweak "t40" "$submenu_40_on" "$submenu_40_off" ;;
            41) submenu_reset ;;
            42) submenu_spoof ;;
            0) return ;;
        esac
    done
}

###############################################################################
# MENU PRINCIPAL
###############################################################################

menu() {
    while true; do
        clear
        echo "╔════════════════════════════════════════════╗"
        echo "║              🎮 FERA ALPHA 🎮              ║"
        echo "╚════════════════════════════════════════════╝"
        echo
        echo "1) Aplicar todos os tweaks"
        echo "2) Ajustes individuais"
        echo "3) Spoof 120 FPS"
        echo "4) Reiniciar dispositivo"
        echo "0) Sair"
        echo
        read_prompt "> " op

        case "$op" in
            1) sh "$0" --ativar-todos ;;
            2) menu_individual ;;
            3) submenu_spoof ;;
            4) reboot ;;
            0) exit 0 ;;
        esac
    done
}

###############################################################################
# LOGIN
###############################################################################

tent=0
while [ $tent -lt 3 ]; do
    loading_bar
    print_header
    input_login

    if ativar_servidor "$USER" "$PASS"; then
        bem_vindo
        menu
        exit 0
    fi

    echo "Acesso negado."
    tent=$((tent+1))
    sleep 1
done

echo "Falha ao autenticar."
exit 1
