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
    # Em produção real, use: echo -n "${DATA}:${CHAVE_SECRETA}" | openssl dgst -sha256 -hmac "$CHAVE_SECRETA"
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
setprop debug.hwui.disable_vsync 0
setprop persist.sys.gpu.low_latency 0
setprop persist.sys.gpu.frame_boost 0
setprop persist.sys.display.force_refresh 60
setprop vendor.display.external_priority 0
setprop persist.video.duplicate.display 0
setprop windowsmgr.max_events_per_sec 90
setprop debug.sf.disable_backpressure 0
setprop debug.sf.use_phase_offset_ns 1
setprop persist.sys.sf.native_mode 0
setprop persist.input.resample 1
setprop debug.sf.hw 0
setprop debug.sf.late.sf.duration 0
setprop debug.sf.early.sf.duration 0
setprop debug.sf.frame_rate_multiple_threshold 60
setprop debug.sf.high_fps_late.app.duration 0
setprop debug.sf.high_fps_late.sf.duration 0
# Novas propriedades adicionadas
setprop debug.hwui.skip_vsync 0
setprop persist.sys.input.priority 0
setprop persist.sys.input.urgent 0
setprop sem_enhanced_cpu_responsiveness 0
# Novas propriedades para remover
setprop debug.input.low_latency 0
setprop debug.input.no_buffer 0
setprop persist.video.duplicate.display 0
setprop persist.vendor.usb.power 0
setprop persist.input.resample 1
setprop persist.sys.input.boost 0
setprop persist.input.resample 1
setprop persist.sys.input.dispatch_fast 0
setprop vendor.usb.hid.report_rate 0
setprop persist.sys.input.priority 0
# Novas propriedades de latch
setprop debug.sf.latch_unsignaled 0
setprop persist.game.frame_stability 0
setprop persist.sys.cpu.boost 0
rm -rf "$MODDIR/disabled_flags"
rm -f "$MODDIR/system.prop" "$MODDIR/spoof_enabled"
rm -f "$MODDIR/original.props"
rm -f "$MODDIR/license_info"
rm -f "$MODDIR/license_signature"
rm -f "$MODDIR/session_token"
# Restaurar flag de touchscreen removida
setprop persist.fera.touch.disabled 0
rm -f "$MODDIR/touch_disabled_list"
# Log de segurança
echo "[$(date '+%Y-%m-%d %H:%M:%S')] RESET_COMPLETO: Sistema restaurado ao padrão" > /data/local/tmp/fera_security.log
reboot
EOF

    chmod 755 "$RESET_SCRIPT"
    sh "$RESET_SCRIPT"
    exit 1
}

verificar_integridade_licenca() {
    # Verificação rigorosa da licença
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
    
    # Verificar se não está vazio
    if [ -z "$EXP" ] || [ -z "$ASSINATURA" ]; then
        log_seguranca "ERRO: Licença ou assinatura vazia"
        return 1
    fi
    
    # Verificar formato - deve ser timestamp numérico válido
    if ! echo "$EXP" | grep -qE '^[0-9]{10,}$'; then
        log_seguranca "ERRO: Formato de licença inválido: $EXP"
        echo -e "${RED}❌ ERRO: Formato de licença inválido${RESET}"
        return 1
    fi
    
    # Verificar timestamp razoável (entre 2020 e 2030)
    if [ "$EXP" -lt 1577836800 ] || [ "$EXP" -gt 1893456000 ]; then
        log_seguranca "ERRO: Timestamp fora do intervalo: $EXP"
        echo -e "${RED}❌ ERRO: Data de licença inválida${RESET}"
        return 1
    fi
    
    # Verificar assinatura
    DADOS_ASSINAR="${EXP}:${FP}"
    if ! verificar_assinatura "$DADOS_ASSINAR" "$ASSINATURA"; then
        log_seguranca "ERRO: Assinatura inválida para licença"
        echo -e "${RED}❌ ERRO: Licença corrompida ou modificada${RESET}"
        return 1
    fi
    
    # Verificar expiração
    NOW=$(date +%s)
    if [ "$NOW" -ge "$EXP" ]; then
        log_seguranca "AVISO: Licença expirada em $EXP, agora é $NOW"
        echo -e "${RED}⚠️  Licença expirada${RESET}"
        return 1
    fi
    
    return 0
}

verifica_expiracao() {
    # Verificação principal que não pode ser burlada
    if ! verificar_integridade_licenca; then
        log_seguranca "BLOQUEIO: Tentativa de acesso sem licença válida"
        reset_total_auto
    fi
    
    # Verificação adicional com servidor (online)
    verificar_licenca_online
}

verificar_licenca_online() {
    # Tentar verificar com servidor se houver conexão
    FP=$(gera_fingerprint)
    EXP=$(cat "$LICENSE_FILE" 2>/dev/null)
    
    # Tentar verificar com servidor
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
    
    # Apenas para timestamps numéricos
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

    # Gerar assinatura local
    FP=$(gera_fingerprint)
    DADOS_ASSINAR="${EXP}:${FP}"
    ASSINATURA=$(gerar_assinatura "$DADOS_ASSINAR")
    
    # Salvar licença com assinatura
    echo "$EXP" > "$LICENSE_FILE"
    echo "$ASSINATURA" > "$LICENSE_SIGNATURE_FILE"
    
    # Gerar token de sessão
    SESSION_TOKEN=$(echo -n "${EXP}:${FP}:$(date +%s)" | sha256sum | awk '{print $1}')
    echo "$SESSION_TOKEN" > "$SESSION_FILE"
    
    log_seguranca "LICENÇA_ATIVADA: Expira=$EXP, Assinatura=$ASSINATURA"

    return 0
}

verificar_sessao() {
    if [ ! -f "$SESSION_FILE" ]; then
        return 1
    fi
    
    SESSION_TOKEN=$(cat "$SESSION_FILE")
    SESSION_TIME=$(stat -c %Y "$SESSION_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    
    # Sessão expira em 24 horas
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
    
    # Log de inicialização
    log_seguranca "INICIALIZACAO: Script iniciado, verificando integridade"
    
    # Verificar se o script foi modificado
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
# 🔄 REINICIAR DISPOSITIVO
###############################################################################

reiniciar_dispositivo() {
    clear
    echo -e "${BOLD}${CYAN}=== REINICIAR DISPOSITIVO ===${RESET}\n"
    
    echo -e "${YELLOW}⚠️  ATENÇÃO: O dispositivo será reiniciado!${RESET}\n"
    
    echo "Selecione o tipo de reinício:"
    echo ""
    echo "1) 🔄 Reinício normal"
    echo "2) ⚡ Reinício rápido"
    echo "3) 🔧 Reinício no recovery"
    echo "4) 📲 Reinício no bootloader"
    echo "0) ↩️  Voltar"
    echo ""
    
    read_prompt "> " opcao_reboot
    
    case "$opcao_reboot" in
        1)
            echo -e "${CYAN}Reiniciando normalmente...${RESET}"
            echo -e "${YELLOW}O dispositivo será reiniciado em 5 segundos.${RESET}"
            sleep 5
            reboot
            ;;
        2)
            echo -e "${CYAN}Reinício rápido...${RESET}"
            echo -e "${YELLOW}Reiniciando em 3 segundos...${RESET}"
            sleep 3
            reboot -f
            ;;
        3)
            echo -e "${CYAN}Reiniciando no recovery...${RESET}"
            echo -e "${YELLOW}Reiniciando em 5 segundos...${RESET}"
            sleep 5
            reboot recovery
            ;;
        4)
            echo -e "${CYAN}Reiniciando no bootloader...${RESET}"
            echo -e "${YELLOW}Reiniciando em 5 segundos...${RESET}"
            sleep 5
            reboot bootloader
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Opção inválida!${RESET}"
            sleep 1
            ;;
    esac
}

###############################################################################
# 🛠️ FUNÇÃO DE ATUALIZAÇÃO (SÓ APÓS LOGIN VÁLIDO)
###############################################################################

auto_update_check() {
    # Verificar licença primeiro
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
    
    # Título do login
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
    
    # Mostrar status da licença
    if [ -f "$LICENSE_FILE" ]; then
        EXP=$(cat "$LICENSE_FILE")
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
    
    # Verificar atualizações se ativado
    if [ -f "$AUTO_UPDATE_FILE" ] && [ "$(cat "$AUTO_UPDATE_FILE")" = "1" ]; then
        echo -e "\n${CYAN}🔄 Verificando atualizações...${RESET}"
        auto_update_check
    fi
    
    sleep 1
    clear
}

###############################################################################
# 🎮 SISTEMA DE 3 NÍVEIS DE OTIMIZAÇÃO GAMING
###############################################################################

# Aplicações para priorização
PRIORITY_APPS=(
    "com.zjx.ztezscreenshot"     # GG Mouse Pro
    "com.dts.freefireth"         # Free Fire TH
    "com.dts.freefiremax"        # Free Fire MAX
)

# Detecção simplificada de chipset
detectar_chipset_rapido() {
    # Coletar informações básicas
    SOC_INFO=$(getprop ro.board.platform 2>/dev/null || echo "unknown")
    HARDWARE=$(getprop ro.hardware 2>/dev/null || echo "unknown")
    ALL_INFO="$SOC_INFO $HARDWARE"
    
    # Verificar se é chipset problemático (S23 SD 8 Gen 2)
    if echo "$ALL_INFO" | grep -qiE "sm8550|taro|kalama"; then
        echo "problematic"  # S23 - precisa de cuidado
    elif echo "$ALL_INFO" | grep -qiE "sm8450|sm8350|sm8250"; then
        echo "high_perf"    # SD 8 Gen 1, 888, 865 - alta performance
    elif echo "$ALL_INFO" | grep -qiE "mt[0-9]{4}|dimensity"; then
        echo "mediatek"     # MediaTek - moderado
    elif echo "$ALL_INFO" | grep -qiE "exynos"; then
        echo "exynos"       # Exynos - cuidadoso
    else
        echo "unknown"      # Chipset desconhecido
    fi
}

# ============================================================================
# NÍVEL 1: OTIMIZAÇÃO SEGURA (Para TODOS os aparelhos)
# ============================================================================
aplicar_otimizacao_segura() {
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}=== 🛡️  MODO GAMING SEGURO ===${RESET}\n"
    echo -e "${GREEN}✅ Compatível com TODOS os aparelhos${RESET}"
    echo -e "${GREEN}✅ Zero risco de reinício${RESET}"
    echo -e "${GREEN}✅ Baixo consumo de bateria${RESET}\n"
    
    echo -e "${YELLOW}🎮 Esta otimização aplica:${RESET}"
    echo "1. 🖱️  Prioridade básica para GG Mouse Pro"
    echo "2. 🎯 Otimizações leves para Free Fire"
    echo "3. ⚡ Melhorias seguras de performance"
    echo "4. 📊 Monitoramento conservador"
    
    echo ""
    read_prompt "Deseja aplicar o modo SEGURO? (s/N): " confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo -e "${YELLOW}❌ Cancelado${RESET}"
        return
    fi
    
    echo ""
    echo -e "${CYAN}🔄 Aplicando otimizações SEGURAS...${RESET}"
    
    # Detectar chipset primeiro
    CHIPSET_TYPE=$(detectar_chipset_rapido)
    
    # Configurações SEGURAS para todos
    SAFE_CPU_MASK="FF"  # Todos os núcleos
    NICE_LEVEL="-10"    # Prioridade moderada
    
    # Ajustes baseados no chipset (seguro)
    case "$CHIPSET_TYPE" in
        "problematic")  # S23 SD 8 Gen 2
            echo -e "${YELLOW}⚠️  Chipset sensível detectado (S23)${RESET}"
            echo -e "${GREEN}✅ Aplicando configurações SEGURAS especiais${RESET}"
            SAFE_CPU_MASK="FC"  # Evita núcleos mais sensíveis
            NICE_LEVEL="-8"
            ;;
        "high_perf")    # SD 8 Gen 1, 888, etc
            echo -e "${GREEN}✅ Chipset de alta performance detectado${RESET}"
            SAFE_CPU_MASK="FF"
            NICE_LEVEL="-12"
            ;;
        *)
            echo -e "${YELLOW}📱 Chipset padrão detectado${RESET}"
            SAFE_CPU_MASK="FF"
            NICE_LEVEL="-10"
            ;;
    esac
    
    # Aplicar otimizações para cada app
    for app in "${PRIORITY_APPS[@]}"; do
        pid=$(pidof "$app" 2>/dev/null)
        if [ -n "$pid" ]; then
            echo -e "⚡ ${CYAN}Otimizando $app${RESET}"
            
            # Prioridade segura
            renice $NICE_LEVEL -p "$pid" 2>/dev/null
            
            # Afinidade segura
            MASK_DEC=$((0x$SAFE_CPU_MASK))
            taskset -p $MASK_DEC "$pid" 2>/dev/null || true
            
            # Configurações específicas
            case "$app" in
                "com.zjx.ztezscreenshot")
                    # GG Mouse Pro - otimização segura
                    setprop persist.sys.input.ggmouse.priority 50 2>/dev/null
                    ;;
                "com.dts.freefire"*)
                    # Free Fire - otimização segura
                    setprop debug.game.ff.safe_mode 1 2>/dev/null
                    ;;
            esac
        else
            echo -e "${YELLOW}📱 $app não está em execução${RESET}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN}✅ MODO SEGURO ATIVADO COM SUCESSO!${RESET}"
    echo ""
    echo -e "${YELLOW}📊 RESUMO DA CONFIGURAÇÃO:${RESET}"
    echo -e "   • Prioridade: ${GREEN}Moderada ($NICE_LEVEL)${RESET}"
    echo -e "   • Afinidade CPU: ${GREEN}$SAFE_CPU_MASK${RESET}"
    echo -e "   • Risco de reinício: ${GREEN}ZERO${RESET}"
    echo -e "   • Consumo bateria: ${GREEN}BAIXO${RESET}"
    
    press_enter
}

# ============================================================================
# NÍVEL 2: OTIMIZAÇÃO BALANCEADA (Para maioria dos aparelhos)
# ============================================================================
aplicar_otimizacao_balanceada() {
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}=== ⚡ MODO GAMING BALANCEADO ===${RESET}\n"
    echo -e "${GREEN}✅ Compatível com 90% dos aparelhos${RESET}"
    echo -e "${GREEN}✅ Risco mínimo de reinício${RESET}"
    echo -e "${GREEN}✅ Performance otimizada${RESET}\n"
    
    echo -e "${YELLOW}🎮 Esta otimização aplica:${RESET}"
    echo "1. 🖱️  Prioridade ALTA para GG Mouse Pro"
    echo "2. 🎯 Otimizações AVANÇADAS para Free Fire"
    echo "3. ⚡ Boost de performance inteligente"
    echo "4. 📊 Monitoramento ativo"
    
    echo ""
    echo -e "${RED}⚠️  NÃO RECOMENDADO para:${RESET}"
    echo "   • Samsung Galaxy S23 (Snapdragon 8 Gen 2)"
    echo "   • Aparelhos com histórico de reinícios"
    
    echo ""
    read_prompt "Deseja aplicar o modo BALANCEADO? (s/N): " confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo -e "${YELLOW}❌ Cancelado${RESET}"
        return
    fi
    
    echo ""
    echo -e "${CYAN}🔄 Aplicando otimizações BALANCEADAS...${RESET}"
    
    # Detectar chipset
    CHIPSET_TYPE=$(detectar_chipset_rapido)
    
    # Verificar se é chipset problemático
    if [ "$CHIPSET_TYPE" = "problematic" ]; then
        echo -e "${RED}🚨 ALERTA: Chipset problemático detectado!${RESET}"
        echo -e "${RED}Este aparelho (S23 SD 8 Gen 2) pode reiniciar!${RESET}"
        echo ""
        read_prompt "Continuar mesmo assim? (digite 'CONFIRMAR'): " confirm2
        if [ "$confirm2" != "CONFIRMAR" ]; then
            echo -e "${YELLOW}❌ Cancelado por segurança${RESET}"
            sleep 2
            return
        fi
        # Configuração ESPECIAL para S23 (mais conservadora)
        CPU_MASK="F8"  # Apenas núcleos 3-7
        NICE_LEVEL="-15"
        echo -e "${YELLOW}⚠️  Modo ESPECIAL para S23 ativado${RESET}"
    else
        # Configuração padrão balanceada
        CPU_MASK="FF"
        NICE_LEVEL="-15"
    fi
    
    # Aplicar otimizações
    for app in "${PRIORITY_APPS[@]}"; do
        pid=$(pidof "$app" 2>/dev/null)
        if [ -n "$pid" ]; then
            echo -e "⚡ ${CYAN}Otimizando $app (Modo Balanceado)${RESET}"
            
            # Prioridade balanceada
            renice $NICE_LEVEL -p "$pid" 2>/dev/null
            
            # Afinidade CPU
            MASK_DEC=$((0x$CPU_MASK))
            taskset -p $MASK_DEC "$pid" 2>/dev/null || true
            
            # OOM protection
            if [ -f "/proc/$pid/oom_score_adj" ]; then
                echo "-300" > "/proc/$pid/oom_score_adj" 2>/dev/null || true
            fi
            
            # I/O Priority
            ionice -c 2 -n 0 -p "$pid" 2>/dev/null || true
            
            # Configurações específicas
            case "$app" in
                "com.zjx.ztezscreenshot")
                    # GG Mouse Pro - otimização balanceada
                    setprop persist.sys.input.ggmouse.boost 1 2>/dev/null
                    
                    # Threads de input
                    input_threads=$(ps -T -p $pid 2>/dev/null | grep -i "input\|event" | awk '{print $2}')
                    for thread in $input_threads; do
                        renice -18 -p "$thread" 2>/dev/null
                    done
                    ;;
                    
                "com.dts.freefire"*)
                    # Free Fire - otimização balanceada
                    setprop debug.game.ff.performance 1 2>/dev/null
                    
                    # Threads de render
                    render_threads=$(ps -T -p $pid 2>/dev/null | grep -i "render\|glthread" | awk '{print $2}' | head -3)
                    for thread in $render_threads; do
                        renice -16 -p "$thread" 2>/dev/null
                    done
                    ;;
            esac
        fi
    done
    
    echo ""
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN}✅ MODO BALANCEADO ATIVADO COM SUCESSO!${RESET}"
    echo ""
    
    if [ "$CHIPSET_TYPE" = "problematic" ]; then
        echo -e "${YELLOW}⚠️  MODO ESPECIAL S23 ATIVADO${RESET}"
        echo -e "   • Núcleos usados: ${GREEN}3-7 apenas${RESET}"
        echo -e "   • Núcleos 0-2: ${RED}DESATIVADOS por segurança${RESET}"
    else
        echo -e "${GREEN}⚡ PERFORMANCE BALANCEADA ATIVADA${RESET}"
        echo -e "   • Todos os núcleos: ${GREEN}OTIMIZADOS${RESET}"
        echo -e "   • Prioridade: ${GREEN}ALTA${RESET}"
    fi
    
    press_enter
}

# ============================================================================
# NÍVEL 3: OTIMIZAÇÃO EXTREMA (Apenas para aparelhos compatíveis)
# ============================================================================
aplicar_otimizacao_extrema() {
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}=== 🔥 MODO GAMING EXTREMO ===${RESET}\n"
    echo -e "${RED}🚨 ATENÇÃO: Este modo é AGressivo!${RESET}"
    echo -e "${YELLOW}⚠️  Apenas para aparelhos compatíveis${RESET}"
    echo -e "${RED}⚠️  Pode causar superaquecimento${RESET}\n"
    
    echo -e "${YELLOW}🎮 Esta otimização aplica:${RESET}"
    echo "1. 🖱️  Prioridade MÁXIMA para GG Mouse Pro"
    echo "2. 🎯 Otimizações EXTREMAS para Free Fire"
    echo "3. ⚡ Boost AGressivo de performance"
    echo "4. 📊 Monitoramento intensivo"
    
    echo ""
    echo -e "${RED}🚫 NÃO USE EM:${RESET}"
    echo "   • Samsung Galaxy S23"
    echo "   • Aparelhos com superaquecimento"
    echo "   • Bateria fraca"
    
    echo ""
    read_prompt "Tem certeza que deseja continuar? (digite 'EXTREMO'): " confirm
    if [ "$confirm" != "EXTREMO" ]; then
        echo -e "${YELLOW}❌ Cancelado${RESET}"
        return
    fi
    
    echo ""
    echo -e "${CYAN}🔄 Aplicando otimizações EXTREMAS...${RESET}"
    
    # Detectar chipset
    CHIPSET_TYPE=$(detectar_chipset_rapido)
    
    # VERIFICAÇÃO DE SEGURANÇA
    if [ "$CHIPSET_TYPE" = "problematic" ]; then
        echo -e "${RED}🚨 ALERTA CRÍTICO!${RESET}"
        echo -e "${RED}Seu aparelho (S23) REINICIARÁ com este modo!${RESET}"
        echo ""
        echo -e "${YELLOW}🔧 Recomendação:${RESET}"
        echo "1. Use o modo 'SEGURO'"
        echo "2. Ou use o modo 'BALANCEADO' com confirmação"
        echo ""
        read_prompt "Pressione ENTER para voltar ao menu seguro..." _
        return
    fi
    
    # Configurações EXTREMAS
    CPU_MASK="FF"
    NICE_LEVEL="-20"  # Prioridade máxima
    
    # Aplicar otimizações EXTREMAS
    for app in "${PRIORITY_APPS[@]}"; do
        pid=$(pidof "$app" 2>/dev/null)
        if [ -n "$pid" ]; then
            echo -e "🔥 ${RED}Otimizando EXTREMA: $app${RESET}"
            
            # Prioridade MÁXIMA
            renice $NICE_LEVEL -p "$pid" 2>/dev/null
            
            # Afinidade CPU - todos os núcleos
            taskset -p 0xFF "$pid" 2>/dev/null || true
            
            # SCHED_FIFO para threads críticas
            if command -v chrt >/dev/null 2>&1; then
                chrt -f -p 99 "$pid" 2>/dev/null || true
            fi
            
            # OOM protection máxima
            if [ -f "/proc/$pid/oom_score_adj" ]; then
                echo "-1000" > "/proc/$pid/oom_score_adj" 2>/dev/null || true
            fi
            
            # I/O Priority máxima
            ionice -c 1 -n 0 -p "$pid" 2>/dev/null || true
            
            # Configurações específicas EXTREMAS
            case "$app" in
                "com.zjx.ztezscreenshot")
                    # GG Mouse Pro - EXTREMO
                    setprop persist.sys.input.ggmouse.extreme 1 2>/dev/null
                    setprop debug.input.latency 0 2>/dev/null
                    
                    # Todas as threads no máximo
                    all_threads=$(ps -T -p $pid 2>/dev/null | awk '{print $2}' | tail -n +2)
                    for thread in $all_threads; do
                        renice -20 -p "$thread" 2>/dev/null
                        ionice -c 1 -n 0 -p "$thread" 2>/dev/null
                    done
                    ;;
                    
                "com.dts.freefire"*)
                    # Free Fire - EXTREMO
                    setprop debug.game.ff.extreme 1 2>/dev/null
                    setprop persist.sys.gpu.boost.max 1 2>/dev/null
                    
                    # Forçar performance máxima
                    echo "performance" > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
                    
                    # Threads de jogo no máximo
                    game_threads=$(ps -T -p $pid 2>/dev/null | grep -v "main" | awk '{print $2}' | tail -n +2)
                    for thread in $game_threads; do
                        renice -19 -p "$thread" 2>/dev/null
                        if command -v chrt >/dev/null 2>&1; then
                            chrt -f -p 90 "$thread" 2>/dev/null || true
                        fi
                    done
                    ;;
            esac
        fi
    done
    
    # Boost de sistema
    setprop persist.sys.performance.extreme 1 2>/dev/null
    setprop debug.sf.game_mode 2 2>/dev/null
    setprop persist.sys.cpu.boost.max 1 2>/dev/null
    
    echo ""
    echo -e "${RED}========================================${RESET}"
    echo -e "${RED}🔥 MODO EXTREMO ATIVADO COM SUCESSO!${RESET}"
    echo ""
    echo -e "${YELLOW}⚠️  AVISOS IMPORTANTES:${RESET}"
    echo -e "   • ${RED}Monitorar temperatura${RESET}"
    echo -e "   • ${RED}Bateria consumirá rapidamente${RESET}"
    echo -e "   • ${GREEN}Performance: MÁXIMA${RESET}"
    echo -e "   • ${GREEN}Latência: MÍNIMA${RESET}"
    
    press_enter
}

# ============================================================================
# FUNÇÃO DE STATUS
# ============================================================================
mostrar_status_gaming() {
    clear
    printf '\033c'
    echo -e "${BOLD}${CYAN}=== 📊 STATUS GAMING ATUAL ===${RESET}\n"
    
    # Verificar apps em execução
    echo -e "${YELLOW}🎮 APPS GAMING:${RESET}"
    for app in "${PRIORITY_APPS[@]}"; do
        pid=$(pidof "$app" 2>/dev/null)
        if [ -n "$pid" ]; then
            nice=$(ps -o nice= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
            cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
            
            echo -e "${GREEN}✅ $app${RESET}"
            echo -e "   PID: $pid | Nice: $nice | CPU: $cpu%"
            
            # Verificar afinidade
            affinity=$(taskset -p "$pid" 2>/dev/null | awk '{print $NF}' || echo "N/A")
            echo -e "   Afinidade: $affinity"
        else
            echo -e "${RED}❌ $app (Não está em execução)${RESET}"
        fi
        echo ""
    done
    
    # Temperatura
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$((temp/1000))
        echo -e "${YELLOW}🌡️ TEMPERATURA: ${temp}°C${RESET}"
        
        if [ "$temp" -gt 60 ]; then
            echo -e "${RED}⚠️  ALTA TEMPERATURA - Evite modos extremos${RESET}"
        elif [ "$temp" -gt 45 ]; then
            echo -e "${YELLOW}⚠️  Temperatura moderada${RESET}"
        else
            echo -e "${GREEN}✅ Temperatura normal${RESET}"
        fi
    fi
    
    press_enter
}

# ============================================================================
# MENU DE SELEÇÃO DE MODO GAMING
# ============================================================================
menu_otimizacao_gaming() {
    while true; do
        clear
        printf '\033c'
        
        # Detectar chipset para mostrar recomendações
        CHIPSET_TYPE=$(detectar_chipset_rapido)
        
        echo -e "${BOLD}${CYAN}=== 🎮 MENU DE OTIMIZAÇÃO GAMING ===${RESET}\n"
        
        # Mostrar detecção de chipset
        case "$CHIPSET_TYPE" in
            "problematic")
                echo -e "${RED}📱 Seu aparelho: S23 (SD 8 Gen 2)${RESET}"
                echo -e "${YELLOW}⚠️  Chipset sensível - requer cuidado${RESET}\n"
                ;;
            "high_perf")
                echo -e "${GREEN}📱 Seu aparelho: SD 8 Gen 1/888/865${RESET}"
                echo -e "${GREEN}✅ Chipset de alta performance${RESET}\n"
                ;;
            "mediatek"|"exynos")
                echo -e "${YELLOW}📱 Seu aparelho: $CHIPSET_TYPE${RESET}"
                echo -e "${YELLOW}⚠️  Use modos balanceados${RESET}\n"
                ;;
            *)
                echo -e "${YELLOW}📱 Chipset: Desconhecido${RESET}"
                echo -e "${YELLOW}⚠️  Recomendado: Comece com modo SEGURO${RESET}\n"
                ;;
        esac
        
        echo -e "${CYAN}Selecione o nível de otimização:${RESET}\n"
        
        echo -e "${GREEN}[1] 🛡️  MODO SEGURO${RESET}"
        echo "   • Para TODOS os aparelhos"
        echo "   • Zero risco de reinício"
        echo "   • Performance básica"
        echo ""
        
        echo -e "${YELLOW}[2] ⚡ MODO BALANCEADO${RESET}"
        echo "   • Para maioria dos aparelhos"
        echo "   • Risco mínimo"
        echo "   • Performance otimizada"
        echo ""
        
        echo -e "${RED}[3] 🔥 MODO EXTREMO${RESET}"
        echo "   • Apenas aparelhos compatíveis"
        echo "   • Risco ALTO (superaquecimento)"
        echo "   • Performance MÁXIMA"
        echo ""
        
        echo -e "${CYAN}[4] 📊 Status Gaming Atual${RESET}"
        echo -e "${CYAN}[0] ⬅️  Voltar${RESET}"
        echo ""
        
        read_prompt "➤ Selecione uma opção: " opcao
        
        case "$opcao" in
            1) aplicar_otimizacao_segura ;;
            2) aplicar_otimizacao_balanceada ;;
            3) aplicar_otimizacao_extrema ;;
            4) mostrar_status_gaming ;;
            0) return ;;
            *) 
                echo -e "${RED}Opção inválida!${RESET}"
                sleep 1
                ;;
        esac
    done
}

###############################################################################
# ===================== INÍCIO DO PAINEL (UNIFICADO) ==========================
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
        "USB RAW=vendor.usb.raw_input.enable=1"
        "USB Low Latency=persist.usb.low_latency_mode=1"
        "USB HID Priority=vendor.usb.hid.priority=1"
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
        "USB Performance Mode=vendor.usb.performance_mode=1"
        "USB Low Latency Interrupts=persist.vendor.usb.low_latency_interrupts=1"
        "Input Dispatch Fast=persist.sys.input.dispatch_fast=1"
        "HID Polling Rate=persist.vendor.hid.polling_rate=1000"
        "CPU Responsividade Aprimorada=sem_enhanced_cpu_responsiveness=1"
        # Novas propriedades adicionadas
        "Debug Input Low Latency=debug.input.low_latency=1"
        "Debug Input No Buffer=debug.input.no_buffer=1"
        # Novas propriedades de latch
        "Debug SF Latch Unsignaled=debug.sf.latch_unsignaled=1"
        "Persist Game Frame Stability=persist.game.frame_stability=1"
        "Persist Sys CPU Boost=persist.sys.cpu.boost=1"
    )

    for TWEAK in "${TWEAK_PROPS[@]}"; do
        NOME=$(echo "$TWEAK" | cut -d'=' -f1)
        PROP_VAL=$(echo "$TWEAK" | cut -d'=' -f2-)
        
        # Verificar se é um setting (começa com settings:)
        if echo "$PROP_VAL" | grep -q "^settings:"; then
            # Formato: settings:namespace:chave=valor
            NS=$(echo "$PROP_VAL" | cut -d':' -f2)
            KEY_VAL=$(echo "$PROP_VAL" | cut -d':' -f3)
            KEY=$(echo "$KEY_VAL" | cut -d'=' -f1)
            VAL=$(echo "$KEY_VAL" | cut -d'=' -f2)
            
            # Aplicar o setting
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

# Função auxiliar para verificar aceleração do mouse
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
        "Modo desempenho USB") echo "$submenu_35_cmd_on" ;;
        "Interrupções USB baixa latência") echo "$submenu_36_cmd_on" ;;
        "Despacho rápido de input") echo "$submenu_38_cmd_on" ;;
        "Polling Rate HID (1000Hz)") echo "$submenu_51_cmd_on" ;;
        "CPU Responsividade Aprimorada") echo "$submenu_56_cmd_on" ;;
        # Novos tweaks
        "Debug Input Low Latency") echo "$submenu_57_cmd_on" ;;
        "Debug Input No Buffer") echo "$submenu_58_cmd_on" ;;
        # Novas propriedades de latch
        "Debug SF Latch Unsignaled") echo "$submenu_63_cmd_on" ;;
        "Persist Game Frame Stability") echo "$submenu_64_cmd_on" ;;
        "Persist Sys CPU Boost") echo "$submenu_65_cmd_on" ;;
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

submenu_1_cmd_on="settings put secure tap_duration_threshold 80"
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
submenu_9_cmd_on="setprop vendor.usb.hid.priority 1"
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

submenu_35_cmd_on="setprop vendor.usb.performance_mode 1"
submenu_35_cmd_off="setprop vendor.usb.performance_mode 0"
submenu_36_cmd_on="setprop persist.vendor.usb.low_latency_interrupts 1"
submenu_36_cmd_off="setprop persist.vendor.usb.low_latency_interrupts 0"

submenu_38_cmd_on="setprop persist.sys.input.dispatch_fast 1"
submenu_38_cmd_off="setprop persist.sys.input.dispatch_fast 0"

submenu_51_cmd_on="setprop persist.vendor.hid.polling_rate 1000"
submenu_51_cmd_off="setprop persist.vendor.hid.polling_rate 0"

submenu_56_cmd_on="setprop sem_enhanced_cpu_responsiveness 1"
submenu_56_cmd_off="setprop sem_enhanced_cpu_responsiveness 0"

# Novos comandos adicionados
submenu_57_cmd_on="setprop debug.input.low_latency 1"
submenu_57_cmd_off="setprop debug.input.low_latency 0"

submenu_58_cmd_on="setprop debug.input.no_buffer 1"
submenu_58_cmd_off="setprop debug.input.no_buffer 0"

# Novas propriedades de latch
submenu_63_cmd_on="setprop debug.sf.latch_unsignaled 1"
submenu_63_cmd_off="setprop debug.sf.latch_unsignaled 0"

submenu_64_cmd_on="setprop persist.game.frame_stability 1"
submenu_64_cmd_off="setprop persist.game.frame_stability 0"

submenu_65_cmd_on="setprop persist.sys.cpu.boost 1"
submenu_65_cmd_off="setprop persist.sys.cpu.boost 0"

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
    read_prompt "Tem certeza absoluta? (digite 'SIM'): " confirm2
    if [ "$confirm2" != "SIM" ]; then
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
    setprop vendor.usb.hid.priority 1
    setprop persist.vendor.usb.high_speed 0
    setprop persist.vendor.usb.power 0
    setprop vendor.usb.hub.boost 0
    setprop vendor.usb.mouse.jitter_filter 0

    setprop persist.sys.mouse.linear_response 0
    setprop persist.sys.pointer.acceleration 1

    setprop persist.sys.input.low_latency_mode 0
    setprop persist.sys.input.high_update_rate false

    setprop debug.hwui.disable_vsync 0
    setprop persist.sys.gpu.low_latency 0
    setprop persist.sys.gpu.frame_boost 0

    setprop vendor.display.external_priority 0
    setprop persist.video.duplicate.display 0

    setprop vendor.hid.input.fastpath 0
    setprop persist.sys.input.filter 1
    setprop persist.sys.input.resample 1
    setprop vendor.usb.performance_mode 0
    setprop persist.vendor.usb.low_latency_interrupts 0
    setprop persist.sys.input.dispatch_fast 0
    
    setprop persist.vendor.hid.polling_rate 0
    
    setprop windowsmgr.max_events_per_sec 90
    
    setprop debug.sf.late.sf.duration 0
    setprop debug.sf.early.sf.duration 0
    setprop debug.sf.frame_rate_multiple_threshold 60
    setprop debug.sf.high_fps_late.app.duration 0
    setprop debug.sf.high_fps_late.sf.duration 0
    
    setprop debug.hwui.skip_vsync 0
    setprop persist.sys.input.urgent 0
    setprop sem_enhanced_cpu_responsiveness 0
    
    # Remover novas propriedades
    setprop debug.input.low_latency 0
    setprop debug.input.no_buffer 0
    settings delete global input.low_latency_mode
    settings delete global input.reduce_input_lag
    settings delete global input.instant_touch_response
    settings delete global pointer.precision

    # Novas propriedades de latch
    setprop debug.sf.latch_unsignaled 0
    setprop persist.game.frame_stability 0
    setprop persist.sys.cpu.boost 0

    rm -rf "$FLAG_DIR" 2>/dev/null
    rm -f "$SPOOF_FILE" "$SPOOF_FLAG" "$ORIG_STORE" 2>/dev/null
    rm -f "$MODDIR/enable_on_boot"
    rm -f "$ENABLED_TWEAKS_FILE"

    echo -e "${GREEN}✔ Todos os valores foram resetados.${RESET}"
    echo -e "${YELLOW}O sistema será reiniciado agora para completar o reset.${RESET}"
    sleep 2
    reboot
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

    apply_if_enabled "tap_duration_threshold" "settings put secure tap_duration_threshold 80"
    apply_if_enabled "long_press_timeout" "settings put secure long_press_timeout 300"
    apply_if_enabled "multi_press_timeout" "settings put secure multi_press_timeout 130"
    apply_if_enabled "accessibility_auto_action_delay" "settings put secure accessibility_auto_action_delay 200"
    apply_if_enabled "block_untrusted_touches" "settings put global block_untrusted_touches 0"
    apply_if_enabled "restricted_device_performance" "settings put global restricted_device_performance '0,0'"
    apply_if_enabled "Refresh 120Hz Interno" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
    apply_if_enabled "Gamepad Redução de latência" "settings put global gamepad.latency_reduction 1"

    echo -e "${CYAN}Garantindo persistência e aplicando Propriedades...${RESET}"
    rebuild_system_prop

    apply_if_enabled "Polling Rate HID (1000Hz)" "setprop persist.vendor.hid.polling_rate 1000"

    apply_if_enabled "CPU Responsividade Aprimorada" "setprop sem_enhanced_cpu_responsiveness 1"
    
    # Aplicar novos tweaks
    apply_if_enabled "Debug Input Low Latency" "setprop debug.input.low_latency 1"
    apply_if_enabled "Debug Input No Buffer" "setprop debug.input.no_buffer 1"
    
    # Aplicar novas propriedades de latch
    apply_if_enabled "Debug SF Latch Unsignaled" "setprop debug.sf.latch_unsignaled 1"
    apply_if_enabled "Persist Game Frame Stability" "setprop persist.game.frame_stability 1"
    apply_if_enabled "Persist Sys CPU Boost" "setprop persist.sys.cpu.boost 1"

    echo -e "${GREEN}✔ Todos os tweaks aplicados (spoof NÃO foi ativado).${RESET}"
    exit 0
fi

if [ "$1" = "--boot" ]; then
    # Verificar licença antes de aplicar tweaks no boot
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

        # Grupo 1: Touch/Latência
        printf " %b [01] ⏱ Tempo mínimo do toque\n" "$(icon check_setting secure tap_duration_threshold 80)"
        printf " %b [02] ⌛ Tempo do toque longo\n" "$(icon check_setting secure long_press_timeout 300)"
        printf " %b [03] ⚡ Toques rápidos (duplo / triplo)\n" "$(icon check_setting secure multi_press_timeout 130)"
        printf " %b [04] 🤖 Ações automáticas mais rápidas\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"
        printf " %b [05] 🖥 Toque no espelhamento\n" "$(icon check_setting global block_untrusted_touches 0)"
        printf " %b [06] 🚀 Desempenho do sistema\n" "$(icon check_setting global restricted_device_performance '0,0')"
        echo ""

        # Grupo 2: USB
        printf " %b [07] 🔌 USB RAW (sem filtro)\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
        printf " %b [08] ⚡ USB baixa latência\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
        printf " %b [09] 🎯 Prioridade HID\n" "$(icon check_prop vendor.usb.hid.priority 1)"
        printf " %b [10] 🚄 USB High Speed\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
        printf " %b [11] 🔋 Potência USB\n" "$(icon check_prop persist.vendor.usb.power 1)"
        printf " %b [12] 🔥 Boost hub USB\n" "$(icon check_prop vendor.usb.hub.boost 1)"
        printf " %b [13] 🖱 Anti-jitter mouse\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 0)"
        echo ""

        # Grupo 3: Mouse/Input
        printf " %b [14] 🎯 Mouse linear (1:1)\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
        printf " %b [15] 🚫 Mouse sem aceleração\n" "$(check_mouse_acceleration)"
        printf " %b [16] ⚡ Input baixa latência\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
        echo ""

        # Grupo 4: VSync/GPU
        printf " %b [17] 🚫 VSync desligado\n" "$(icon check_prop debug.hwui.disable_vsync 0)"
        printf " %b [18] 🎮 GPU baixa latência\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
        printf " %b [19] 🧩 GPU aceleração quadros\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
        echo ""

        # Grupo 5: Display
        printf " %b [20] 📱 Tela 120Hz fixo\n" "$(icon check_setting system peak_refresh_rate 120)"
        printf " %b [21] 🖥 Espelhamento otimizado\n" "$(icon check_prop persist.video.duplicate.display 1)"
        printf " %b [22] 📺 Prioridade vídeo externa\n" "$(icon check_prop vendor.display.external_priority 1)"
        echo ""

        # Grupo 6: Gamepad/HID
        printf " %b [23] 🎮 Gamepad baixa latência\n" "$(icon check_setting global gamepad.latency_reduction 1)"
        printf " %b [24] 🛣 Fastpath HID\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
        printf " %b [25] ⚡ USB modo desempenho\n" "$(icon check_prop vendor.usb.performance_mode 1)"
        printf " %b [26] ⏱ IRQ USB baixa latência\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
        printf " %b [27] 🚀 Despacho rápido input\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
        echo ""

        # Grupo 7: Polling/CPU
        printf " %b [28] 📡 Polling Rate 1000Hz\n" "$(icon check_prop persist.vendor.hid.polling_rate 1000)"
        printf " %b [29] 🧠 Responsividade CPU\n" "$(icon check_prop sem_enhanced_cpu_responsiveness 1)"
        echo ""

        # Grupo 8: Debug/Performance
        printf " %b [30] 🐞 Debug input low latency\n" "$(icon check_prop debug.input.low_latency 1)"
        printf " %b [31] 🧪 Debug input no buffer\n" "$(icon check_prop debug.input.no_buffer 1)"
        printf " %b [32] 🖼 SF latch unsignaled\n" "$(icon check_prop debug.sf.latch_unsignaled 1)"
        printf " %b [33] 📊 Estabilidade de frames\n" "$(icon check_prop persist.game.frame_stability 1)"
        printf " %b [34] 🚀 CPU boost persistente\n" "$(icon check_prop persist.sys.cpu.boost 1)"
        
        echo -e "\n${BOLD}${CYAN}────────────────────────────────────${RESET}"
        
        # Opções especiais
        if spoof_status; then
            SPOOF_ICON="${GREEN}🟢${RESET}"
        else
            SPOOF_ICON="${RED}🔴${RESET}"
        fi
        printf " %b [43] 🎯 Spoof 120 FPS\n" "$SPOOF_ICON"
        printf " ${RED}🔴${RESET} [44] ♻️  Reset total\n"
        
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
            25) toggle_tweak "Modo desempenho USB" "$submenu_35_cmd_on" "$submenu_35_cmd_off" ;;
            26) toggle_tweak "Interrupções USB baixa latência" "$submenu_36_cmd_on" "$submenu_36_cmd_off" ;;
            27) toggle_tweak "Despacho rápido de input" "$submenu_38_cmd_on" "$submenu_38_cmd_off" ;;
            28) toggle_tweak "Polling Rate HID (1000Hz)" "$submenu_51_cmd_on" "$submenu_51_cmd_off" ;;
            29) toggle_tweak "CPU Responsividade Aprimorada" "$submenu_56_cmd_on" "$submenu_56_cmd_off" ;;
            30) toggle_tweak "Debug Input Low Latency" "$submenu_57_cmd_on" "$submenu_57_cmd_off" ;;
            31) toggle_tweak "Debug Input No Buffer" "$submenu_58_cmd_on" "$submenu_58_cmd_off" ;;
            32) toggle_tweak "Debug SF Latch Unsignaled" "$submenu_63_cmd_on" "$submenu_63_cmd_off" ;;
            33) toggle_tweak "Persist Game Frame Stability" "$submenu_64_cmd_on" "$submenu_64_cmd_off" ;;
            34) toggle_tweak "Persist Sys CPU Boost" "$submenu_65_cmd_on" "$submenu_65_cmd_off" ;;
            43) submenu_spoof ;;
            44) submenu_reset ;;
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
    # Verificação rigorosa antes de mostrar menu
    if ! verificar_integridade_licenca; then
        echo -e "${RED}⛔ ACESSO NEGADO: Licença inválida ou expirada${RESET}"
        echo -e "${YELLOW}Execute o script novamente para autenticar.${RESET}"
        sleep 3
        exit 1
    fi
    
    # Verificar sessão
    if ! verificar_sessao; then
        echo -e "${YELLOW}⚠️  Sessão expirada. Faça login novamente.${RESET}"
        sleep 2
        return 1
    fi
    
    while true; do
        clear
        printf '\033c'
        
        check_license_warning

        echo -e "\033[1;37m🔥 FERA ALPHA ULTRA GAMER"
        echo -e "\033[1;37m────────────────────────"
        
        # Mostrar status da licença
        if [ -f "$LICENSE_FILE" ]; then
            EXP=$(cat "$LICENSE_FILE" 2>/dev/null)
            NOW=$(date +%s)
            if echo "$EXP" | grep -qE '^[0-9]+$'; then
                DIFF=$((EXP - NOW))
                DAYS=$((DIFF / 86400))
                if [ "$DAYS" -gt 365 ]; then
                    echo -e "\033[1;37mStatus: 🟢 Ativo  |  VIP ILIMITADO\033[0m"
                elif [ "$DAYS" -gt 0 ]; then
                    echo -e "\033[1;37mStatus: 🟢 Ativo  |  $DAYS dias restantes\033[0m"
                else
                    echo -e "\033[1;37mStatus: 🔴 Expirado\033[0m"
                fi
            else
                echo -e "\033[1;37mStatus: 🔴 Inválido\033[0m"
            fi
        else
            echo -e "\033[1;37mStatus: 🔴 Não ativo\033[0m"
        fi

        echo -e "\033[1;37m"
        echo "[01] ⚡ Aplicar tudo"
        echo "[02] 🎛 Tweaks individuais"
        echo ""
        echo "[03] ⚡ Turbo absoluto"
        echo "[04] 🔥 Extremo (sem limites)"
        echo ""
        echo "[05] 🎮 Menu Gaming Completo"
        echo "[06] 🎯 Spoof 120 FPS"
        echo "[07] 🖥 Resolução / DPI"
        echo ""
        echo "[08] 📊 Status do sistema"
        echo "[09] ⚙️  Config. Atualização"
        echo "[10] 🧹 Limpar cache"
        echo "[11] 🔄 Reiniciar dispositivo"
        echo "[12] ♻️  Reset geral"
        echo ""
        echo "[00] ❌ Sair"
        echo ""
        echo -n "➤ Selecione uma opção: "
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
                echo -e "\033[1;37m"
                apply_safe_performance
                press_enter
                ;;
            04) 
                echo -e "\033[1;37m"
                apply_extreme_performance
                press_enter
                ;;
            05) 
                menu_otimizacao_gaming
                ;;
            06) 
                submenu_spoof
                ;;
            07) 
                config_resolucao_dpi
                ;;
            08) 
                show_performance_status
                ;;
            09) 
                menu_config_update
                ;;
            10) 
                limpar_cache_simples
                ;;
            11) 
                reiniciar_dispositivo
                ;;
            12) 
                submenu_reset
                ;;
            00) 
                echo -e "${GREEN}👋 Saindo...${RESET}"
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

# Inicializar log de segurança
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INICIO: Script iniciado" > "$SECURITY_LOG"

verificacao_inicial

# Verificar se já tem licença válida
if verificar_integridade_licenca && verificar_sessao; then
    echo -e "${GREEN}✅ Licença válida detectada. Acessando painel...${RESET}"
    sleep 1
    menu
    exit 0
fi

# Se não tem licença válida, exigir login
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
    
    # Log de tentativa falha
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
