#!/system/bin/sh

###############################################################################
# ⚡ ATUALIZAÇÃO AUTOMÁTICA - VERSÃO AUTOMÁTICA
###############################################################################
MODDIR=${0%/*}
ARQUIVO_IDENTIFICACAO="$MODDIR/impressao_digital"
URL_PAINEL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh"
URL_HASH="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt"
SELF="$0"
HASH_LOCAL="/data/local/tmp/painel_hash"
TMP_DOWNLOAD="/data/local/tmp/painel_novo.sh"

# Configuração de auto-update
ARQUIVO_AUTO_UPDATE="$MODDIR/auto_update_ativado"
[ ! -f "$ARQUIVO_AUTO_UPDATE" ] && echo "1" > "$ARQUIVO_AUTO_UPDATE"

###############################################################################
# 🔐 SISTEMA DE LICENÇA FORTIFICADO
###############################################################################

SERVIDOR="https://painel-licenca-server.onrender.com"
ARQUIVO_LICENCA="$MODDIR/info_licenca"
ARQUIVO_ASSINATURA="$MODDIR/assinatura_licenca"
SCRIPT_RESET="$MODDIR/reset_auto.sh"
ARQUIVO_SESSAO="$MODDIR/token_sessao"
CHAVE_SECRETA="FER4_4LPH4_2024_S3CR3T_K3Y_N0T_SH4R3D"

# Log de segurança
LOG_SEGURANCA="/data/local/tmp/fera_seguranca.log"
log_seguranca() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_SEGURANCA"
}

gera_impressao_digital() {
    ID_ANDROID=$(settings get secure android_id 2>/dev/null || echo "")
    SERIAL=$(getprop ro.serialno 2>/dev/null || echo "")
    HARDWARE=$(getprop ro.boot.hardware 2>/dev/null || echo "")
    SERIAL_BOOT=$(getprop ro.boot.serialno 2>/dev/null || echo "")
    PLATAFORMA=$(getprop ro.hardware.chipname 2>/dev/null || getprop ro.board.platform 2>/dev/null || echo "")
    
    DADOS_CRUS="${ID_ANDROID}-${SERIAL}-${HARDWARE}-${SERIAL_BOOT}-${PLATAFORMA}"
    
    if command -v sha256sum >/dev/null 2>&1; then
        FP=$(echo -n "$DADOS_CRUS" | sha256sum | awk '{print $1}')
    elif command -v md5sum >/dev/null 2>&1; then
        FP=$(echo -n "$DADOS_CRUS" | md5sum | awk '{print $1}')
    elif command -v md5 >/dev/null 2>&1; then
        FP=$(echo -n "$DADOS_CRUS" | md5 | awk '{print $1}')
    else
        FP=$(echo -n "$DADOS_CRUS" | tr -d ' ' | tr -d '\n')
    fi
    
    echo "$FP"
}

gerar_assinatura() {
    DADOS="$1"
    echo -n "$DADOS" | sha256sum | awk '{print $1}'
}

verificar_assinatura() {
    DADOS="$1"
    ASSINATURA="$2"
    
    CALCULADA=$(gerar_assinatura "$DADOS")
    
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

    echo -e "${VERMELHO}⚠️  Licença expirada. Restaurando configurações padrão...${RESET}"
    
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

    setprop vendor.usb.raw_input.enable 1
    setprop persist.usb.low_latency_mode 0
    setprop vendor.usb.hid.priority 1
    setprop persist.vendor.usb.high_speed 0
    setprop persist.vendor.usb.power 0
    setprop vendor.usb.mouse.jitter_filter 1

    setprop persist.sys.mouse.linear_response 0
    setprop persist.sys.pointer.acceleration 1

    setprop persist.sys.input.low_latency_mode 0
    setprop persist.sys.input.high_update_rate false

    setprop persist.sys.gpu.low_latency 0
    setprop persist.sys.gpu.frame_boost 0

    setprop vendor.display.external_priority 0

    setprop vendor.hid.input.fastpath 0
    setprop persist.sys.input.filter 1
    setprop persist.sys.input.resample 1
    setprop persist.vendor.usb.low_latency_interrupts 1
    setprop persist.sys.input.dispatch_fast 1
    
    setprop debug.input.low_latency 1
    
    setprop windowsmgr.max_events_per_sec 120
    
    setprop debug.sf.late.sf.duration 0
    setprop debug.sf.early.sf.duration 0
    setprop debug.sf.frame_rate_multiple_threshold 60
    setprop debug.sf.high_fps_late.app.duration 0
    setprop debug.sf.high_fps_late.sf.duration 0
    
    setprop debug.hwui.skip_vsync 0
    setprop debug.hwui.render_dirty_regions true
    setprop persist.sys.input.urgent 0
    
    setprop debug.sf.latch_unsignaled 0
    setprop persist.sys.cpu.boost 0
    setprop persist.video.low_latency_path 0
    
    settings put global window_animation_scale 1
    settings put global transition_animation_scale 1
    settings put global animator_duration_scale 1

    setprop persist.sys.input.priority 0
    setprop persist.sys.input.absolute_mode 0
    setprop persist.sys.input.relative_mode 1

    # Limpar arquivos de controle
    rm -rf "$MODDIR/bandeiras_desativadas"
    rm -f "$MODDIR/system.prop" "$MODDIR/spoof_ativado"
    rm -f "$MODDIR/props_originais"
    rm -f "$MODDIR/info_licenca"
    rm -f "$MODDIR/assinatura_licenca"
    rm -f "$MODDIR/token_sessao"
    rm -f "$MODDIR/ativar_no_boot"
    rm -f "$ARQUIVO_TWEAKS_ATIVOS"
    
    setprop persist.fera.touch.disabled 0
    rm -f "$MODDIR/lista_touch_desativado"
    
    log_seguranca "RESET_COMPLETO: Sistema restaurado ao padrão"
    
    echo -e "${AMARELO}✅ Configurações restauradas ao padrão.${RESET}"
    exit 1
}

verificar_integridade_licenca() {
    if [ ! -f "$ARQUIVO_LICENCA" ]; then
        log_seguranca "ERRO: Arquivo de licença não existe"
        echo -e "${VERMELHO}❌ ERRO: Licença não encontrada${RESET}"
        return 1
    fi
    
    if [ ! -f "$ARQUIVO_ASSINATURA" ]; then
        log_seguranca "ERRO: Assinatura da licença não existe"
        echo -e "${VERMELHO}❌ ERRO: Assinatura de licença não encontrada${RESET}"
        return 1
    fi
    
    EXP=$(cat "$ARQUIVO_LICENCA" 2>/dev/null)
    ASSINATURA=$(cat "$ARQUIVO_ASSINATURA" 2>/dev/null)
    FP=$(gera_impressao_digital)
    
    if [ -z "$EXP" ] || [ -z "$ASSINATURA" ]; then
        log_seguranca "ERRO: Licença ou assinatura vazia"
        return 1
    fi
    
    if ! echo "$EXP" | grep -qE '^[0-9]{10,}$'; then
        log_seguranca "ERRO: Formato de licença inválido: $EXP"
        echo -e "${VERMELHO}❌ ERRO: Formato de licença inválido${RESET}"
        return 1
    fi
    
    DADOS_ASSINAR="${EXP}:${FP}"
    if ! verificar_assinatura "$DADOS_ASSINAR" "$ASSINATURA"; then
        log_seguranca "ERRO: Assinatura inválida para licença"
        echo -e "${VERMELHO}❌ ERRO: Licença corrompida ou modificada${RESET}"
        return 1
    fi
    
    AGORA=$(date +%s)
    if [ "$AGORA" -ge "$EXP" ]; then
        log_seguranca "AVISO: Licença expirada em $EXP, agora é $AGORA"
        echo -e "${VERMELHO}⚠️  Licença expirada${RESET}"
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
    FP=$(gera_impressao_digital)
    EXP=$(cat "$ARQUIVO_LICENCA" 2>/dev/null)
    
    if curl --connect-timeout 10 -s -f "$SERVIDOR/ping" >/dev/null 2>&1; then
        RESP=$(curl -s -X POST -H "Content-Type: application/json" \
               -d "{\"fingerprint\":\"$FP\",\"expires\":\"$EXP\"}" \
               "$SERVIDOR/verify_license")
        
        if echo "$RESP" | grep -q '"valid":false'; then
            log_seguranca "SERVIDOR_REJEITOU: Licença inválida no servidor"
            reset_total_auto
        fi
    fi
}

verificar_aviso_licenca() {
    if [ ! -f "$ARQUIVO_LICENCA" ]; then
        return 0
    fi
    
    EXP=$(cat "$ARQUIVO_LICENCA")
    AGORA=$(date +%s)
    
    if echo "$EXP" | grep -qE '^[0-9]+$'; then
        DIFERENCA=$((EXP - AGORA))
        HORAS=$((DIFERENCA / 3600))
        
        if [ "$DIFERENCA" -gt 0 ] && [ "$HORAS" -lt 24 ]; then
            echo -e "\n${VERMELHO}⚠️  AVISO: SUA LICENÇA IRÁ EXPIRAR EM ${HORAS} HORA(S)!${RESET}"
            echo -e "${AMARELO}Renove seu acesso para evitar perda das configurações.${RESET}\n"
            sleep 3
        fi
    fi
}

ativar_servidor() {
    USUARIO="$1"
    SENHA="$2"
    FP=$(gera_impressao_digital)
    
    log_seguranca "TENTATIVA_LOGIN: Usuário=$USUARIO, Impressão digital=$FP"

    JSON="{\"username\":\"$USUARIO\",\"password\":\"$SENHA\",\"fingerprint\":\"$FP\"}"

    RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVIDOR/activate")

    if echo "$RESP" | grep -q '"status":"error"' || echo "$RESP" | grep -q '"error"'; then
        MOTIVO=$(echo "$RESP" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
        log_seguranca "LOGIN_FALHOU: $MOTIVO"
        echo -e "\033[1;31m❌ Erro: ${MOTIVO:-Credenciais inválidas}\033[0m"
        return 1
    fi

    echo -e "\033[1;32m✔ Login aprovado!\033[0m"
    log_seguranca "LOGIN_SUCESSO: Usuário=$USUARIO"

    EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
    if [ -z "$EXP" ]; then
        echo -e "\033[1;31m❌ Erro: Resposta inválida do servidor\033[0m"
        log_seguranca "ERRO_SERVIDOR: Resposta sem timestamp"
        return 1
    fi

    FP=$(gera_impressao_digital)
    DADOS_ASSINAR="${EXP}:${FP}"
    ASSINATURA=$(gerar_assinatura "$DADOS_ASSINAR")
    
    echo "$EXP" > "$ARQUIVO_LICENCA"
    echo "$ASSINATURA" > "$ARQUIVO_ASSINATURA"
    
    TOKEN_SESSAO=$(echo -n "${EXP}:${FP}:$(date +%s)" | sha256sum | awk '{print $1}')
    echo "$TOKEN_SESSAO" > "$ARQUIVO_SESSAO"
    
    log_seguranca "LICENÇA_ATIVADA: Expira=$EXP, Assinatura=$ASSINATURA"

    return 0
}

verificar_sessao() {
    if [ ! -f "$ARQUIVO_SESSAO" ]; then
        return 1
    fi
    
    if ! verificar_integridade_licenca; then
        rm -f "$ARQUIVO_SESSAO"
        log_seguranca "SESSAO_INVALIDA: Licença inválida para sessão"
        return 1
    fi
    
    TOKEN_SESSAO=$(cat "$ARQUIVO_SESSAO")
    TEMPO_SESSAO=$(stat -c %Y "$ARQUIVO_SESSAO" 2>/dev/null || echo "0")
    AGORA=$(date +%s)
    
    if [ $((AGORA - TEMPO_SESSAO)) -gt 86400 ]; then
        rm -f "$ARQUIVO_SESSAO"
        log_seguranca "SESSAO_EXPIROU: Tempo decorrido $((AGORA - TEMPO_SESSAO))s"
        return 1
    fi
    
    return 0
}

###############################################################################
# 🛡️ VERIFICAÇÃO INICIAL FORTIFICADA
###############################################################################

salvar_props_originais() {
    if [ ! -f "$ARMAZENAMENTO_ORIGINAL" ]; then
        {
            echo "ro.product.model=$(getprop ro.product.model 2>/dev/null || echo "")"
            echo "ro.product.brand=$(getprop ro.product.brand 2>/dev/null || echo "")"
            echo "ro.product.name=$(getprop ro.product.name 2>/dev/null || echo "")"
            echo "ro.product.device=$(getprop ro.product.device 2>/dev/null || echo "")"
            echo "ro.product.manufacturer=$(getprop ro.product.manufacturer 2>/dev/null || echo "")"
            echo "ro.build.id=$(getprop ro.build.id 2>/dev/null || echo "")"
            echo "ro.build.fingerprint=$(getprop ro.build.fingerprint 2>/dev/null || echo "")"
        } > "$ARMAZENAMENTO_ORIGINAL"
        chmod 644 "$ARMAZENAMENTO_ORIGINAL" 2>/dev/null
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
    
    HASH_SCRIPT=$(sha256sum "$0" 2>/dev/null | awk '{print $1}' || echo "")
    if [ -n "$HASH_SCRIPT" ]; then
        log_seguranca "SCRIPT_HASH: $HASH_SCRIPT"
    fi
    
    echo "🔍 Verificando configurações de spoof..."
    if [ -f "$BANDEIRA_SPOOF" ] || ( [ -f "$ARQUIVO_SPOOF" ] && grep -q "ro.product.model=RMX5101" "$ARQUIVO_SPOOF" 2>/dev/null ); then
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
        echo -e "${NEGRITO}${CIANO}=== CONFIGURAÇÕES DE ATUALIZAÇÃO ===${RESET}\n"
        
        if [ -f "$ARQUIVO_AUTO_UPDATE" ] && [ "$(cat "$ARQUIVO_AUTO_UPDATE")" = "1" ]; then
            echo -e "Status: ${VERDE}✅ ATUALIZAÇÃO AUTOMÁTICA ATIVADA${RESET}\n"
        else
            echo -e "Status: ${VERMELHO}❌ ATUALIZAÇÃO AUTOMÁTICA DESATIVADA${RESET}\n"
        fi
        
        echo "1) Ativar atualização automática"
        echo "2) Desativar atualização automática"
        echo "0) Voltar"
        echo ""
        
        ler_prompt "> " opcao_update
        
        case "$opcao_update" in
            1)
                echo "1" > "$ARQUIVO_AUTO_UPDATE"
                echo -e "${VERDE}✅ Atualização automática ativada!${RESET}"
                sleep 1
                ;;
            2)
                echo "0" > "$ARQUIVO_AUTO_UPDATE"
                echo -e "${AMARELO}⚠️  Atualização automática desativada${RESET}"
                sleep 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${VERMELHO}Opção inválida!${RESET}"
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
    echo -e "${NEGRITO}${CIANO}=== LIMPEZA DE CACHE ===${RESET}\n"
    
    echo -e "${CIANO}Limpando cache do sistema...${RESET}"
    pm trim-caches 1000G
    
    echo -e "${CIANO}Limpando cache do usuário...${RESET}"
    rm -rf /data/local/tmp/* 2>/dev/null
    rm -rf /data/dalvik-cache/* 2>/dev/null
    
    echo -e "${VERDE}✅ Cache limpo com sucesso!${RESET}"
    
    echo ""
    df -h /data | tail -1 | awk '{print "📊 Espaço livre em /data: " $4}'
    
    pressionar_enter
}

###############################################################################
# 🔄 REINICIAR DISPOSITIVO (SIMPLIFICADO)
###############################################################################

reiniciar_dispositivo_simples() {
    clear
    echo -e "${NEGRITO}${CIANO}=== REINICIAR DISPOSITIVO ===${RESET}\n"
    
    echo -e "${AMARELO}⚠️  ATENÇÃO: O dispositivo será reiniciado!${RESET}\n"
    
    ler_prompt "Deseja realmente reiniciar? (s/N): " confirmar
    if [ "$confirmar" = "s" ] || [ "$confirmar" = "S" ]; then
        echo -e "${CIANO}Reiniciando...${RESET}"
        echo -e "${AMARELO}O dispositivo será reiniciado em 3 segundos.${RESET}"
        sleep 3
        reboot
    else
        echo -e "${AMARELO}❌ Reinício cancelado${RESET}"
        sleep 1
    fi
}

###############################################################################
# 🛠️ FUNÇÃO DE ATUALIZAÇÃO (SÓ APÓS LOGIN VÁLIDO)
###############################################################################

verificar_atualizacao_auto() {
    if ! verificar_integridade_licenca; then
        log_seguranca "UPDATE_BLOQUEADO: Licença inválida para atualização"
        return 1
    fi
    
    if [ ! -f "$ARQUIVO_AUTO_UPDATE" ] || [ "$(cat "$ARQUIVO_AUTO_UPDATE")" != "1" ]; then
        return 0
    fi
    
    echo -e "\n🔍 Verificando atualizações..."
    
    LOCAL=$(cat "$HASH_LOCAL" 2>/dev/null || echo "0")
    REMOTO=$(curl -fsSL "${URL_HASH}?$(date +%s)" | sed 's/[^0-9a-fA-F]//g')
    
    if [ -z "$REMOTO" ] || [ "$LOCAL" = "$REMOTO" ]; then
        return 0
    fi
    
    echo "🔄 Nova versão disponível! Atualizando..."
    
    curl -fsSL "${URL_PAINEL}?$(date +%s)" -o "$TMP_DOWNLOAD"
    
    if [ ! -s "$TMP_DOWNLOAD" ]; then
        log_seguranca "UPDATE_ERRO: Download falhou ou arquivo vazio"
        return 1
    fi
    
    NOVO_HASH=$(sha256sum "$TMP_DOWNLOAD" | awk '{print $1}')
    if [ "$NOVO_HASH" != "$REMOTO" ]; then
        log_seguranca "UPDATE_ERRO: Hash não confere: $NOVO_HASH vs $REMOTO"
        return 1
    fi
    
    cp -f "$TMP_DOWNLOAD" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$HASH_LOCAL"
    
    log_seguranca "UPDATE_SUCESSO: Script atualizado para hash $REMOTO"
    echo -e "✅ Atualização concluída! Reiniciando painel...\n"
    sleep 2
    exec "$SELF"
}

###############################################################################
# 🎮 SISTEMA DE PRIORIDADE POR APLICATIVO (SIMPLIFICADO)
###############################################################################

ARQUIVO_APPS_PRIORITARIOS="$MODDIR/apps_prioritarios.txt"
ARQUIVO_PRIORIDADE_ATIVA="$MODDIR/prioridade_ativa.flag"

# Aplicativos prioritários padrão (GG Mouse + Free Fire)
APPS_PRIORITARIOS_PADRAO="com.zjx.ztezscreenshot
com.dts.freefiremax
com.dts.freefireth"

verificar_prioridade_ativa() {
    if [ -f "$ARQUIVO_PRIORIDADE_ATIVA" ]; then
        return 0  # Prioridade ativa
    else
        return 1  # Prioridade inativa
    fi
}

aplicar_prioridade_ggmouse_ff() {
    echo -e "${CIANO}🎮 Aplicando prioridade máxima para GG Mouse e Free Fire...${RESET}"
    
    # Criar arquivo de flag para indicar que está ativo
    touch "$ARQUIVO_PRIORIDADE_ATIVA"
    
    # Aplicar para GG Mouse Pro
    echo "🎮 Configurando GG Mouse Pro..."
    setprop persist.sys.input.priority 3
    setprop persist.sys.mouse.entrada_crua 1
    setprop persist.sys.mouse.taxa_atualizacao 1000
    setprop persist.sys.input.filtro 0
    setprop persist.sys.cpu.boost.mouse 1
    setprop persist.vendor.gpu.boost.mouse 1
    setprop persist.usb.modo_baixa_latencia 2
    setprop vendor.usb.hid.priority 3
    setprop persist.sys.mouse.perfil_aceleracao 0
    setprop persist.sys.mouse.sensibilidade 1.0
    
    # Aplicar para Free Fire
    echo "🔥 Configurando Free Fire..."
    setprop persist.sys.modo_jogo 2
    setprop persist.vendor.perf.jogos 2
    setprop persist.sys.priority.input 2
    setprop persist.sys.cpu.boost.jogos 2
    setprop persist.vendor.gpu.boost.jogos 2
    setprop persist.vendor.touch.jogos 1
    setprop persist.sys.touch.resposta 0
    
    # Configurações comuns
    setprop debug.sf.latch_unsignaled 1
    setprop video.accelerate.hw 1
    setprop persist.sys.ui.hw 1
    setprop windowsmgr.max_events_per_sec 240
    setprop debug.egl.swapinterval 0
    
    # Prioridade de processo
    setprop persist.sys.priority.foreground 90
    setprop persist.sys.priority.jogo 95
    setprop persist.sys.oom_score_adj -800
    
    # Salvar lista de apps prioritários
    echo "$APPS_PRIORITARIOS_PADRAO" > "$ARQUIVO_APPS_PRIORITARIOS"
    
    echo -e "${VERDE}✅ Prioridade máxima aplicada para GG Mouse e Free Fire!${RESET}"
    echo -e "${AMARELO}As configurações serão mantidas até você desativar.${RESET}"
}

desativar_prioridade_ggmouse_ff() {
    echo -e "${CIANO}🔄 Desativando prioridade para GG Mouse e Free Fire...${RESET}"
    
    # Remover arquivo de flag
    rm -f "$ARQUIVO_PRIORIDADE_ATIVA"
    
    # Restaurar configurações padrão
    setprop persist.sys.input.priority 1
    setprop persist.sys.mouse.entrada_crua 0
    setprop persist.sys.mouse.taxa_atualizacao 125
    setprop persist.sys.input.filtro 1
    setprop persist.sys.cpu.boost.mouse 0
    setprop persist.vendor.gpu.boost.mouse 0
    setprop persist.usb.modo_baixa_latencia 0
    setprop vendor.usb.hid.priority 1
    
    setprop persist.sys.modo_jogo 0
    setprop persist.vendor.perf.jogos 0
    setprop persist.sys.cpu.boost.jogos 0
    setprop persist.vendor.gpu.boost.jogos 0
    
    setprop persist.sys.priority.foreground 0
    setprop persist.sys.priority.jogo 0
    setprop persist.sys.oom_score_adj 0
    
    echo -e "${VERDE}✅ Prioridade desativada.${RESET}"
    echo -e "${AMARELO}Configurações restauradas para padrão.${RESET}"
}

###############################################################################
# ⚡ FUNÇÃO RÁPIDA DE PRIORIDADE
###############################################################################

alternar_prioridade_ggmouse_ff() {
    if verificar_prioridade_ativa; then
        echo -e "${CIANO}🔍 Status: ${VERDE}✅ PRIORIDADE ATIVA${RESET}"
        echo -e "${AMARELO}Deseja desativar a prioridade?${RESET}"
        ler_prompt "Desativar? (s/N): " confirmar
        
        if [ "$confirmar" = "s" ] || [ "$confirmar" = "S" ]; then
            desativar_prioridade_ggmouse_ff
        else
            echo -e "${AMARELO}✅ Mantendo prioridade ativa.${RESET}"
        fi
    else
        echo -e "${CIANO}🔍 Status: ${VERMELHO}❌ PRIORIDADE INATIVA${RESET}"
        echo -e "${AMARELO}Deseja ativar prioridade máxima para GG Mouse e Free Fire?${RESET}"
        ler_prompt "Ativar? (s/N): " confirmar
        
        if [ "$confirmar" = "s" ] || [ "$confirmar" = "S" ]; then
            aplicar_prioridade_ggmouse_ff
        else
            echo -e "${AMARELO}❌ Prioridade não ativada.${RESET}"
        fi
    fi
}

###############################################################################
# 🎯 FUNÇÃO SIMPLES PARA APPS PRIORITÁRIOS
###############################################################################

menu_apps_prioritarios_simples() {
    while true; do
        clear
        printf '\033c'
        
        # Verificar status atual
        if verificar_prioridade_ativa; then
            STATUS_PRIORIDADE="${VERDE}✅ ATIVA${RESET}"
            OPCAO_PRINCIPAL="1) Desativar prioridade GG Mouse + FF"
        else
            STATUS_PRIORIDADE="${VERMELHO}❌ INATIVA${RESET}"
            OPCAO_PRINCIPAL="1) Ativar prioridade GG Mouse + FF"
        fi
        
        echo -e "${NEGRITO}${CIANO}=== APPS PRIORITÁRIOS (GG Mouse + Free Fire) ===${RESET}\n"
        echo -e "Status: $STATUS_PRIORIDADE"
        echo "────────────────────────────────────"
        echo ""
        
        echo "$OPCAO_PRINCIPAL"
        echo "2) Ver apps na lista"
        echo "3) Adicionar app à lista"
        echo "4) Remover app da lista"
        echo "5) Restaurar lista padrão"
        echo "0) Voltar"
        echo ""
        
        ler_prompt "> " opcao
        
        case "$opcao" in
            1)
                alternar_prioridade_ggmouse_ff
                pressionar_enter
                ;;
            2)
                clear
                echo -e "${CIANO}📋 Apps atualmente prioritários:${RESET}"
                echo "────────────────────────────────────"
                if [ -f "$ARQUIVO_APPS_PRIORITARIOS" ]; then
                    cat "$ARQUIVO_APPS_PRIORITARIOS"
                else
                    echo "$APPS_PRIORITARIOS_PADRAO"
                fi
                echo "────────────────────────────────────"
                pressionar_enter
                ;;
            3)
                ler_prompt "Digite o pacote do app (ex: com.exemplo.app): " novo_app
                if [ -n "$novo_app" ]; then
                    if [ ! -f "$ARQUIVO_APPS_PRIORITARIOS" ]; then
                        echo "$APPS_PRIORITARIOS_PADRAO" > "$ARQUIVO_APPS_PRIORITARIOS"
                    fi
                    echo "$novo_app" >> "$ARQUIVO_APPS_PRIORITARIOS"
                    echo -e "${VERDE}✅ App adicionado à lista${RESET}"
                fi
                sleep 1
                ;;
            4)
                if [ -f "$ARQUIVO_APPS_PRIORITARIOS" ]; then
                    echo -e "${CIANO}📋 Apps na lista:${RESET}"
                    cat "$ARQUIVO_APPS_PRIORITARIOS"
                    echo ""
                    ler_prompt "Digite o pacote do app para remover: " remover_app
                    if [ -n "$remover_app" ]; then
                        sed -i "/^${remover_app}$/d" "$ARQUIVO_APPS_PRIORITARIOS"
                        echo -e "${VERMELHO}✅ App removido da lista${RESET}"
                    fi
                else
                    echo -e "${AMARELO}⚠️  Lista de apps não existe.${RESET}"
                fi
                sleep 1
                ;;
            5)
                echo "$APPS_PRIORITARIOS_PADRAO" > "$ARQUIVO_APPS_PRIORITARIOS"
                echo -e "${VERDE}✅ Lista padrão restaurada${RESET}"
                sleep 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${VERMELHO}Opção inválida!${RESET}"
                sleep 1
                ;;
        esac
    done
}

###############################################################################
# VISUAL
###############################################################################

barra_carregamento() {
    clear
    echo -e "\n\033[1;36mCarregando Painel FERA ALPHA...\033[0m\n"
    printf "\033[1;32m[██████████████████] 100%%\033[0m\n"
    return
}

cabecalho() {
    clear
    cols=$(stty size | awk '{print $2}')
    
    echo -e "\n\033[1;37m🔥 FERA ALPHA ULTRA GAMER\033[0m"
    echo -e "\n\033[1;37m🔐 LOGIN OBRIGATÓRIO\033[0m\n"
}

entrada_login() {
    echo -e "\033[1;37m👤 Usuário:\033[0m"
    echo -n "➤ "
    read USUARIO
    echo -e "\033[1;37m🔒 Senha:\033[0m"
    echo -n "➤ "
    read SENHA
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
    
    if [ -f "$ARQUIVO_LICENCA" ]; then
        EXP=$(cat "$ARQUIVO_LICENCA" 2>/dev/null)
        AGORA=$(date +%s)
        
        if echo "$EXP" | grep -qE '^[0-9]+$'; then
            DIFERENCA=$((EXP - AGORA))
            DIAS=$((DIFERENCA / 86400))
            if [ "$DIAS" -gt 365 ]; then
                echo -e "\033[1;36m🌟 LICENÇA VIP ATIVADA!\033[0m"
                echo -e "\033[1;33m📅 Expira em: $(date -d @$EXP '+%d/%m/%Y %H:%M')\033[0m"
            elif [ "$DIAS" -gt 0 ]; then
                echo -e "\033[1;33m📅 Dias restantes: $DIAS\033[0m"
            fi
        fi
    fi
    
    if [ -f "$ARQUIVO_AUTO_UPDATE" ] && [ "$(cat "$ARQUIVO_AUTO_UPDATE")" = "1" ]; then
        echo -e "\n${CIANO}🔄 Verificando atualizações...${RESET}"
        verificar_atualizacao_auto
    fi
    
    sleep 1
    clear
}

###############################################################################

VERMELHO="\033[1;31m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
CIANO="\033[1;36m"
MAGENTA="\033[1;35m"
RESET="\033[0m"
NEGRITO="\033[1m"

ICON_LIGADO="🟢"
ICON_DESLIGADO="🔴"
SETA="➤"

BANDEIRA_SPOOF="$MODDIR/spoof_ativado"
ARQUIVO_SPOOF="$MODDIR/system.prop"
ARMAZENAMENTO_ORIGINAL="$MODDIR/props_originais"
DIRETORIO_BANDEIRAS="$MODDIR/bandeiras_desativadas"
mkdir -p "$DIRETORIO_BANDEIRAS" 2>/dev/null

salvar_props_originais

ARQUIVO_TWEAKS_ATIVOS="$MODDIR/tweaks_ativos.txt"

# =====================================================
# GERENCIAMENTO CENTRALIZADO DE PROPS
# =====================================================

reconstruir_apenas_spoof() {
    rm -f "$ARQUIVO_SPOOF" 2>/dev/null
    touch "$ARQUIVO_SPOOF" 2>/dev/null

    if [ -f "$BANDEIRA_SPOOF" ]; then
        echo -e "\n# Spoof Realme 15 Pro\n" >> "$ARQUIVO_SPOOF"
        cat >> "$ARQUIVO_SPOOF" <<'EOF'
ro.product.model=RMX5101
ro.product.brand=realme
ro.product.name=realme15pro
ro.product.device=RMX5101
ro.product.manufacturer=realme
EOF
    fi

    chmod 644 "$ARQUIVO_SPOOF" 2>/dev/null
}

adicionar_props_tweaks() {
    touch "$ARQUIVO_SPOOF" 2>/dev/null
    echo -e "\n# Tweaks de Propriedades Ativos\n" >> "$ARQUIVO_SPOOF"

    PROPS_TWEAKS=(
        "USB Baixa Latência=persist.usb.low_latency_mode=1"
        "Prioridade HID USB=vendor.usb.hid.priority=2"
        "USB Alta Velocidade=persist.vendor.usb.high_speed=1"
        "Potência USB Aprimorada=persist.vendor.usb.power=1"
        "Anti-jitter USB (mouse)=vendor.usb.mouse.jitter_filter=0"
        "Resposta Linear do Mouse=persist.sys.mouse.linear_response=1"
        "Aceleração do Mouse DESLIGADA=persist.sys.pointer.acceleration=0"
        "Modo Input Baixa Latência=persist.sys.input.low_latency_mode=1"
        "GPU Baixa Latência=persist.sys.gpu.low_latency=1"
        "Boost de Quadros GPU=persist.sys.gpu.frame_boost=1"
        "Interrupções USB Baixa Latência=persist.vendor.usb.low_latency_interrupts=1"
        "Persist Sys CPU Boost=persist.sys.cpu.boost=0"
        "Escala de Animação de Janela=settings:global:window_animation_scale=0"
        "Escala de Animação de Transição=settings:global:transition_animation_scale=0"
        "Escala de Duração do Animador=settings:global:animator_duration_scale=0"
        "Prioridade de Input=persist.sys.input.priority=1"
        "Filtro de Input=persist.sys.input.filter=0"
        "Máximo de Eventos por Segundo=windowsmgr.max_events_per_sec=240"
        "SF Latch Unsignaled=debug.sf.latch_unsignaled=0"
        "Display Primário Externo=persist.sys.display.primary_external=1"
        "HWUI Render Dirty Regions=debug.hwui.render_dirty_regions=false"
        "Caminho de Vídeo Baixa Latência=persist.video.low_latency_path=1"
    )

    for TWEAK in "${PROPS_TWEAKS[@]}"; do
        NOME=$(echo "$TWEAK" | cut -d'=' -f1)
        PROP_VALOR=$(echo "$TWEAK" | cut -d'=' -f2-)
        
        if echo "$PROP_VALOR" | grep -q "^settings:"; then
            NS=$(echo "$PROP_VALOR" | cut -d':' -f2)
            CHAVE_VALOR=$(echo "$PROP_VALOR" | cut -d':' -f3)
            CHAVE=$(echo "$CHAVE_VALOR" | cut -d'=' -f1)
            VALOR=$(echo "$CHAVE_VALOR" | cut -d'=' -f2)
            
            settings put "$NS" "$CHAVE" "$VALOR" 2>/dev/null
            continue
        fi

        if [ ! -f "$DIRETORIO_BANDEIRAS/$NOME" ]; then
            chave_prop=$(echo "$PROP_VALOR" | cut -d'=' -f1)
            if grep -q "^${chave_prop}=" "$ARQUIVO_SPOOF" 2>/dev/null; then
                sed -i "s|^${chave_prop}=.*|${PROP_VALOR}|" "$ARQUIVO_SPOOF" 2>/dev/null || true
            else
                echo "$PROP_VALOR" >> "$ARQUIVO_SPOOF"
            fi
            setprop "$chave_prop" "$(echo "$PROP_VALOR" | cut -d'=' -f2)" 2>/dev/null
        fi
    done

    chmod 644 "$ARQUIVO_SPOOF" 2>/dev/null
}

reconstruir_system_prop() {
    reconstruir_apenas_spoof
    adicionar_props_tweaks
}

adicionar_linha_prop() {
    chave_prop="$1"
    valor_prop="$2"
    if [ -z "$chave_prop" ]; then return; fi
    touch "$ARQUIVO_SPOOF" 2>/dev/null
    if grep -q "^${chave_prop}=" "$ARQUIVO_SPOOF" 2>/dev/null; then
        sed -i "s|^${chave_prop}=.*|${chave_prop}=${valor_prop}|" "$ARQUIVO_SPOOF" 2>/dev/null || true
    else
        echo "${chave_prop}=${valor_prop}" >> "$ARQUIVO_SPOOF"
    fi
    chmod 644 "$ARQUIVO_SPOOF" 2>/dev/null
}

remover_linha_prop() {
    chave_prop="$1"
    [ -f "$ARQUIVO_SPOOF" ] || return
    if grep -q "^${chave_prop}=" "$ARQUIVO_SPOOF" 2>/dev/null; then
        sed -i "/^${chave_prop}=/d" "$ARQUIVO_SPOOF" 2>/dev/null || true
    fi
}

ler_prompt() { printf "%s" "$1"; read -r "$2"; }
pressionar_enter()  { printf "\nPressione ENTER para continuar..."; read -r _; }

ativar_tweak() {
    nome="$1"; cmd="$2"
    BANDEIRA="$DIRETORIO_BANDEIRAS/$nome"
    echo -e "\n${CIANO}${SETA} Ativando:${RESET} $nome"

    rm -f "$BANDEIRA"

    if ! grep -q "^$nome$" "$ARQUIVO_TWEAKS_ATIVOS" 2>/dev/null; then
        echo "$nome" >> "$ARQUIVO_TWEAKS_ATIVOS"
    fi

    if echo "$cmd" | grep -qE "^settings"; then
        eval "$cmd"
    elif echo "$cmd" | grep -qE "^setprop"; then
        chave_prop=$(echo "$cmd" | awk '{print $2}')
        valor_prop=$(echo "$cmd" | awk '{print $3}')
        [ -n "$chave_prop" ] && setprop "$chave_prop" "$valor_prop" 2>/dev/null
        adicionar_linha_prop "$chave_prop" "$valor_prop"
    else
        eval "$cmd"
    fi

    echo -e "${VERDE}✔ Aplicado: $nome${RESET}"
}

desativar_tweak() {
    nome="$1"; cmd="$2"
    BANDEIRA="$DIRETORIO_BANDEIRAS/$nome"
    echo -e "\n${CIANO}${SETA} Desativando:${RESET} $nome"

    touch "$BANDEIRA"

    if [ -f "$ARQUIVO_TWEAKS_ATIVOS" ]; then
        sed -i "/^$nome$/d" "$ARQUIVO_TWEAKS_ATIVOS"
    fi

    if echo "$cmd" | grep -qE "^settings"; then
        eval "$cmd"
    elif echo "$cmd" | grep -qE "^setprop"; then
        chave_prop=$(echo "$cmd" | awk '{print $2}')
        valor_prop=$(echo "$cmd" | awk '{print $3}')
        [ -n "$chave_prop" ] && setprop "$chave_prop" "$valor_prop" 2>/dev/null
        remover_linha_prop "$chave_prop"
    else
        eval "$cmd"
    fi

    echo -e "${VERMELHO}✔ Desativado: $nome${RESET}"
}

verificar_configuracao() {
    ns="$1"; chave="$2"; esperado="$3"
    valor=$(settings get "$ns" "$chave" 2>/dev/null)
    nv=$(echo "$valor" | tr '[:upper:]' '[:lower:]')
    ne=$(echo "$esperado" | tr '[:upper:]' '[:lower:]')
    [ "$nv" = "true" ] && nv="1"
    [ "$ne" = "true" ] && ne="1"
    if echo "$nv" | grep -Eq '^[0-9]+(\.[0-9]+)?$' && echo "$ne" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
        av=$(printf "%.1f" "$nv"); bv=$(printf "%.1f" "$ne")
        [ "$av" = "$bv" ] && return 0
    fi
    [ "$nv" = "$ne" ]
}
verificar_prop() {
    prop="$1"; esperado="$2"
    valor=$(getprop "$prop" 2>/dev/null)
    nv=$(echo "$valor" | tr '[:upper:]' '[:lower:]')
    ne=$(echo "$esperado" | tr '[:upper:]' '[:lower:]')
    [ "$nv" = "true" ] && nv="1"
    [ "$ne" = "true" ] && ne="1"
    if echo "$nv" | grep -Eq '^[0-9]+(\.[0-9]+)?$' && echo "$ne" | grep -Eq '^[0-9]+(\.[0-9]+)?$'; then
        av=$(printf "%.1f" "$nv"); bv=$(printf "%.1f" "$ne")
        [ "$av" = "$bv" ] && return 0
    fi
    [ "$nv" = "$ne" ]
}
icone() { if "$@"; then printf "${VERDE}🟢${RESET}"; else printf "${VERMELHO}🔴${RESET}"; fi; }

verificar_aceleracao_mouse() {
    ACELERACAO=$(getprop persist.sys.pointer.acceleration 2>/dev/null)
    if [ "$ACELERACAO" = "0" ]; then 
        printf "${VERDE}🟢${RESET}"
    else
        printf "${VERMELHO}🔴${RESET}"
    fi
}

verificar_prioridade_video_externo() {
    PRIORIDADE=$(getprop vendor.display.external_priority 2>/dev/null)
    if [ "$PRIORIDADE" = "1" ]; then 
        printf "${VERDE}🟢${RESET}"
    else
        printf "${VERMELHO}🔴${RESET}"
    fi
}

mapear_tweak_para_comando() {
    case "$1" in
        "Tempo mínimo do toque") echo "$submenu_1_cmd_on" ;;
        "Tempo do toque longo") echo "$submenu_2_cmd_on" ;;
        "Toques rápidos (duplo/triplo)") echo "$submenu_3_cmd_on" ;;
        "Ações automáticas mais rápidas") echo "$submenu_4_cmd_on" ;;
        "Permitir toques no espelhamento") echo "$submenu_5_cmd_on" ;;
        "Desbloquear desempenho do sistema") echo "$submenu_6_cmd_on" ;;
        "USB baixa latência") echo "$submenu_8_cmd_on" ;;
        "Prioridade HID") echo "$submenu_9_cmd_on" ;;
        "Modo High Speed USB") echo "$submenu_10_cmd_on" ;;
        "Potência USB aprimorada") echo "$submenu_11_cmd_on" ;;
        "Anti-jitter USB (mouse)") echo "$submenu_13_cmd_on" ;;
        "Resposta linear do mouse (1:1)") echo "$submenu_14_cmd_on" ;;
        "Aceleração do mouse desligada") echo "$submenu_15_cmd_on" ;;
        "Input: baixa latência") echo "$submenu_17_cmd_on" ;;
        "GPU: baixa latência") echo "$submenu_21_cmd_on" ;;
        "GPU: aceleração de quadros") echo "$submenu_22_cmd_on" ;;
        "Tela interna 120Hz (fixo)") echo "$submenu_23_cmd_on" ;;
        "Prioridade de vídeo externa") echo "$submenu_26_cmd_on" ;;
        "Interrupções USB baixa latência") echo "$submenu_36_cmd_on" ;;
        "Persist Sys CPU Boost") echo "$submenu_65_cmd_on" ;;
        "Window Animation Scale") echo "$submenu_66_cmd_on" ;;
        "Transition Animation Scale") echo "$submenu_67_cmd_on" ;;
        "Animator Duration Scale") echo "$submenu_68_cmd_on" ;;
        "Input Priority") echo "$submenu_33_cmd_on" ;;
        "Input Filter") echo "$submenu_34_cmd_on" ;;
        "Max Events per Sec") echo "$submenu_35_cmd_on" ;;
        "SF Latch Unsignaled") echo "$submenu_73_cmd_on" ;;
        "Display Primary External") echo "$submenu_74_cmd_on" ;;
        "HWUI Render Dirty Regions") echo "$submenu_75_cmd_on" ;;
        "Video Low Latency Path") echo "$submenu_76_cmd_on" ;;
        *) echo "" ;;
    esac
}

aplicar_tweaks_ativos_arquivo() {
    if [ ! -f "$ARQUIVO_TWEAKS_ATIVOS" ]; then
        return
    fi

    while IFS= read -r nome; do
        cmd=$(mapear_tweak_para_comando "$nome")
        if [ -n "$cmd" ]; then
            eval "$cmd"
        fi
    done < "$ARQUIVO_TWEAKS_ATIVOS"
}

ativar_spoof() {
    if [ ! -f "$ARMAZENAMENTO_ORIGINAL" ]; then
        salvar_props_originais
    fi

    touch "$BANDEIRA_SPOOF"
    reconstruir_apenas_spoof

    echo -e "${VERDE}✔ Spoof Realme 15 Pro ativado.${RESET}"
    echo -e "${AMARELO}Obs: Algumas mudanças de prop só aplicam após reboot de apps/sistema.${RESET}"
}

desativar_spoof() {
    rm -f "$BANDEIRA_SPOOF"
    reconstruir_apenas_spoof

    echo -e "${VERDE}✔ Spoof desativado — sistema voltará aos valores originais (ou após reboot).${RESET}"
}

status_spoof() {
    if [ -f "$BANDEIRA_SPOOF" ] && [ -f "$ARQUIVO_SPOOF" ]; then
        return 0
    fi
    return 1
}

submenu_spoof() {
    while true; do
        clear
        printf '\033c'
        echo -e "${NEGRITO}${CIANO}=== Ativar / Desativar Spoof 120 FPS (Realme 15 Pro) ===${RESET}\n"
        if status_spoof; then
            echo -e "${VERDE}Status: Ativado${RESET}\n"
            echo "1) Desativar spoof (remover spoof do módulo)"
        else
            echo -e "${VERMELHO}Status: Desativado${RESET}\n"
            echo "1) Ativar spoof (aplicar spoof Realme 15 Pro)"
        fi
        echo "0) Voltar"
        ler_prompt "> " opcao_spoof
        case "$opcao_spoof" in
            1)
                if status_spoof; then
                    desativar_spoof
                else
                    ativar_spoof
                fi
                pressionar_enter
                ;;
            0) break ;;
            *) echo -e "${VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
        esac
    done
}

alternar_tweak() {
    nome="$1"; cmd_ligado="$2"; cmd_desligado="$3"

    if echo "$cmd_ligado" | grep -qE "^settings"; then
        ns=$(echo "$cmd_ligado" | awk '{print $3}')
        chave=$(echo "$cmd_ligado" | awk '{print $4}')
        valor=$(echo "$cmd_ligado" | awk '{print $5}')
        if verificar_configuracao "$ns" "$chave" "$valor"; then
            desativar_tweak "$nome" "$cmd_desligado"
        else
            ativar_tweak "$nome" "$cmd_ligado"
        fi
    elif echo "$cmd_ligado" | grep -qE "^setprop"; then
        prop=$(echo "$cmd_ligado" | awk '{print $2}')
        valor=$(echo "$cmd_ligado" | awk '{print $3}')
        if verificar_prop "$prop" "$valor"; then
            desativar_tweak "$nome" "$cmd_desligado"
        else
            ativar_tweak "$nome" "$cmd_ligado"
        fi
    else
        ativar_tweak "$nome" "$cmd_ligado"
    fi
    sleep 0.15
}

# =====================================================
# SUBMENUS (chamadas) — comandos usados pelo alternar
# =====================================================

# ALTERADO: 80 → 60
submenu_1_cmd_on="settings put secure tap_duration_threshold 60"
submenu_1_cmd_off="settings put secure tap_duration_threshold 100"
submenu_2_cmd_on="settings put secure long_press_timeout 300"
submenu_2_cmd_off="settings put secure long_press_timeout 500"
# ALTERADO: 130 → 110
submenu_3_cmd_on="settings put secure multi_press_timeout 110"
submenu_3_cmd_off="settings put secure multi_press_timeout 300"
submenu_4_cmd_on="settings put secure accessibility_auto_action_delay 200"
submenu_4_cmd_off="settings put secure accessibility_auto_action_delay 200"
submenu_5_cmd_on="settings put global block_untrusted_touches 0"
submenu_5_cmd_off="settings put global block_untrusted_touches 1"
submenu_6_cmd_on="settings put global restricted_device_performance '0,0'"
submenu_6_cmd_off="settings put global restricted_device_performance '1,1'"

submenu_8_cmd_on="setprop persist.usb.low_latency_mode 1"
submenu_8_cmd_off="setprop persist.usb.low_latency_mode 0"
submenu_9_cmd_on="setprop vendor.usb.hid.priority 2"
submenu_9_cmd_off="setprop vendor.usb.hid.priority 1"
submenu_10_cmd_on="setprop persist.vendor.usb.high_speed 1"
submenu_10_cmd_off="setprop persist.vendor.usb.high_speed 0"
submenu_11_cmd_on="setprop persist.vendor.usb.power 1"
submenu_11_cmd_off="setprop persist.vendor.usb.power 0"
submenu_13_cmd_on="setprop vendor.usb.mouse.jitter_filter 0"
submenu_13_cmd_off="setprop vendor.usb.mouse.jitter_filter 1"

submenu_14_cmd_on="setprop persist.sys.mouse.linear_response 1"
submenu_14_cmd_off="setprop persist.sys.mouse.linear_response 0"
submenu_15_cmd_on="setprop persist.sys.pointer.acceleration 0"
submenu_15_cmd_off="setprop persist.sys.pointer.acceleration 1"

submenu_17_cmd_on="setprop persist.sys.input.low_latency_mode 1"
submenu_17_cmd_off="setprop persist.sys.input.low_latency_mode 0"

submenu_21_cmd_on="setprop persist.sys.gpu.low_latency 1"
submenu_21_cmd_off="setprop persist.sys.gpu.low_latency 0"
submenu_22_cmd_on="setprop persist.sys.gpu.frame_boost 1"
submenu_22_cmd_off="setprop persist.sys.gpu.frame_boost 0"

submenu_23_cmd_on="settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
submenu_23_cmd_off="settings delete system peak_refresh_rate; settings delete system.min_refresh_rate"

submenu_26_cmd_on="setprop vendor.display.external_priority 1"
submenu_26_cmd_off="setprop vendor.display.external_priority 0"

submenu_33_cmd_on="setprop persist.sys.input.priority 1"
submenu_33_cmd_off="setprop persist.sys.input.priority 0"

submenu_34_cmd_on="setprop persist.sys.input.filter 0"
submenu_34_cmd_off="setprop persist.sys.input.filter 1"

# ALTERADO: 90 → 240
submenu_35_cmd_on="setprop windowsmgr.max_events_per_sec 240"
submenu_35_cmd_off="setprop windowsmgr.max_events_per_sec 60"

submenu_36_cmd_on="setprop persist.vendor.usb.low_latency_interrupts 1"
submenu_36_cmd_off="setprop persist.vendor.usb.low_latency_interrupts 0"

submenu_65_cmd_on="setprop persist.sys.cpu.boost 0"
submenu_65_cmd_off="setprop persist.sys.cpu.boost 0"

submenu_66_cmd_on="settings put global window_animation_scale 0"
submenu_66_cmd_off="settings put global window_animation_scale 1"
submenu_67_cmd_on="settings put global transition_animation_scale 0"
submenu_67_cmd_off="settings put global transition_animation_scale 1"
submenu_68_cmd_on="settings put global animator_duration_scale 0"
submenu_68_cmd_off="settings put global animator_duration_scale 1"

submenu_73_cmd_on="setprop debug.sf.latch_unsignaled 0"
submenu_73_cmd_off="setprop debug.sf.latch_unsignaled 0"

submenu_74_cmd_on="setprop persist.sys.display.primary_external 1"
submenu_74_cmd_off="setprop persist.sys.display.primary_external 0"

submenu_75_cmd_on="setprop debug.hwui.render_dirty_regions false"
submenu_75_cmd_off="setprop debug.hwui.render_dirty_regions true"

submenu_76_cmd_on="setprop persist.video.low_latency_path 1"
submenu_76_cmd_off="setprop persist.video.low_latency_path 0"

aplicar_performance_segura() {
    echo -e "${CIANO}${SETA} Ativando modo PERFORMANCE ULTRA SEGURO...${RESET}"
    
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
                governadores_disponiveis=$(cat "$cpu/cpufreq/scaling_available_governors")
                
                if echo "$governadores_disponiveis" | grep -q "performance"; then
                    echo "performance" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                    echo "🚀 CPU$cpu_num: performance ativado"
                elif echo "$governadores_disponiveis" | grep -q "schedutil"; then
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
    
    echo -e "${VERDE}✅ PERFORMANCE ULTRA SEGURO ATIVADO!${RESET}"
    echo -e "${AMARELO}⚠️  Núcleos 0-2 não foram alterados para evitar reinícios${RESET}"
}

restaurar_tudo_padrao() {
    echo -e "${CIANO}${SETA} Restaurando TODAS as configurações para padrão...${RESET}"
    
    echo "🔄 Restaurando governadores de CPU..."
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            cpu_num=$(basename "$cpu" | sed 's/cpu//')
            
            if [ -f "$cpu/cpufreq/scaling_available_governors" ]; then
                governadores_disponiveis=$(cat "$cpu/cpufreq/scaling_available_governors")
                
                if echo "$governadores_disponiveis" | grep -q "schedutil"; then
                    echo "schedutil" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                elif echo "$governadores_disponiveis" | grep -q "interactive"; then
                    echo "interactive" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                fi
            fi
            
            freq_min=$(cat "$cpu/cpufreq/cpuinfo_min_freq" 2>/dev/null)
            freq_max=$(cat "$cpu/cpufreq/cpuinfo_max_freq" 2>/dev/null)
            
            [ -n "$freq_min" ] && echo $freq_min > "$cpu/cpufreq/scaling_min_freq" 2>/dev/null
            [ -n "$freq_max" ] && echo $freq_max > "$cpu/cpufreq/scaling_max_freq" 2>/dev/null
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
    
    echo -e "${VERDE}✅ TODAS as configurações foram restauradas para padrão!${RESET}"
    echo -e "${AMARELO}Algumas mudanças podem requerer reinício para efeito completo.${RESET}"
}

mostrar_status_performance() {
    echo -e "${CIANO}${SETA} Status de Performance Atual:${RESET}"
    
    echo ""
    echo "=== STATUS CPU ==="
    echo "Núcleos ativos: $(grep '^processor' /proc/cpuinfo | wc -l)"
    
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            cpu_num=$(basename $cpu | sed 's/cpu//')
            governador=$(cat $cpu/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
            freq_atual=$(cat $cpu/cpufreq/scaling_cur_freq 2>/dev/null || echo "N/A")
            freq_max=$(cat $cpu/cpufreq/scaling_max_freq 2>/dev/null || echo "N/A")
            
            if [ "$freq_atual" != "N/A" ] && [ "$freq_atual" -gt 1000 ]; then
                freq_atual=$((freq_atual / 1000))"MHz"
            fi
            if [ "$freq_max" != "N/A" ] && [ "$freq_max" -gt 1000 ]; then
                freq_max=$((freq_max / 1000))"MHz"
            fi
            
            if [ "$cpu_num" -lt 3 ]; then
                echo "⚠️  CPU$cpu_num: $governador | Freq: $freq_atual / Max: $freq_max (NÃO ALTERAR)"
            else
                echo "✅ CPU$cpu_num: $governador | Freq: $freq_atual / Max: $freq_max"
            fi
        fi
    done
    
    echo ""
    echo "=== STATUS GPU ==="
    if [ -f "/sys/class/kgsl/kgsl-3d0/gpuclk" ]; then
        clock_gpu=$(cat /sys/class/kgsl/kgsl-3d0/gpuclk)
        echo "Clock GPU: $((clock_gpu / 1000000))MHz"
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
    echo "=== MEMÓRIA ==="
    free -h | grep Mem | awk '{print "Total: " $2 " | Usada: " $3 " | Livre: " $4}'
    
    pressionar_enter
}

aplicar_performance_extrema() {
    echo -e "${VERMELHO}${SETA} ⚠️  ATIVANDO MODO EXTREMO (RISCO ALTO DE REINÍCIO) ⚠️${RESET}"
    echo -e "${AMARELO}Este modo força todos os núcleos no máximo e PODE CAUSAR REINÍCIOS IMEDIATOS!${RESET}"
    
    ler_prompt "Continuar? (s/N): " confirmar
    if [ "$confirmar" != "s" ] && [ "$confirmar" != "S" ]; then
        echo -e "${AMARELO}Cancelado.${RESET}"
        return 1
    fi
    
    echo -e "${VERMELHO}ALERTA: Esta configuração provavelmente causará reinício!${RESET}"
    ler_prompt "Tem certeza absoluta? (s/N): " confirmar2
    if [ "$confirmar2" != "s" ] && [ "$confirmar2" != "S" ]; then
        echo -e "${AMARELO}Cancelado por segurança.${RESET}"
        return 1
    fi
    
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
        if [ -d "$cpu/cpufreq" ]; then
            echo "performance" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
            
            freq_max=$(cat "$cpu/cpufreq/cpuinfo_max_freq" 2>/dev/null)
            if [ -n "$freq_max" ]; then
                echo $freq_max > "$cpu/cpufreq/scaling_min_freq" 2>/dev/null
                echo $freq_max > "$cpu/cpufreq/scaling_max_freq" 2>/dev/null
            fi
        fi
    done
    
    echo -e "${VERDE}✅ MODO EXTREMO ATIVADO!${RESET}"
    echo -e "${VERMELHO}🚨 ALERTA: DISPOSITIVO PODE REINICIAR A QUALQUER MOMENTO!${RESET}"
    echo -e "${VERMELHO}🚨 NÚCLEOS 0-2 FORÇADOS EM PERFORMANCE MÁXIMA - RISCO MUITO ALTO!${RESET}"
}

submenu_reset() {
    clear
    printf '\033c'
    echo -e "${CIANO}Restaurando todas as configurações padrão...${RESET}"

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

    setprop vendor.usb.raw_input.enable 1
    setprop persist.usb.low_latency_mode 0
    setprop vendor.usb.hid.priority 1
    setprop persist.vendor.usb.high_speed 0
    setprop persist.vendor.usb.power 0
    setprop vendor.usb.mouse.jitter_filter 1

    setprop persist.sys.mouse.linear_response 0
    setprop persist.sys.pointer.acceleration 1

    setprop persist.sys.input.low_latency_mode 0
    setprop persist.sys.input.high_update_rate false

    setprop persist.sys.gpu.low_latency 0
    setprop persist.sys.gpu.frame_boost 0

    setprop vendor.display.external_priority 0

    setprop vendor.hid.input.fastpath 0
    setprop persist.sys.input.filter 1
    setprop persist.sys.input.resample 1
    setprop persist.vendor.usb.low_latency_interrupts 1
    setprop persist.sys.input.dispatch_fast 1
    
    setprop debug.input.low_latency 1
    
    setprop windowsmgr.max_events_per_sec 120
    
    setprop debug.sf.late.sf.duration 0
    setprop debug.sf.early.sf.duration 0
    setprop debug.sf.frame_rate_multiple_threshold 60
    setprop debug.sf.high_fps_late.app.duration 0
    setprop debug.sf.high_fps_late.sf.duration 0
    
    setprop debug.hwui.skip_vsync 0
    setprop debug.hwui.render_dirty_regions true
    setprop persist.sys.input.urgent 0
    
    setprop debug.sf.latch_unsignaled 0
    setprop persist.sys.cpu.boost 0
    setprop persist.video.low_latency_path 0
    
    settings put global window_animation_scale 1
    settings put global transition_animation_scale 1
    settings put global animator_duration_scale 1

    setprop persist.sys.input.priority 0
    setprop persist.sys.input.absolute_mode 0
    setprop persist.sys.input.relative_mode 1

    setprop debug.sf.disable_backpressure 0
    setprop persist.sys.display.primary_external 0

    # Limpar arquivos de controle
    rm -rf "$DIRETORIO_BANDEIRAS" 2>/dev/null
    rm -f "$ARQUIVO_SPOOF" "$BANDEIRA_SPOOF" "$ARMAZENAMENTO_ORIGINAL" 2>/dev/null
    rm -f "$MODDIR/ativar_no_boot"
    rm -f "$ARQUIVO_TWEAKS_ATIVOS"

    echo -e "${VERDE}✔ Todos os valores foram resetados para padrão.${RESET}"
    echo -e "${AMARELO}O sistema NÃO será reiniciado.${RESET}"
    sleep 2
}

if [ "$1" = "--ativar-todos" ]; then
    echo -e "${CIANO}Aplicando todos os tweaks (exceto spoof)...${RESET}"
    
    aplicar_se_ativado() {
        NOME_TWEAK="$1"
        COMANDO="$2"
        BANDEIRA="$DIRETORIO_BANDEIRAS/$NOME_TWEAK"
        if [ ! -f "$BANDEIRA" ]; then
            if echo "$COMANDO" | grep -qE "^settings"; then
                eval "$COMANDO"
            elif echo "$COMANDO" | grep -qE "^setprop"; then
                chave_prop=$(echo "$COMANDO" | awk '{print $2}')
                valor_prop=$(echo "$COMANDO" | awk '{print $3}')
                [ -n "$chave_prop" ] && setprop "$chave_prop" "$valor_prop" 2>/dev/null
                adicionar_linha_prop "$chave_prop" "$valor_prop"
            fi
        fi
    }

    aplicar_se_ativado "Tempo mínimo do toque" "$submenu_1_cmd_on"
    aplicar_se_ativado "Tempo do toque longo" "$submenu_2_cmd_on"
    aplicar_se_ativado "Toques rápidos (duplo/triplo)" "$submenu_3_cmd_on"
    aplicar_se_ativado "Ações automáticas mais rápidas" "$submenu_4_cmd_on"
    aplicar_se_ativado "Permitir toques no espelhamento" "$submenu_5_cmd_on"
    aplicar_se_ativado "Desbloquear desempenho do sistema" "$submenu_6_cmd_on"
    aplicar_se_ativado "Tela interna 120Hz (fixo)" "$submenu_23_cmd_on"

    echo -e "${CIANO}Garantindo persistência e aplicando Propriedades...${RESET}"
    reconstruir_system_prop

    aplicar_se_ativado "USB baixa latência" "$submenu_8_cmd_on"
    aplicar_se_ativado "Prioridade HID" "$submenu_9_cmd_on"
    aplicar_se_ativado "Modo High Speed USB" "$submenu_10_cmd_on"
    aplicar_se_ativado "Potência USB aprimorada" "$submenu_11_cmd_on"
    aplicar_se_ativado "Anti-jitter USB (mouse)" "$submenu_13_cmd_on"
    aplicar_se_ativado "Resposta linear do mouse (1:1)" "$submenu_14_cmd_on"
    aplicar_se_ativado "Aceleração do mouse desligada" "$submenu_15_cmd_on"
    aplicar_se_ativado "Input: baixa latência" "$submenu_17_cmd_on"
    aplicar_se_ativado "GPU: baixa latência" "$submenu_21_cmd_on"
    aplicar_se_ativado "GPU: aceleração de quadros" "$submenu_22_cmd_on"
    aplicar_se_ativado "Prioridade de vídeo externa" "$submenu_26_cmd_on"
    aplicar_se_ativado "Interrupções USB baixa latência" "$submenu_36_cmd_on"
    
    aplicar_se_ativado "Window Animation Scale" "$submenu_66_cmd_on"
    aplicar_se_ativado "Transition Animation Scale" "$submenu_67_cmd_on"
    aplicar_se_ativado "Animator Duration Scale" "$submenu_68_cmd_on"
    
    aplicar_se_ativado "Input Priority" "$submenu_33_cmd_on"
    aplicar_se_ativado "Input Filter" "$submenu_34_cmd_on"
    aplicar_se_ativado "Max Events per Sec" "$submenu_35_cmd_on"
    
    aplicar_se_ativado "SF Latch Unsignaled" "$submenu_73_cmd_on"
    aplicar_se_ativado "Display Primary External" "$submenu_74_cmd_on"
    aplicar_se_ativado "HWUI Render Dirty Regions" "$submenu_75_cmd_on"
    aplicar_se_ativado "Video Low Latency Path" "$submenu_76_cmd_on"

    echo -e "${VERDE}✔ Todos os tweaks aplicados (spoof NÃO foi ativado).${RESET}"
    exit 0
fi

if [ "$1" = "--boot" ]; then
    if ! verificar_integridade_licenca; then
        log_seguranca "BOOT_BLOQUEADO: Licença inválida no boot"
        exit 1
    fi
    
    # Aplicar prioridade se estiver ativa
    if [ -f "$ARQUIVO_PRIORIDADE_ATIVA" ]; then
        aplicar_prioridade_ggmouse_ff
    fi
    
    aplicar_tweaks_ativos_arquivo
    if [ -f "$BANDEIRA_SPOOF" ]; then
        ativar_spoof
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
        echo -e "${NEGRITO}${CIANO}🔥 COMANDOS INDIVIDUAIS${RESET}"
        echo -e "${NEGRITO}${CIANO}────────────────────────────────────${RESET}"
        echo -e "${VERDE}🟢 ATIVO     ${VERMELHO}🔴 DESATIVADO${RESET}\n"

        printf " %b [01] ⏱ Tempo mínimo do toque\n" "$(icone verificar_configuracao secure tap_duration_threshold 60)"
        printf " %b [02] ⌛ Tempo do toque longo\n" "$(icone verificar_configuracao secure long_press_timeout 300)"
        printf " %b [03] ⚡ Toques rápidos (duplo / triplo)\n" "$(icone verificar_configuracao secure multi_press_timeout 110)"
        printf " %b [04] 🤖 Ações automáticas mais rápidas\n" "$(icone verificar_configuracao secure accessibility_auto_action_delay 200)"
        printf " %b [05] 🖥 Toque no espelhamento\n" "$(icone verificar_configuracao global block_untrusted_touches 0)"
        printf " %b [06] 🚀 Desempenho do sistema\n" "$(icone verificar_configuracao global restricted_device_performance '0,0')"
        echo ""

        printf " %b [07] ⚡ USB baixa latência\n" "$(icone verificar_prop persist.usb.low_latency_mode 1)"
        printf " %b [08] 🎯 Prioridade HID\n" "$(icone verificar_prop vendor.usb.hid.priority 2)"
        printf " %b [09] 🚄 USB High Speed\n" "$(icone verificar_prop persist.vendor.usb.high_speed 1)"
        printf " %b [10] 🔋 Potência USB\n" "$(icone verificar_prop persist.vendor.usb.power 1)"
        printf " %b [11] 🖱 Anti-jitter mouse\n" "$(icone verificar_prop vendor.usb.mouse.jitter_filter 0)"
        echo ""

        printf " %b [12] 🎯 Mouse linear (1:1)\n" "$(icone verificar_prop persist.sys.mouse.linear_response 1)"
        printf " %b [13] 🚫 Mouse sem aceleração\n" "$(verificar_aceleracao_mouse)"
        printf " %b [14] ⚡ Input baixa latência\n" "$(icone verificar_prop persist.sys.input.low_latency_mode 1)"
        echo ""

        printf " %b [15] 🎮 GPU baixa latência\n" "$(icone verificar_prop persist.sys.gpu.low_latency 1)"
        printf " %b [16] 🧩 GPU aceleração quadros\n" "$(icone verificar_prop persist.sys.gpu.frame_boost 1)"
        echo ""

        printf " %b [17] 📱 Tela 120Hz fixo\n" "$(icone verificar_configuracao system peak_refresh_rate 120)"
        printf " %b [18] 📺 Prioridade vídeo externa\n" "$(verificar_prioridade_video_externo)"
        echo ""

        printf " %b [19] ⏱ IRQ USB baixa latência\n" "$(icone verificar_prop persist.vendor.usb.low_latency_interrupts 1)"
        echo ""

        printf " %b [20] 🪟 Window Animation Scale\n" "$(icone verificar_configuracao global window_animation_scale 0)"
        printf " %b [21] 🔄 Transition Animation Scale\n" "$(icone verificar_configuracao global transition_animation_scale 0)"
        printf " %b [22] ⏱️ Animator Duration Scale\n" "$(icone verificar_configuracao global animator_duration_scale 0)"
        printf " %b [23] 🎯 Input Priority\n" "$(icone verificar_prop persist.sys.input.priority 1)"
        printf " %b [24] 🚫 Input Filter\n" "$(icone verificar_prop persist.sys.input.filter 0)"
        printf " %b [25] 🪟 Max Events per Sec\n" "$(icone verificar_prop windowsmgr.max_events_per_sec 240)"
        
        printf " %b [26] 🔒 SF Latch Unsignaled\n" "$(icone verificar_prop debug.sf.latch_unsignaled 0)"
        printf " %b [27] 🖥 Display Primary External\n" "$(icone verificar_prop persist.sys.display.primary_external 1)"
        printf " %b [28] 🎨 HWUI Render Dirty Regions\n" "$(icone verificar_prop debug.hwui.render_dirty_regions false)"
        printf " %b [29] 🎬 Video Low Latency Path\n" "$(icone verificar_prop persist.video.low_latency_path 1)"
        
        echo -e "\n${NEGRITO}${CIANO}────────────────────────────────────${RESET}"
        
        if status_spoof; then
            ICON_SPOOF="${VERDE}🟢${RESET}"
        else
            ICON_SPOOF="${VERMELHO}🔴${RESET}"
        fi
        printf " %b [30] 🎯 Spoof 120 FPS\n" "$ICON_SPOOF"
        printf " ${VERMELHO}🔴${RESET} [31] ♻️  Reset total\n"
        
        echo -e "\n${NEGRITO}${CIANO}[0] ⬅️ Voltar${RESET}"
        echo ""
        ler_prompt "➤ Selecione uma opção: " item

        case "$item" in
            01) alternar_tweak "Tempo mínimo do toque" "$submenu_1_cmd_on" "$submenu_1_cmd_off" ;;
            02) alternar_tweak "Tempo do toque longo" "$submenu_2_cmd_on" "$submenu_2_cmd_off" ;;
            03) alternar_tweak "Toques rápidos (duplo/triplo)" "$submenu_3_cmd_on" "$submenu_3_cmd_off" ;;
            04) alternar_tweak "Ações automáticas mais rápidas" "$submenu_4_cmd_on" "$submenu_4_cmd_off" ;;
            05) alternar_tweak "Permitir toques no espelhamento" "$submenu_5_cmd_on" "$submenu_5_cmd_off" ;;
            06) alternar_tweak "Desbloquear desempenho do sistema" "$submenu_6_cmd_on" "$submenu_6_cmd_off" ;;
            07) alternar_tweak "USB baixa latência" "$submenu_8_cmd_on" "$submenu_8_cmd_off" ;;
            08) alternar_tweak "Prioridade HID" "$submenu_9_cmd_on" "$submenu_9_cmd_off" ;;
            09) alternar_tweak "Modo High Speed USB" "$submenu_10_cmd_on" "$submenu_10_cmd_off" ;;
            10) alternar_tweak "Potência USB aprimorada" "$submenu_11_cmd_on" "$submenu_11_cmd_off" ;;
            11) alternar_tweak "Anti-jitter USB (mouse)" "$submenu_13_cmd_on" "$submenu_13_cmd_off" ;;
            12) alternar_tweak "Resposta linear do mouse (1:1)" "$submenu_14_cmd_on" "$submenu_14_cmd_off" ;;
            13) alternar_tweak "Aceleração do mouse desligada" "$submenu_15_cmd_on" "$submenu_15_cmd_off" ;;
            14) alternar_tweak "Input: baixa latência" "$submenu_17_cmd_on" "$submenu_17_cmd_off" ;;
            15) alternar_tweak "GPU: baixa latência" "$submenu_21_cmd_on" "$submenu_21_cmd_off" ;;
            16) alternar_tweak "GPU: aceleração de quadros" "$submenu_22_cmd_on" "$submenu_22_cmd_off" ;;
            17) alternar_tweak "Tela interna 120Hz (fixo)" "$submenu_23_cmd_on" "$submenu_23_cmd_off" ;;
            18) alternar_tweak "Prioridade de vídeo externa" "$submenu_26_cmd_on" "$submenu_26_cmd_off" ;;
            19) alternar_tweak "Interrupções USB baixa latência" "$submenu_36_cmd_on" "$submenu_36_cmd_off" ;;
            20) alternar_tweak "Window Animation Scale" "$submenu_66_cmd_on" "$submenu_66_cmd_off" ;;
            21) alternar_tweak "Transition Animation Scale" "$submenu_67_cmd_on" "$submenu_67_cmd_off" ;;
            22) alternar_tweak "Animator Duration Scale" "$submenu_68_cmd_on" "$submenu_68_cmd_off" ;;
            23) alternar_tweak "Input Priority" "$submenu_33_cmd_on" "$submenu_33_cmd_off" ;;
            24) alternar_tweak "Input Filter" "$submenu_34_cmd_on" "$submenu_34_cmd_off" ;;
            25) alternar_tweak "Max Events per Sec" "$submenu_35_cmd_on" "$submenu_35_cmd_off" ;;
            26) alternar_tweak "SF Latch Unsignaled" "$submenu_73_cmd_on" "$submenu_73_cmd_off" ;;
            27) alternar_tweak "Display Primary External" "$submenu_74_cmd_on" "$submenu_74_cmd_off" ;;
            28) alternar_tweak "HWUI Render Dirty Regions" "$submenu_75_cmd_on" "$submenu_75_cmd_off" ;;
            29) alternar_tweak "Video Low Latency Path" "$submenu_76_cmd_on" "$submenu_76_cmd_off" ;;
            30) submenu_spoof ;;
            31) submenu_reset ;;
            0) return ;;
            *) echo -e "${VERMELHO}Opção inválida...${RESET}"; sleep 1 ;;
        esac
    done
}

###############################################################################
# 🖥️ CONFIGURADOR SIMPLIFICADO DE RESOLUÇÃO
###############################################################################

config_resolucao_dpi() {
    while true; do
        clear
        printf '\033c'
        echo -e "${NEGRITO}${CIANO}=== CONFIGURADOR DE RESOLUÇÃO ===${RESET}\n"
        
        RESOLUCAO_ATUAL=$(wm size 2>/dev/null | grep -oE "[0-9]+x[0-9]+" || echo "Desconhecido")
        DPI_ATUAL=$(wm density 2>/dev/null | grep -oE "[0-9]+" || echo "Desconhecido")
        
        echo -e "${AMARELO}⚙️  Configurações atuais:${RESET}"
        echo -e "📱 Resolução: ${VERDE}${RESOLUCAO_ATUAL}${RESET}"
        echo -e "🎯 DPI: ${VERDE}${DPI_ATUAL}${RESET}"
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
        
        ler_prompt "> " opcao_res
        
        case "$opcao_res" in
            1) nova_res="1080x1920"; nova_dpi="400" ;;
            2) nova_res="1440x2560"; nova_dpi="400" ;;
            3) 
                while true; do
                    ler_prompt "Digite a resolução (ex: 720x1280): " nova_res
                    if echo "$nova_res" | grep -Eq '^[0-9]+x[0-9]+$'; then
                        break
                    else
                        echo -e "${VERMELHO}❌ Formato inválido! Use LarguraxAltura (ex: 720x1280)${RESET}"
                    fi
                done
                
                while true; do
                    ler_prompt "Digite o DPI (ex: 320): " nova_dpi
                    if echo "$nova_dpi" | grep -Eq '^[0-9]+$'; then
                        break
                    else
                        echo -e "${VERMELHO}❌ DPI inválido! Use apenas números${RESET}"
                    fi
                done
                ;;
            4) 
                restaurar_padrao_resolucao
                pressionar_enter
                continue
                ;;
            0) return ;;
            *)
                echo -e "${VERMELHO}Opção inválida!${RESET}"
                sleep 1
                continue
                ;;
        esac
        
        aplicar_resolucao_dpi "$nova_res" "$nova_dpi"
        pressionar_enter
    done
}

restaurar_padrao_resolucao() {
    echo -e "${CIANO}Restaurando configuração padrão do dispositivo...${RESET}"
    
    wm size reset
    wm density reset
    
    rm -f "$MODDIR/config_resolucao" 2>/dev/null
    
    echo -e "${VERDE}✅ Configuração padrão restaurada!${RESET}"
    echo -e "${AMARELO}Alguns apps podem precisar ser reiniciados.${RESET}"
    
    sleep 2
}

aplicar_resolucao_dpi() {
    nova_res="$1"
    nova_dpi="$2"
    
    clear
    printf '\033c'
    echo -e "${NEGRITO}${CIANO}=== APLICANDO CONFIGURAÇÃO ===${RESET}\n"
    
    echo -e "📱 ${VERDE}Nova Resolução: ${nova_res}${RESET}"
    echo -e "🎯 ${VERDE}Novo DPI: ${nova_dpi}${RESET}"
    
    echo -e "\n${AMARELO}Aplicando configuração...${RESET}"
    wm size "${nova_res}"
    wm density "${nova_dpi}"
    
    RES_APLICADA=$(wm size 2>/dev/null | grep -oE "[0-9]+x[0-9]+" || echo "")
    DPI_APLICADO=$(wm density 2>/dev/null | grep -oE "[0-9]+" || echo "")
    
    if [ "$RES_APLICADA" = "$nova_res" ] && [ "$DPI_APLICADO" = "$nova_dpi" ]; then
        echo -e "${VERDE}✅ Configuração aplicada com sucesso!${RESET}"
        
        ARQUIVO_CONFIG_RES="$MODDIR/config_resolucao"
        echo "${nova_res}|${nova_dpi}" > "$ARQUIVO_CONFIG_RES"
        
        ARQUIVO_BOOT="$MODDIR/ativar_no_boot"
        if [ -f "$ARQUIVO_BOOT" ]; then
            if ! grep -q "aplicar_resolucao_no_boot" "$ARQUIVO_BOOT"; then
                echo "aplicar_resolucao_no_boot" >> "$ARQUIVO_BOOT"
            fi
        fi
        
    else
        echo -e "${VERMELHO}❌ Erro ao aplicar configuração${RESET}"
        echo -e "${AMARELO}Aplicado: ${RES_APLICADA} (DPI: ${DPI_APLICADO})${RESET}"
    fi
}

aplicar_resolucao_no_boot() {
    if [ -f "$MODDIR/config_resolucao" ]; then
        config=$(cat "$MODDIR/config_resolucao")
        nova_res=$(echo "$config" | cut -d'|' -f1)
        nova_dpi=$(echo "$config" | cut -d'|' -f2)
        
        if [ -n "$nova_res" ] && [ -n "$nova_dpi" ]; then
            sleep 3
            wm size "${nova_res}" 2>/dev/null
            wm density "${nova_dpi}" 2>/dev/null
        fi
    fi
}

###############################################################################
# MENU PRINCIPAL SEGURO
###############################################################################
menu() {
    if ! verificar_integridade_licenca; then
        echo -e "${VERMELHO}⛔ ACESSO NEGADO: Licença inválida ou expirada${RESET}"
        echo -e "${AMARELO}Execute o script novamente para autenticar.${RESET}"
        sleep 3
        return 1
    fi
    
    if ! verificar_sessao; then
        echo -e "${AMARELO}⚠️  Sessão expirada. Faça login novamente.${RESET}"
        sleep 2
        rm -f "$ARQUIVO_SESSAO"
        return 1
    fi
    
    while true; do
        clear
        printf '\033c'
        
        if ! verificar_integridade_licenca; then
            echo -e "${VERMELHO}⛔ ACESSO NEGADO: Licença inválida ou expirada${RESET}"
            echo -e "${AMARELO}Execute o script novamente para autenticar.${RESET}"
            sleep 3
            return 1
        fi

        verificar_aviso_licenca

        echo -e "\033[1;37m🔥 FERA ALPHA • ULTRA GAMER"
        echo -e "\033[1;37m────────────────────────────"
        
        if [ -f "$ARQUIVO_LICENCA" ]; then
            EXP=$(cat "$ARQUIVO_LICENCA" 2>/dev/null)
            AGORA=$(date +%s)
            if echo "$EXP" | grep -qE '^[0-9]+$'; then
                DIFERENCA=$((EXP - AGORA))
                DIAS=$((DIFERENCA / 86400))
                
                if [ "$DIAS" -gt 365 ]; then
                    TEXTO_STATUS="Status: \033[1;37m🟢 Ativo | VIP ILIMITADO\033[0m"
                elif [ "$DIAS" -gt 0 ]; then
                    if [ "$DIAS" -lt 10 ]; then
                        TEXTO_STATUS="Status: \033[1;31m🟢 Ativo | ⏳ $DIAS dias\033[0m"
                    else
                        TEXTO_STATUS="Status: \033[1;37m🟢 Ativo | ⏳ $DIAS dias\033[0m"
                    fi
                else
                    TEXTO_STATUS="Status: \033[1;31m🔴 Expirado\033[0m"
                fi
                echo -e "$TEXTO_STATUS"
            else
                echo -e "Status: \033[1;31m🔴 Inválido\033[0m"
            fi
        else
            echo -e "Status: \033[1;31m🔴 Não ativo\033[0m"
        fi
        
        echo -e "\033[1;37m────────────────────────────\033[0m"
        echo ""
        
        echo -e "\033[1;37m⚡ AÇÃO RÁPIDA\033[0m"
        echo -e "\033[1;37m[01] ⚡ Aplicar tudo\033[0m"
        echo -e "\033[1;37m[02] 🎛 Comandos individuais\033[0m"
        
        # Mostrar status da prioridade GG Mouse + FF
        if verificar_prioridade_ativa; then
            echo -e "\033[1;37m[03] ${VERDE}🟢${RESET} Prioridade GG Mouse + FF\033[0m"
        else
            echo -e "\033[1;37m[03] ${VERMELHO}🔴${RESET} Prioridade GG Mouse + FF\033[0m"
        fi
        
        echo ""
        
        echo -e "\033[1;37m🚀 DESEMPENHO\033[0m"
        echo -e "\033[1;37m[04] 🚀 Performance Máxima\033[0m"
        echo -e "\033[1;37m[05] 🔥 Extremo (sem limites)\033[0m"
        echo ""
        
        echo -e "\033[1;37m🎮 JOGOS\033[0m"
        echo -e "\033[1;37m[06] 🎯 Apps GG Mouse + FF\033[0m"
        echo -e "\033[1;37m[07] 🎯 Spoof 120 FPS\033[0m"
        echo -e "\033[1;37m[08] 🖥 Resolução / DPI\033[0m"
        echo ""
        
        echo -e "\033[1;37m🧠 SISTEMA\033[0m"
        echo -e "\033[1;37m[09] 📊 Status do sistema\033[0m"
        echo -e "\033[1;37m[10] ⚙ Atualização\033[0m"
        echo -e "\033[1;37m[11] 🧹 Limpar cache\033[0m"
        echo ""
        
        echo -e "\033[1;37m🔄 MANUTENÇÃO\033[0m"
        echo -e "\033[1;37m[12] 🔄 Reiniciar\033[0m"
        echo -e "\033[1;37m[13] ♻ Reset geral\033[0m"
        echo ""
        
        echo -e "\033[1;37m[00] ❌ Sair\033[0m"
        echo -e "\033[1;37m────────────────────────────\033[0m"
        echo ""
        echo -n -e "\033[1;37m➤ Selecione uma opção: \033[0m"
        read op

        case "$op" in
            01) 
                sh "$0" --ativar-todos
                pressionar_enter
                ;;
            02) 
                menu_todos_tweaks
                ;;
            03) 
                alternar_prioridade_ggmouse_ff
                pressionar_enter
                ;;
            04) 
                aplicar_performance_segura
                pressionar_enter
                ;;
            05) 
                aplicar_performance_extrema
                pressionar_enter
                ;;
            06) 
                menu_apps_prioritarios_simples
                ;;
            07) 
                submenu_spoof
                ;;
            08) 
                config_resolucao_dpi
                ;;
            09) 
                mostrar_status_performance
                ;;
            10) 
                menu_config_update
                ;;
            11) 
                limpar_cache_simples
                ;;
            12) 
                reiniciar_dispositivo_simples
                ;;
            13) 
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

###############################################################################
# FLUXO PRINCIPAL COM SEGURANÇA FORTIFICADA
###############################################################################

echo "[$(date '+%Y-%m-%d %H:%M:%S')] INICIO: Script iniciado" > "$LOG_SEGURANCA"

verificacao_inicial

if [ -f "$ARQUIVO_SESSAO" ] && verificar_integridade_licenca; then
    TEMPO_SESSAO=$(stat -c %Y "$ARQUIVO_SESSAO" 2>/dev/null || echo "0")
    AGORA=$(date +%s)
    
    if [ $((AGORA - TEMPO_SESSAO)) -le 86400 ]; then
        echo -e "${VERDE}✅ Sessão válida detectada. Acessando painel...${RESET}"
        sleep 1
        menu
        exit 0
    else
        rm -f "$ARQUIVO_SESSAO"
        log_seguranca "SESSAO_EXPIRADA: Removendo sessão antiga"
    fi
fi

tentativas=0
MAX_TENTATIVAS=3

while [ $tentativas -lt $MAX_TENTATIVAS ]; do
    barra_carregamento
    cabecalho
    entrada_login

    echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"
    ativar_servidor "$USUARIO" "$SENHA"

    if [ $? -eq 0 ]; then
        bem_vindo
        menu
        break
    fi

    erro_login
    tentativas=$((tentativas+1))
    echo -e "\033[1;33mTentativas restantes: $((MAX_TENTATIVAS-tentativas))\033[0m"
    
    log_seguranca "TENTATIVA_FALHA_$tentativas: Usuário=$USUARIO"
    
    if [ $tentativas -ge $MAX_TENTATIVAS ]; then
        echo -e "\033[1;31m🚫 Muitas tentativas falhas. Aguarde 60 segundos.\033[0m"
        log_seguranca "BLOQUEIO_TEMPORARIO: Muitas tentativas falhas"
        sleep 60
        tentativas=0
    else
        sleep 2
    fi
done

if [ $tentativas -ge $MAX_TENTATIVAS ]; then
    echo -e "\033[1;31m❌ Falha ao autenticar. Saindo.\033[0m"
    log_seguranca "SAIDA: Autenticação falhou após $MAX_TENTATIVAS tentativas"
    exit 1
fi

exit 0
