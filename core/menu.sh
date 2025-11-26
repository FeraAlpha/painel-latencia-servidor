#!/system/bin/sh
MODDIR=${0%/*}

# IMPORTANTE: este arquivo depende das funções:
# - submenu_1 até submenu_40 (tweaks)
# - submenu_spoof (spoof)
# - submenu_boot (boot)
# - submenu_reset (tweaks)
# por isso tweaks.sh, spoof.sh e boot.sh devem ser carregados antes.

menu_individual() {
    while true; do
        clear
        echo -e "\033[1;35m=== TWEAKS INDIVIDUAIS ===\033[0m\n"

        printf " %b 1) Tempo mínimo do toque\n" "$(icon check_setting secure tap_duration_threshold 70)"
        printf " %b 2) Tempo do toque longo\n" "$(icon check_setting secure long_press_timeout 300)"
        printf " %b 3) Toques rápidos\n" "$(icon check_setting secure multi_press_timeout 130)"
        printf " %b 4) Ações automáticas rápidas\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"

        printf " %b 5) Toques no espelhamento\n" "$(icon check_setting global block_untrusted_touches 0)"
        printf " %b 6) Desempenho desbloqueado\n" "$(icon check_setting global restricted_device_performance '0,0')"

        printf " %b 7) RAW USB\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
        printf " %b 8) USB baixa latência\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
        printf " %b 9) Prioridade HID\n" "$(icon check_prop vendor.usb.hid.priority 2)"
        printf " %b 10) USB high speed\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
        
        printf " %b 11) Potência USB\n" "$(icon check_prop persist.vendor.usb.power 1)"
        printf " %b 12) Hub Boost\n" "$(icon check_prop vendor.usb.hub.boost 1)"
        printf " %b 13) Anti-jitter USB\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"

        printf " %b 14) Mouse linear\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
        printf " %b 15) Aceleração OFF\n" "$(icon check_prop persist.sys.pointer.acceleration 0)"
        printf " %b 16) Anti-jitter ponteiro\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"

        printf " %b 17) Input baixa latência\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
        printf " %b 18) High Update Rate\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
        printf " %b 19) Input Boost\n" "$(icon check_prop persist.sys.input.boost 1)"

        printf " %b 20) VSync OFF\n" "$(icon check_prop debug.hwui.disable_vsync true)"
        printf " %b 21) GPU baixa latência\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
        printf " %b 22) GPU Frame Boost\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"

        printf " %b 23) 120Hz interno\n" "$(icon check_setting system peak_refresh_rate 120)"
        printf " %b 24) Forçar 120Hz\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
        printf " %b 25) Duplicação externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
        printf " %b 26) Prioridade externa\n" "$(icon check_prop vendor.display.external_priority 1)"
        printf " %b 27) Dual Output\n" "$(icon check_setting global display_dual_output 1)"

        printf " %b 28) Gamepad baixa latência\n" "$(icon check_setting global gamepad.latency_reduction 1)"

        echo -e "\n %b 41) RESET TOTAL\n" "$RED$ICON_OFF$RESET"

        if spoof_status; then SPO="${GREEN}${ICON_ON}${RESET}"; else SPO="${RED}${ICON_OFF}${RESET}"; fi
        printf " %b 42) Spoof Realme 15 Pro\n" "$SPO"

        echo -e "\n0) Voltar\n"
        read -p "> " op

        case "$op" in
            1) submenu_1 ;;
            2) submenu_2 ;;
            3) submenu_3 ;;
            4) submenu_4 ;;
            5) submenu_5 ;;
            6) submenu_6 ;;
            7) submenu_7 ;;
            8) submenu_8 ;;
            9) submenu_9 ;;
            10) submenu_10 ;;
            11) submenu_11 ;;
            12) submenu_12 ;;
            13) submenu_13 ;;
            14) submenu_14 ;;
            15) submenu_15 ;;
            16) submenu_16 ;;
            17) submenu_17 ;;
            18) submenu_18 ;;
            19) submenu_19 ;;
            20) submenu_20 ;;
            21) submenu_21 ;;
            22) submenu_22 ;;
            23) submenu_23 ;;
            24) submenu_24 ;;
            25) submenu_25 ;;
            26) submenu_26 ;;
            27) submenu_27 ;;
            28) submenu_28 ;;
            41) submenu_reset ;;
            42) submenu_spoof ;;
            0) return ;;
        esac
    done
}

# ============================
# CATEGORIAS
# ============================

menu_categoria_toque() {
    while true; do
        clear
        echo -e "=== TOQUE ===\n"
        echo "1) Tempo mínimo"
        echo "2) Toque longo"
        echo "3) Toques rápidos"
        echo "4) Ações automáticas"
        echo "0) Voltar"
        read -p "> " c
        case "$c" in
            1) submenu_1 ;;
            2) submenu_2 ;;
            3) submenu_3 ;;
            4) submenu_4 ;;
            0) return ;;
        esac
    done
}

menu_categoria_usb() {
    while true; do
        clear
        echo -e "=== USB & HID ===\n"
        echo "1) RAW USB"
        echo "2) baixa latência"
        echo "3) prior. HID"
        echo "4) High Speed"
        echo "5) Potência USB"
        echo "6) Hub boost"
        echo "7) Anti-jitter"
        echo "0) Voltar"
        read -p "> " c
        case "$c" in
            1) submenu_7 ;;
            2) submenu_8 ;;
            3) submenu_9 ;;
            4) submenu_10 ;;
            5) submenu_11 ;;
            6) submenu_12 ;;
            7) submenu_13 ;;
            0) return ;;
        esac
    done
}

menu_categoria_mouse() {
    while true; do
        clear
        echo -e "=== MOUSE ===\n"
        echo "1) Linear"
        echo "2) Aceleração OFF"
        echo "3) Anti-jitter ponteiro"
        echo "0) Voltar"
        read -p "> " c
        case "$c" in
            1) submenu_14 ;;
            2) submenu_15 ;;
            3) submenu_16 ;;
            0) return ;;
        esac
    done
}

menu_categoria_gpu() {
    while true; do
        clear
        echo -e "=== GPU ===\n"
        echo "1) Baixa latência"
        echo "2) Frame boost"
        echo "3) VSync OFF"
        read -p "> " c
        case "$c" in
            1) submenu_21 ;;
            2) submenu_22 ;;
            3) submenu_20 ;;
            0) return ;;
        esac
    done
}

menu_categoria_input() {
    while true; do
        clear
        echo -e "=== INPUT ===\n"
        echo "1) baixa latência"
        echo "2) update rate"
        echo "3) input boost"
        echo "0) Voltar"
        read -p "> " c
        case "$c" in
            1) submenu_17 ;;
            2) submenu_18 ;;
            3) submenu_19 ;;
            0) return ;;
        esac
    done
}

menu_categoria_display() {
    while true; do
        clear
        echo -e "=== DISPLAY ===\n"
        echo "1) 120Hz interno"
        echo "2) forçar 120Hz"
        echo "3) duplicação externa"
        echo "4) prioridade externa"
        echo "5) dual output"
        read -p "> " c
        case "$c" in
            1) submenu_23 ;;
            2) submenu_24 ;;
            3) submenu_25 ;;
            4) submenu_26 ;;
            5) submenu_27 ;;
            0) return ;;
        esac
    done
}

menu_misc() {
    while true; do
        clear
        echo -e "=== UTILIDADES ===\n"
        echo "1) Aplicar TODOS"
        echo "2) RESET"
        echo "3) Auto-boot"
        echo "4) Reboot"
        echo "0) Voltar"
        read -p "> " m

        case "$m" in
            1) sh "$0" --ativar-todos ;;
            2) submenu_reset ;;
            3) submenu_boot ;;
            4) reboot ;;
            0) return ;;
        esac
    done
}

# ============================
# MENU PRINCIPAL
# ============================
menu() {
    while true; do
        clear

        echo -e "\033[1;32m=== FERA ALPHA — Painel de Latência ===\033[0m\n"
        echo "1) Aplicar TODOS"
        echo "2) Ajustes Individuais"
        echo "3) Automação de Boot"
        echo "4) Spoof 120 FPS"
        echo "5) Categorias rápidas"
        echo "6) Reiniciar dispositivo"
        echo
        echo "0) Sair"

        read -p "> " m

        case "$m" in
            1) sh "$0" --ativar-todos ;;
            2) menu_individual ;;
            3) submenu_boot ;;
            4) submenu_spoof ;;
            5)
                while true; do
                    clear
                    echo -e "=== CATEGORIAS ===\n"
                    echo "1) Toque"
                    echo "2) USB"
                    echo "3) Mouse"
                    echo "4) Input"
                    echo "5) GPU"
                    echo "6) Display"
                    echo "7) Utilidades"
                    echo "0) Voltar"
                    read -p "> " x
                    case "$x" in
                        1) menu_categoria_toque ;;
                        2) menu_categoria_usb ;;
                        3) menu_categoria_mouse ;;
                        4) menu_categoria_input ;;
                        5) menu_categoria_gpu ;;
                        6) menu_categoria_display ;;
                        7) menu_misc ;;
                        0) break ;;
                    esac
                done
            ;;
            6) reboot ;;
            0) exit ;;
        esac
    done
}
