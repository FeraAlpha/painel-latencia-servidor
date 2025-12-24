#!/system/bin/sh

###############################################################################
# ⚡ AUTO UPDATE - VERSÃO AUTOMÁTICA
###############################################################################
MODDIR=${0%/*}
FINGERPRINT_FILE="$MODDIR/device_fingerprint"
PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt"
SELF="$0"
LOCAL_HASH="/data/local/tmp/painel_hash"
TMP_DL="/data/local/tmp/painel_new.sh"

# Configuração de auto-update
AUTO_UPDATE_FILE="$MODDIR/auto_update_enabled"
[ ! -f "$AUTO_UPDATE_FILE" ] && echo "1" > "$AUTO_UPDATE_FILE"

###############################################################################
# 🔐 SISTEMA DE LICENÇA FORTIFICADO
###############################################################################

SERVER="https://painel-licenca-server.onrender.com"
LICENSE_FILE="$MODDIR/license_info"
LICENSE_SIGNATURE_FILE="$MODDIR/license_signature"
RESET_SCRIPT="$MODDIR/reset_auto.sh"
SESSION_FILE="$MODDIR/session_token"
CHAVE_SECRETA="FER4_4LPH4_2024_S3CR3T_K3Y_N0T_SH4R3D"

# Log de segurança
SECURITY_LOG="/data/local/tmp/fera_security.log"
log_seguranca() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SECURITY_LOG"
}

gera_fingerprint() {
    # Gerar fingerprint com dados HARDWARE QUE NÃO MUDAM COM SPOOF
    # Usar apenas identificadores de hardware imutáveis
    ANDROID_ID=$(settings get secure android_id 2>/dev/null || echo "")
    SERIAL=$(getprop ro.serialno 2>/dev/null || echo "")
    HARDWARE=$(getprop ro.boot.hardware 2>/dev/null || echo "")
    BOOT_SERIAL=$(getprop ro.boot.serialno 2>/dev/null || echo "")
    PLATFORM=$(getprop ro.hardware.chipname 2>/dev/null || getprop ro.board.platform 2>/dev/null || echo "")
    
    # Combinação segura e imutável
    FP_RAW="${ANDROID_ID}-${SERIAL}-${HARDWARE}-${BOOT_SERIAL}-${PLATFORM}"
    
    if command -v sha256sum >/dev/null 2>&1; then
        FP=$(echo -n "$FP_RAW" | sha256sum | awk '{print $1}')
    elif command -v md5sum >/dev/null 2>&1; then
        FP=$(echo -n "$FP_RAW" | md5sum | awk '{print $1}')
    elif command -v md5 >/dev/null 2>&1; then
        FP=$(echo -n "$FP_RAW" | md5 | awk '{print $1}')
    else
        FP=$(echo -n "$FP_RAW" | tr -d ' ' | tr -d '\n')
    fi
    
    echo "$FP"
}

gerar_assinatura() {
    DATA="$1"
    echo -n "$DATA" | sha256sum | awk '{print $1}'
}

verificar_assinatura() {
    DATA="$1"
    ASSINATURA="$2"
    
    CALCULADA=$(gerar_assinatura "$DATA")
    
    if [ "$ASSINATURA" = "$CALCULADA" ]; then
        return 0
    else
        log_seguranca "FALHA_ASSINATURA: Esperada=$CALCULADA, Recebida=$ASSINATURA"
        return 1
    fi
}

reset_total_auto() {
    echo "⚠ RESET AUTOMÁTICO — LICENÇA EXPIRADA/INVÁLIDA" > /dev/kmsg
    log_seguranca "RESET_AUTO: Licença expirada ou inválida, resetando sistema"

    echo -e "${RED}⚠️  Licença expirada. Restaurando configurações padrão...${RESET}"
    
    # RESTAURAR VALORES PADRÃO (NÃO REMOVER)
    settings put global restricted_device_performance '1,1'
    settings put secure tap_duration_threshold 100
    settings put secure long_press_timeout 500
    settings put secure multi_press_timeout 300
    settings put secure accessibility_auto_action_delay 200
    settings put global block_untrusted_touches 1
    settings delete system peak_refresh_rate
    settings delete system min_refresh_rate
    settings delete global display_dual_output
    settings delete global gamepad.latency_reduction

    setprop vendor.usb.raw_input.enable 1
    setprop persist.usb.low_latency_mode 0
    setprop vendor.usb.hid.priority 1
    setprop persist.vendor.usb.high_speed 0
    setprop persist.vendor.usb.power 0
    setprop vendor.usb.hub.boost 0
    setprop vendor.usb.mouse.jitter_filter 1

    setprop persist.sys.mouse.linear_response 0
    setprop persist.sys.pointer.acceleration 1

    setprop persist.sys.input.low_latency_mode 0
    setprop persist.sys.input.high_update_rate false

    setprop debug.hwui.disable_vsync 1
    setprop persist.sys.gpu.low_latency 0
    setprop persist.sys.gpu.frame_boost 0

    setprop vendor.display.external_priority 0
    setprop persist.video.duplicate.display 0

    setprop vendor.hid.input.fastpath 0
    setprop persist.sys.input.filter 1
    setprop persist.sys.input.resample 1
    setprop persist.vendor.usb.low_latency_interrupts 1
    setprop persist.sys.input.dispatch_fast 0
    
    setprop debug.input.low_latency 1
    
    setprop windowsmgr.max_events_per_sec 90
    
    setprop debug.sf.late.sf.duration 0
    setprop debug.sf.early.sf.duration 0
    setprop debug.sf.frame_rate_multiple_threshold 60
    setprop debug.sf.high_fps_late.app.duration 0
    setprop debug.sf.high_fps_late.sf.duration 0
    
    setprop debug.hwui.skip_vsync 0
    setprop persist.sys.input.urgent 0
    
    setprop debug.sf.latch_unsignaled 0
    setprop persist.sys.cpu.boost 0
    
    settings put global window_animation_scale 1
    settings put global transition_animation_scale 1
    settings put global animator_duration_scale 1

    # Novas propriedades
    setprop persist.sys.input.priority 0
    setprop persist.video.low_latency_path 0

    # Limpar apenas os arquivos de controle, NÃO reiniciar
    rm -rf "$MODDIR/disabled_flags"
    rm -f "$MODDIR/system.prop" "$MODDIR/spoof_enabled"
    rm -f "$MODDIR/original.props"
    rm -f "$MODDIR/license_info"
    rm -f "$MODDIR/license_signature"
    rm -f "$MODDIR/session_token"
    rm -f "$MODDIR/enable_on_boot"
    rm -f "$ENABLED_TWEAKS_FILE"
    
    setprop persist.fera.touch.disabled 0
    rm -f "$MODDIR/touch_disabled_list"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESET_COMPLETO: Sistema restaurado ao padrão SEM REINÍCIO" > /data/local/tmp/fera_security.log
    
    # NÃO REINICIAR - apenas mostrar mensagem e sair
    echo -e "${YELLOW}✅ Configurações restauradas ao padrão.${RESET}"
    echo -e "${CYAN}O sistema NÃO será reiniciado.${RESET}"
    exit 1
}

verificar_integridade_licenca() {
    if [ ! -f "$LICENSE_FILE" ]; then
        log_seguranca "ERRO: Arquivo de licença não existe"
        echo -e "${RED}❌ ERRO: Licença não encontrada${RESET}"
        return 1
    fi
    
    if [ ! -f "$LICENSE_SIGNATURE_FILE" ]; then
        log_seguranca "ERRO: Assinatura da licença não existe"
        echo -e "${RED}❌ ERRO: Assinatura de licença não encontrada${RESET}"
        return 1
    fi
    
    EXP=$(cat "$LICENSE_FILE" 2>/dev/null)
    ASSINATURA=$(cat "$LICENSE_SIGNATURE_FILE" 2>/dev/null)
    FP=$(gera_fingerprint)
    
    if [ -z "$EXP" ] || [ -z "$ASSINATURA" ]; then
        log_seguranca "ERRO: Licença ou assinatura vazia"
        return 1
    fi
    
    if ! echo "$EXP" | grep -qE '^[0-9]{10,}$'; then
        log_seguranca "ERRO: Formato de licença inválido: $EXP"
        echo -e "${RED}❌ ERRO: Formato de licença inválido${RESET}"
        return 1
    fi
    
    if [ "$EXP" -lt 1577836800 ] || [ "$EXP" -gt 1893456000 ]; then
        log_seguranca "ERRO: Timestamp fora do intervalo: $EXP"
        echo -e "${RED}❌ ERRO: Data de licença inválida${RESET}"
        return 1
    fi
    
    DADOS_ASSINAR="${EXP}:${FP}"
    if ! verificar_assinatura "$DADOS_ASSINAR" "$ASSINATURA"; then
        log_seguranca "ERRO: Assinatura inválida para licença"
        echo -e "${RED}❌ ERRO: Licença corrompida ou modificada${RESET}"
        return 1
    fi
    
    NOW=$(date +%s)
    if [ "$NOW" -ge "$EXP" ]; then
        log_seguranca "AVISO: Licença expirada em $EXP, agora é $NOW"
        echo -e "${RED}⚠️  Licença expirada${RESET}"
        return 1
    fi
    
    return 0
}

verifica_expiracao() {
    if ! verificar_integridade_licenca; then
        log_seguranca "BLOQUEIO: Tentativa de acesso sem licença válida"
        reset_total_auto
    fi
    
    verificar_licenca_online
}

verificar_licenca_online() {
    FP=$(gera_fingerprint)
    EXP=$(cat "$LICENSE_FILE" 2>/dev/null)
    
    if curl --connect-timeout 10 -s -f "$SERVER/ping" >/dev/null 2>&1; then
        RESP=$(curl -s -X POST -H "Content-Type: application/json" \
               -d "{\"fingerprint\":\"$FP\",\"expires\":\"$EXP\"}" \
               "$SERVER/verify_license")
        
        if echo "$RESP" | grep -q '"valid":false'; then
            log_seguranca "SERVIDOR_REJEITOU: Licença inválida no servidor"
            reset_total_auto
        fi
    fi
}

check_license_warning() {
    if [ ! -f "$LICENSE_FILE" ]; then
        return 0
    fi
    
    EXP=$(cat "$LICENSE_FILE")
    NOW=$(date +%s)
    
    if echo "$EXP" | grep -qE '^[0-9]+$'; then
        DIFF=$((EXP - NOW))
        HOURS=$((DIFF / 3600))
        
        if [ "$DIFF" -gt 0 ] && [ "$HOURS" -lt 24 ]; then
            echo -e "\n${RED}⚠️  AVISO: SUA LICENÇA IRÁ EXPIRAR EM ${HOURS} HORA(S)!${RESET}"
            echo -e "${YELLOW}Renove seu acesso para evitar perda das configurações.${RESET}\n"
            sleep 3
        fi
    fi
}

ativar_servidor() {
    USER="$1"
    PASS="$2"
    FP=$(gera_fingerprint)
    
    log_seguranca "TENTATIVA_LOGIN: Usuário=$USER, Fingerprint=$FP"

    JSON="{\"username\":\"$USER\",\"password\":\"$PASS\",\"fingerprint\":\"$FP\"}"

    RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")

    if echo "$RESP" | grep -q '"status":"error"' || echo "$RESP" | grep -q '"error"'; then
        REASON=$(echo "$RESP" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
        log_seguranca "LOGIN_FALHOU: $REASON"
        echo -e "\033[1;31m❌ Erro: ${REASON:-Credenciais inválidas}\033[0m"
        return 1
    fi

    echo -e "\033[1;32m✔ Login aprovado!\033[0m"
    log_seguranca "LOGIN_SUCESSO: Usuário=$USER"

    EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
    if [ -z "$EXP" ]; then
        echo -e "\033[1;31m❌ Erro: Resposta inválida do servidor\033[0m"
        log_seguranca "ERRO_SERVIDOR: Resposta sem timestamp"
        return 1
    fi

    FP=$(gera_fingerprint)
    DADOS_ASSINAR="${EXP}:${FP}"
    ASSINATURA=$(gerar_assinatura "$DADOS_ASSINAR")
    
    echo "$EXP" > "$LICENSE_FILE"
    echo "$ASSINATURA" > "$LICENSE_SIGNATURE_FILE"
    
    SESSION_TOKEN=$(echo -n "${EXP}:${FP}:$(date +%s)" | sha256sum | awk '{print $1}')
    echo "$SESSION_TOKEN" > "$SESSION_FILE"
    
    log_seguranca "LICENÇA_ATIVADA: Expira=$EXP, Assinatura=$ASSINATURA"

    return 0
}

verificar_sessao() {
    if [ ! -f "$SESSION_FILE" ]; then
        return 1
    fi
    
    # 🔴 CORREÇÃO CRÍTICA: Verificar licença primeiro!
    if ! verificar_integridade_licenca; then
        rm -f "$SESSION_FILE"
        log_seguranca "SESSAO_INVALIDA: Licença inválida para sessão"
        return 1
    fi
    
    SESSION_TOKEN=$(cat "$SESSION_FILE")
    SESSION_TIME=$(stat -c %Y "$SESSION_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    
    if [ $((NOW - SESSION_TIME)) -gt 86400 ]; then
        rm -f "$SESSION_FILE"
        log_seguranca "SESSAO_EXPIROU: Tempo decorrido $((NOW - SESSION_TIME))s"
        return 1
    fi
    
    return 0
}

###############################################################################
# 🛡️ VERIFICAÇÃO INICIAL FORTIFICADA
###############################################################################

salvar_props_originais() {
    if [ ! -f "$ORIG_STORE" ]; then
        {
            echo "ro.product.model=$(getprop ro.product.model 2>/dev/null || echo "")"
            echo "ro.product.brand=$(getprop ro.product.brand 2>/dev/null || echo "")"
            echo "ro.product.name=$(getprop ro.product.name 2>/dev/null || echo "")"
            echo "ro.product.device=$(getprop ro.product.device 2>/dev/null || echo "")"
            echo "ro.product.manufacturer=$(getprop ro.product.manufacturer 2>/dev/null || echo "")"
            echo "ro.build.id=$(getprop ro.build.id 2>/dev/null || echo "")"
            echo "ro.build.fingerprint=$(getprop ro.build.fingerprint 2>/dev/null || echo "")"
        } > "$ORIG_STORE"
        chmod 644 "$ORIG_STORE" 2>/dev/null
    fi
}

verificacao_inicial() {
    clear
    echo ""
    echo "──────────────────────────────────────────────"
    echo "        FERA ALPHA — Inicializando...         "
    echo "──────────────────────────────────────────────"
    echo ""
    
    log_seguranca "INICIALIZACAO: Script iniciado, verificando integridade"
    
    SCRIPT_HASH=$(sha256sum "$0" 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$SCRIPT_HASH" ]; then
        log_seguranca "SCRIPT_HASH: $SCRIPT_HASH"
    fi
    
    echo "🔍 Verificando configurações de spoof..."
    if [ -f "$SPOOF_FLAG" ] || ( [ -f "$SPOOF_FILE" ] && grep -q "ro.product.model=RMX5101" "$SPOOF_FILE" 2>/dev/null ); then
        echo -e "\033[1;33m📱 Spoof Realme 15 Pro detectado.\033[0m"
        echo -e "\033[1;36mℹ️  Você pode gerenciar o spoof após o login.\033[0m"
        echo ""
    else
        echo -e "\033[1;32m✅ Spoof não está ativo\033[0m"
        echo ""
    fi
    
    return 0
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
# 🧹 LIMPEZA DE CACHE COMPLETA
###############################################################################

limpar_cache_simples() {
    clear
    echo -e "${BOLD}${CYAN}=== LIMPEZA DE CACHE ===${RESET}\n"
    
    echo -e "${CYAN}Limpando cache do sistema...${RESET}"
    pm trim-caches 1000G
    
    echo -e "${CYAN}Limpando cache do usuário...${RESET}"
    rm -rf /data/local/tmp/* 2>/dev/null
    rm -rf /data/dalvik-cache/* 2>/dev/null
    
    echo -e "${GREEN}✅ Cache limpo com sucesso!${RESET}"
    
    echo ""
    df -h /data | tail -1 | awk '{print "📊 Espaço livre em /data: " $4}'
    
    press_enter
}

###############################################################################
# 🔄 REINICIAR DISPOSITIVO (SIMPLIFICADO)
###############################################################################

reiniciar_dispositivo_simples() {
    clear
    echo -e "${BOLD}${CYAN}=== REINICIAR DISPOSITIVO ===${RESET}\n"
    
    echo -e "${YELLOW}⚠️  ATENÇÃO: O dispositivo será reiniciado!${RESET}\n"
    
    read_prompt "Deseja realmente reiniciar? (s/N): " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        echo -e "${CYAN}Reiniciando...${RESET}"
        echo -e "${YELLOW}O dispositivo será reiniciado em 3 segundos.${RESET}"
        sleep 3
        reboot
    else
        echo -e "${YELLOW}❌ Reinício cancelado${RESET}"
        sleep 1
    fi
}

###############################################################################
# 🛠️ FUNÇÃO DE ATUALIZAÇÃO (SÓ APÓS LOGIN VÁLIDO)
###############################################################################

auto_update_check() {
    if ! verificar_integridade_licenca; then
        log_seguranca "UPDATE_BLOQUEADO: Licença inválida para atualização"
        return 1
    fi
    
    if [ ! -f "$AUTO_UPDATE_FILE" ] || [ "$(cat "$AUTO_UPDATE_FILE")" != "1" ]; then
        return 0
    fi
    
    echo -e "\n🔍 Verificando atualizações..."
    
    LOCAL=$(cat "$LOCAL_HASH" 2>/dev/null || echo "0")
    REMOTO=$(curl -fsSL "${HASH_URL}?$(date +%s)" | sed 's/[^0-9a-fA-F]//g')
    
    if [ -z "$REMOTO" ] || [ "$LOCAL" = "$REMOTO" ]; then
        return 0
    fi
    
    echo "🔄 Nova versão disponível! Atualizando..."
    
    curl -fsSL "${PAINEL_URL}?$(date +%s)" -o "$TMP_DL"
    
    if [ ! -s "$TMP_DL" ]; then
        log_seguranca "UPDATE_ERRO: Download falhou ou arquivo vazio"
        return 1
    fi
    
    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        log_seguranca "UPDATE_ERRO: Hash não confere: $NEW_HASH vs $REMOTO"
        return 1
    fi
    
    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"
    
    log_seguranca "UPDATE_SUCESSO: Script atualizado para hash $REMOTO"
    echo -e "✅ Atualização concluída! Reiniciando painel...\n"
    sleep 2
    exec "$SELF"
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
    
    echo -e "\n\033[1;37m🔥 FERA ALPHA ULTRA GAMER\033[0m"
    echo -e "\n\033[1;37m🔐 LOGIN OBRIGATÓRIO\033[0m\n"
}

input_login() {
    echo -e "\033[1;37m👤 Usuário:\033[0m"
    echo -n "➤ "
    read USER
    echo -e "\033[1;37m🔒 Senha:\033[0m"
    echo -n "➤ "
    read PASS
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
    
    if [ -f "$LICENSE_FILE" ]; then
        EXP=$(cat "$LICENSE_FILE" 2>/dev/null)
        NOW=$(date +%s)
        
        if echo "$EXP" | grep -qE '^[0-9]+$'; then
            DIFF=$((EXP - NOW))
            DAYS=$((DIFF / 86400))
            if [ "$DAYS" -gt 365 ]; then
                echo -e "\033[1;36m🌟 LICENÇA VIP ATIVADA!\033[0m"
                echo -e "\033[1;33m📅 Expira em: $(date -d @$EXP '+%d/%m/%Y %H:%M')\033[0m"
            elif [ "$DAYS" -gt 0 ]; then
                echo -e "\033[1;33m📅 Dias restantes: $DAYS\033[0m"
            fi
        fi
    fi
    
    if [ -f "$AUTO_UPDATE_FILE" ] && [ "$(cat "$AUTO_UPDATE_FILE")" = "1" ]; then
        echo -e "\n${CYAN}🔄 Verificando atualizações...${RESET}"
        auto_update_check
    fi
    
    sleep 1
    clear
}

###############################################################################

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

SPOOF_FLAG="$MODDIR/spoof_enabled"
SPOOF_FILE="$MODDIR/system.prop"
ORIG_STORE="$MODDIR/original.props"
FLAG_DIR="$MODDIR/disabled_flags"
mkdir -p "$FLAG_DIR" 2>/dev/null

salvar_props_originais

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
        "USB RAW=vendor.usb.raw_input.enable=0"
        "USB Low Latency=persist.usb.low_latency_mode=1"
        "USB HID Priority=vendor.usb.hid.priority=2"
        "USB High Speed=persist.vendor.usb.high_speed=1"
        "USB Power Boost=persist.vendor.usb.power=1"
        "USB Hub Boost=vendor.usb.hub.boost=1"
        "USB Mouse AntiJitter=vendor.usb.mouse.jitter_filter=0"
        "Mouse Resposta Linear=persist.sys.mouse.linear_response=1"
        "Mouse Aceleração OFF=persist.sys.pointer.acceleration=0"
        "Input Low Latency Mode=persist.sys.input.low_latency_mode=1"
        "VSync OFF=debug.hwui.disable_vsync=0"
        "GPU Low Latency=persist.sys.gpu.low_latency=1"
        "GPU Frame Boost=persist.sys.gpu.frame_boost=1"
        "HID Fastpath=vendor.hid.input.fastpath=1"
        "USB Low Latency Interrupts=persist.vendor.usb.low_latency_interrupts=0"
        "Input Dispatch Fast=persist.sys.input.dispatch_fast=0"
        "Debug Input Low Latency=debug.input.low_latency=0"
        "Persist Sys CPU Boost=persist.sys.cpu.boost=1"
        "Window Animation Scale=settings:global:window_animation_scale=0"
        "Transition Animation Scale=settings:global:transition_animation_scale=0"
        "Animator Duration Scale=settings:global:animator_duration_scale=0"
        "Input Resample=persist.sys.input.resample=0"
        "Input Priority=persist.sys.input.priority=1"
        "Input Filter=persist.sys.input.filter=0"
        "Max Events per Sec=windowsmgr.max_events_per_sec=120"
        "Video Low Latency Path=persist.video.low_latency_path=1"
    )

    for TWEAK in "${TWEAK_PROPS[@]}"; do
        NOME=$(echo "$TWEAK" | cut -d'=' -f1)
        PROP_VAL=$(echo "$TWEAK" | cut -d'=' -f2-)
        
        if echo "$PROP_VAL" | grep -q "^settings:"; then
            NS=$(echo "$PROP_VAL" | cut -d':' -f2)
            KEY_VAL=$(echo "$PROP_VAL" | cut -d':' -f3)
            KEY=$(echo "$KEY_VAL" | cut -d'=' -f1)
            VAL=$(echo "$KEY_VAL" | cut -d'=' -f2)
            
            settings put "$NS" "$KEY" "$VAL" 2>/dev/null
            continue
        fi

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

read_prompt() { printf "%s" "$1"; read -r "$2"; }
press_enter()  { printf "\nPressione ENTER para continuar..."; read -r _; }

ativar_tweak() {
    nome="$1"; cmd="$2"
    FLAG="$FLAG_DIR/$nome"
    echo -e "\n${CYAN}${ARROW} Ativando:${RESET} $nome"

    rm -f "$FLAG"

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
icon() { if "$@"; then printf "${GREEN}🟢${RESET}"; else printf "${RED}🔴${RESET}"; fi; }

check_mouse_acceleration() {
    ACEL=$(getprop persist.sys.pointer.acceleration 2>/dev/null)
    if [ "$ACEL" = "0" ]; then 
        printf "${GREEN}🟢${RESET}"
    else
        printf "${RED}🔴${RESET}"
    fi
}

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
        "Input: baixa latência") echo "$submenu_17_cmd_on" ;;
        "VSync desligado") echo "$submenu_20_cmd_on" ;;
        "GPU: baixa latência") echo "$submenu_21_cmd_on" ;;
        "GPU: aceleração de quadros") echo "$submenu_22_cmd_on" ;;
        "Tela interna 120Hz (fixo)") echo "$submenu_23_cmd_on" ;;
        "Duplicação (espelhamento) externa") echo "$submenu_25_cmd_on" ;;
        "Prioridade de vídeo externa") echo "$submenu_26_cmd_on" ;;
        "Gamepad: baixa latência") echo "$submenu_28_cmd_on" ;;
        "Fastpath HID (rota direta)") echo "$submenu_31_cmd_on" ;;
        "Interrupções USB baixa latência") echo "$submenu_36_cmd_on" ;;
        "Despacho rápido de input") echo "$submenu_38_cmd_on" ;;
        "Debug Input Low Latency") echo "$submenu_57_cmd_on" ;;
        "Persist Sys CPU Boost") echo "$submenu_65_cmd_on" ;;
        "Window Animation Scale") echo "$submenu_66_cmd_on" ;;
        "Transition Animation Scale") echo "$submenu_67_cmd_on" ;;
        "Animator Duration Scale") echo "$submenu_68_cmd_on" ;;
        "Input Resample") echo "$submenu_32_cmd_on" ;;
        "Input Priority") echo "$submenu_33_cmd_on" ;;
        "Input Filter") echo "$submenu_34_cmd_on" ;;
        "Max Events per Sec") echo "$submenu_35_cmd_on" ;;
        "Video Low Latency Path") echo "$submenu_36_cmd_on" ;;
        *) echo "" ;;
    esac
}

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

submenu_1_cmd_on="settings put secure tap_duration_threshold 60"
submenu_1_cmd_off="settings put secure tap_duration_threshold 100"
submenu_2_cmd_on="settings put secure long_press_timeout 300"
submenu_2_cmd_off="settings put secure long_press_timeout 500"
submenu_3_cmd_on="settings put secure multi_press_timeout 130"
submenu_3_cmd_off="settings put secure multi_press_timeout 300"
submenu_4_cmd_on="settings put secure accessibility_auto_action_delay 200"
submenu_4_cmd_off="settings put secure accessibility_auto_action_delay 200"
submenu_5_cmd_on="settings put global block_untrusted_touches 0"
submenu_5_cmd_off="settings put global block_untrusted_touches 1"
submenu_6_cmd_on="settings put global restricted_device_performance '0,0'"
submenu_6_cmd_off="settings put global restricted_device_performance '1,1'"

submenu_7_cmd_on="setprop vendor.usb.raw_input.enable 0"
submenu_7_cmd_off="setprop vendor.usb.raw_input.enable 1"
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
submenu_13_cmd_on="setprop vendor.usb.mouse.jitter_filter 0"
submenu_13_cmd_off="setprop vendor.usb.mouse.jitter_filter 1"

submenu_14_cmd_on="setprop persist.sys.mouse.linear_response 1"
submenu_14_cmd_off="setprop persist.sys.mouse.linear_response 0"
submenu_15_cmd_on="setprop persist.sys.pointer.acceleration 0"
submenu_15_cmd_off="setprop persist.sys.pointer.acceleration 1"

submenu_17_cmd_on="setprop persist.sys.input.low_latency_mode 1"
submenu_17_cmd_off="setprop persist.sys.input.low_latency_mode 0"

submenu_20_cmd_on="setprop debug.hwui.disable_vsync 0"
submenu_20_cmd_off="setprop debug.hwui.disable_vsync 1"
submenu_21_cmd_on="setprop persist.sys.gpu.low_latency 1"
submenu_21_cmd_off="setprop persist.sys.gpu.low_latency 0"
submenu_22_cmd_on="setprop persist.sys.gpu.frame_boost 1"
submenu_22_cmd_off="setprop persist.sys.gpu.frame_boost 0"

submenu_23_cmd_on="settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
submenu_23_cmd_off="settings delete system peak_refresh_rate; settings delete system.min_refresh_rate"

submenu_25_cmd_on="setprop persist.video.duplicate.display 1"
submenu_25_cmd_off="setprop persist.video.duplicate.display 0"
submenu_26_cmd_on="setprop vendor.display.external_priority 1"
submenu_26_cmd_off="setprop vendor.display.external_priority 0"

submenu_28_cmd_on="settings put global gamepad.latency_reduction 1"
submenu_28_cmd_off="settings delete global gamepad.latencia_reduction"

submenu_31_cmd_on="setprop vendor.hid.input.fastpath 1"
submenu_31_cmd_off="setprop vendor.hid.input.fastpath 0"

# Novas propriedades adicionadas
submenu_32_cmd_on="setprop persist.sys.input.resample 0"
submenu_32_cmd_off="setprop persist.sys.input.resample 1"

submenu_33_cmd_on="setprop persist.sys.input.priority 1"
submenu_33_cmd_off="setprop persist.sys.input.priority 0"

submenu_34_cmd_on="setprop persist.sys.input.filter 0"
submenu_34_cmd_off="setprop persist.sys.input.filter 1"

submenu_35_cmd_on="setprop windowsmgr.max_events_per_sec 120"
submenu_35_cmd_off="setprop windowsmgr.max_events_per_sec 90"

submenu_36_cmd_on="setprop persist.video.low_latency_path 1"
submenu_36_cmd_off="setprop persist.video.low_latency_path 0"

# Ajustar números das propriedades existentes
submenu_38_cmd_on="setprop persist.sys.input.dispatch_fast 0"
submenu_38_cmd_off="setprop persist.sys.input.dispatch_fast 1"

submenu_57_cmd_on="setprop debug.input.low_latency 0"
submenu_57_cmd_off="setprop debug.input.low_latency 1"

submenu_65_cmd_on="setprop persist.sys.cpu.boost 1"
submenu_65_cmd_off="setprop persist.sys.cpu.boost 0"

# Configurações de animação
submenu_66_cmd_on="settings put global window_animation_scale 0"
submenu_66_cmd_off="settings put global window_animation_scale 1"
submenu_67_cmd_on="settings put global transition_animation_scale 0"
submenu_67_cmd_off="settings put global transition_animation_scale 1"
submenu_68_cmd_on="settings put global animator_duration_scale 0"
submenu_68_cmd_off="settings put global animator_duration_scale 1"

apply_safe_performance() {
    echo -e "${CYAN}${ARROW} Ativando modo PERFORMANCE ULTRA SEGURO...${RESET}"
    
    echo "🔧 Abordagem conservadora - núcleos 0-2 serão IGNORADOS"
    
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -f "$cpu/online" ]; then
            echo 1 > "$cpu/online" 2>/dev/null
        fi
    done
    
    echo "📌 Núcleos 0-2: Configuração original mantida"
    
    echo "⚡ Otimizando núcleos grandes (3+)..."
    
    for cpu in /sys/devices/system/cpu/cpu[3-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            cpu_num=$(basename "$cpu" | sed 's/cpu//')
            
            if [ -f "$cpu/cpufreq/scaling_available_governors" ]; then
                avail_govs=$(cat "$cpu/cpufreq/scaling_available_governors")
                
                if echo "$avail_govs" | grep -q "performance"; then
                    echo "performance" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                    echo "🚀 CPU$cpu_num: performance ativado"
                elif echo "$avail_govs" | grep -q "schedutil"; then
                    echo "schedutil" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                    echo "⚡ CPU$cpu_num: schedutil ativado"
                fi
            fi
        fi
    done
    
    echo "🎮 Otimizando GPU..."
    
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        if [ -f "/sys/class/kgsl/kgsl-3d0/devfreq/available_governors" ]; then
            if grep -q "performance" /sys/class/kgsl/kgsl-3d0/devfreq/available_governors; then
                echo "performance" > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
                echo "🎮 GPU: performance ativado"
            fi
        fi
    fi
    
    setprop persist.sys.perf.high 1
    setprop persist.vendor.perf.gaming 1
    
    echo -e "${GREEN}✅ PERFORMANCE ULTRA SEGURO ATIVADO!${RESET}"
    echo -e "${YELLOW}⚠️  Núcleos 0-2 não foram alterados para evitar reinícios${RESET}"
}

restaurar_tudo_padrao() {
    echo -e "${CYAN}${ARROW} Restaurando TODAS as configurações para padrão...${RESET}"
    
    echo "🔄 Restaurando governors de CPU..."
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            cpu_num=$(basename "$cpu" | sed 's/cpu//')
            
            if [ -f "$cpu/cpufreq/scaling_available_governors" ]; then
                avail_govs=$(cat "$cpu/cpufreq/scaling_available_governors")
                
                if echo "$avail_govs" | grep -q "schedutil"; then
                    echo "schedutil" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                elif echo "$avail_govs" | grep -q "interactive"; then
                    echo "interactive" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                fi
            fi
            
            min_freq=$(cat "$cpu/cpufreq/cpuinfo_min_freq" 2>/dev/null)
            max_freq=$(cat "$cpu/cpufreq/cpuinfo_max_freq" 2>/dev/null)
            
            [ -n "$min_freq" ] && echo $min_freq > "$cpu/cpufreq/scaling_min_freq" 2>/dev/null
            [ -n "$max_freq" ] && echo $max_freq > "$cpu/cpufreq/scaling_max_freq" 2>/dev/null
        fi
    done
    
    echo "🎮 Restaurando GPU..."
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        if [ -f "/sys/class/kgsl/kgsl-3d0/devfreq/available_governors" ]; then
            if grep -q "msm-adreno-tz" /sys/class/kgsl/kgsl-3d0/devfreq/available_governors; then
                echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
            fi
        fi
    fi
    
    echo "⚙️ Removendo propriedades de performance..."
    setprop persist.sys.perf.high 0
    setprop persist.vendor.perf.gaming 0
    setprop persist.vendor.cpufreq.max_performance 0
    setprop persist.vendor.gpu.max_performance 0
    setprop persist.vendor.power_profile balanced
    
    echo -e "${GREEN}✅ TODAS as configurações foram restauradas para padrão!${RESET}"
    echo -e "${YELLOW}Algumas mudanças podem requerer reinício para efeito completo.${RESET}"
}

show_performance_status() {
    echo -e "${CYAN}${ARROW} Status de Performance Atual:${RESET}"
    
    echo ""
    echo "=== CPU STATUS ==="
    echo "Núcleos ativos: $(grep '^processor' /proc/cpuinfo | wc -l)"
    
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            cpu_num=$(basename $cpu | sed 's/cpu//')
            gov=$(cat $cpu/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
            cur_freq=$(cat $cpu/cpufreq/scaling_cur_freq 2>/dev/null || echo "N/A")
            max_freq=$(cat $cpu/cpufreq/scaling_max_freq 2>/dev/null || echo "N/A")
            
            if [ "$cur_freq" != "N/A" ] && [ "$cur_freq" -gt 1000 ]; then
                cur_freq=$((cur_freq / 1000))"MHz"
            fi
            if [ "$max_freq" != "N/A" ] && [ "$max_freq" -gt 1000 ]; then
                max_freq=$((max_freq / 1000))"MHz"
            fi
            
            if [ "$cpu_num" -lt 3 ]; then
                echo "⚠️  CPU$cpu_num: $gov | Freq: $cur_freq / Max: $max_freq (NÃO ALTERAR)"
            else
                echo "✅ CPU$cpu_num: $gov | Freq: $cur_freq / Max: $max_freq"
            fi
        fi
    done
    
    echo ""
    echo "=== GPU STATUS ==="
    if [ -f "/sys/class/kgsl/kgsl-3d0/gpuclk" ]; then
        gpu_clk=$(cat /sys/class/kgsl/kgsl-3d0/gpuclk)
        echo "GPU Clock: $((gpu_clk / 1000000))MHz"
    fi
    
    echo ""
    echo "=== TEMPERATURA ==="
    for temp in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$temp" ]; then
            t=$(cat $temp)
            if [ "$t" -gt 1000 ]; then
                t=$((t / 1000))
            fi
            echo "Temp: ${t}°C"
            break
        fi
    done
    
    echo ""
    echo "=== MEMORY ==="
    free -h | grep Mem | awk '{print "Total: " $2 " | Usada: " $3 " | Livre: " $4}'
    
    press_enter
}

apply_extreme_performance() {
    echo -e "${RED}${ARROW} ⚠️  ATIVANDO MODO EXTREME (RISCO ALTO DE REINÍCIO) ⚠️${RESET}"
    echo -e "${YELLOW}Este modo força todos os núcleos no máximo e PODE CAUSAR REINÍCIOS IMEDIATOS!${RESET}"
    
    read_prompt "Continuar? (s/N): " confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo -e "${YELLOW}Cancelado.${RESET}"
        return 1
    fi
    
    echo -e "${RED}ALERTA: Esta configuração provavelmente causará reinício!${RESET}"
    read_prompt "Tem certeza absoluta? (s/N): " confirm2
    if [ "$confirm2" != "s" ] && [ "$confirm2" != "S" ]; then
        echo -e "${YELLOW}Cancelado por segurança.${RESET}"
        return 1
    fi
    
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            echo "performance" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
            
            max_freq=$(cat "$cpu/cpufreq/cpuinfo_max_freq" 2>/dev/null)
            if [ -n "$max_freq" ]; then
                echo $max_freq > "$cpu/cpufreq/scaling_min_freq" 2>/dev/null
                echo $max_freq > "$cpu/cpufreq/scaling_max_freq" 2>/dev/null
            fi
        fi
    done
    
    echo -e "${GREEN}✅ EXTREME MODE ATIVADO!${RESET}"
    echo -e "${RED}🚨 ALERTA: DISPOSITIVO PODE REINICIAR A QUALQUER MOMENTO!${RESET}"
    echo -e "${RED}🚨 NÚCLEOS 0-2 FORÇADOS EM PERFORMANCE MÁXIMA - RISCO MUITO ALTO!${RESET}"
}

submenu_reset() {
    clear
    printf '\033c'
    echo -e "${CYAN}Restaurando todas as configurações padrão...${RESET}"

    # RESTAURAR VALORES PADRÃO
    settings put global restricted_device_performance '1,1'
    settings put secure tap_duration_threshold 100
    settings put secure long_press_timeout 500
    settings put secure multi_press_timeout 300
    settings put secure accessibility_auto_action_delay 200
    settings put global block_untrusted_touches 1
    settings delete system peak_refresh_rate
    settings delete system min_refresh_rate
    settings delete global display_dual_output
    settings delete global gamepad.latency_reduction

    setprop vendor.usb.raw_input.enable 1
    setprop persist.usb.low_latency_mode 0
    setprop vendor.usb.hid.priority 1
    setprop persist.vendor.usb.high_speed 0
    setprop persist.vendor.usb.power 0
    setprop vendor.usb.hub.boost 0
    setprop vendor.usb.mouse.jitter_filter 1

    setprop persist.sys.mouse.linear_response 0
    setprop persist.sys.pointer.acceleration 1

    setprop persist.sys.input.low_latency_mode 0
    setprop persist.sys.input.high_update_rate false

    setprop debug.hwui.disable_vsync 1
    setprop persist.sys.gpu.low_latency 0
    setprop persist.sys.gpu.frame_boost 0

    setprop vendor.display.external_priority 0
    setprop persist.video.duplicate.display 0

    setprop vendor.hid.input.fastpath 0
    setprop persist.sys.input.filter 1
    setprop persist.sys.input.resample 1
    setprop persist.vendor.usb.low_latency_interrupts 1
    setprop persist.sys.input.dispatch_fast 1
    
    setprop debug.input.low_latency 1
    
    setprop windowsmgr.max_events_per_sec 90
    
    setprop debug.sf.late.sf.duration 0
    setprop debug.sf.early.sf.duration 0
    setprop debug.sf.frame_rate_multiple_threshold 60
    setprop debug.sf.high_fps_late.app.duration 0
    setprop debug.sf.high_fps_late.sf.duration 0
    
    setprop debug.hwui.skip_vsync 0
    setprop persist.sys.input.urgent 0
    
    setprop debug.sf.latch_unsignaled 0
    setprop persist.sys.cpu.boost 0
    
    settings put global window_animation_scale 1
    settings put global transition_animation_scale 1
    settings put global animator_duration_scale 1

    # Novas propriedades
    setprop persist.sys.input.priority 0
    setprop persist.video.low_latency_path 0

    # Limpar arquivos de controle
    rm -rf "$FLAG_DIR" 2>/dev/null
    rm -f "$SPOOF_FILE" "$SPOOF_FLAG" "$ORIG_STORE" 2>/dev/null
    rm -f "$MODDIR/enable_on_boot"
    rm -f "$ENABLED_TWEAKS_FILE"

    echo -e "${GREEN}✔ Todos os valores foram resetados para padrão.${RESET}"
    echo -e "${YELLOW}O sistema NÃO será reiniciado.${RESET}"
    sleep 2
}

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

    apply_if_enabled "tap_duration_threshold" "settings put secure tap_duration_threshold 60"
    apply_if_enabled "long_press_timeout" "settings put secure long_press_timeout 300"
    apply_if_enabled "multi_press_timeout" "settings put secure multi_press_timeout 130"
    apply_if_enabled "accessibility_auto_action_delay" "settings put secure accessibility_auto_action_delay 200"
    apply_if_enabled "block_untrusted_touches" "settings put global block_untrusted_touches 0"
    apply_if_enabled "restricted_device_performance" "settings put global restricted_device_performance '0,0'"
    apply_if_enabled "Refresh 120Hz Interno" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
    apply_if_enabled "Gamepad Redução de latência" "settings put global gamepad.latency_reduction 1"

    echo -e "${CYAN}Garantindo persistência e aplicando Propriedades...${RESET}"
    rebuild_system_prop

    apply_if_enabled "Interrupções USB baixa latência" "setprop persist.vendor.usb.low_latency_interrupts 0"
    
    apply_if_enabled "Debug Input Low Latency" "setprop debug.input.low_latency 0"
    
    apply_if_enabled "Persist Sys CPU Boost" "setprop persist.sys.cpu.boost 1"
    
    apply_if_enabled "Window Animation Scale" "settings put global window_animation_scale 0"
    apply_if_enabled "Transition Animation Scale" "settings put global transition_animation_scale 0"
    apply_if_enabled "Animator Duration Scale" "settings put global animator_duration_scale 0"

    # Novas propriedades
    apply_if_enabled "Input Resample" "setprop persist.sys.input.resample 0"
    apply_if_enabled "Input Priority" "setprop persist.sys.input.priority 1"
    apply_if_enabled "Input Filter" "setprop persist.sys.input.filter 0"
    apply_if_enabled "Max Events per Sec" "setprop windowsmgr.max_events_per_sec 120"
    apply_if_enabled "Video Low Latency Path" "setprop persist.video.low_latency_path 1"

    echo -e "${GREEN}✔ Todos os tweaks aplicados (spoof NÃO foi ativado).${RESET}"
    exit 0
fi

if [ "$1" = "--boot" ]; then
    if ! verificar_integridade_licenca; then
        log_seguranca "BOOT_BLOQUEADO: Licença inválida no boot"
        exit 1
    fi
    
    apply_enabled_tweaks_from_file
    if [ -f "$SPOOF_FLAG" ]; then
        enable_spoof
    fi
    exit 0
fi

# =====================================================
# MENU DE TODOS OS TWEAKS COM NOVA INTERFACE
# =====================================================

menu_todos_tweaks() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}🔥 COMANDOS INDIVIDUAIS${RESET}"
        echo -e "${BOLD}${CYAN}────────────────────────────────────${RESET}"
        echo -e "${GREEN}🟢 ATIVO     ${RED}🔴 DESATIVADO${RESET}\n"

        printf " %b [01] ⏱ Tempo mínimo do toque\n" "$(icon check_setting secure tap_duration_threshold 60)"
        printf " %b [02] ⌛ Tempo do toque longo\n" "$(icon check_setting secure long_press_timeout 300)"
        printf " %b [03] ⚡ Toques rápidos (duplo / triplo)\n" "$(icon check_setting secure multi_press_timeout 130)"
        printf " %b [04] 🤖 Ações automáticas mais rápidas\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"
        printf " %b [05] 🖥 Toque no espelhamento\n" "$(icon check_setting global block_untrusted_touches 0)"
        printf " %b [06] 🚀 Desempenho do sistema\n" "$(icon check_setting global restricted_device_performance '0,0')"
        echo ""

        printf " %b [07] 🔌 USB RAW (sem filtro)\n" "$(icon check_prop vendor.usb.raw_input.enable 0)"
        printf " %b [08] ⚡ USB baixa latência\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
        printf " %b [09] 🎯 Prioridade HID\n" "$(icon check_prop vendor.usb.hid.priority 2)"
        printf " %b [10] 🚄 USB High Speed\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
        printf " %b [11] 🔋 Potência USB\n" "$(icon check_prop persist.vendor.usb.power 1)"
        printf " %b [12] 🔥 Boost hub USB\n" "$(icon check_prop vendor.usb.hub.boost 1)"
        printf " %b [13] 🖱 Anti-jitter mouse\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 0)"
        echo ""

        printf " %b [14] 🎯 Mouse linear (1:1)\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
        printf " %b [15] 🚫 Mouse sem aceleração\n" "$(check_mouse_acceleration)"
        printf " %b [16] ⚡ Input baixa latência\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
        echo ""

        printf " %b [17] 🚫 VSync desligado\n" "$(icon check_prop debug.hwui.disable_vsync 0)"
        printf " %b [18] 🎮 GPU baixa latência\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
        printf " %b [19] 🧩 GPU aceleração quadros\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
        echo ""

        printf " %b [20] 📱 Tela 120Hz fixo\n" "$(icon check_setting system peak_refresh_rate 120)"
        printf " %b [21] 🖥 Espelhamento otimizado\n" "$(icon check_prop persist.video.duplicate.display 1)"
        printf " %b [22] 📺 Prioridade vídeo externa\n" "$(icon check_prop vendor.display.external_priority 1)"
        echo ""

        printf " %b [23] 🎮 Gamepad baixa latência\n" "$(icon check_setting global gamepad.latency_reduction 1)"
        printf " %b [24] 🛣 Fastpath HID\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
        printf " %b [25] ⏱ IRQ USB baixa latência\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 0)"
        printf " %b [26] 🚀 Despacho rápido input\n" "$(icon check_prop persist.sys.input.dispatch_fast 0)"
        echo ""

        printf " %b [27] 🐞 Debug input low latency\n" "$(icon check_prop debug.input.low_latency 0)"
        echo ""

        printf " %b [28] 🚀 CPU boost persistente\n" "$(icon check_prop persist.sys.cpu.boost 1)"
        printf " %b [29] 🪟 Window Animation Scale\n" "$(icon check_setting global window_animation_scale 0)"
        printf " %b [30] 🔄 Transition Animation Scale\n" "$(icon check_setting global transition_animation_scale 0)"
        printf " %b [31] ⏱️ Animator Duration Scale\n" "$(icon check_setting global animator_duration_scale 0)"
        printf " %b [32] 🔄 Input Resample\n" "$(icon check_prop persist.sys.input.resample 0)"
        printf " %b [33] 🎯 Input Priority\n" "$(icon check_prop persist.sys.input.priority 1)"
        printf " %b [34] 🚫 Input Filter\n" "$(icon check_prop persist.sys.input.filter 0)"
        printf " %b [35] 🪟 Max Events per Sec\n" "$(icon check_prop windowsmgr.max_events_per_sec 120)"
        printf " %b [36] 🎥 Video Low Latency Path\n" "$(icon check_prop persist.video.low_latency_path 1)"
        
        echo -e "\n${BOLD}${CYAN}────────────────────────────────────${RESET}"
        
        if spoof_status; then
            SPOOF_ICON="${GREEN}🟢${RESET}"
        else
            SPOOF_ICON="${RED}🔴${RESET}"
        fi
        printf " %b [37] 🎯 Spoof 120 FPS\n" "$SPOOF_ICON"
        printf " ${RED}🔴${RESET} [38] ♻️  Reset total\n"
        
        echo -e "\n${BOLD}${CYAN}[0] ⬅️ Voltar${RESET}"
        echo ""
        read_prompt "➤ Selecione uma opção: " item

        case "$item" in
            01) toggle_tweak "Tempo mínimo do toque" "$submenu_1_cmd_on" "$submenu_1_cmd_off" ;;
            02) toggle_tweak "Tempo do toque longo" "$submenu_2_cmd_on" "$submenu_2_cmd_off" ;;
            03) toggle_tweak "Toques rápidos (duplo/triplo)" "$submenu_3_cmd_on" "$submenu_3_cmd_off" ;;
            04) toggle_tweak "Ações automáticas mais rápidas" "$submenu_4_cmd_on" "$submenu_4_cmd_off" ;;
            05) toggle_tweak "Permitir toques no espelhamento" "$submenu_5_cmd_on" "$submenu_5_cmd_off" ;;
            06) toggle_tweak "Desbloquear desempenho do sistema" "$submenu_6_cmd_on" "$submenu_6_cmd_off" ;;
            07) toggle_tweak "Entrada USB sem filtro (RAW)" "$submenu_7_cmd_on" "$submenu_7_cmd_off" ;;
            08) toggle_tweak "USB baixa latência" "$submenu_8_cmd_on" "$submenu_8_cmd_off" ;;
            09) toggle_tweak "Prioridade HID" "$submenu_9_cmd_on" "$submenu_9_cmd_off" ;;
            10) toggle_tweak "Modo High Speed USB" "$submenu_10_cmd_on" "$submenu_10_cmd_off" ;;
            11) toggle_tweak "Potência USB aprimorada" "$submenu_11_cmd_on" "$submenu_11_cmd_off" ;;
            12) toggle_tweak "Boost no hub USB" "$submenu_12_cmd_on" "$submenu_12_cmd_off" ;;
            13) toggle_tweak "Anti-jitter USB (mouse)" "$submenu_13_cmd_on" "$submenu_13_cmd_off" ;;
            14) toggle_tweak "Resposta linear do mouse (1:1)" "$submenu_14_cmd_on" "$submenu_14_cmd_off" ;;
            15) toggle_tweak "Aceleração do mouse desligada" "$submenu_15_cmd_on" "$submenu_15_cmd_off" ;;
            16) toggle_tweak "Input: baixa latência" "$submenu_17_cmd_on" "$submenu_17_cmd_off" ;;
            17) toggle_tweak "VSync desligado" "$submenu_20_cmd_on" "$submenu_20_cmd_off" ;;
            18) toggle_tweak "GPU: baixa latência" "$submenu_21_cmd_on" "$submenu_21_cmd_off" ;;
            19) toggle_tweak "GPU: aceleração de quadros" "$submenu_22_cmd_on" "$submenu_22_cmd_off" ;;
            20) toggle_tweak "Tela interna 120Hz (fixo)" "$submenu_23_cmd_on" "$submenu_23_cmd_off" ;;
            21) toggle_tweak "Duplicação (espelhamento) externa" "$submenu_25_cmd_on" "$submenu_25_cmd_off" ;;
            22) toggle_tweak "Prioridade de vídeo externa" "$submenu_26_cmd_on" "$submenu_26_cmd_off" ;;
            23) toggle_tweak "Gamepad: baixa latência" "$submenu_28_cmd_on" "$submenu_28_cmd_off" ;;
            24) toggle_tweak "Fastpath HID (rota direta)" "$submenu_31_cmd_on" "$submenu_31_cmd_off" ;;
            25) toggle_tweak "Interrupções USB baixa latência" "$submenu_36_cmd_on" "$submenu_36_cmd_off" ;;
            26) toggle_tweak "Despacho rápido de input" "$submenu_38_cmd_on" "$submenu_38_cmd_off" ;;
            27) toggle_tweak "Debug Input Low Latency" "$submenu_57_cmd_on" "$submenu_57_cmd_off" ;;
            28) toggle_tweak "Persist Sys CPU Boost" "$submenu_65_cmd_on" "$submenu_65_cmd_off" ;;
            29) toggle_tweak "Window Animation Scale" "$submenu_66_cmd_on" "$submenu_66_cmd_off" ;;
            30) toggle_tweak "Transition Animation Scale" "$submenu_67_cmd_on" "$submenu_67_cmd_off" ;;
            31) toggle_tweak "Animator Duration Scale" "$submenu_68_cmd_on" "$submenu_68_cmd_off" ;;
            32) toggle_tweak "Input Resample" "$submenu_32_cmd_on" "$submenu_32_cmd_off" ;;
            33) toggle_tweak "Input Priority" "$submenu_33_cmd_on" "$submenu_33_cmd_off" ;;
            34) toggle_tweak "Input Filter" "$submenu_34_cmd_on" "$submenu_34_cmd_off" ;;
            35) toggle_tweak "Max Events per Sec" "$submenu_35_cmd_on" "$submenu_35_cmd_off" ;;
            36) toggle_tweak "Video Low Latency Path" "$submenu_36_cmd_on" "$submenu_36_cmd_off" ;;
            37) submenu_spoof ;;
            38) submenu_reset ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida...${RESET}"; sleep 1 ;;
        esac
    done
}

# =====================================================
# 📐 CONFIGURADOR SIMPLIFICADO DE RESOLUÇÃO
# =====================================================

config_resolucao_dpi() {
    while true; do
        clear
        printf '\033c'
        echo -e "${BOLD}${CYAN}=== CONFIGURADOR DE RESOLUÇÃO ===${RESET}\n"
        
        CURRENT_RES=$(wm size 2>/dev/null | grep -oE "[0-9]+x[0-9]+" || echo "Desconhecido")
        CURRENT_DPI=$(wm density 2>/dev/null | grep -oE "[0-9]+" || echo "Desconhecido")
        
        echo -e "${YELLOW}⚙️  Configurações atuais:${RESET}"
        echo -e "📱 Resolução: ${GREEN}${CURRENT_RES}${RESET}"
        echo -e "🎯 DPI: ${GREEN}${CURRENT_DPI}${RESET}"
        echo ""
        
        echo "📋 OPÇÕES DE RESOLUÇÃO:"
        echo ""
        echo "1) 1080x1920 - DPI: 400"
        echo "2) 1440x2560 - DPI: 400"
        echo "3) Personalizado (digitar resolução e DPI)"
        echo ""
        echo "4) Restaurar configuração padrão"
        echo ""
        echo "0) Voltar"
        echo ""
        
        read_prompt "> " opcao_res
        
        case "$opcao_res" in
            1) nova_res="1080x1920"; nova_dpi="400" ;;
            2) nova_res="1440x2560"; nova_dpi="400" ;;
            3) 
                while true; do
                    read_prompt "Digite a resolução (ex: 720x1280): " nova_res
                    if echo "$nova_res" | grep -Eq '^[0-9]+x[0-9]+$'; then
                        break
                    else
                        echo -e "${RED}❌ Formato inválido! Use WxH (ex: 720x1280)${RESET}"
                    fi
                done
                
                while true; do
                    read_prompt "Digite o DPI (ex: 320): " nova_dpi
                    if echo "$nova_dpi" | grep -Eq '^[0-9]+$'; then
                        break
                    else
                        echo -e "${RED}❌ DPI inválido! Use apenas números${RESET}"
                    fi
                done
                ;;
            4) 
                restaurar_padrao_resolucao
                press_enter
                continue
                ;;
            0) return ;;
            *)
                echo -e "${RED}Opção inválida!${RESET}"
                sleep 1
                continue
                ;;
        esac
        
        aplicar_resolucao_dpi "$nova_res" "$nova_dpi"
        press_enter
    done
}

restaurar_padrao_resolucao() {
    echo -e "${CYAN}Restaurando configuração padrão do dispositivo...${RESET}"
    
    wm size reset
    wm density reset
    
    rm -f "$MODDIR/resolution_config" 2>/dev/null
    
    echo -e "${GREEN}✅ Configuração padrão restaurada!${RESET}"
    echo -e "${YELLOW}Alguns apps podem precisar ser reiniciados.${RESET}"
    
    sleep 2
}

aplicar_resolucao_dpi() {
    nova_res="$1"
    nova_dpi="$2"
    
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}=== APLICANDO CONFIGURAÇÃO ===${RESET}\n"
    
    echo -e "📱 ${GREEN}Nova Resolução: ${nova_res}${RESET}"
    echo -e "🎯 ${GREEN}Novo DPI: ${nova_dpi}${RESET}"
    
    echo -e "\n${YELLOW}Aplicando configuração...${RESET}"
    wm size "${nova_res}"
    wm density "${nova_dpi}"
    
    APPLIED_RES=$(wm size 2>/dev/null | grep -oE "[0-9]+x[0-9]+" || echo "")
    APPLIED_DPI=$(wm density 2>/dev/null | grep -oE "[0-9]+" || echo "")
    
    if [ "$APPLIED_RES" = "$nova_res" ] && [ "$APPLIED_DPI" = "$nova_dpi" ]; then
        echo -e "${GREEN}✅ Configuração aplicada com sucesso!${RESET}"
        
        RES_CONFIG_FILE="$MODDIR/resolution_config"
        echo "${nova_res}|${nova_dpi}" > "$RES_CONFIG_FILE"
        
        BOOT_FILE="$MODDIR/enable_on_boot"
        if [ -f "$BOOT_FILE" ]; then
            if ! grep -q "apply_resolution_on_boot" "$BOOT_FILE"; then
                echo "apply_resolution_on_boot" >> "$BOOT_FILE"
            fi
        fi
        
    else
        echo -e "${RED}❌ Erro ao aplicar configuração${RESET}"
        echo -e "${YELLOW}Aplicado: ${APPLIED_RES} (DPI: ${APPLIED_DPI})${RESET}"
    fi
}

apply_resolution_on_boot() {
    if [ -f "$MODDIR/resolution_config" ]; then
        config=$(cat "$MODDIR/resolution_config")
        nova_res=$(echo "$config" | cut -d'|' -f1)
        nova_dpi=$(echo "$config" | cut -d'|' -f2)
        
        if [ -n "$nova_res" ] && [ -n "$nova_dpi" ]; then
            sleep 3
            wm size "${nova_res}" 2>/dev/null
            wm density "${nova_dpi}" 2>/dev/null
        fi
    fi
}

# =====================================================
# MENU PRINCIPAL SEGURO
# =====================================================
menu() {
    # 🔴 VERIFICAÇÃO FORTIFICADA - Sempre verificar licença primeiro
    if ! verificar_integridade_licenca; then
        echo -e "${RED}⛔ ACESSO NEGADO: Licença inválida ou expirada${RESET}"
        echo -e "${YELLOW}Execute o script novamente para autenticar.${RESET}"
        sleep 3
        return 1
    fi
    
    # Depois verificar sessão (agora com licença válida)
    if ! verificar_sessao; then
        echo -e "${YELLOW}⚠️  Sessão expirada. Faça login novamente.${RESET}"
        sleep 2
        
        # Forçar novo login
        rm -f "$SESSION_FILE"
        return 1
    fi
    
    while true; do
        clear
        printf '\033c'
        
        # 🔴 VERIFICAÇÃO FORTIFICADA A CADA LOOP
        if ! verificar_integridade_licenca; then
            echo -e "${RED}⛔ ACESSO NEGADO: Licença inválida ou expirada${RESET}"
            echo -e "${YELLOW}Execute o script novamente para autenticar.${RESET}"
            sleep 3
            return 1
        fi

        check_license_warning

        # Título
        echo -e "\033[1;37m🔥 FERA ALPHA • ULTRA GAMER"
        echo -e "\033[1;37m────────────────────────────"
        
        # Status da licença
        if [ -f "$LICENSE_FILE" ]; then
            EXP=$(cat "$LICENSE_FILE" 2>/dev/null)
            NOW=$(date +%s)
            if echo "$EXP" | grep -qE '^[0-9]+$'; then
                DIFF=$((EXP - NOW))
                DAYS=$((DIFF / 86400))
                
                if [ "$DAYS" -gt 365 ]; then
                    STATUS_TEXT="Status: \033[1;37m🟢 Ativo | VIP ILIMITADO\033[0m"
                elif [ "$DAYS" -gt 0 ]; then
                    if [ "$DAYS" -lt 10 ]; then
                        STATUS_TEXT="Status: \033[1;31m🟢 Ativo | ⏳ $DAYS dias\033[0m"
                    else
                        STATUS_TEXT="Status: \033[1;37m🟢 Ativo | ⏳ $DAYS dias\033[0m"
                    fi
                else
                    STATUS_TEXT="Status: \033[1;31m🔴 Expirado\033[0m"
                fi
                echo -e "$STATUS_TEXT"
            else
                echo -e "Status: \033[1;31m🔴 Inválido\033[0m"
            fi
        else
            echo -e "Status: \033[1;31m🔴 Não ativo\033[0m"
        fi
        
        echo -e "\033[1;37m────────────────────────────\033[0m"
        echo ""
        
        # Seções do menu
        echo -e "\033[1;37m⚡ AÇÃO RÁPIDA\033[0m"
        echo -e "\033[1;37m[01] ⚡ Aplicar tudo\033[0m"
        echo -e "\033[1;37m[02] 🎛 Comandos individuais\033[0m"
        echo ""
        
        echo -e "\033[1;37m🚀 DESEMPENHO\033[0m"
        echo -e "\033[1;37m[03] 🚀 Performance Máxima\033[0m"
        echo -e "\033[1;37m[04] 🔥 Extremo (sem limites)\033[0m"
        echo ""
        
        echo -e "\033[1;37m🎮 JOGOS\033[0m"
        echo -e "\033[1;37m[05] 🎯 Spoof 120 FPS\033[0m"
        echo -e "\033[1;37m[06] 🖥 Resolução / DPI\033[0m"
        echo ""
        
        echo -e "\033[1;37m🧠 SISTEMA\033[0m"
        echo -e "\033[1;37m[07] 📊 Status do sistema\033[0m"
        echo -e "\033[1;37m[08] ⚙ Atualização\033[0m"
        echo -e "\033[1;37m[09] 🧹 Limpar cache\033[0m"
        echo ""
        
        echo -e "\033[1;37m🔄 MANUTENÇÃO\033[0m"
        echo -e "\033[1;37m[10] 🔄 Reiniciar\033[0m"
        echo -e "\033[1;37m[11] ♻ Reset geral\033[0m"
        echo ""
        
        echo -e "\033[1;37m[00] ❌ Sair\033[0m"
        echo -e "\033[1;37m────────────────────────────\033[0m"
        echo ""
        echo -n -e "\033[1;37m➤ Selecione uma opção: \033[0m"
        read op

        case "$op" in
            01) 
                sh "$0" --ativar-todos
                press_enter
                ;;
            02) 
                menu_todos_tweaks
                ;;
            03) 
                apply_safe_performance
                press_enter
                ;;
            04) 
                apply_extreme_performance
                press_enter
                ;;
            05) 
                submenu_spoof
                ;;
            06) 
                config_resolucao_dpi
                ;;
            07) 
                show_performance_status
                ;;
            08) 
                menu_config_update
                ;;
            09) 
                limpar_cache_simples
                ;;
            10) 
                reiniciar_dispositivo_simples
                ;;
            11) 
                submenu_reset
                ;;
            00) 
                echo -e "\033[1;37m👋 Saindo...\033[0m"
                exit 0
                ;;
            *) 
                echo -e "\033[1;31mOpção inválida\033[0m"
                sleep 1
                ;;
        esac
    done
}

# =====================================================
# FLUXO PRINCIPAL COM SEGURANÇA FORTIFICADA
# =====================================================

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INICIO: Script iniciado" > "$SECURITY_LOG"

verificacao_inicial

# ✅ CORREÇÃO: Sempre exigir verificação completa da licença
# A sessão só é válida se a licença estiver válida
if [ -f "$SESSION_FILE" ] && verificar_integridade_licenca; then
    # Verificar tempo da sessão
    SESSION_TIME=$(stat -c %Y "$SESSION_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    
    if [ $((NOW - SESSION_TIME)) -le 86400 ]; then
        echo -e "${GREEN}✅ Sessão válida detectada. Acessando painel...${RESET}"
        sleep 1
        menu
        exit 0
    else
        # Sessão expirada, remover arquivo
        rm -f "$SESSION_FILE"
        log_seguranca "SESSAO_EXPIRADA: Removendo sessão antiga"
    fi
fi

# Se chegou aqui, precisa fazer login
tent=0
MAX_TENT=3

while [ $tent -lt $MAX_TENT ]; do
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
    echo -e "\033[1;33mTentativas restantes: $((MAX_TENT-tent))\033[0m"
    
    log_seguranca "TENTATIVA_FALHA_$tent: Usuário=$USER"
    
    if [ $tent -ge $MAX_TENT ]; then
        echo -e "\033[1;31m🚫 Muitas tentativas falhas. Aguarde 60 segundos.\033[0m"
        log_seguranca "BLOQUEIO_TEMPORARIO: Muitas tentativas falhas"
        sleep 60
        tent=0
    else
        sleep 2
    fi
done

if [ $tent -ge $MAX_TENT ]; then
    echo -e "\033[1;31m❌ Falha ao autenticar. Saindo.\033[0m"
    log_seguranca "SAIDA: Autenticação falhou após $MAX_TENT tentativas"
    exit 1
fi

exit 0
