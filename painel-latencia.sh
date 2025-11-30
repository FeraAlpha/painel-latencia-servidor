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

    LOCAL=$(cat "$LOCAL_HASH")
    REMOTO=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

    if [ -z "$REMOTO" ]; then
        echo "⚠ Não foi possível verificar atualização."
        return
    fi

    if [ "$LOCAL" = "$REMOTO" ]; then
        echo "✔ Já está na versão mais recente."
        return
    fi

    echo "🔄 Nova versão detectada! Baixando..."

    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ ! -s "$TMP_DL" ]; then
        echo "❌ Falha no download."
        return
    fi

    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        echo "❌ Hash incorreto. Atualização cancelada."
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
setprop persist.sys.mouse.linear_response 1
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
# Restaurar flag e lista de touchscreen (se existirem)
setprop persist.fera.touch.disabled 0
rm -f "$MODDIR/touch_disabled_list"
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
    # bar simplificado (sem loop)
    printf "\033[1;32m[██████████████████] 100%%\033[0m\n"
    return
}

print_header() {
    clear
    cols=$(stty size | awk '{print $2}')

    t1="FERA ALPHA"
    t2="LOGIN"
    line=$(printf "%${#t1}s" | tr " " "=")

    # header sem animação (mais rápido e visual igual)
    pad=$(( (cols - ( ${#line} + 2 + ${#t1} + 2 + ${#line} )) / 2 ))
    printf "%${pad}s"
    echo -e "\033[1;34m$line  $t1  $line\033[0m"

    printf "%$(( (cols - ${#t2}) / 2 ))s"
    echo -e "\033[1;37m$t2\033[0m"
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

# Nota: corrigido para separar SPOOF das entradas de TWEAKS.
# Funções novas:
#  - rebuild_spoof_only: escreve somente props do spoof
#  - append_tweaks_props: escreve somente os tweaks (se não desativados)
#  - rebuild_system_prop: chama as duas, mantendo compatibilidade com chamadas anteriores

# Função que cria/atualiza apenas as props do SPOOF
rebuild_spoof_only() {
    # remove antigo e inicia novo
    rm -f "$SPOOF_FILE" 2>/dev/null
    touch "$SPOOF_FILE" 2>/dev/null

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

    chmod 644 "$SPOOF_FILE" 2>/dev/null
}

# Função que adiciona TWEAKS (somente se não estiverem desativados via FLAG_DIR)
append_tweaks_props() {
    # assegura que o arquivo existe (reaproveita SPOOF_FILE)
    touch "$SPOOF_FILE" 2>/dev/null

    # adiciona cabeçalho apenas se houver algo para adicionar
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
            # evita duplicar a mesma linha (substitui se já existir)
            prop_key=$(echo "$PROP_VAL" | cut -d'=' -f1)
            # remove linha antiga se existir
            if grep -q "^${prop_key}=" "$SPOOF_FILE" 2>/dev/null; then
                sed -i "s|^${prop_key}=.*|${PROP_VAL}|" "$SPOOF_FILE" 2>/dev/null || true
            else
                echo "$PROP_VAL" >> "$SPOOF_FILE"
            fi
            # aplica via setprop para efeito imediato
            setprop "$prop_key" "$(echo "$PROP_VAL" | cut -d'=' -f2)" 2>/dev/null
        fi
    done

    chmod 644 "$SPOOF_FILE" 2>/dev/null
}

# Função compat para chamadas externas: recria spoof + tweaks (usada por --ativar-todos e hodgers)
rebuild_system_prop() {
    rebuild_spoof_only
    append_tweaks_props
}

# ====== Helpers para manipular system.prop incrementalmente ======
# adiciona linha prop_key=prop_value se não existir
add_prop_line() {
    prop_key="$1"
    prop_value="$2"
    if [ -z "$prop_key" ]; then return; fi
    # cria arquivo se não existir
    touch "$SPOOF_FILE" 2>/dev/null
    # se já tem, substitui; caso contrário adiciona
    if grep -q "^${prop_key}=" "$SPOOF_FILE" 2>/dev/null; then
        sed -i "s|^${prop_key}=.*|${prop_key}=${prop_value}|" "$SPOOF_FILE" 2>/dev/null || true
    else
        echo "${prop_key}=${prop_value}" >> "$SPOOF_FILE"
    fi
    chmod 644 "$SPOOF_FILE" 2>/dev/null
}

# remove linha com prop_key
remove_prop_line() {
    prop_key="$1"
    [ -f "$SPOOF_FILE" ] || return
    if grep -q "^${prop_key}=" "$SPOOF_FILE" 2>/dev/null; then
        sed -i "/^${prop_key}=/d" "$SPOOF_FILE" 2>/dev/null || true
    fi
}

# ====== Entrada simples ======
read_prompt() { printf "%s" "$1"; read -r "$2"; }
press_enter()  { printf "\nPressione ENTER para continuar..."; read -r _; }

ativar_tweak() {
    nome="$1"; cmd="$2"
    FLAG="$FLAG_DIR/$nome"
    echo -e "\n${CYAN}${ARROW} Ativando:${RESET} $nome"

    rm -f "$FLAG"

    if echo "$cmd" | grep -qE "^settings"; then
        # settings put namespace key value
        eval "$cmd"
    elif echo "$cmd" | grep -qE "^setprop"; then
        # setprop key value
        prop_key=$(echo "$cmd" | awk '{print $2}')
        prop_value=$(echo "$cmd" | awk '{print $3}')
        [ -n "$prop_key" ] && setprop "$prop_key" "$prop_value" 2>/dev/null
        # atualiza system.prop apenas para esta prop (incremental)
        add_prop_line "$prop_key" "$prop_value"
    else
        # outros comandos (exec)
        eval "$cmd"
    fi

    echo -e "${GREEN}✔ Aplicado: $nome${RESET}"
}

desativar_tweak() {
    nome="$1"; cmd="$2"
    FLAG="$FLAG_DIR/$nome"
    echo -e "\n${CYAN}${ARROW} Desativando:${RESET} $nome"

    touch "$FLAG"

    if echo "$cmd" | grep -qE "^settings"; then
        # off command expected is like "settings delete namespace key"
        eval "$cmd"
    elif echo "$cmd" | grep -qE "^setprop"; then
        # off command might be "setprop key 0" or "setprop key false" or explicit default
        prop_key=$(echo "$cmd" | awk '{print $2}')
        prop_value=$(echo "$cmd" | awk '{print $3}')
        # apply default/off value
        [ -n "$prop_key" ] && setprop "$prop_key" "$prop_value" 2>/dev/null
        # remove from system.prop persistence
        remove_prop_line "$prop_key"
    else
        eval "$cmd"
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
    # Importante: agora chamamos SOMENTE rebuild_spoof_only para evitar
    # que o spoof ative tweaks automaticamente.
    rebuild_spoof_only

    echo -e "${GREEN}✔ Spoof Realme 15 Pro ativado.${RESET}"
    echo -e "${YELLOW}Obs: Algumas mudanças de prop só aplicam após reboot de apps/sistema.${RESET}"
}

disable_spoof() {
    rm -f "$SPOOF_FLAG"
    # atualiza apenas as props de spoof (remove a seção de spoof do arquivo)
    rebuild_spoof_only

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

toggle_tweak() {
    nome="$1"; on_cmd="$2"; off_cmd="$3"

    # Detecta tipo (settings / setprop)
    if echo "$on_cmd" | grep -qE "^settings"; then
        # campos: settings put <ns> <key> <value>
        ns=$(echo "$on_cmd" | awk '{print $3}')
        key=$(echo "$on_cmd" | awk '{print $4}')
        val=$(echo "$on_cmd" | awk '{print $5}')
        if check_setting "$ns" "$key" "$val"; then
            # está ativo -> desativa (executa off_cmd)
            desativar_tweak "$nome" "$off_cmd"
        else
            ativar_tweak "$nome" "$on_cmd"
        fi
    elif echo "$on_cmd" | grep -qE "^setprop"; then
        prop=$(echo "$on_cmd" | awk '{print $2}')
        val=$(echo "$on_cmd" | awk '{print $3}')
        if check_prop "$prop" "$val"; then
            desativar_tweak "$nome" "$off_cmd"
        else
            ativar_tweak "$nome" "$on_cmd"
        fi
    else
        # default: try on/off detection via string compare (fallback)
        # if on_cmd equals off_cmd? just run on_cmd
        ativar_tweak "$nome" "$on_cmd"
    fi
    # pequeno delay para feedback visual consistente
    sleep 0.15
}

# =====================================================
# SUBMENU GENÉRICO (remains but we will use toggle in main)
# =====================================================
submenu_tela() {
    # kept for compatibility but not used on toggle flow
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
# SUBMENUS (chamadas) — comandos usados pelo toggle
# (definições mantidas idênticas ao seu script original)
# =====================================================

submenu_1_cmd_on="settings put secure tap_duration_threshold 70"
submenu_1_cmd_off="settings delete secure tap_duration_threshold"
submenu_2_cmd_on="settings put secure long_press_timeout 300"
submenu_2_cmd_off="settings delete secure long_press_timeout"
submenu_3_cmd_on="settings put secure multi_press_timeout 130"
submenu_3_cmd_off="settings delete secure multi_press_timeout"
submenu_4_cmd_on="settings put secure accessibility_auto_action_delay 200"
submenu_4_cmd_off="settings delete secure accessibility_auto_action_delay"
submenu_5_cmd_on="settings put global block_untrusted_touches 0"
submenu_5_cmd_off="settings delete global block_untrusted_touches"
submenu_6_cmd_on="settings put global restricted_device_performance '0,0'"
submenu_6_cmd_off="settings delete global restricted_device_performance"

submenu_7_cmd_on="setprop vendor.usb.raw_input.enable 1"
submenu_7_cmd_off="setprop vendor.usb.raw_input.enable 0"
submenu_8_cmd_on="setprop persist.usb.low_latency_mode 1"
submenu_8_cmd_off="setprop persist.usb.low_latency_mode 0"
submenu_9_cmd_on="setprop vendor.usb.hid.priority 2"
submenu_9_cmd_off="setprop vendor.usb.hid.priority 1"
submenu_10_cmd_on="setprop persist.vendor.usb.high_speed 1"
submenu_10_cmd_off="setprop persist.vendor.usb.high_speed 0"
submenu_11_cmd_on="setprop persist.vendor.usb.power 1"
submenu_11_cmd_off="setprop persist.vendor.usb.power 0"
submenu_12_cmd_on="setprop vendor.usb.hub.boost 1"
submenu_12_cmd_off="setprop vendor.usb.hub.boost 0"
submenu_13_cmd_on="setprop vendor.usb.mouse.jitter_filter 1"
submenu_13_cmd_off="setprop vendor.usb.mouse.jitter_filter 0"

submenu_14_cmd_on="setprop persist.sys.mouse.linear_response 1"
submenu_14_cmd_off="setprop persist.sys.mouse.linear_response 0"
submenu_15_cmd_on="setprop persist.sys.pointer.acceleration 0"
submenu_15_cmd_off="setprop persist.sys.pointer.acceleration 1"
submenu_16_cmd_on="setprop persist.input.pointer_jitter_smoothing 1"
submenu_16_cmd_off="setprop persist.input.pointer_jitter_smoothing 0"

submenu_17_cmd_on="setprop persist.sys.input.low_latency_mode 1"
submenu_17_cmd_off="setprop persist.sys.input.low_latency_mode 0"
submenu_18_cmd_on="setprop persist.sys.input.high_update_rate true"
submenu_18_cmd_off="setprop persist.sys.input.high_update_rate false"
submenu_19_cmd_on="setprop persist.sys.input.boost 1"
submenu_19_cmd_off="setprop persist.sys.input.boost 0"

submenu_20_cmd_on="setprop debug.hwui.disable_vsync true"
submenu_20_cmd_off="setprop debug.hwui.disable_vsync false"
submenu_21_cmd_on="setprop persist.sys.gpu.low_latency 1"
submenu_21_cmd_off="setprop persist.sys.gpu.low_latency 0"
submenu_22_cmd_on="setprop persist.sys.gpu.frame_boost 1"
submenu_22_cmd_off="setprop persist.sys.gpu.frame_boost 0"

submenu_23_cmd_on="settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
submenu_23_cmd_off="settings delete system peak_refresh_rate; settings delete system.min_refresh_rate"
submenu_24_cmd_on="setprop persist.sys.display.force_refresh 120"
submenu_24_cmd_off="setprop persist.sys.display.force_refresh 60"
submenu_25_cmd_on="setprop persist.video.duplicate.display 1"
submenu_25_cmd_off="setprop persist.video.duplicate.display 0"
submenu_26_cmd_on="setprop vendor.display.external_priority 1"
submenu_26_cmd_off="setprop vendor.display.external_priority 0"
submenu_27_cmd_on="settings put global display_dual_output 1"
submenu_27_cmd_off="settings delete global display_dual_output"

submenu_28_cmd_on="settings put global gamepad.latency_reduction 1"
submenu_28_cmd_off="settings delete global gamepad.latency_reduction"

# (o título de seção de latência foi removido para ficar mais clean — sem alterar itens)
printf "" >/dev/null

# Reset (41) - kept separated (calls reboot)
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
    setprop persist.vendor.usb.max_bus_bandwidth 0
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
            elif echo "$COMMAND" | grep -qE "^setprop"; then
                prop_key=$(echo "$COMMAND" | awk '{print $2}')
                prop_value=$(echo "$COMMAND" | awk '{print $3}')
                [ -n "$prop_key" ] && setprop "$prop_key" "$prop_value" 2>/dev/null
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
# MENU INDIVIDUAL (usa TOGGLE: um clique liga/desliga)
# =====================================================
menu_individual() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${MAGENTA}========== TWEAKS INDIVIDUAIS ==========${RESET}\n"

        # <-- RÓTULOS ENCURTADOS (solicitação) -->
        printf " %b 1) Reduz atraso do toque\n" "$(icon check_setting secure tap_duration_threshold 70)"
        printf " %b 2) Diminui duração do toque longo\n" "$(icon check_setting secure long_press_timeout 300)"
        printf " %b 3) Aumenta resposta a cliques múltiplos\n" "$(icon check_setting secure multi_press_timeout 130)"
        printf " %b 4) Deixa ações automáticas mais rápidas\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"

        printf " %b 5) Permite toques via espelhamento\n" "$(icon check_setting global block_untrusted_touches 0)"
        printf " %b 6) Remove limites de desempenho\n" "$(icon check_setting global restricted_device_performance '0,0')"

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

        # linhas de latência (tweaks mantidos, sem título extra)
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

        # ===> ADICIONADO: Touchscreen toggle (item 43)
        printf " %b 43) Desativar/Ativar Touchscreen\n" "$(icon check_prop persist.fera.touch.disabled 1)"

        echo -e "\n 0) Voltar\n"
        read_prompt "> " item

        case "$item" in
            1) toggle_tweak "Tempo mínimo do toque" "$submenu_1_cmd_on" "$submenu_1_cmd_off" ;;
            2) toggle_tweak "Tempo do toque longo" "$submenu_2_cmd_on" "$submenu_2_cmd_off" ;;
            3) toggle_tweak "Toques rápidos (duplo/triplo)" "$submenu_3_cmd_on" "$submenu_3_cmd_off" ;;
            4) toggle_tweak "Ações automáticas mais rápidas" "$submenu_4_cmd_on" "$submenu_4_cmd_off" ;;
            5) toggle_tweak "Permitir toques no espelhamento" "$submenu_5_cmd_on" "$submenu_5_cmd_off" ;;
            6) toggle_tweak "Desbloquear desempenho do sistema" "$submenu_6_cmd_on" "$submenu_6_cmd_off" ;;
            7) toggle_tweak "Entrada USB sem filtro (RAW)" "$submenu_7_cmd_on" "$submenu_7_cmd_off" ;;
            8) toggle_tweak "USB baixa latência" "$submenu_8_cmd_on" "$submenu_8_cmd_off" ;;
            9) toggle_tweak "Prioridade HID" "$submenu_9_cmd_on" "$submenu_9_cmd_off" ;;
            10) toggle_tweak "Modo High Speed USB" "$submenu_10_cmd_on" "$submenu_10_cmd_off" ;;
            11) toggle_tweak "Potência USB aprimorada" "$submenu_11_cmd_on" "$submenu_11_cmd_off" ;;
            12) toggle_tweak "Boost no hub USB" "$submenu_12_cmd_on" "$submenu_12_cmd_off" ;;
            13) toggle_tweak "Anti-jitter USB (mouse)" "$submenu_13_cmd_on" "$submenu_13_cmd_off" ;;
            14) toggle_tweak "Resposta linear do mouse (1:1)" "$submenu_14_cmd_on" "$submenu_14_cmd_off" ;;
            15) toggle_tweak "Aceleração do mouse desligada" "$submenu_15_cmd_on" "$submenu_15_cmd_off" ;;
            16) toggle_tweak "Anti-jitter do ponteiro" "$submenu_16_cmd_on" "$submenu_16_cmd_off" ;;
            17) toggle_tweak "Input: baixa latência" "$submenu_17_cmd_on" "$submenu_17_cmd_off" ;;
            18) toggle_tweak "Input: alta taxa de atualização" "$submenu_18_cmd_on" "$submenu_18_cmd_off" ;;
            19) toggle_tweak "Input Boost (priorizar eventos)" "$submenu_19_cmd_on" "$submenu_19_cmd_off" ;;
            20) toggle_tweak "VSync desligado" "$submenu_20_cmd_on" "$submenu_20_cmd_off" ;;
            21) toggle_tweak "GPU: baixa latência" "$submenu_21_cmd_on" "$submenu_21_cmd_off" ;;
            22) toggle_tweak "GPU: aceleração de quadros" "$submenu_22_cmd_on" "$submenu_22_cmd_off" ;;
            23) toggle_tweak "Tela interna 120Hz (fixo)" "$submenu_23_cmd_on" "$submenu_23_cmd_off" ;;
            24) toggle_tweak "Forçar 120Hz no display" "$submenu_24_cmd_on" "$submenu_24_cmd_off" ;;
            25) toggle_tweak "Duplicação (espelhamento) externa" "$submenu_25_cmd_on" "$submenu_25_cmd_off" ;;
            26) toggle_tweak "Prioridade de vídeo externa" "$submenu_26_cmd_on" "$submenu_26_cmd_off" ;;
            27) toggle_tweak "Saída dupla de vídeo" "$submenu_27_cmd_on" "$submenu_27_cmd_off" ;;
            28) toggle_tweak "Gamepad: baixa latência" "$submenu_28_cmd_on" "$submenu_28_cmd_off" ;;
            29) toggle_tweak "Polling rápido HID" "$submenu_29_cmd_on" "$submenu_29_cmd_off" ;;
            30) toggle_tweak "Ultra Polling HID" "$submenu_30_cmd_on" "$submenu_30_cmd_off" ;;
            31) toggle_tweak "Fastpath HID (rota direta)" "$submenu_31_cmd_on" "$submenu_31_cmd_off" ;;
            32) toggle_tweak "Filtro de input: desligado" "$submenu_32_cmd_on" "$submenu_32_cmd_off" ;;
            33) toggle_tweak "Suavização do touchpad: desligada" "$submenu_33_cmd_on" "$submenu_33_cmd_off" ;;
            34) toggle_tweak "Reamostragem de input: desligada" "$submenu_34_cmd_on" "$submenu_34_cmd_off" ;;
            35) toggle_tweak "Dejitter de input: desligado" "$submenu_35_cmd_on" "$submenu_35_cmd_off" ;;
            36) toggle_tweak "Modo desempenho USB" "$submenu_36_cmd_on" "$submenu_36_cmd_off" ;;
            37) toggle_tweak "Interrupções USB baixa latência" "$submenu_37_cmd_on" "$submenu_37_cmd_off" ;;
            38) toggle_tweak "Máxima largura de banda USB" "$submenu_38_cmd_on" "$submenu_38_cmd_off" ;;
            39) toggle_tweak "Despacho rápido de input" "$submenu_39_cmd_on" "$submenu_39_cmd_off" ;;
            40) toggle_tweak "Despacho imediato de input" "$submenu_40_cmd_on" "$submenu_40_cmd_off" ;;
            41) submenu_reset ;;
            42) submenu_spoof ;;
            # ===> ADICIONADO: case para Touchscreen toggle
            43) toggle_touchscreen ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida...${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# MENUS POR CATEGORIA (rápidos) — labels em português
# (mantidos idênticos — sem alteração visual)
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
            1) toggle_tweak "Tempo mínimo do toque" "$submenu_1_cmd_on" "$submenu_1_cmd_off" ;;
            2) toggle_tweak "Tempo do toque longo" "$submenu_2_cmd_on" "$submenu_2_cmd_off" ;;
            3) toggle_tweak "Toques rápidos (duplo/triplo)" "$submenu_3_cmd_on" "$submenu_3_cmd_off" ;;
            4) toggle_tweak "Ações automáticas mais rápidas" "$submenu_4_cmd_on" "$submenu_4_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

menu_categoria_usb() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- USB / HID ---${RESET}\n"
        printf " %b 7) Entrada USB sem filtro (RAW)\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
        printf " %b 8) USB baixa latência\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
        printf " %b 9) Prioridade HID\n" "$(icon check_prop vendor.usb.hid.priority 2)"
        printf " %b 10) Modo High Speed USB\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
        printf " %b 11) Potência USB aprimorada\n" "$(icon check_prop persist.vendor.usb.power 1)"
        printf " %b 12) Boost no hub USB\n" "$(icon check_prop vendor.usb.hub.boost 1)"
        printf " %b 13) Anti-jitter USB (mouse)\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " op
        case "$op" in
            7) toggle_tweak "Entrada USB sem filtro (RAW)" "$submenu_7_cmd_on" "$submenu_7_cmd_off" ;;
            8) toggle_tweak "USB baixa latência" "$submenu_8_cmd_on" "$submenu_8_cmd_off" ;;
            9) toggle_tweak "Prioridade HID" "$submenu_9_cmd_on" "$submenu_9_cmd_off" ;;
            10) toggle_tweak "Modo High Speed USB" "$submenu_10_cmd_on" "$submenu_10_cmd_off" ;;
            11) toggle_tweak "Potência USB aprimorada" "$submenu_11_cmd_on" "$submenu_11_cmd_off" ;;
            12) toggle_tweak "Boost no hub USB" "$submenu_12_cmd_on" "$submenu_12_cmd_off" ;;
            13) toggle_tweak "Anti-jitter USB (mouse)" "$submenu_13_cmd_on" "$submenu_13_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# NOVA VERSÃO – Touchscreen (isolado e sem interferência)
# Substitui bloco anterior para evitar alterar permissões de /dev/input/event*
# =====================================================

# Arquivo que guarda apenas a flag (não gera props conflitantes)
TOUCH_FLAG="$MODDIR/touch.disabled"
KEYLAYOUT_DIR="$MODDIR/system/usr/keylayout"
KEYLAYOUT_FILE="$KEYLAYOUT_DIR/touchscreen.kl"

touchscreen_disable() {
    # marca flag persistente local (arquivo)
    echo "1" > "$TOUCH_FLAG" 2>/dev/null

    # Cria keylayout substituto no diretório do módulo (não no /system real)
    mkdir -p "$KEYLAYOUT_DIR" 2>/dev/null
    cat > "$KEYLAYOUT_FILE" <<'EOF'
# Touchscreen bloqueado pelo Fera Alpha
# Arquivo de placeholder para neutralizar eventos via keylayout
key 330   WAKE
EOF
    # Ajuste de permissões seguro
    chmod 644 "$KEYLAYOUT_FILE" 2>/dev/null

    # Trigger leve: prop apenas para sinalizar reload interno (não conflita com outros)
    setprop persist.fera.touch.reload 1 2>/dev/null
}

touchscreen_enable() {
    # Remove flag e arquivo criado
    rm -f "$TOUCH_FLAG" 2>/dev/null
    rm -f "$KEYLAYOUT_FILE" 2>/dev/null

    # Trigger leve para sinalizar restauração
    setprop persist.fera.touch.reload 0 2>/dev/null
}

toggle_touchscreen() {
    # Mantém comportamento de toggle original (mesmo UX)
    if [ -f "$TOUCH_FLAG" ]; then
        echo -e "${CYAN}${ARROW} Ativando touchscreen...${RESET}"
        touchscreen_enable
        echo -e "${GREEN}✔ Touchscreen ativado${RESET}"
    else
        echo -e "${CYAN}${ARROW} Desativando touchscreen...${RESET}"
        touchscreen_disable
        echo -e "${RED}✔ Touchscreen desativado${RESET}"
    fi
    sleep 0.3
}

# =====================================================
# CONTINUAÇÃO DO SCRIPT ORIGINAL (menus restantes)
# =====================================================

# =====================================================
# NOVAS FUNÇÕES: TOUCHSCREEN (disable / enable / toggle)
# =====================================================
# -- Observação: entradas antigas foram substituídas pela versão segura acima.
# -- A chamada toggle_touchscreen segue a mesma assinatura para compatibilidade.

# =====================================================
# MENU CATEGORIA: MOUSE / PONTEIRO
# =====================================================
menu_categoria_mouse() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- MOUSE / PONTEIRO ---${RESET}\n"
        printf " %b 14) Resposta linear do mouse (1:1)\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
        ACEL=$(getprop persist.sys.pointer.acceleration 2>/dev/null)
        [ "$ACEL" = "0" ] && AC_ICON="${GREEN}${ICON_ON}${RESET}" || AC_ICON="${RED}${ICON_OFF}${RESET}"
        printf " %b 15) Aceleração do mouse desligada\n" "$AC_ICON"
        printf " %b 16) Anti-jitter do ponteiro\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " op
        case "$op" in
            14) toggle_tweak "Resposta linear do mouse (1:1)" "$submenu_14_cmd_on" "$submenu_14_cmd_off" ;;
            15) toggle_tweak "Aceleração do mouse desligada" "$submenu_15_cmd_on" "$submenu_15_cmd_off" ;;
            16) toggle_tweak "Anti-jitter do ponteiro" "$submenu_16_cmd_on" "$submenu_16_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU CATEGORIA INPUT
# =====================================================
menu_categoria_input() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- INPUT ---${RESET}\n"
        printf " %b 17) Input baixa latência\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
        printf " %b 18) Input alta taxa de atualização\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
        printf " %b 19) Input Boost\n" "$(icon check_prop persist.sys.input.boost 1)"
        printf " %b 32) Filtro de input: desligado\n" "$(icon check_prop persist.sys.input.filter 0)"
        printf " %b 34) Reamostragem desligada\n" "$(icon check_prop persist.sys.input.resample 0)"
        printf " %b 35) Dejitter desligado\n" "$(icon check_prop persist.sys.input.dejitter 0)"
        printf " %b 39) Despacho rápido de input\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
        printf " %b 40) Despacho imediato de input\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " op
        case "$op" in
            17) toggle_tweak "Input baixa latência" "$submenu_17_cmd_on" "$submenu_17_cmd_off" ;;
            18) toggle_tweak "Input alta taxa de atualização" "$submenu_18_cmd_on" "$submenu_18_cmd_off" ;;
            19) toggle_tweak "Input Boost" "$submenu_19_cmd_on" "$submenu_19_cmd_off" ;;
            32) toggle_tweak "Filtro input" "$submenu_32_cmd_on" "$submenu_32_cmd_off" ;;
            34) toggle_tweak "Reamostragem" "$submenu_34_cmd_on" "$submenu_34_cmd_off" ;;
            35) toggle_tweak "Dejitter" "$submenu_35_cmd_on" "$submenu_35_cmd_off" ;;
            39) toggle_tweak "Despacho rápido de input" "$submenu_39_cmd_on" "$submenu_39_cmd_off" ;;
            40) toggle_tweak "Despacho imediato de input" "$submenu_40_cmd_on" "$submenu_40_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU CATEGORIA GPU
# =====================================================
menu_categoria_gpu() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- GPU ---${RESET}\n"
        printf " %b 20) VSync desligado\n" "$(icon check_prop debug.hwui.disable_vsync true)"
        printf " %b 21) GPU baixa latência\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
        printf " %b 22) GPU aceleração de quadros\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " op
        case "$op" in
            20) toggle_tweak "VSync Off" "$submenu_20_cmd_on" "$submenu_20_cmd_off" ;;
            21) toggle_tweak "GPU baixa latência" "$submenu_21_cmd_on" "$submenu_21_cmd_off" ;;
            22) toggle_tweak "GPU aceleração quadros" "$submenu_22_cmd_on" "$submenu_22_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU CATEGORIA DISPLAY
# =====================================================
menu_categoria_display() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- DISPLAY ---${RESET}\n"
        printf " %b 23) Tela interna 120Hz\n" "$(icon check_setting system peak_refresh_rate 120)"
        printf " %b 24) Forçar 120Hz\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
        printf " %b 25) Duplicação externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
        printf " %b 26) Prioridade externa\n" "$(icon check_prop vendor.display.external_priority 1)"
        printf " %b 27) Saída dupla\n" "$(icon check_setting global display_dual_output 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " op
        case "$op" in
            23) toggle_tweak "Tela interna 120Hz" "$submenu_23_cmd_on" "$submenu_23_cmd_off" ;;
            24) toggle_tweak "Forçar 120Hz Display" "$submenu_24_cmd_on" "$submenu_24_cmd_off" ;;
            25) toggle_tweak "Duplicação externa" "$submenu_25_cmd_on" "$submenu_25_cmd_off" ;;
            26) toggle_tweak "Prioridade externa" "$submenu_26_cmd_on" "$submenu_26_cmd_off" ;;
            27) toggle_tweak "Saída dupla" "$submenu_27_cmd_on" "$submenu_27_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU CATEGORIA GAMEPAD
# =====================================================
menu_categoria_gamepad() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- GAMEPAD ---${RESET}\n"
        printf " %b 28) Gamepad baixa latência\n" "$(icon check_setting global gamepad.latency_reduction 1)"
        echo -e "\n0) Voltar\n"
        read_prompt "> " op
        case "$op" in
            28) toggle_tweak "Gamepad baixa latência" "$submenu_28_cmd_on" "$submenu_28_cmd_off" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU MISC (Reset / Boot)
# =====================================================
menu_misc() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- UTILIDADES ---${RESET}\n"
        echo "1) 🔄 Reset geral"
        echo "2) 🔁 Reiniciar dispositivo"
        echo "0) Voltar"
        read_prompt "> " op
        case "$op" in
            1) submenu_reset ;;
            2) submenu_reboot ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU PRINCIPAL
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
        echo "[3] 🎭 Spoof 120 FPS (Realme 15 Pro)"
        echo "[4] ⚙️ Categorias rápidas"
        echo "[5] 🔄 Reiniciar o Dispositivo"
        echo
        echo "[0] ❌ Sair"
        echo

        read_prompt "> " op
        case "$op" in
            1) sh "$0" --ativar-todos; press_enter ;;
            2) menu_individual ;;
            3) submenu_spoof ;;
            4)
                while true; do
                    clear
                    printf '\033c'
                    echo -e "${BOLD}${CYAN}--- CATEGORIAS RÁPIDAS ---${RESET}\n"
                    echo "1) Toque"
                    echo "2) USB/HID (Latency)"
                    echo "3) Mouse/Ponteiro"
                    echo "4) Input"
                    echo "5) GPU"
                    echo "6) Display"
                    echo "7) Gamepad"
                    echo "8) Utilidades"
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
                        *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
                    esac
                done
                ;;
            5) submenu_reboot ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# FLUXO DE LOGIN
# =====================================================
tent=0
while [ $tent -lt 3 ]; do
    loading_bar
    print_header
    input_login

    echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"
    ativar_servidor "$USER" "$PASS"

    if [ $? -eq 0 ]; then
        bem_vindo
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

exit 0
