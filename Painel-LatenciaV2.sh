#!/system/bin/sh

###############################################################################
# 🔄 VERIFICAÇÃO DE UPDATE (MANUAL)
###############################################################################
MODDIR=${0%/*}
PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh?$(date +%s)"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt?$(date +%s)"
SELF="$0"
LOCAL_HASH="/data/local/tmp/painel_hash"
TMP_DL="/data/local/tmp/painel_new.sh"

[ ! -f "$LOCAL_HASH" ] && echo "0" > "$LOCAL_HASH"

verificar_update_manual() {
    clear
    echo ""
    echo "──────────────────────────────────────────────"
    echo "        FERA ALPHA — Verificar Atualização    "
    echo "──────────────────────────────────────────────"
    echo ""
    echo "🔍 Verificando servidor..."
    sleep 0.3

    LOCAL=$(cat "$LOCAL_HASH")
    REMOTO=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

    if [ -z "$REMOTO" ]; then
        echo "⚠ Não foi possível verificar atualização."
        sleep 1
        return
    fi

    if [ "$LOCAL" = "$REMOTO" ]; then
        echo "✔ Já está na versão mais recente."
        sleep 1
        return
    fi

    echo "🔄 Nova versão detectada! Baixando..."
    sleep 0.3

    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ ! -s "$TMP_DL" ]; then
        echo "❌ Falha no download."
        sleep 1
        return
    fi

    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        echo "❌ Hash incorreto. Atualização cancelada."
        sleep 1
        return
    fi

    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"

    clear
    echo "✔ Painel atualizado com sucesso!"
    echo ""
    echo "Reabra usando:"
    echo "sh $SELF"
    exit
}

###############################################################################
# 🔐 LOGIN OBRIGATÓRIO
###############################################################################

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
# RESET COMPLETO DA LICENÇA (INTEGRIDADE 100% MANTIDA)
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
rm -rf "$MODDIR/disabled_flags"
rm -f "$MODDIR/system.prop" "$MODDIR/spoof_enabled"
rm -f "$MODDIR/original.props"
rm -f "$MODDIR/license_info"
reboot
EOF

    chmod 755 "$RESET_SCRIPT"
    sh "$RESET_SCRIPT"
    exit 1
}

verifica_expiracao() {
    if [ ! -f "$LICENSE_FILE" ]; then
        return 0
    fi
    EXP=$(cat "$LICENSE_FILE")
    NOW=$(date +%s)
    if [ "$NOW" -ge "$EXP" ]; then
        reset_total_auto
    fi
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

###############################################################################
# VISUAL — (Loading mais rápido)
###############################################################################

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

###############################################################################
# ===================== INÍCIO DO PAINEL (UNIFICADO) ==========================
# =============================================================================
# 🎮 FERA ALPHA – GAMING PERFORMANCE PANEL (tudo abaixo é o painel que você
# forneceu; reorganizado para usar a mesma MODDIR e sem duplicações)
# =============================================================================

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

# Paths para spoof e flags
SPOOF_FLAG="$MODDIR/spoof_enabled"
SPOOF_FILE="$MODDIR/system.prop"
ORIG_STORE="$MODDIR/original.props"
FLAG_DIR="$MODDIR/disabled_flags"
mkdir -p "$FLAG_DIR" 2>/dev/null

# =====================================================
# GERENCIAMENTO CENTRALIZADO DE PROPS (Para persistência no Magisk)
# =====================================================
rebuild_system_prop() {
    rm -f "$SPOOF_FILE" 2>/dev/null

    if [ -f "$SPOOF_FLAG" ]; then
        echo -e "\n# Spoof Realme 15 Pro\n" >> "$SPOOF_FILE"
        cat >> "$SPOOF_FILE" <<'EOF'
ro.product.model=RMX5101
ro.product.brand=realme
ro.product.name=realme15pro
ro.product.device=RMX5101
ro.product.manufacturer=realme
EOF
    fi

    echo -e "\n# Tweaks de Propriedades Ativos\n" >> "$SPOOF_FILE"

    TWEAK_PROPS=(
        "USB RAW=vendor.usb.raw_input.enable=1"
        "USB Low Latency=persist.usb.low_latency_mode=1"
        "USB HID Priority=vendor.usb.hid.priority=2"
        "USB High Speed=persist.vendor.usb.high_speed=1"
        "USB Power Boost=persist.vendor.usb.power=1"
        "USB Hub Boost=vendor.usb.hub.boost=1"
        "USB Mouse AntiJitter=vendor.usb.mouse.jitter_filter=1"
        "Mouse Resposta Linear=persist.sys.mouse.linear_response=1"
        "Mouse Aceleração OFF=persist.sys.pointer.acceleration=0"
        "Mouse Anti-jitter do ponteiro=persist.input.pointer_jitter_smoothing=1"
        "Input Low Latency Mode=persist.sys.input.low_latency_mode=1"
        "Input High Update Rate=persist.sys.input.high_update_rate=true"
        "Input Boost=persist.sys.input.boost=1"
        "VSync OFF=debug.hwui.disable_vsync=true"
        "GPU Low Latency=persist.sys.gpu.low_latency=1"
        "GPU Frame Boost=persist.sys.gpu.frame_boost=1"
        "Forçar 120Hz Display=persist.sys.display.force_refresh=120"
        "Duplicação Externa=persist.video.duplicate.display=1"
        "Prioridade Externa=vendor.display.external_priority=1"
        "HID Busy Polling=persist.sys.hid.busy_polling=1"
        "HID Ultra Polling=persist.vendor.hid.ultra_polling=1"
        "HID Fastpath=vendor.hid.input.fastpath=1"
        "Input Filter OFF=persist.sys.input.filter=0"
        "Touchpad Smooth OFF=persist.sys.touchpad.smooth=0"
        "Input Resample OFF=persist.sys.input.resample=0"
        "Input Dejitter OFF=persist.sys.input.dejitter=0"
        "USB Performance Mode=vendor.usb.performance_mode=1"
        "USB Low Latency Interrupts=persist.vendor.usb.low_latency_interrupts=1"
        "USB Max Bus Bandwidth=vendor.usb.max_bus_bandwidth=1"
        "Input Dispatch Fast=persist.sys.input.dispatch_fast=1"
        "Input Dispatch Immediate=persist.sys.input.dispatch_immediate=1"
    )

    for TWEAK in "${TWEAK_PROPS[@]}"; do
        NOME=$(echo "$TWEAK" | cut -d'=' -f1)
        PROP_VAL=$(echo "$TWEAK" | cut -d'=' -f2-)

        # Se a flag de desativação NÃO existir, adiciona ao arquivo
        if [ ! -f "$FLAG_DIR/$NOME" ]; then
            echo "$PROP_VAL" >> "$SPOOF_FILE"

            prop_key=$(echo "$PROP_VAL" | cut -d'=' -f1)
            prop_value=$(echo "$PROP_VAL" | cut -d'=' -f2)
            setprop "$prop_key" "$prop_value" 2>/dev/null
        fi
    done

    if [ -f "$SPOOF_FILE" ]; then
        chmod 644 "$SPOOF_FILE" 2>/dev/null
    fi
}

# ====== Entrada simples ======
read_prompt() { printf "%s" "$1"; read -r "$2"; }
press_enter()  { printf "\nPressione ENTER para continuar..."; read -r _; }

# ====== Ações de ativar/desativar ======
ativar_tweak() {
    nome="$1"; cmd="$2"
    FLAG="$FLAG_DIR/$nome"
    echo -e "\n${CYAN}${ARROW} Ativando:${RESET} $nome"

    rm -f "$FLAG"

    if echo "$cmd" | grep -qE "^settings"; then
        eval "$cmd"
    fi

    if echo "$cmd" | grep -qE "^setprop"; then
        rebuild_system_prop
    fi

    echo -e "${GREEN}✔ Aplicado: $nome${RESET}"
}

desativar_tweak() {
    nome="$1"; cmd="$2"
    FLAG="$FLAG_DIR/$nome"
    echo -e "\n${CYAN}${ARROW} Desativando:${RESET} $nome"

    touch "$FLAG"

    if echo "$cmd" | grep -qE "^settings"; then
        eval "$cmd"
    fi

    if echo "$cmd" | grep -qE "^setprop"; then
        prop_key=$(echo "$cmd" | cut -d' ' -f2)
        prop_value=$(echo "$cmd" | cut -d' ' -f3)
        setprop "$prop_key" "$prop_value" 2>/dev/null
        rebuild_system_prop
    fi

    echo -e "${RED}✔ Desativado: $nome${RESET}"
}

# ====== Checagens inteligentes (settings/getprop) ======
check_setting() {
    ns="$1"; key="$2"; exp="$3"
    val=$(settings get "$ns" "$key" 2>/dev/null)
    nv=$(echo "$val" | tr '[:upper:]' '[:lower:]')
    ne=$(echo "$exp" | tr '[:upper:]' '[:lower:]')
    [ "$nv" = "true" ] && nv="1"
    [ "$ne" = "true" ] && ne="1"
    if echo "$nv" | grep -Eq '^[0-9]+(\.[0-9]+)?$' && echo "$ne" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
        av=$(printf "%.1f" "$nv"); bv=$(printf "%.1f" "$ne")
        [ "$av" = "$bv" ] && return 0
    fi
    [ "$nv" = "$ne" ]
}
check_prop() {
    prop="$1"; exp="$2"
    val=$(getprop "$prop" 2>/dev/null)
    nv=$(echo "$val" | tr '[:upper:]' '[:lower:]')
    ne=$(echo "$exp" | tr '[:upper:]' '[:lower:]')
    [ "$nv" = "true" ] && nv="1"
    [ "$ne" = "true" ] && ne="1"
    if echo "$nv" | grep -Eq '^[0-9]+(\.[0-9]+)?$' && echo "$ne" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
        av=$(printf "%.1f" "$nv"); bv=$(printf "%.1f" "$ne")
        [ "$av" = "$bv" ] && return 0
    fi
    [ "$nv" = "$ne" ]
}
icon() { if "$@"; then printf "${GREEN}${ICON_ON}${RESET}"; else printf "${RED}${ICON_OFF}${RESET}"; fi; }

# =====================================================
# Funções de Spoof Realme 15 Pro
# =====================================================
save_original_props() {
    {
        echo "ro.product.model=$(getprop ro.product.model 2>/dev/null)"
        echo "ro.product.brand=$(getprop ro.product.brand 2>/dev/null)"
        echo "ro.product.name=$(getprop ro.product.name 2>/dev/null)"
        echo "ro.product.device=$(getprop ro.product.device 2>/dev/null)"
        echo "ro.product.manufacturer=$(getprop ro.product.manufacturer 2>/dev/null)"
    } > "$ORIG_STORE"
    chmod 644 "$ORIG_STORE" 2>/dev/null
}

enable_spoof() {
    if [ ! -f "$ORIG_STORE" ]; then
        save_original_props
    fi

    touch "$SPOOF_FLAG"
    rebuild_system_prop

    echo -e "${GREEN}✔ Spoof Realme 15 Pro ativado.${RESET}"
    echo -e "${YELLOW}Obs: Algumas mudanças de prop só aplicam após reboot de apps/sistema.${RESET}"
}

disable_spoof() {
    rm -f "$SPOOF_FLAG"
    rebuild_system_prop

    echo -e "${GREEN}✔ Spoof desativado — sistema voltará aos valores originais (ou após reboot).${RESET}"
}

spoof_status() {
    if [ -f "$SPOOF_FLAG" ] && [ -f "$SPOOF_FILE" ]; then
        return 0
    fi
    return 1
}

submenu_spoof() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}=== Ativar / Desativar Spoof 120 FPS (Realme 15 Pro) ===${RESET}\n"
        if spoof_status; then
            echo -e "${GREEN}Status: Ativado${RESET}\n"
            echo "1) Desativar spoof (remover spoof do módulo)"
        else
            echo -e "${RED}Status: Desativado${RESET}\n"
            echo "1) Ativar spoof (aplicar spoof Realme 15 Pro)"
        fi
        echo "0) Voltar"
        read_prompt "> " __op
        case "$__op" in
            1)
                if spoof_status; then
                    disable_spoof
                else
                    enable_spoof
                fi
                press_enter
                ;;
            0) break ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# DESCRIÇÕES CURTAS
# =====================================================
DESC_1="- Reduz o tempo mínimo para reconhecer um toque e diminuir latência."
DESC_2="- Ajusta o tempo para reconhecer toque longo (evita long press acidental)."
DESC_3="- Diminui janela entre cliques múltiplos, melhora respostas rápidas."
DESC_4="- Reduz atraso para ações automáticas de acessibilidade."
DESC_5="- Desativa bloqueio de toques 'não confiáveis' (útil no espelhamento)."
DESC_6="- Remove limites de desempenho do sistema (pode aumentar temperatura)."
DESC_7="- Habilita raw input USB (eventos sem filtragem), melhora precisão."
DESC_8="- Força modo USB de baixa latência (reduz buffers USB)."
DESC_9="- Define prioridade HID para reduzir conflitos entre dispositivos."
DESC_10="- Tenta forçar USB em high-speed (pode ajudar adaptadores)."
DESC_11="- Aumenta energia declarada ao controlador USB (estabilidade de periféricos)."
DESC_12="- Boost do driver de hub USB para estabilidade em setups complexos."
DESC_13="- Filtro anti-jitter no mouse para reduzir micro-tremores."
DESC_14="- Resposta linear do mouse (remove curvaturas/curvas de aceleração)."
DESC_15="- Desativa aceleração do ponteiro (1:1 entre movimento e cursor)."
DESC_16="- Suaviza jitter do ponteiro por software (reduz oscilações pequenas)."
DESC_17="- Habilita modo de entrada de baixa latência (prioriza eventos)."
DESC_18="- Ativa alta taxa de atualização de input (dependente do driver)."
DESC_19="- Input boost para priorizar eventos em picos de uso."
DESC_20="- Desativa VSync no HWUI (reduz input lag, pode causar tearing)."
DESC_21="- Configura GPU para baixa latência (pode elevar consumo)."
DESC_22="- Habilita frame boost na GPU (tenta manter FPS curtos mais altos)."
DESC_23="- Mantém o display em 120Hz nativo (min/max 120Hz)."
DESC_24="- Força 120Hz via propriedade (nem sempre funciona em todos OEMs)."
DESC_25="- Ativa duplicação de vídeo para saída externa (espelhamento)."
DESC_26="- Prioriza display externo em relação ao interno (útil em hubs)."
DESC_27="- Habilita saída dual quando suportado pelo driver."
DESC_28="- Reduz latência em gamepads (melhora a leitura de eventos)."
DESC_29="- Força 'polling' mais rápido para dispositivos de interface humana (HID)."
DESC_30="- Habilita o modo de ultra-polling persistente para entradas HID, reduzindo o atraso."
DESC_31="- Ativa o caminho rápido ('fastpath') para eventos de entrada de dispositivos HID (melhora a taxa de eventos)."
DESC_32="- Desativa qualquer filtro de software no sistema de input (recebe o input cru)."
DESC_33="- Desativa o suavizamento de software para 'touchpad' ou ponteiro (para resposta 1:1)."
DESC_34="- Desativa a reamostragem do sistema de input (usa a taxa de evento nativa)."
DESC_35="- Desativa o filtro de 'dejitter' (redução de tremidos) para input, visando resposta máxima."
DESC_36="- Coloca o controlador USB em modo de desempenho máximo (prioriza velocidade/taxa de transferência)."
DESC_37="- Habilita interrupções de baixa latência no USB (reduz o tempo de espera para processar dados)."
DESC_38="- Aumenta a largura de banda máxima permitida no barramento USB (evita gargalos)."
DESC_39="- Prioriza o despacho rápido de eventos de input na fila do sistema."
DESC_40="- Força o processamento imediato de eventos de input, minimizando atrasos."
DESC_RESET="- Remove todas as chaves aplicadas e reinicia para aplicar mudanças."

# =====================================================
# SUBMENU GENÉRICO (ativa/desativa)
# =====================================================
submenu_tela() {
    nome="$1"; desc="$2"; on="$3"; off="$4"
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}=== $nome ===${RESET}"
    echo -e "${YELLOW}$desc${RESET}\n"
    echo "1) ${GREEN}Ativar${RESET}"
    echo "2) ${RED}Desativar${RESET}"
    echo "0) Voltar"
    echo
    read_prompt "> " op
    case "$op" in
        1) ativar_tweak "$nome" "$on" ;;
        2) desativar_tweak "$nome" "$off" ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
    esac
    press_enter
}

# =====================================================
# Submenus (chamadas) — nomes exibidos em português
# =====================================================
submenu_1() { submenu_tela "Tempo mínimo do toque" "$DESC_1" "settings put secure tap_duration_threshold 70" "settings delete secure tap_duration_threshold"; }
submenu_2() { submenu_tela "Tempo do toque longo" "$DESC_2" "settings put secure long_press_timeout 300" "settings delete secure long_press_timeout"; }
submenu_3() { submenu_tela "Toques rápidos (duplo/triplo)" "$DESC_3" "settings put secure multi_press_timeout 130" "settings delete secure multi_press_timeout"; }
submenu_4() { submenu_tela "Ações automáticas mais rápidas" "$DESC_4" "settings put secure accessibility_auto_action_delay 200" "settings delete secure accessibility_auto_action_delay"; }
submenu_5() { submenu_tela "Permitir toques no espelhamento" "$DESC_5" "settings put global block_untrusted_touches 0" "settings delete global block_untrusted_touches"; }
submenu_6() { submenu_tela "Desbloquear desempenho do sistema" "$DESC_6" "settings put global restricted_device_performance '0,0'" "settings delete global restricted_device_performance"; }

submenu_7() { submenu_tela "Entrada USB sem filtro (RAW)" "$DESC_7" "setprop vendor.usb.raw_input.enable 1" "setprop vendor.usb.raw_input.enable 0"; }
submenu_8() { submenu_tela "USB baixa latência" "$DESC_8" "setprop persist.usb.low_latency_mode 1" "setprop persist.usb.low_latency_mode 0"; }
submenu_9() { submenu_tela "Prioridade HID" "$DESC_9" "setprop vendor.usb.hid.priority 2" "setprop vendor.usb.hid.priority 1"; }
submenu_10() { submenu_tela "Modo High Speed USB" "$DESC_10" "setprop persist.vendor.usb.high_speed 1" "setprop persist.vendor.usb.high_speed 0"; }
submenu_11() { submenu_tela "Potência USB aprimorada" "$DESC_11" "setprop persist.vendor.usb.power 1" "setprop persist.vendor.usb.power 0"; }
submenu_12() { submenu_tela "Boost no hub USB" "$DESC_12" "setprop vendor.usb.hub.boost 1" "setprop vendor.usb.hub.boost 0"; }
submenu_13() { submenu_tela "Anti-jitter USB (mouse)" "$DESC_13" "setprop vendor.usb.mouse.jitter_filter 1" "setprop vendor.usb.mouse.jitter_filter 0"; }

submenu_14() { submenu_tela "Resposta linear do mouse (1:1)" "$DESC_14" "setprop persist.sys.mouse.linear_response 1" "setprop persist.sys.mouse.linear_response 0"; }
submenu_15() { submenu_tela "Aceleração do mouse desligada" "$DESC_15" "setprop persist.sys.pointer.acceleration 0" "setprop persist.sys.pointer.acceleration 1"; }
submenu_16() { submenu_tela "Anti-jitter do ponteiro" "$DESC_16" "setprop persist.input.pointer_jitter_smoothing 1" "setprop persist.input.pointer_jitter_smoothing 0"; }

submenu_17() { submenu_tela "Input: baixa latência" "$DESC_17" "setprop persist.sys.input.low_latency_mode 1" "setprop persist.sys.input.low_latency_mode 0"; }
submenu_18() { submenu_tela "Input: alta taxa de atualização" "$DESC_18" "setprop persist.sys.input.high_update_rate true" "setprop persist.sys.input.high_update_rate false"; }
submenu_19() { submenu_tela "Input Boost (priorizar eventos)" "$DESC_19" "setprop persist.sys.input.boost 1" "setprop persist.sys.input.boost 0"; }

submenu_20() { submenu_tela "VSync desligado" "$DESC_20" "setprop debug.hwui.disable_vsync true" "setprop debug.hwui.disable_vsync false"; }
submenu_21() { submenu_tela "GPU: baixa latência" "$DESC_21" "setprop persist.sys.gpu.low_latency 1" "setprop persist.sys.gpu.low_latency 0"; }
submenu_22() { submenu_tela "GPU: aceleração de quadros" "$DESC_22" "setprop persist.sys.gpu.frame_boost 1" "setprop persist.sys.gpu.frame_boost 0"; }

submenu_23() { submenu_tela "Tela interna 120Hz (fixo)" "$DESC_23" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120" "settings delete system peak_refresh_rate; settings delete system min_refresh_rate"; }
submenu_24() { submenu_tela "Forçar 120Hz no display" "$DESC_24" "setprop persist.sys.display.force_refresh 120" "setprop persist.sys.display.force_refresh 60"; }
submenu_25() { submenu_tela "Duplicação (espelhamento) externa" "$DESC_25" "setprop persist.video.duplicate.display 1" "setprop persist.video.duplicate.display 0"; }
submenu_26() { submenu_tela "Prioridade de vídeo externa" "$DESC_26" "setprop vendor.display.external_priority 1" "setprop vendor.display.external_priority 0"; }
submenu_27() { submenu_tela "Saída dupla de vídeo" "$DESC_27" "settings put global display_dual_output 1" "settings delete global display_dual_output"; }

submenu_28() { submenu_tela "Gamepad: baixa latência" "$DESC_28" "settings put global gamepad.latency_reduction 1" "settings delete global gamepad.latency_reduction"; }

# NOVOS TWEAKS ADICIONADOS (29–40)
submenu_29() { submenu_tela "Polling rápido HID" "$DESC_29" "setprop persist.sys.hid.busy_polling 1" "setprop persist.sys.hid.busy_polling 0"; }
submenu_30() { submenu_tela "Ultra Polling HID" "$DESC_30" "setprop persist.vendor.hid.ultra_polling 1" "setprop persist.vendor.hid.ultra_polling 0"; }
submenu_31() { submenu_tela "Fastpath HID (rota direta)" "$DESC_31" "setprop vendor.hid.input.fastpath 1" "setprop vendor.hid.input.fastpath 0"; }
submenu_32() { submenu_tela "Filtro de input: desligado" "$DESC_32" "setprop persist.sys.input.filter 0" "setprop persist.sys.input.filter 1"; }
submenu_33() { submenu_tela "Suavização do touchpad: desligada" "$DESC_33" "setprop persist.sys.touchpad.smooth 0" "setprop persist.sys.touchpad.smooth 1"; }
submenu_34() { submenu_tela "Reamostragem de input: desligada" "$DESC_34" "setprop persist.sys.input.resample 0" "setprop persist.sys.input.resample 1"; }
submenu_35() { submenu_tela "Dejitter de input: desligado" "$DESC_35" "setprop persist.sys.input.dejitter 0" "setprop persist.sys.input.dejitter 1"; }
submenu_36() { submenu_tela "Modo desempenho USB" "$DESC_36" "setprop vendor.usb.performance_mode 1" "setprop vendor.usb.performance_mode 0"; }
submenu_37() { submenu_tela "Interrupções USB baixa latência" "$DESC_37" "setprop persist.vendor.usb.low_latency_interrupts 1" "setprop persist.vendor.usb.low_latency_interrupts 0"; }
submenu_38() { submenu_tela "Máxima largura de banda USB" "$DESC_38" "setprop vendor.usb.max_bus_bandwidth 1" "setprop vendor.usb.max_bus_bandwidth 0"; }
submenu_39() { submenu_tela "Despacho rápido de input" "$DESC_39" "setprop persist.sys.input.dispatch_fast 1" "setprop persist.sys.input.dispatch_fast 0"; }
submenu_40() { submenu_tela "Despacho imediato de input" "$DESC_40" "setprop persist.sys.input.dispatch_immediate 1" "setprop persist.sys.input.dispatch_immediate 0"; }

# Reset (41) - Renomeado para submenu_reset
submenu_reset() {
    clear
    printf '\033c'
    echo -e "${CYAN}Restaurando todas as configurações padrão...${RESET}"

    # SETTINGS DELETE
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

    # SETPROP (Restaurando valor padrão - 0 ou 1)
    setprop vendor.usb.raw_input.enable 0
    setprop persist.usb.low_latency_mode 0
    setprop vendor.usb.hid.priority 1
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

    # NOVOS COMANDOS DE RESET
    setprop persist.sys.hid.busy_polling 0
    setprop persist.vendor.hid.ultra_polling 0
    setprop vendor.hid.input.fastpath 0
    setprop persist.sys.input.filter 1
    setprop persist.sys.touchpad.smooth 1
    setprop persist.sys.input.resample 1
    setprop persist.sys.input.dejitter 1
    setprop vendor.usb.performance_mode 0
    setprop persist.vendor.usb.low_latency_interrupts 0
    setprop vendor.usb.max_bus_bandwidth 0
    setprop persist.sys.input.dispatch_fast 0
    setprop persist.sys.input.dispatch_immediate 0

    # Adicionado: Remove todas as flags de desativação manual
    rm -rf "$FLAG_DIR" 2>/dev/null

    # Também remove spoof e arquivos de backup para garantir reset limpo
    rm -f "$SPOOF_FILE" "$SPOOF_FLAG" "$ORIG_STORE" 2>/dev/null
    rm -f "$MODDIR/enable_on_boot" # Resetar auto-boot

    echo -e "${GREEN}✔ Todos os valores foram resetados.${RESET}"
    echo -e "${YELLOW}O sistema será reiniciado agora para completar o reset.${RESET}"
    sleep 2
    reboot
}

# =====================================================
# NOVA FUNÇÃO: REINICIAR (REBOOT)
# =====================================================
submenu_reboot() {
    clear
    printf '\033c'
    echo -e "${BOLD}${RED}========== REINICIAR O DISPOSITIVO ==========${RESET}\n"
    echo -e "${YELLOW}A reinicialização garante que todos os tweaks de propriedade (setprop) e kernel sejam aplicados completamente.${RESET}\n"
    echo "Deseja reiniciar o dispositivo agora?"
    echo "1) 🔄 Sim, Reiniciar Agora"
    echo "0) Voltar"
    echo
    read_prompt "> " confirm

    case "$confirm" in
        1)
            echo -e "${RED}Reiniciando em 3 segundos...${RESET}"
            sleep 3
            reboot
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida${RESET}"
            sleep 1
            ;;
    esac
}

# =====================================================
# ATIVAR TODOS (argumento --ativar-todos)
# =====================================================
if [ "$1" = "--ativar-todos" ]; then

    apply_if_enabled() {
        TWEAK_NAME="$1"
        COMMAND="$2"
        if [ ! -f "$FLAG_DIR/$TWEAK_NAME" ]; then
            if echo "$COMMAND" | grep -qE "^settings"; then
                eval "$COMMAND"
            fi
        fi
    }

    # SETTINGS PUT
    apply_if_enabled "tap_duration_threshold" "settings put secure tap_duration_threshold 70"
    apply_if_enabled "long_press_timeout" "settings put secure long_press_timeout 300"
    apply_if_enabled "multi_press_timeout" "settings put secure multi_press_timeout 130"
    apply_if_enabled "accessibility_auto_action_delay" "settings put secure accessibility_auto_action_delay 200"
    apply_if_enabled "block_untrusted_touches" "settings put global block_untrusted_touches 0"
    apply_if_enabled "restricted_device_performance" "settings put global restricted_device_performance '0,0'"
    apply_if_enabled "Refresh 120Hz Interno" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
    apply_if_enabled "Saída Dual" "settings put global display_dual_output 1"
    apply_if_enabled "Gamepad Redução de latência" "settings put global gamepad.latency_reduction 1"

    # PROPS (Todos os props são garantidos pelo rebuild_system_prop)
    echo -e "${CYAN}Garantindo persistência e aplicando Propriedades...${RESET}"
    rebuild_system_prop

    echo -e "${GREEN}✔ Todos os tweaks aplicados (spoof NÃO foi ativado).${RESET}"
    exit 0
fi

# =====================================================
# MENU INDIVIDUAL
# =====================================================
menu_individual() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${MAGENTA}========== TWEAKS INDIVIDUAIS ==========${RESET}\n"

        printf " %b 1) Tempo mínimo do toque — reduz atraso do toque\n" "$(icon check_setting secure tap_duration_threshold 70)"
        printf " %b 2) Tempo do toque longo — duração do toque longo\n" "$(icon check_setting secure long_press_timeout 300)"
        printf " %b 3) Toques rápidos (duplo/triplo) — resposta a cliques múltiplos\n" "$(icon check_setting secure multi_press_timeout 130)"
        printf " %b 4) Ações automáticas mais rápidas — acelera ações automáticas\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"

        printf " %b 5) Permitir toques no espelhamento — desbloqueia toques via espelhamento\n" "$(icon check_setting global block_untrusted_touches 0)"
        printf " %b 6) Desbloquear desempenho do sistema — remove limites de desempenho\n" "$(icon check_setting global restricted_device_performance '0,0')"

        printf " %b 7) Entrada USB sem filtro (RAW)\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
        printf " %b 8) USB baixa latência\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
        printf " %b 9) Prioridade HID\n" "$(icon check_prop vendor.usb.hid.priority 2)"
        printf " %b 10) Modo High Speed USB\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
        printf " %b 11) Potência USB aprimorada\n" "$(icon check_prop persist.vendor.usb.power 1)"
        printf " %b 12) Boost no hub USB\n" "$(icon check_prop vendor.usb.hub.boost 1)"
        printf " %b 13) Anti-jitter USB (mouse)\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"

        printf " %b 14) Resposta linear do mouse (1:1)\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
        ACEL=$(getprop persist.sys.pointer.acceleration 2>/dev/null)
        if [ "$ACEL" = "0" ]; then AC_ICON="${GREEN}${ICON_ON}${RESET}"; else AC_ICON="${RED}${ICON_OFF}${RESET}"; fi
        printf " %b 15) Aceleração do mouse desligada\n" "$AC_ICON"
        printf " %b 16) Anti-jitter do ponteiro\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"

        printf " %b 17) Input: baixa latência\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
        printf " %b 18) Input: alta taxa de atualização\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
        printf " %b 19) Input Boost (priorizar eventos)\n" "$(icon check_prop persist.sys.input.boost 1)"

        printf " %b 20) VSync desligado\n" "$(icon check_prop debug.hwui.disable_vsync true)"
        printf " %b 21) GPU: baixa latência\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
        printf " %b 22) GPU: aceleração de quadros\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"

        printf " %b 23) Tela interna 120Hz (fixo)\n" "$(icon check_setting system peak_refresh_rate 120)"
        printf " %b 24) Forçar 120Hz no display\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
        printf " %b 25) Duplicação (espelhamento) externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
        printf " %b 26) Prioridade de vídeo externa\n" "$(icon check_prop vendor.display.external_priority 1)"
        printf " %b 27) Saída dupla de vídeo\n" "$(icon check_setting global display_dual_output 1)"

        printf " %b 28) Gamepad: baixa latência\n" "$(icon check_setting global gamepad.latency_reduction 1)"

        printf "\n${YELLOW}${BOLD}--- NOVOS TWEAKS DE LATÊNCIA ---${RESET}\n"
        printf " %b 29) Polling rápido HID\n" "$(icon check_prop persist.sys.hid.busy_polling 1)"
        printf " %b 30) Ultra Polling HID\n" "$(icon check_prop persist.vendor.hid.ultra_polling 1)"
        printf " %b 31) Fastpath HID (rota direta)\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
        printf " %b 32) Filtro de input: desligado\n" "$(icon check_prop persist.sys.input.filter 0)"
        printf " %b 33) Suavização do touchpad: desligada\n" "$(icon check_prop persist.sys.touchpad.smooth 0)"
        printf " %b 34) Reamostragem de input: desligada\n" "$(icon check_prop persist.sys.input.resample 0)"
        printf " %b 35) Dejitter de input: desligado\n" "$(icon check_prop persist.sys.input.dejitter 0)"
        printf " %b 36) Modo desempenho USB\n" "$(icon check_prop vendor.usb.performance_mode 1)"
        printf " %b 37) Interrupções USB baixa latência\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
        printf " %b 38) Máxima largura de banda USB\n" "$(icon check_prop vendor.usb.max_bus_bandwidth 1)"
        printf " %b 39) Despacho rápido de input\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
        printf " %b 40) Despacho imediato de input\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"

        printf "\n %b 41) Reset total (restaura tudo + reboot)\n" "${RED}${ICON_OFF}${RESET}"
        if spoof_status; then
            SPOOF_ICON="${GREEN}${ICON_ON}${RESET}"
        else
            SPOOF_ICON="${RED}${ICON_OFF}${RESET}"
        fi
        printf " %b 42) Ativar / Desativar Spoof 120 FPS (Realme 15 Pro)\n" "$SPOOF_ICON"

        echo -e "\n 0) Voltar\n"
        read_prompt "> " item

        case "$item" in
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
            29) submenu_29 ;;
            30) submenu_30 ;;
            31) submenu_31 ;;
            32) submenu_32 ;;
            33) submenu_33 ;;
            34) submenu_34 ;;
            35) submenu_35 ;;
            36) submenu_36 ;;
            37) submenu_37 ;;
            38) submenu_38 ;;
            39) submenu_39 ;;
            40) submenu_40 ;;
            41) submenu_reset ;;
            42) submenu_spoof ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida...${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# MENUS POR CATEGORIA (rápidos) — labels em português
# =====================================================
menu_categoria_toque() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- TOQUE ---${RESET}\n"
        printf " %b 1) Tempo mínimo do toque\n" "$(icon check_setting secure tap_duration_threshold 70)"
        printf " %b 2) Tempo do toque longo\n" "$(icon check_setting secure long_press_timeout 300)"
        printf " %b 3) Toques rápidos (duplo/triplo)\n" "$(icon check_setting secure multi_press_timeout 130)"
        printf " %b 4) Ações automáticas mais rápidas\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_1 ;;
            2) submenu_2 ;;
            3) submenu_3 ;;
            4) submenu_4 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

menu_categoria_usb() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- USB & HID ---${RESET}\n"
        printf " %b 1) Entrada RAW USB\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
        printf " %b 2) USB baixa latência\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
        printf " %b 3) Prioridade HID\n" "$(icon check_prop vendor.usb.hid.priority 2)"
        printf " %b 4) Modo High Speed USB\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
        printf " %b 5) Potência USB aprimorada\n" "$(icon check_prop persist.vendor.usb.power 1)"
        printf " %b 6) Boost no hub USB\n" "$(icon check_prop vendor.usb.hub.boost 1)"
        printf " %b 7) Anti-jitter USB (mouse)\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"
        printf " %b 8) Modo desempenho USB\n" "$(icon check_prop vendor.usb.performance_mode 1)"
        printf " %b 9) Interrupções USB baixa latência\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
        printf " %b 10) Máxima largura de banda USB\n" "$(icon check_prop vendor.usb.max_bus_bandwidth 1)"
        printf " %b 11) Polling rápido HID\n" "$(icon check_prop persist.sys.hid.busy_polling 1)"
        printf " %b 12) Ultra Polling HID\n" "$(icon check_prop persist.vendor.hid.ultra_polling 1)"
        printf " %b 13) Fastpath HID\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_7 ;;
            2) submenu_8 ;;
            3) submenu_9 ;;
            4) submenu_10 ;;
            5) submenu_11 ;;
            6) submenu_12 ;;
            7) submenu_13 ;;
            8) submenu_36 ;;
            9) submenu_37 ;;
            10) submenu_38 ;;
            11) submenu_29 ;;
            12) submenu_30 ;;
            13) submenu_31 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

menu_categoria_mouse() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- MOUSE / PONTEIRO ---${RESET}\n"
        printf " %b 1) Resposta linear do mouse\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
        printf " %b 2) Aceleração do mouse desligada\n" "$(icon check_prop persist.sys.pointer.acceleration 0)"
        printf " %b 3) Anti-jitter do ponteiro\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"
        printf " %b 4) Suavização do touchpad desligada\n" "$(icon check_prop persist.sys.touchpad.smooth 0)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_14 ;;
            2) submenu_15 ;;
            3) submenu_16 ;;
            4) submenu_33 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

menu_categoria_input() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- INPUT ---${RESET}\n"
        printf " %b 1) Input: baixa latência\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
        printf " %b 2) Input: alta taxa de atualização\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
        printf " %b 3) Input Boost (priorizar eventos)\n" "$(icon check_prop persist.sys.input.boost 1)"
        printf " %b 4) Filtro de input: desligado\n" "$(icon check_prop persist.sys.input.filter 0)"
        printf " %b 5) Reamostragem de input: desligada\n" "$(icon check_prop persist.sys.input.resample 0)"
        printf " %b 6) Dejitter de input: desligado\n" "$(icon check_prop persist.sys.input.dejitter 0)"
        printf " %b 7) Despacho rápido de input\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
        printf " %b 8) Despacho imediato de input\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_17 ;;
            2) submenu_18 ;;
            3) submenu_19 ;;
            4) submenu_32 ;;
            5) submenu_34 ;;
            6) submenu_35 ;;
            7) submenu_39 ;;
            8) submenu_40 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}


menu_categoria_gpu() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- GPU ---${RESET}\n"
        printf " %b 1) GPU: baixa latência\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
        printf " %b 2) GPU: aceleração de quadros\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
        printf " %b 3) VSync desligado\n" "$(icon check_prop debug.hwui.disable_vsync true)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_21 ;;
            2) submenu_22 ;;
            3) submenu_20 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

menu_categoria_display() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- DISPLAY ---${RESET}\n"
        printf " %b 1) Tela interna 120Hz (fixo)\n" "$(icon check_setting system peak_refresh_rate 120)"
        printf " %b 2) Forçar 120Hz no display\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
        printf " %b 3) Duplicação (espelhamento) externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
        printf " %b 4) Prioridade de vídeo externa\n" "$(icon check_prop vendor.display.external_priority 1)"
        printf " %b 5) Saída dupla de vídeo\n" "$(icon check_setting global display_dual_output 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_23 ;;
            2) submenu_24 ;;
            3) submenu_25 ;;
            4) submenu_26 ;;
            5) submenu_27 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

menu_categoria_gamepad() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- GAMEPAD / CONTROLES ---${RESET}\n"
        printf " %b 1) Redução de latência (gamepad)\n" "$(icon check_setting global gamepad.latency_reduction 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " __op
        case "$__op" in
            1) submenu_28 ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# UTILIDADES / MISC
# =====================================================
menu_misc() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- UTILIDADES ---${RESET}\n"
        echo "1) Aplicar TODOS os tweaks agora"
        echo "2) Restaurar configurações padrão (RESET + Reboot)"
        echo "3) Aplicar no boot (abrir menu de boot)"
        echo "4) 🔄 Reiniciar o Dispositivo (Reboot)"
        echo "0) Voltar"
        echo
        read_prompt "> " op
        case "$op" in
            1)
                echo -e "${CYAN}Aplicando todos os tweaks...${RESET}"
                sh "$0" --ativar-todos
                press_enter
                ;;
            2)
                echo -e "${YELLOW}Reset solicitado: o sistema será reiniciado.${RESET}"
                read_prompt "Confirmar reset? (s/N): " confirm
                if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                    submenu_reset
                fi
                ;;
            3) submenu_boot ;;
            4) submenu_reboot ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# SUBMENU BOOT (menu avançado)
# =====================================================
submenu_boot() {
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}============== AUTOMAÇÃO DE BOOT ==============${RESET}\n"
    echo -e "${YELLOW}Quando ativado, todos os tweaks serão aplicados automaticamente\na cada reinício do dispositivo, RESPEITANDO suas desativações manuais.${RESET}\n"

    if [ -f "$MODDIR/enable_on_boot" ]; then
        echo -e "Status atual: ${GREEN}🟢 ATIVADO${RESET}\n"
    else
        echo -e "Status atual: ${RED}🔴 DESATIVADO${RESET}\n"
    fi

    echo "1) Ativar aplicar no boot"
    echo "2) Desativar aplicar no boot"
    echo "3) Aplicar agora e ativar no boot"
    echo "0) Voltar"
    echo
    read_prompt "> " boot_op

    case "$boot_op" in
        1)
            touch "$MODDIR/enable_on_boot"
            echo -e "${GREEN}✔ Auto-boot ATIVADO${RESET}"
            press_enter
            ;;
        2)
            rm -f "$MODDIR/enable_on_boot"
            echo -e "${RED}✔ Auto-boot DESATIVADO${RESET}"
            press_enter
            ;;
        3)
            touch "$MODDIR/enable_on_boot"
            echo -e "${CYAN}Aplicando todos os tweaks agora...${RESET}"
            sh "$0" --ativar-todos
            echo -e "${GREEN}✔ Aplicado e Auto-boot ATIVADO${RESET}"
            press_enter
            ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
    esac
}

# =====================================================
# MENU PRINCIPAL (com a nova opção de Reboot)
# =====================================================
menu() {
    while true; do
        clear
        printf '\033c'

        echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}${BOLD}║            🎮  F E R A   A L P H A  🎮            ║${RESET}"
        echo -e "${GREEN}${BOLD}║      Sistema Avançado de Desempenho & Latência    ║${RESET}"
        echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${RESET}\n"

        echo "[1] 🟢 Aplicar todos os tweaks"
        echo "[2] 🔧 Ajustes individuais (Mais Completo)"
        echo "[3] 🔁 Automação de Boot"
        echo "[4] 🎭 Spoof 120 FPS (Realme 15 Pro)"
        echo "[5] ⚙️ Categorias rápidas (Toque / USB / Input / GPU / Display, etc.)"
        echo "[6] 🔄 Reiniciar o Dispositivo (Reboot)"
        echo
        echo "[0] ❌ Sair"
        echo

        read_prompt "> " op
        case "$op" in
            1) sh "$0" --ativar-todos; press_enter ;;
            2) menu_individual ;;
            3) submenu_boot ;;
            4) submenu_spoof ;;
            5)
               while true; do
                   clear
                   printf '\033c'
                   echo -e "${BOLD}${CYAN}--- CATEGORIAS RÁPIDAS ---${RESET}\n"
                   echo "1) Toque"
                   echo "2) USB/HID (Latency)"
                   echo "3) Mouse/Ponteiro"
                   echo "4) Input (Despacho de Eventos)"
                   echo "5) GPU"
                   echo "6) Display"
                   echo "7) Gamepad"
                   echo "8) Utilidades (Reset/Boot)"
                   echo "0) Voltar"
                   read_prompt "> " catop
                   case "$catop" in
                       1) menu_categoria_toque ;;
                       2) menu_categoria_usb ;;
                       3) menu_categoria_mouse ;;
                       4) menu_categoria_input ;;
                       5) menu_categoria_gpu ;;
                       6) menu_categoria_display ;;
                       7) menu_categoria_gamepad ;;
                       8) menu_misc ;;
                       0) break ;;
                       *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
                   esac
               done
            ;;
            6) submenu_reboot ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

# ===================== INÍCIO DO FLUXO: LOGIN E ABERTURA DO MENU =====================
# Tentativas de login (3)
tent=0
while [ $tent -lt 3 ]; do
    loading_bar
    print_header
    input_login

    echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"

    ativar_servidor "$USER" "$PASS"
    if [ $? -eq 0 ]; then
        bem_vindo
        # Após login válido, só entra no menu principal
        menu
        break
    fi

    erro_login
    tent=$((tent+1))
    echo -e "\033[1;33mTentativas restantes: $((3-tent))\033[0m"
    sleep 1
done

if [ $tent -ge 3 ]; then
    echo -e "\033[1;31m❌ Falha ao autenticar. Saindo.\033[0m"
    exit 1
fi

# Fim do script
exit 0