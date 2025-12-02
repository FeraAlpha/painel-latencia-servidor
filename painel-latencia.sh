#!/system/bin/sh

###############################################################################
# ⚡ AUTO UPDATE - VERSÃO AUTOMÁTICA
###############################################################################
MODDIR=${0%/*}
PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt"
SELF="$0"
LOCAL_HASH="/data/local/tmp/painel_hash"
TMP_DL="/data/local/tmp/painel_new.sh"

# Configuração de auto-update
AUTO_UPDATE_FILE="$MODDIR/auto_update_enabled"
[ ! -f "$AUTO_UPDATE_FILE" ] && echo "1" > "$AUTO_UPDATE_FILE"

auto_update_check() {
    if [ ! -f "$AUTO_UPDATE_FILE" ] || [ "$(cat "$AUTO_UPDATE_FILE")" != "1" ]; then
        return 0
    fi
    
    echo -e "\n🔍 Verificando atualizações automaticamente..."
    
    LOCAL=$(cat "$LOCAL_HASH" 2>/dev/null || echo "0")
    REMOTO=$(curl -fsSL "${HASH_URL}?$(date +%s)" | sed 's/[^0-9a-fA-F]//g')
    
    if [ -z "$REMOTO" ] || [ "$LOCAL" = "$REMOTO" ]; then
        return 0
    fi
    
    echo "🔄 Nova versão disponível! Atualizando..."
    
    curl -fsSL "${PAINEL_URL}?$(date +%s)" -o "$TMP_DL"
    
    if [ ! -s "$TMP_DL" ]; then
        return 1
    fi
    
    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        return 1
    fi
    
    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"
    
    echo -e "✅ Atualização concluída! Reiniciando painel...\n"
    sleep 2
    exec "$SELF"
}

# Verificar atualização ao iniciar
auto_update_check

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
# Restaurar flag de touchscreen removida
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
# 🛡️ VERIFICAÇÃO INICIAL
###############################################################################

verificacao_inicial() {
    clear
    echo ""
    echo "──────────────────────────────────────────────"
    echo "        FERA ALPHA — Verificações Iniciais    "
    echo "──────────────────────────────────────────────"
    echo ""
    
    # Verificar Spoof
    echo "🔍 Verificando configurações de spoof..."
    if [ -f "$SPOOF_FLAG" ] || ( [ -f "$SPOOF_FILE" ] && grep -q "ro.product.model=RMX5101" "$SPOOF_FILE" 2>/dev/null ); then
        echo -e "\033[1;31m⚠️  SPOOF ATIVO DETECTADO!\033[0m"
        echo -e "\033[1;33mO spoof do Realme 15 Pro está ativo.\033[0m"
        echo -e "\033[1;33mIsso pode impedir o login correto.\033[0m"
        echo ""
        
        echo -e "\033[1;36m📝 O que deseja fazer?\033[0m"
        echo "1) Continuar para login (pode falhar)"
        echo "2) Desativar spoof e continuar"
        echo "3) Verificar atualizações primeiro"
        echo "4) Sair"
        echo ""
        
        while true; do
            read_prompt "> " escolha
            
            case "$escolha" in
                1)
                    echo -e "\033[1;33m⚠️  Continuando com spoof ativo...\033[0m"
                    echo -e "\033[1;31mSe o login falhar, desative o spoof.\033[0m"
                    sleep 2
                    return 1
                    ;;
                2)
                    echo -e "\033[1;36m🔄 Desativando spoof...\033[0m"
                    rm -f "$SPOOF_FLAG" 2>/dev/null
                    
                    # Restaurar props originais
                    if [ -f "$ORIG_STORE" ]; then
                        while IFS='=' read -r prop value; do
                            [ -n "$prop" ] && [ "$prop" != "" ] && setprop "$prop" "$value" 2>/dev/null
                        done < "$ORIG_STORE"
                    fi
                    
                    # Rebuild para remover spoof do system.prop
                    rebuild_spoof_only
                    
                    echo -e "\033[1;32m✅ Spoof desativado!\033[0m"
                    sleep 2
                    return 0
                    ;;
                3)
                    echo -e "\033[1;36m🔄 Verificando atualizações...\033[0m"
                    verificar_update_manual
                    echo ""
                    echo -e "\033[1;33mPressione ENTER para voltar às opções...\033[0m"
                    read -r _
                    clear
                    echo ""
                    echo "──────────────────────────────────────────────"
                    echo "        FERA ALPHA — Verificações Iniciais    "
                    echo "──────────────────────────────────────────────"
                    echo ""
                    echo -e "\033[1;31m⚠️  SPOOF ATIVO DETECTADO!\033[0m"
                    echo -e "\033[1;33mO spoof do Realme 15 Pro está ativo.\033[0m"
                    echo -e "\033[1;33mIsso pode impedir o login correto.\033[0m"
                    echo ""
                    echo -e "\033[1;36m📝 O que deseja fazer?\033[0m"
                    echo "1) Continuar para login (pode falhar)"
                    echo "2) Desativar spoof e continuar"
                    echo "3) Verificar atualizações primeiro"
                    echo "4) Sair"
                    echo ""
                    ;;
                4)
                    echo -e "\033[1;36m👋 Saindo...\033[0m"
                    exit 1
                    ;;
                *)
                    echo -e "\033[1;31m❌ Opção inválida. Tente 1, 2, 3 ou 4.\033[0m"
                    ;;
            esac
        done
    else
        echo -e "\033[1;32m✅ Spoof não está ativo\033[0m"
        echo ""
        return 0
    fi
}

###############################################################################
# 🧹 LIMPEZA DE CACHE AVANÇADA
###############################################################################

limpar_cache_avancado() {
    clear
    echo -e "${BOLD}${CYAN}=== LIMPEZA DE CACHE AVANÇADA ===${RESET}\n"
    
    echo -e "${YELLOW}Escolha o tipo de limpeza:${RESET}"
    echo "1) 📦 Cache de apps (padrão)"
    echo "2) 🗑️  Cache total do sistema (1000G)"
    echo "3) 🎯 Cache de dalvik"
    echo "4) 🔍 Cache específico de apps"
    echo "0) Voltar"
    echo ""
    
    read_prompt "> " opcao_cache
    
    case "$opcao_cache" in
        1)
            echo -e "\n${CYAN}Limpando cache de apps...${RESET}"
            pm trim-caches 0
            echo -e "${GREEN}✅ Cache de apps limpo!${RESET}"
            ;;
        2)
            echo -e "\n${CYAN}Limpando cache TOTAL do sistema (1000G)...${RESET}"
            pm trim-caches 1000G
            echo -e "${GREEN}✅ Cache total limpo!${RESET}"
            ;;
        3)
            echo -e "\n${CYAN}Limpando cache dalvik...${RESET}"
            rm -rf /data/dalvik-cache/* 2>/dev/null
            echo -e "${GREEN}✅ Cache dalvik limpo!${RESET}"
            ;;
        4)
            echo -e "\n${CYAN}Limpando cache de apps específicos...${RESET}"
            echo -e "${YELLOW}Digite o nome do pacote do app (ex: com.whatsapp):${RESET}"
            echo "ou deixe em branco para cancelar"
            read_prompt "> " app_package
            
            if [ -n "$app_package" ]; then
                echo -e "\n${CYAN}Limpando cache de $app_package...${RESET}"
                pm clear "$app_package"
                echo -e "${GREEN}✅ Cache de $app_package limpo!${RESET}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${RESET}"
            ;;
    esac
    
    # Mostrar espaço liberado
    echo ""
    df -h /data | tail -1 | awk '{print "📊 Espaço livre em /data: " $4}'
    
    press_enter
}

###############################################################################
# ⚙️ CONFIGURAÇÕES DE ATUALIZAÇÃO AUTOMÁTICA
###############################################################################

menu_config_update() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}=== CONFIGURAÇÕES DE ATUALIZAÇÃO ===${RESET}\n"
        
        if [ -f "$AUTO_UPDATE_FILE" ] && [ "$(cat "$AUTO_UPDATE_FILE")" = "1" ]; then
            echo -e "Status: ${GREEN}✅ ATUALIZAÇÃO AUTOMÁTICA ATIVADA${RESET}\n"
        else
            echo -e "Status: ${RED}❌ ATUALIZAÇÃO AUTOMÁTICA DESATIVADA${RESET}\n"
        fi
        
        echo "1) Ativar atualização automática"
        echo "2) Desativar atualização automática"
        echo "3) Verificar atualização agora"
        echo "0) Voltar"
        echo ""
        
        read_prompt "> " opcao_update
        
        case "$opcao_update" in
            1)
                echo "1" > "$AUTO_UPDATE_FILE"
                echo -e "${GREEN}✅ Atualização automática ativada!${RESET}"
                sleep 1
                ;;
            2)
                echo "0" > "$AUTO_UPDATE_FILE"
                echo -e "${YELLOW}⚠️  Atualização automática desativada${RESET}"
                sleep 1
                ;;
            3)
                echo -e "\n${CYAN}Verificando atualização...${RESET}"
                LOCAL=$(cat "$LOCAL_HASH" 2>/dev/null || echo "0")
                REMOTO=$(curl -fsSL "${HASH_URL}?$(date +%s)" | sed 's/[^0-9a-fA-F]//g')
                
                if [ -z "$REMOTO" ]; then
                    echo -e "${RED}❌ Não foi possível conectar ao servidor${RESET}"
                elif [ "$LOCAL" = "$REMOTO" ]; then
                    echo -e "${GREEN}✅ Você já tem a versão mais recente!${RESET}"
                else
                    echo -e "${YELLOW}🔄 Nova versão disponível!${RESET}"
                    echo "Deseja atualizar agora? (s/n)"
                    read_prompt "> " resposta
                    
                    if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
                        curl -fsSL "${PAINEL_URL}?$(date +%s)" -o "$TMP_DL"
                        
                        if [ ! -s "$TMP_DL" ]; then
                            echo -e "${RED}❌ Falha no download${RESET}"
                        else
                            cp -f "$TMP_DL" "$SELF"
                            chmod 755 "$SELF"
                            echo "$REMOTO" > "$LOCAL_HASH"
                            echo -e "${GREEN}✅ Atualização concluída!${RESET}"
                            echo -e "\nReiniciando painel..."
                            sleep 2
                            exec "$SELF"
                        fi
                    fi
                fi
                press_enter
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${RESET}"
                sleep 1
                ;;
        esac
    done
}

###############################################################################
# VISUAL
###############################################################################

loading_bar() {
    clear
    echo -e "\n\033[1;36mCarregando Painel FERA ALPHA...\033[0m\n"
    printf "\033[1;32m[██████████████████] 100%%\033[0m\n"
    return
}

print_header() {
    clear
    cols=$(stty size | awk '{print $2}')

    t1="FERA ALPHA"
    t2="LOGIN"
    line=$(printf "%${#t1}s" | tr " " "=")

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
    
    # Verificar atualização após login (se auto-update estiver ativo)
    if [ -f "$AUTO_UPDATE_FILE" ] && [ "$(cat "$AUTO_UPDATE_FILE")" = "1" ]; then
        echo -e "\n${CYAN}🔄 Verificando atualizações...${RESET}"
        auto_update_check
    fi
    
    sleep 1
    clear
}

###############################################################################
# ===================== INÍCIO DO PAINEL (UNIFICADO) ==========================
###############################################################################

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

# Arquivo para armazenar tweaks ativos
ENABLED_TWEAKS_FILE="$MODDIR/enabled_tweaks.txt"

# =====================================================
# GERENCIAMENTO CENTRALIZADO DE PROPS
# =====================================================

rebuild_spoof_only() {
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

append_tweaks_props() {
    touch "$SPOOF_FILE" 2>/dev/null
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

        if [ ! -f "$FLAG_DIR/$NOME" ]; then
            prop_key=$(echo "$PROP_VAL" | cut -d'=' -f1)
            if grep -q "^${prop_key}=" "$SPOOF_FILE" 2>/dev/null; then
                sed -i "s|^${prop_key}=.*|${PROP_VAL}|" "$SPOOF_FILE" 2>/dev/null || true
            else
                echo "$PROP_VAL" >> "$SPOOF_FILE"
            fi
            setprop "$prop_key" "$(echo "$PROP_VAL" | cut -d'=' -f2)" 2>/dev/null
        fi
    done

    chmod 644 "$SPOOF_FILE" 2>/dev/null
}

rebuild_system_prop() {
    rebuild_spoof_only
    append_tweaks_props
}

add_prop_line() {
    prop_key="$1"
    prop_value="$2"
    if [ -z "$prop_key" ]; then return; fi
    touch "$SPOOF_FILE" 2>/dev/null
    if grep -q "^${prop_key}=" "$SPOOF_FILE" 2>/dev/null; then
        sed -i "s|^${prop_key}=.*|${prop_key}=${prop_value}|" "$SPOOF_FILE" 2>/dev/null || true
    else
        echo "${prop_key}=${prop_value}" >> "$SPOOF_FILE"
    fi
    chmod 644 "$SPOOF_FILE" 2>/dev/null
}

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

    # Adicionar ao arquivo de tweaks ativos
    if ! grep -q "^$nome$" "$ENABLED_TWEAKS_FILE" 2>/dev/null; then
        echo "$nome" >> "$ENABLED_TWEAKS_FILE"
    fi

    if echo "$cmd" | grep -qE "^settings"; then
        eval "$cmd"
    elif echo "$cmd" | grep -qE "^setprop"; then
        prop_key=$(echo "$cmd" | awk '{print $2}')
        prop_value=$(echo "$cmd" | awk '{print $3}')
        [ -n "$prop_key" ] && setprop "$prop_key" "$prop_value" 2>/dev/null
        add_prop_line "$prop_key" "$prop_value"
    else
        eval "$cmd"
    fi

    echo -e "${GREEN}✔ Aplicado: $nome${RESET}"
}

desativar_tweak() {
    nome="$1"; cmd="$2"
    FLAG="$FLAG_DIR/$nome"
    echo -e "\n${CYAN}${ARROW} Desativando:${RESET} $nome"

    touch "$FLAG"

    # Remover do arquivo de tweaks ativos
    if [ -f "$ENABLED_TWEAKS_FILE" ]; then
        sed -i "/^$nome$/d" "$ENABLED_TWEAKS_FILE"
    fi

    if echo "$cmd" | grep -qE "^settings"; then
        eval "$cmd"
    elif echo "$cmd" | grep -qE "^setprop"; then
        prop_key=$(echo "$cmd" | awk '{print $2}')
        prop_value=$(echo "$cmd" | awk '{print $3}')
        [ -n "$prop_key" ] && setprop "$prop_key" "$prop_value" 2>/dev/null
        remove_prop_line "$prop_key"
    else
        eval "$cmd"
    fi

    echo -e "${RED}✔ Desativado: $nome${RESET}"
}

# ====== Checagens inteligentes ======
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
# Mapeamento de tweaks para comandos
# =====================================================
map_tweak_to_cmd() {
    case "$1" in
        "Tempo mínimo do toque") echo "$submenu_1_cmd_on" ;;
        "Tempo do toque longo") echo "$submenu_2_cmd_on" ;;
        "Toques rápidos (duplo/triplo)") echo "$submenu_3_cmd_on" ;;
        "Ações automáticas mais rápidas") echo "$submenu_4_cmd_on" ;;
        "Permitir toques no espelhamento") echo "$submenu_5_cmd_on" ;;
        "Desbloquear desempenho do sistema") echo "$submenu_6_cmd_on" ;;
        "Entrada USB sem filtro (RAW)") echo "$submenu_7_cmd_on" ;;
        "USB baixa latência") echo "$submenu_8_cmd_on" ;;
        "Prioridade HID") echo "$submenu_9_cmd_on" ;;
        "Modo High Speed USB") echo "$submenu_10_cmd_on" ;;
        "Potência USB aprimorada") echo "$submenu_11_cmd_on" ;;
        "Boost no hub USB") echo "$submenu_12_cmd_on" ;;
        "Anti-jitter USB (mouse)") echo "$submenu_13_cmd_on" ;;
        "Resposta linear do mouse (1:1)") echo "$submenu_14_cmd_on" ;;
        "Aceleração do mouse desligada") echo "$submenu_15_cmd_on" ;;
        "Anti-jitter do ponteiro") echo "$submenu_16_cmd_on" ;;
        "Input: baixa latência") echo "$submenu_17_cmd_on" ;;
        "Input: alta taxa de atualização") echo "$submenu_18_cmd_on" ;;
        "Input Boost (priorizar eventos)") echo "$submenu_19_cmd_on" ;;
        "VSync desligado") echo "$submenu_20_cmd_on" ;;
        "GPU: baixa latência") echo "$submenu_21_cmd_on" ;;
        "GPU: aceleração de quadros") echo "$submenu_22_cmd_on" ;;
        "Tela interna 120Hz (fixo)") echo "$submenu_23_cmd_on" ;;
        "Forçar 120Hz no display") echo "$submenu_24_cmd_on" ;;
        "Duplicação (espelhamento) externa") echo "$submenu_25_cmd_on" ;;
        "Prioridade de vídeo externa") echo "$submenu_26_cmd_on" ;;
        "Saída dupla de vídeo") echo "$submenu_27_cmd_on" ;;
        "Gamepad: baixa latência") echo "$submenu_28_cmd_on" ;;
        "Polling rápido HID") echo "$submenu_29_cmd_on" ;;
        "Ultra Polling HID") echo "$submenu_30_cmd_on" ;;
        "Fastpath HID (rota direta)") echo "$submenu_31_cmd_on" ;;
        "Filtro de input: desligado") echo "$submenu_32_cmd_on" ;;
        "Suavização do touchpad: desligada") echo "$submenu_33_cmd_on" ;;
        "Reamostragem de input: desligada") echo "$submenu_34_cmd_on" ;;
        "Dejitter de input: desligado") echo "$submenu_35_cmd_on" ;;
        "Modo desempenho USB") echo "$submenu_36_cmd_on" ;;
        "Interrupções USB baixa latência") echo "$submenu_37_cmd_on" ;;
        "Máxima largura de banda USB") echo "$submenu_38_cmd_on" ;;
        "Despacho rápido de input") echo "$submenu_39_cmd_on" ;;
        "Despacho imediato de input") echo "$submenu_40_cmd_on" ;;
        *) echo "" ;;
    esac
}

# =====================================================
# Aplicar tweaks ativos no boot
# =====================================================
apply_enabled_tweaks_from_file() {
    if [ ! -f "$ENABLED_TWEAKS_FILE" ]; then
        return
    fi

    while IFS= read -r nome; do
        cmd=$(map_tweak_to_cmd "$nome")
        if [ -n "$cmd" ]; then
            eval "$cmd"
        fi
    done < "$ENABLED_TWEAKS_FILE"
}

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
    rebuild_spoof_only

    echo -e "${GREEN}✔ Spoof Realme 15 Pro ativado.${RESET}"
    echo -e "${YELLOW}Obs: Algumas mudanças de prop só aplicam após reboot de apps/sistema.${RESET}"
}

disable_spoof() {
    rm -f "$SPOOF_FLAG"
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

    if echo "$on_cmd" | grep -qE "^settings"; then
        ns=$(echo "$on_cmd" | awk '{print $3}')
        key=$(echo "$on_cmd" | awk '{print $4}')
        val=$(echo "$on_cmd" | awk '{print $5}')
        if check_setting "$ns" "$key" "$val"; then
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
        ativar_tweak "$nome" "$on_cmd"
    fi
    sleep 0.15
}

# =====================================================
# SUBMENUS (chamadas) — comandos usados pelo toggle
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

submenu_29_cmd_on="setprop persist.sys.hid.busy_polling 1"
submenu_29_cmd_off="setprop persist.sys.hid.busy_polling 0"
submenu_30_cmd_on="setprop persist.vendor.hid.ultra_polling 1"
submenu_30_cmd_off="setprop persist.vendor.hid.ultra_polling 0"
submenu_31_cmd_on="setprop vendor.hid.input.fastpath 1"
submenu_31_cmd_off="setprop vendor.hid.input.fastpath 0"
submenu_32_cmd_on="setprop persist.sys.input.filter 0"
submenu_32_cmd_off="setprop persist.sys.input.filter 1"
submenu_33_cmd_on="setprop persist.sys.touchpad.smooth 0"
submenu_33_cmd_off="setprop persist.sys.touchpad.smooth 1"
submenu_34_cmd_on="setprop persist.sys.input.resample 0"
submenu_34_cmd_off="setprop persist.sys.input.resample 1"
submenu_35_cmd_on="setprop persist.sys.input.dejitter 0"
submenu_35_cmd_off="setprop persist.sys.input.dejitter 1"
submenu_36_cmd_on="setprop vendor.usb.performance_mode 1"
submenu_36_cmd_off="setprop vendor.usb.performance_mode 0"
submenu_37_cmd_on="setprop persist.vendor.usb.low_latency_interrupts 1"
submenu_37_cmd_off="setprop persist.vendor.usb.low_latency_interrupts 0"
submenu_38_cmd_on="setprop vendor.usb.max_bus_bandwidth 1"
submenu_38_cmd_off="setprop vendor.usb.max_bus_bandwidth 0"
submenu_39_cmd_on="setprop persist.sys.input.dispatch_fast 1"
submenu_39_cmd_off="setprop persist.sys.input.dispatch_fast 0"
submenu_40_cmd_on="setprop persist.sys.input.dispatch_immediate 1"
submenu_40_cmd_off="setprop persist.sys.input.dispatch_immediate 0"

# Reset
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

    # SETPROP
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

    rm -rf "$FLAG_DIR" 2>/dev/null
    rm -f "$SPOOF_FILE" "$SPOOF_FLAG" "$ORIG_STORE" 2>/dev/null
    rm -f "$MODDIR/enable_on_boot"
    rm -f "$ENABLED_TWEAKS_FILE"

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

    # PROPS
    echo -e "${CYAN}Garantindo persistência e aplicando Propriedades...${RESET}"
    rebuild_system_prop

    echo -e "${GREEN}✔ Todos os tweaks aplicados (spoof NÃO foi ativado).${RESET}"
    exit 0
fi

# =====================================================
# Modo boot (--boot) - Aplicar tweaks ativos automaticamente
# =====================================================
if [ "$1" = "--boot" ]; then
    apply_enabled_tweaks_from_file
    if [ -f "$SPOOF_FLAG" ]; then
        enable_spoof
    fi
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
            0) return ;;
            *) echo -e "${RED}Opção inválida...${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# MENUS POR CATEGORIA
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
# MENU MISC
# =====================================================
menu_misc() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}--- UTILIDADES ---${RESET}\n"
        echo "1) 🔄 Reset geral"
        echo "2) 🔁 Reiniciar dispositivo"
        echo "3) 🗑️  Limpeza de cache"
        echo "4) ⚙️  Config. atualização"
        echo "0) Voltar"
        read_prompt "> " op
        case "$op" in
            1) submenu_reset ;;
            2) submenu_reboot ;;
            3) limpar_cache_avancado ;;
            4) menu_config_update ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# MENU PRINCIPAL OTIMIZADO
# =====================================================
menu() {
    while true; do
        clear
        printf '\033c'

        echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}${BOLD}║              🎮  F E R A   A L P H A  🎮              ║${RESET}"
        echo -e "${GREEN}${BOLD}║        Sistema Avançado de Desempenho & Latência      ║${RESET}"
        echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"

        echo "[1] 🟢 Aplicar todos os tweaks"
        echo "[2] 🔧 Ajustes individuais (Mais Completo)"
        echo "[3] 🎭 Spoof 120 FPS (Realme 15 Pro)"
        echo "[4] ⚙️  Categorias rápidas"
        echo "[5] 🧹 Limpeza de cache avançada"
        echo "[6] 🔄 Configurações de atualização"
        echo "[7] 🔁 Reiniciar dispositivo"
        echo ""
        echo "[0] ❌ Sair"
        echo ""

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
            5) limpar_cache_avancado ;;
            6) menu_config_update ;;
            7) submenu_reboot ;;
            0) exit 0 ;;
            *) echo -e "${RED}Opção inválida${RESET}" && sleep 1 ;;
        esac
    done
}

# =====================================================
# FLUXO PRINCIPAL
# =====================================================

# 🛡️ EXECUTAR VERIFICAÇÃO INICIAL
verificacao_inicial

# 🔐 AGORA IR PARA LOGIN
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
