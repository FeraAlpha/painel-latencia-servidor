###############################################################
#                  🔐 LOGIN OBRIGATÓRIO SEMPRE
#     Toda vez que abrir o painel no Termux, pede login
###############################################################

MODDIR=${0%/*}
SERVER="https://painel-licenca-server.onrender.com"
LICENSE_FILE="$MODDIR/license_info"
RESET_SCRIPT="$MODDIR/reset_auto.sh"

# ---- Gera fingerprint única ----
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

###############################################################
#        ⏳ SISTEMA DE EXPIRAÇÃO + RESET AUTOMÁTICO
#  Se a licença vencer, o painel reseta tudo e bloqueia acesso
###############################################################

reset_total_auto() {
    echo "⚠ RESET AUTOMÁTICO — LICENÇA EXPIRADA" > /dev/kmsg

    cat > "$RESET_SCRIPT" <<'EOF'
#!/system/bin/sh
# RESET COMPLETO AUTOMÁTICO DA LICENÇA

# TOQUE
settings delete secure tap_duration_threshold
settings delete secure long_press_timeout
settings delete secure multi_press_timeout
settings delete secure accessibility_auto_action_delay

# SISTEMA
settings delete global block_untrusted_touches
settings delete global restricted_device_performance

# DISPLAY
settings delete system peak_refresh_rate
settings delete system min_refresh_rate
settings delete global display_dual_output

# GAMEPAD
settings delete global gamepad.latency_reduction

# USB / HID
setprop vendor.usb.raw_input.enable 0
setprop persist.usb.low_latency_mode 0
setprop vendor.usb.hid.priority 0
setprop persist.vendor.usb.high_speed 0
setprop persist.vendor.usb.power 0
setprop vendor.usb.hub.boost 0
setprop vendor.usb.mouse.jitter_filter 0

# MOUSE
setprop persist.sys.mouse.linear_response 0
setprop persist.sys.pointer.acceleration 1
setprop persist.input.pointer_jitter_smoothing 0

# INPUT
setprop persist.sys.input.low_latency_mode 0
setprop persist.sys.input.high_update_rate false
setprop persist.sys.input.boost 0

# GPU
setprop debug.hwui.disable_vsync false
setprop persist.sys.gpu.low_latency 0
setprop persist.sys.gpu.frame_boost 0

# DISPLAY
setprop persist.sys.display.force_refresh 60
setprop vendor.display.external_priority 0
setprop persist.video.duplicate.display 0

# FLAGS
rm -rf "$MODDIR/disabled_flags"
rm -f "$MODDIR/system.prop" "$MODDIR/spoof_enabled"
rm -f "$MODDIR/original.props"

# LICENÇA
rm -f "$MODDIR/license_info"

# REBOOT
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

# Executa verificação de expiração TODA VEZ que abrir o painel
verifica_expiracao

###############################################################
# ---- Autenticação no servidor ----
###############################################################
ativar_servidor() {
  USER="$1"
  PASS="$2"
  FP=$(gera_fingerprint)

  JSON="{\"username\":\"$USER\",\"password\":\"$PASS\",\"fingerprint\":\"$FP\"}"

  echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"
  RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")

  if echo "$RESP" | grep -q '"status":"error"' || echo "$RESP" | grep -q '"error"'; then
    REASON=$(echo "$RESP" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
    echo -e "\033[1;31m❌ Erro: ${REASON:-Credenciais inválidas}\033[0m"
    return 1
  fi

  echo -e "\033[1;32m✔ Login aprovado!\033[0m"

  # ---- Salvar data de expiração retornada pelo servidor ----
  EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
  if [ ! -z "$EXP" ]; then
    echo "$EXP" > "$MODDIR/license_info"
  fi

  return 0
}

###############################################################
# ---- Painel de Login ----
###############################################################
painel_login() {
  clear
  echo "======================================"
  echo "       🔐 FERA ALPHA — LOGIN"
  echo "======================================"
  echo -n "Usuário: "
  read USER
  echo -n "Senha: "
  stty -echo
  read PASS
  stty echo
  echo ""

  ativar_servidor "$USER" "$PASS"
  return $?
}

###############################################################
# ---- Entrada obrigatória ----
###############################################################
tent=0
while [ $tent -lt 3 ]; do
  painel_login
  [ $? -eq 0 ] && break
  tent=$((tent+1))
  echo -e "\033[1;33mTentativas restantes: $((3-tent))\033[0m"
done

if [ $tent -ge 3 ]; then
  echo -e "\033[1;31m❌ Falha ao autenticar. Saindo.\033[0m"
  exit 1
fi

# =====================================================
#         🎮 FERA ALPHA – PAINEL DE PERFORMANCE GAMING 🎮
#               Painel de Desempenho / Latência
# =====================================================

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

# Paths para spoof e flags (DIRETÓRIO DE FLAGS ADICIONADO AQUI)
SPOOF_FLAG="$MODDIR/spoof_habilitado"
SPOOF_FILE="$MODDIR/system.prop"
ORIG_STORE="$MODDIR/props_originais.txt"
FLAG_DIR="$MODDIR/flags_desabilitadas"
mkdir -p "$FLAG_DIR" 2>/dev/null # Garante que o diretório de flags exista

# =====================================================
# Variáveis de Cache de Status (PREENCHIDAS ANTES DO MENU)
# =====================================================
PROP_CACHE=""
SETTING_CACHE=""

# =====================================================
# ⚡ CARREGAR TODOS OS STATUS EM CACHE (Para acelerar o menu) ⚡
# =====================================================
cache_status() {
    # Coleta todas as propriedades (getprop) e configurações (settings) em uma única execução
    PROP_CACHE=$(getprop)
    SETTING_CACHE=$(settings list secure)
    SETTING_CACHE="$SETTING_CACHE $(settings list global)"
    SETTING_CACHE="$SETTING_CACHE $(settings list system)"
}

# ====== Checagens inteligentes AGORA USAM O CACHE ======
check_setting() {
    ns="$1"; key="$2"; exp="$3"
    # Procura a chave no cache de settings (independente do namespace)
    val=$(echo "$SETTING_CACHE" | grep -m 1 "$key=" | cut -d'=' -f2)
    
    # Lógica de comparação (usa o valor encontrado no cache)
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
    # Procura a chave no cache de props (Propriedades são formatadas como [prop] [valor])
    val=$(echo "$PROP_CACHE" | grep -m 1 "\[$prop\]" | cut -d'[' -f3 | cut -d']' -f1)
    
    # Lógica de comparação (usa o valor encontrado no cache)
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
# GERENCIAMENTO CENTRALIZADO DE PROPS (Para persistência no Magisk)
# =====================================================
rebuild_system_prop() {
    # 1. Limpa o arquivo atual
    rm -f "$SPOOF_FILE" 2>/dev/null
    
    # 2. Adiciona as propriedades do SPOOF (se a flag existir)
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

    # 3. Adiciona as propriedades dos TWEAKS (se a flag de desativação NÃO existir)
    echo -e "\n# Tweaks de Propriedades Ativos\n" >> "$SPOOF_FILE"
    
    # Mapeamento TWEAK_NAME="prop=valor"
    TWEAK_PROPS=(
        # USB/INPUT Existentes
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
        # NOVAS PROPRIEDADES
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
            echo "$PROP_VAL" >> "$SPOOF_FILE"
            
            # Aplica imediatamente (setprop)
            prop_key=$(echo "$PROP_VAL" | cut -d'=' -f1)
            prop_value=$(echo "$PROP_VAL" | cut -d'=' -f2)
            setprop "$prop_key" "$prop_value"
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
        
        # Tenta aplicar o comando OFF imediatamente
        prop_key=$(echo "$cmd" | cut -d' ' -f2)
        prop_value=$(echo "$cmd" | cut -d' ' -f3)
        setprop "$prop_key" "$prop_value" 
        
        rebuild_system_prop
    fi

    echo -e "${RED}✔ Desativado: $nome${RESET}"
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
        printf '\033c' # LIMPEZA FORÇADA
        echo -e "${BOLD}${CYAN}=== Habilitar / Desabilitar Spoof 120 FPS (Realme 15 Pro) ===${RESET}\n"
        if spoof_status; then
            echo -e "${GREEN}Status: Habilitado${RESET}\n"
            echo "1) Desabilitar spoof (remover spoof do módulo)"
        else
            echo -e "${RED}Status: Desabilitado${RESET}\n"
            echo "1) Habilitar spoof (aplicar spoof Realme 15 Pro)"
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
DESC_10="- Tenta forçar USB em alta velocidade (pode ajudar adaptadores)."
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
    printf '\033c' # LIMPEZA FORÇADA
    echo -e "${BOLD}${CYAN}=== $nome ===${RESET}"
    echo -e "${YELLOW}$desc${RESET}\n"
    echo "1) ${GREEN}Habilitar${RESET}"
    echo "2) ${RED}Desabilitar${RESET}"
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
# Submenus (apenas chamadas)
# =====================================================
submenu_1() { submenu_tela "Toque: Tempo Mínimo" "$DESC_1" "settings put secure tap_duration_threshold 70" "settings delete secure tap_duration_threshold"; }
submenu_2() { submenu_tela "Toque: Longo (Timeout)" "$DESC_2" "settings put secure long_press_timeout 300" "settings delete secure long_press_timeout"; }
submenu_3() { submenu_tela "Toque: Múltiplos (Fast Tap)" "$DESC_3" "settings put secure multi_press_timeout 130" "settings delete secure multi_press_timeout"; }
submenu_4() { submenu_tela "Acessibilidade: Ação Rápida" "$DESC_4" "settings put secure accessibility_auto_action_delay 200" "settings delete secure accessibility_auto_action_delay"; }
submenu_5() { submenu_tela "Sistema: Bloqueio de Toques OFF" "$DESC_5" "settings put global block_untrusted_touches 0" "settings delete global block_untrusted_touches"; }
submenu_6() { submenu_tela "Sistema: Performance Máx" "$DESC_6" "settings put global restricted_device_performance '0,0'" "settings delete global restricted_device_performance"; }

submenu_7() { submenu_tela "USB: Raw Input" "$DESC_7" "setprop vendor.usb.raw_input.enable 1" "setprop vendor.usb.raw_input.enable 0"; }
submenu_8() { submenu_tela "USB: Low Latency Mode" "$DESC_8" "setprop persist.usb.low_latency_mode 1" "setprop persist.usb.low_latency_mode 0"; }
submenu_9() { submenu_tela "USB: HID Priority" "$DESC_9" "setprop vendor.usb.hid.priority 2" "setprop vendor.usb.hid.priority 1"; }
submenu_10() { submenu_tela "USB: High Speed" "$DESC_10" "setprop persist.vendor.usb.high_speed 1" "setprop persist.vendor.usb.high_speed 0"; }
submenu_11() { submenu_tela "USB: Power Boost" "$DESC_11" "setprop persist.vendor.usb.power 1" "setprop persist.vendor.usb.power 0"; }
submenu_12() { submenu_tela "USB: Hub Boost" "$DESC_12" "setprop vendor.usb.hub.boost 1" "setprop vendor.usb.hub.boost 0"; }
submenu_13() { submenu_tela "Mouse: Anti-Jitter USB" "$DESC_13" "setprop vendor.usb.mouse.jitter_filter 1" "setprop vendor.usb.mouse.jitter_filter 0"; }

submenu_14() { submenu_tela "Mouse: Resposta Linear" "$DESC_14" "setprop persist.sys.mouse.linear_response 1" "setprop persist.sys.mouse.linear_response 0"; }
submenu_15() { submenu_tela "Mouse: Aceleração OFF" "$DESC_15" "setprop persist.sys.pointer.acceleration 0" "setprop persist.sys.pointer.acceleration 1"; }
submenu_16() { submenu_tela "Mouse: Anti-jitter do ponteiro" "$DESC_16" "setprop persist.input.pointer_jitter_smoothing 1" "setprop persist.input.pointer_jitter_smoothing 0"; }

submenu_17() { submenu_tela "Input: Low Latency Mode" "$DESC_17" "setprop persist.sys.input.low_latency_mode 1" "setprop persist.sys.input.low_latency_mode 0"; }
submenu_18() { submenu_tela "Input: High Update Rate" "$DESC_18" "setprop persist.sys.input.high_update_rate true" "setprop persist.sys.input.high_update_rate false"; }
submenu_19() { submenu_tela "Input: Boost" "$DESC_19" "setprop persist.sys.input.boost 1" "setprop persist.sys.input.boost 0"; }

submenu_20() { submenu_tela "GPU: VSync OFF (HWUI)" "$DESC_20" "setprop debug.hwui.disable_vsync true" "setprop debug.hwui.disable_vsync false"; }
submenu_21() { submenu_tela "GPU: Low Latency" "$DESC_21" "setprop persist.sys.gpu.low_latency 1" "setprop persist.sys.gpu.low_latency 0"; }
submenu_22() { submenu_tela "GPU: Frame Boost" "$DESC_22" "setprop persist.sys.gpu.frame_boost 1" "setprop persist.sys.gpu.frame_boost 0"; }

submenu_23() { submenu_tela "Display: Refresh Interno 120Hz" "$DESC_23" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120" "settings delete system peak_refresh_rate; settings delete system min_refresh_rate"; }
submenu_24() { submenu_tela "Display: Forçar Refresh 120Hz" "$DESC_24" "setprop persist.sys.display.force_refresh 120" "setprop persist.sys.display.force_refresh 60"; }
submenu_25() { submenu_tela "Display: Duplicação Externa" "$DESC_25" "setprop persist.video.duplicate.display 1" "setprop persist.video.duplicate.display 0"; }
submenu_26() { submenu_tela "Display: Prioridade Externa" "$DESC_26" "setprop vendor.display.external_priority 1" "setprop vendor.display.external_priority 0"; }
submenu_27() { submenu_tela "Display: Saída Dual" "$DESC_27" "settings put global display_dual_output 1" "settings delete global display_dual_output"; }

submenu_28() { submenu_tela "Gamepad: Redução de latência" "$DESC_28" "settings put global gamepad.latency_reduction 1" "settings delete global gamepad.latency_reduction"; }

# NOVOS TWEAKS ADICIONADOS
submenu_29() { submenu_tela "HID: Busy Polling (Sondagem)" "$DESC_29" "setprop persist.sys.hid.busy_polling 1" "setprop persist.sys.hid.busy_polling 0"; }
submenu_30() { submenu_tela "HID: Ultra Polling" "$DESC_30" "setprop persist.vendor.hid.ultra_polling 1" "setprop persist.vendor.hid.ultra_polling 0"; }
submenu_31() { submenu_tela "HID: Fastpath (Caminho Rápido)" "$DESC_31" "setprop vendor.hid.input.fastpath 1" "setprop vendor.hid.input.fastpath 0"; }
submenu_32() { submenu_tela "Input: Filtro OFF (RAW)" "$DESC_32" "setprop persist.sys.input.filter 0" "setprop persist.sys.input.filter 1"; }
submenu_33() { submenu_tela "Input: Touchpad Smooth OFF" "$DESC_33" "setprop persist.sys.touchpad.smooth 0" "setprop persist.sys.touchpad.smooth 1"; }
submenu_34() { submenu_tela "Input: Resample OFF" "$DESC_34" "setprop persist.sys.input.resample 0" "setprop persist.sys.input.resample 1"; }
submenu_35() { submenu_tela "Input: Dejitter OFF" "$DESC_35" "setprop persist.sys.input.dejitter 0" "setprop persist.sys.input.dejitter 1"; }
submenu_36() { submenu_tela "USB: Performance Mode" "$DESC_36" "setprop vendor.usb.performance_mode 1" "setprop vendor.usb.performance_mode 0"; }
submenu_37() { submenu_tela "USB: Low Latency Interrupts" "$DESC_37" "setprop persist.vendor.usb.low_latency_interrupts 1" "setprop persist.vendor.usb.low_latency_interrupts 0"; }
submenu_38() { submenu_tela "USB: Max Bus Bandwidth" "$DESC_38" "setprop vendor.usb.max_bus_bandwidth 1" "setprop vendor.usb.max_bus_bandwidth 0"; }
submenu_39() { submenu_tela "Input: Despacho Rápido" "$DESC_39" "setprop persist.sys.input.dispatch_fast 1" "setprop persist.sys.input.dispatch_fast 0"; }
submenu_40() { submenu_tela "Input: Despacho Imediato" "$DESC_40" "setprop persist.sys.input.dispatch_immediate 1" "setprop persist.sys.input.dispatch_immediate 0"; }

# Reset (41) - Renomeado para submenu_reset
submenu_reset() {
    clear
    printf '\033c' # LIMPEZA FORÇADA
    echo -e "${CYAN}Restaurando todas as configurações padrão...${RESET}"

    # SETTINGS DELETE (Settings put)
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
    # FIM DOS NOVOS COMANDOS

    # Adicionado: Remove todas as flags de desativação manual
    rm -rf "$FLAG_DIR" 2>/dev/null
    
    # Também remove spoof e arquivos de backup para garantir reset limpo
    rm -f "$SPOOF_FILE" "$SPOOF_FLAG" "$ORIG_STORE" 2>/dev/null
    rm -f "$MODDIR/habilitar_no_boot" # Resetar auto-boot

    echo -e "${GREEN}✔ Todos os valores foram resetados.${RESET}"
    echo -e "${YELLOW}O sistema será reiniciado agora para completar o reset.${RESET}"
    sleep 2
    reboot
}

# =====================================================
# NOVA FUNÇÃO: REINICIAR (REBOOT)
# =====================================================
submenu_reboot() {
    while true; do
        clear
        printf '\033c' # LIMPEZA FORÇADA
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
                # Se o reboot falhar ou não sair do script
                exit 0
                ;;
            0) 
                return 
                ;;
            *) 
                echo -e "${RED}Opção inválida${RESET}"
                sleep 1
                ;;
        esac
    done
}

# =====================================================
# ATIVAR TODOS (argumento --ativar-todos)
# =====================================================
if [ "$1" = "--ativar-todos" ]; then
    
    apply_if_enabled() {
        TWEAK_NAME="$1"
        COMMAND="$2"
        # Verifica se a flag de desativação manual para este tweak NÃO existe
        if [ ! -f "$FLAG_DIR/$TWEAK_NAME" ]; then
            if echo "$COMMAND" | grep -qE "^settings"; then
                eval "$COMMAND"
            fi
        fi
    }

    # SETTINGS PUT
    apply_if_enabled "Toque: Tempo Mínimo" "settings put secure tap_duration_threshold 70"
    apply_if_enabled "Toque: Longo (Timeout)" "settings put secure long_press_timeout 300"
    apply_if_enabled "Toque: Múltiplos (Fast Tap)" "settings put secure multi_press_timeout 130"
    apply_if_enabled "Acessibilidade: Ação Rápida" "settings put secure accessibility_auto_action_delay 200"
    apply_if_enabled "Sistema: Bloqueio de Toques OFF" "settings put global block_untrusted_touches 0"
    apply_if_enabled "Sistema: Performance Máx" "settings put global restricted_device_performance '0,0'"
    apply_if_enabled "Display: Refresh Interno 120Hz" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120"
    apply_if_enabled "Display: Saída Dual" "settings put global display_dual_output 1"
    apply_if_enabled "Gamepad: Redução de latência" "settings put global gamepad.latency_reduction 1"

    # PROPS (Todos os props são garantidos pelo rebuild_system_prop)
    echo -e "${CYAN}Garantindo persistência e aplicando Propriedades...${RESET}"
    rebuild_system_prop
    
    echo -e "${GREEN}✔ Todos os tweaks aplicados (spoof NÃO foi ativado).${RESET}"
    exit 0
fi

# =====================================================
# MENU INDIVIDUAL (OTIMIZADO)
# =====================================================
menu_individual() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    
    # Executa o cache de status AQUI para garantir velocidade máxima no display
    cache_status 
    
    echo -e "${BOLD}${MAGENTA}========== TWEAKS INDIVIDUAIS ==========${RESET}\n"

    # --- TOQUE/TELA (1-6) ---
    printf " %b 1) Toque: Tempo Mínimo\n" "$(icon check_setting secure tap_duration_threshold 70)"
    printf " %b 2) Toque: Longo (Timeout)\n" "$(icon check_setting secure long_press_timeout 300)"
    printf " %b 3) Toque: Múltiplos (Fast Tap)\n" "$(icon check_setting secure multi_press_timeout 130)"
    printf " %b 4) Acessibilidade: Ação Rápida\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"
    printf " %b 5) Sistema: Bloqueio de Toques OFF\n" "$(icon check_setting global block_untrusted_touches 0)"
    printf " %b 6) Sistema: Performance Máx\n" "$(icon check_setting global restricted_device_performance '0,0')"

    # --- USB / PERIFÉRICOS (7-13) ---
    printf "\n${YELLOW}${BOLD}--- USB/MOUSE (EXISTENTES) ---${RESET}\n"
    printf " %b 7) USB: Raw Input\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
    printf " %b 8) USB: Low Latency Mode\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
    printf " %b 9) USB: HID Priority\n" "$(icon check_prop vendor.usb.hid.priority 2)"
    printf " %b 10) USB: High Speed\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
    printf " %b 11) USB: Power Boost\n" "$(icon check_prop persist.vendor.usb.power 1)"
    printf " %b 12) USB: Hub Boost\n" "$(icon check_prop vendor.usb.hub.boost 1)"
    printf " %b 13) Mouse: Anti-Jitter USB\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"

    # --- MOUSE / PONTEIRO (14-16) ---
    printf "\n${YELLOW}${BOLD}--- MOUSE/PONTEIRO ---${RESET}\n"
    printf " %b 14) Mouse: Resposta Linear\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
    printf " %b 15) Mouse: Aceleração OFF\n" "$(icon check_prop persist.sys.pointer.acceleration 0)"
    printf " %b 16) Mouse: Suavização Ponteiro\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"

    # --- INPUT (17-19) ---
    printf "\n${YELLOW}${BOLD}--- INPUT (LATÊNCIA) ---${RESET}\n"
    printf " %b 17) Input: Low Latency Mode\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
    printf " %b 18) Input: High Update Rate\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
    printf " %b 19) Input: Boost (Picos)\n" "$(icon check_prop persist.sys.input.boost 1)"

    # --- GPU / DISPLAY (20-28) ---
    printf "\n${YELLOW}${BOLD}--- GRÁFICOS / DISPLAY ---${RESET}\n"
    printf " %b 20) GPU: VSync OFF (HWUI)\n" "$(icon check_prop debug.hwui.disable_vsync true)"
    printf " %b 21) GPU: Low Latency\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
    printf " %b 22) GPU: Frame Boost\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
    printf " %b 23) Display: Refresh Interno 120Hz\n" "$(icon check_setting system peak_refresh_rate 120)"
    printf " %b 24) Display: Forçar Refresh 120Hz\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
    printf " %b 25) Display: Duplicação Externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
    printf " %b 26) Display: Prioridade Externa\n" "$(icon check_prop vendor.display.external_priority 1)"
    printf " %b 27) Display: Saída Dual\n" "$(icon check_setting global display_dual_output 1)"
    printf " %b 28) Gamepad: Redução de Latência\n" "$(icon check_setting global gamepad.latency_reduction 1)"
    
    # --- LATÊNCIA AVANÇADA (29 - 40) ---
    printf "\n${YELLOW}${BOLD}--- INPUT AVANÇADO / HID ---${RESET}\n" 
    printf " %b 29) HID: Busy Polling (Sondagem)\n" "$(icon check_prop persist.sys.hid.busy_polling 1)"
    printf " %b 30) HID: Ultra Polling\n" "$(icon check_prop persist.vendor.hid.ultra_polling 1)"
    printf " %b 31) HID: Fastpath (Caminho Rápido)\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
    printf " %b 32) Input: Filtro OFF (RAW)\n" "$(icon check_prop persist.sys.input.filter 0)"
    printf " %b 33) Input: Touchpad Smooth OFF\n" "$(icon check_prop persist.sys.touchpad.smooth 0)"
    printf " %b 34) Input: Resample OFF\n" "$(icon check_prop persist.sys.input.resample 0)"
    printf " %b 35) Input: Dejitter OFF\n" "$(icon check_prop persist.sys.input.dejitter 0)"
    printf " %b 36) USB: Performance Mode\n" "$(icon check_prop vendor.usb.performance_mode 1)"
    printf " %b 37) USB: Low Latency Interrupts\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
    printf " %b 38) USB: Max Bus Bandwidth\n" "$(icon check_prop vendor.usb.max_bus_bandwidth 1)"
    printf " %b 39) Input: Despacho Rápido\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
    printf " %b 40) Input: Despacho Imediato\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"

    # RESET / SPOOF
    printf "\n %b 41) Reset total (restaura tudo + reboot)\n" "${RED}${ICON_OFF}${RESET}"
    if spoof_status; then
        SPOOF_ICON="${GREEN}${ICON_ON}${RESET}"
    else
        SPOOF_ICON="${RED}${ICON_OFF}${RESET}"
    fi
    printf " %b 42) Habilitar / Desabilitar Spoof 120 FPS\n" "$SPOOF_ICON"

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
# MENUS POR CATEGORIA (rápidos)
# =====================================================

menu_categoria_toque() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- TOQUE ---${RESET}\n"
    printf " %b 1) Tempo Mínimo\n" "$(icon check_setting secure tap_duration_threshold 70)"
    printf " %b 2) Longo (Timeout)\n" "$(icon check_setting secure long_press_timeout 300)"
    printf " %b 3) Múltiplos (Fast Tap)\n" "$(icon check_setting secure multi_press_timeout 130)"
    printf " %b 4) Acessibilidade: Ação Rápida\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"
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
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- USB & HID ---${RESET}\n"
    printf " %b 1) USB: Raw Input\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
    printf " %b 2) USB: Low Latency Mode\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
    printf " %b 3) USB: HID Priority\n" "$(icon check_prop vendor.usb.hid.priority 2)"
    printf " %b 4) USB: High Speed\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
    printf " %b 5) USB: Power Boost\n" "$(icon check_prop persist.vendor.usb.power 1)"
    printf " %b 6) USB: Hub Boost\n" "$(icon check_prop vendor.usb.hub.boost 1)"
    printf " %b 7) Mouse: Anti-Jitter USB\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"
    # NOVOS USB
    printf " %b 8) USB: Performance Mode\n" "$(icon check_prop vendor.usb.performance_mode 1)"
    printf " %b 9) USB: Low Latency Interrupts\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
    printf " %b 10) USB: Max Bus Bandwidth\n" "$(icon check_prop vendor.usb.max_bus_bandwidth 1)"
    # NOVOS HID
    printf " %b 11) HID: Busy Polling (Sondagem)\n" "$(icon check_prop persist.sys.hid.busy_polling 1)"
    printf " %b 12) HID: Ultra Polling\n" "$(icon check_prop persist.vendor.hid.ultra_polling 1)"
    printf " %b 13) HID: Fastpath (Caminho Rápido)\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
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
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- MOUSE / PONTEIRO ---${RESET}\n"
    printf " %b 1) Resposta Linear\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
    printf " %b 2) Aceleração OFF\n" "$(icon check_prop persist.sys.pointer.acceleration 0)"
    printf " %b 3) Anti-jitter Ponteiro\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"
    printf " %b 4) Touchpad Smooth OFF\n" "$(icon check_prop persist.sys.touchpad.smooth 0)"
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
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- INPUT ---${RESET}\n"
    printf " %b 1) Low Latency Mode\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
    printf " %b 2) High Update Rate\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
    printf " %b 3) Input Boost\n" "$(icon check_prop persist.sys.input.boost 1)"
    # NOVOS INPUTS
    printf " %b 4) Filtro OFF (RAW)\n" "$(icon check_prop persist.sys.input.filter 0)"
    printf " %b 5) Resample OFF\n" "$(icon check_prop persist.sys.input.resample 0)"
    printf " %b 6) Dejitter OFF\n" "$(icon check_prop persist.sys.input.dejitter 0)"
    printf " %b 7) Despacho Rápido\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
    printf " %b 8) Despacho Imediato\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"
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
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- GPU ---${RESET}\n"
    printf " %b 1) GPU Low Latency\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
    printf " %b 2) GPU Frame Boost\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
    printf " %b 3) VSync OFF (HWUI)\n" "$(icon check_prop debug.hwui.disable_vsync true)"
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
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- DISPLAY ---${RESET}\n"
    printf " %b 1) Refresh interno 120Hz\n" "$(icon check_setting system peak_refresh_rate 120)"
    printf " %b 2) Forçar refresh 120Hz\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
    printf " %b 3) Duplicação externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
    printf " %b 4) Prioridade externa\n" "$(icon check_prop vendor.display.external_priority 1)"
    printf " %b 5) Saída dual\n" "$(icon check_setting global display_dual_output 1)"
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
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
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
    printf '\033c' # LIMPEZA FORÇADA
    echo -e "${BOLD}${CYAN}--- UTILIDADES ---${RESET}\n"
    echo "1) Aplicar TODOS os tweaks agora"
    echo "2) Restaurar configurações padrão (RESET + Reboot)"
    echo "3) Automação de Boot (Habilitar/Desabilitar)"
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
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    echo -e "${BOLD}${CYAN}============== AUTOMAÇÃO DE BOOT ==============${RESET}\n"
    echo -e "${YELLOW}Quando ativado, todos os tweaks serão aplicados automaticamente\na cada reinício do dispositivo, RESPEITANDO suas desativações manuais.${RESET}\n"

    if [ -f "$MODDIR/habilitar_no_boot" ]; then
        echo -e "Status atual: ${GREEN}🟢 ATIVADO${RESET}\n"
    else
        echo -e "Status atual: ${RED}🔴 DESATIVADO${RESET}\n"
    fi

    echo "1) Habilitar aplicar no boot"
    echo "2) Desabilitar aplicar no boot"
    echo "3) Aplicar agora e Habilitar no boot"
    echo "0) Voltar"
    echo
    read_prompt "> " boot_op

    case "$boot_op" in
        1)
            touch "$MODDIR/habilitar_no_boot"
            echo -e "${GREEN}✔ Auto-boot HABILITADO${RESET}"
            press_enter
            ;;
        2)
            rm -f "$MODDIR/habilitar_no_boot"
            echo -e "${RED}✔ Auto-boot DESABILITADO${RESET}"
            press_enter
            ;;
        3)
            touch "$MODDIR/habilitar_no_boot"
            echo -e "${CYAN}Aplicando todos os tweaks agora...${RESET}"
            sh "$0" --ativar-todos
            echo -e "${GREEN}✔ Aplicado e Auto-boot HABILITADO${RESET}"
            press_enter
            ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

# =====================================================
# MENU PRINCIPAL (com a nova opção de Reboot)
# =====================================================
menu() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA

    # Cabeçalho novo
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
               printf '\033c' # LIMPEZA FORÇADA
               echo -e "${BOLD}${CYAN}--- CATEGORIAS RÁPIDAS ---${RESET}\n"
               echo "1) Toque"
               echo "2) USB/HID (Latência)"
               echo "3) Mouse/Ponteiro"
               echo "4) Input (Despacho de Eventos)"
               echo "5) GPU"
               echo "6) Display"
               echo "7) Gamepad"
               echo "8) Utilidades (Reset/Boot/Reboot)"
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

# =====================================================
# START
# =====================================================

# Otimização: Preenche o cache de status AQUI, se não for a chamada --ativar-todos
if [ "$1" != "--ativar-todos" ]; then
    cache_status 2>/dev/null
fi

menu
con check_prop persist.sys.gpu.frame_boost 1)"
    printf " %b 3) VSync OFF (HWUI)\n" "$(icon check_prop debug.hwui.disable_vsync true)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_21 ;;
        2) submenu_22 ;;
        3) submenu_20 ;;
        0) return ;;
        *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

menu_categoria_display() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${NEGRITO}${NEGRITO_CIANO}--- DISPLAY ---${RESET}\n"
    printf " %b 1) Refresh interno 120Hz\n" "$(icon check_setting system peak_refresh_rate 120)"
    printf " %b 2) Forçar refresh 120Hz\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
    printf " %b 3) Duplicação externa\n" "$(icon check_prop persist.video.duplicate.display 1)"
    printf " %b 4) Prioridade externa\n" "$(icon check_prop vendor.display.external_priority 1)"
    printf " %b 5) Saída dual\n" "$(icon check_setting global display_dual_output 1)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_23 ;;
        2) submenu_24 ;;
        3) submenu_25 ;;
        4) submenu_26 ;;
        5) submenu_27 ;;
        0) return ;;
        *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

menu_categoria_gamepad() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${NEGRITO}${NEGRITO_CIANO}--- GAMEPAD / CONTROLES ---${RESET}\n"
    printf " %b 1) Redução de latência (gamepad)\n" "$(icon check_setting global gamepad.latency_reduction 1)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_28 ;;
        0) return ;;
        *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

# =====================================================
# UTILIDADES / MISC
# =====================================================
menu_misc() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    echo -e "${NEGRITO}${NEGRITO_CIANO}--- UTILIDADES ---${RESET}\n"
    echo "1) Aplicar TODOS os tweaks agora"
    echo "2) Restaurar configurações padrão (RESET + Reboot)"
    echo "3) Aplicar no boot (abrir menu de boot)"
    echo "4) 🔄 Reiniciar o Dispositivo (Reboot)" # Adicionado no menu Misc
    echo "0) Voltar"
    echo
    read_prompt "> " op
    case "$op" in
        1)
            echo -e "${NEGRITO_CIANO}Aplicando todos os tweaks...${RESET}"
            sh "$0" --ativar-todos
            press_enter
            ;;
        2)
            echo -e "${NEGRITO_AMARELO}Reset solicitado: o sistema será reiniciado.${RESET}"
            read_prompt "Confirmar reset? (s/N): " confirm
            if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                submenu_reset
            fi
            ;;
        3) submenu_boot ;;
        4) submenu_reboot ;;
        0) return ;;
        *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

# =====================================================
# SUBMENU BOOT (menu avançado)
# =====================================================
submenu_boot() {
clear
printf '\033c' # LIMPEZA FORÇADA
echo -e "${NEGRITO}${NEGRITO_CIANO}============== AUTOMAÇÃO DE BOOT ==============${RESET}\n"
echo -e "${NEGRITO_AMARELO}Quando ativado, todos os tweaks serão aplicados automaticamente\na cada reinício do dispositivo, RESPEITANDO suas desativações manuais.${RESET}\n"

if [ -f "$MODDIR/enable_on_boot" ]; then
    echo -e "Status atual: ${NEGRITO_VERDE}${ICONE_LIGADO} ATIVADO${RESET}\n"
else
    echo -e "Status atual: ${NEGRITO_VERMELHO}${ICONE_DESLIGADO} DESATIVADO${RESET}\n"
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
        echo -e "${NEGRITO_VERDE}${CHECK} Auto-boot ATIVADO${RESET}"
        press_enter
        ;;
    2)
        rm -f "$MODDIR/enable_on_boot"
        echo -e "${NEGRITO_VERMELHO}${CHECK} Auto-boot DESATIVADO${RESET}"
        press_enter
        ;;
    3)
        touch "$MODDIR/enable_on_boot"
        echo -e "${NEGRITO_CIANO}Aplicando todos os tweaks agora...${RESET}"
        sh "$0" --ativar-todos
        echo -e "${NEGRITO_VERDE}${CHECK} Aplicado e Auto-boot ATIVADO${RESET}"
        press_enter
        ;;
    0) return ;;
    *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
esac
}

# =====================================================
# MENU PRINCIPAL (com a nova opção de Reboot)
# =====================================================
menu() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA

    # Cabeçalho novo
    echo -e "${NEGRITO_VERDE}${NEGRITO}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${NEGRITO_VERDE}${NEGRITO}║            🎮  F E R A   A L P H A  🎮            ║${RESET}"
    echo -e "${NEGRITO_VERDE}${NEGRITO}║      Sistema Avançado de Desempenho & Latência    ║${RESET}"
    echo -e "${NEGRITO_VERDE}${NEGRITO}╚══════════════════════════════════════════════════╝${RESET}\n"

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
               printf '\033c' # LIMPEZA FORÇADA
               echo -e "${NEGRITO}${NEGRITO_CIANO}--- CATEGORIAS RÁPIDAS ---${RESET}\n"
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
                   *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
               esac
           done
        ;;
        6) submenu_reboot ;;
        0) exit 0 ;;
        *) echo -e "${NEGRITO_VERMELHO}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

# =====================================================
# START
# =====================================================

# Otimização: Preenche o cache de status AQUI, se não for a chamada --ativar-todos
if [ "$1" != "--ativar-todos" ]; then
    cache_status 2>/dev/null
fi

menu
