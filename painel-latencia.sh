#!/system/bin/sh
MODDIR=${0%/*}

###############################################################################
# 🔄 VERIFICAÇÃO DE UPDATE (MANUAL)
###############################################################################
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

    [ -z "$REMOTO" ] && echo "⚠ Não foi possível verificar." && sleep 1 && return

    if [ "$LOCAL" = "$REMOTO" ]; then
        echo "✔ Já está na versão mais recente."
        sleep 1
        return
    fi

    echo "🔄 Nova versão detectada! Baixando..."
    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    [ ! -s "$TMP_DL" ] && echo "❌ Falha no download." && sleep 1 && return

    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    [ "$NEW_HASH" != "$REMOTO" ] && echo "❌ Hash incorreto." && sleep 1 && return

    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"

    clear
    echo "✔ Painel atualizado!"
    echo "Reabra com: sh $SELF"
    exit
}

###############################################################################
# 🔐 LOGIN, SESSÃO E SEGURANÇA
###############################################################################

MODDIR=${0%/*}
SERVER="https://painel-licenca-server.onrender.com"
LICENSE_FILE="$MODDIR/license_info"
RESET_SCRIPT="$MODDIR/reset_auto.sh"
SESSION_FILE="/data/local/tmp/fera_session"

gera_fingerprint() {
ANDROID_ID=$(settings get secure android_id 2>/dev/null || echo "")
SERIAL=$(getprop ro.serialno 2>/dev/null || echo "")
MODEL=$(getprop ro.product.model 2>/dev/null || echo "")
FP_RAW="${ANDROID_ID}-${SERIAL}-${MODEL}"
echo -n "$FP_RAW" | md5sum | awk '{print $1}'
}

gera_sessao() {
    FP_NOW=$(gera_fingerprint)
    echo "$FP_NOW" > "$SESSION_FILE"
    chmod 600 "$SESSION_FILE"
}

sessao_ok() {
    [ ! -f "$SESSION_FILE" ] && return 1
    FP_NOW=$(gera_fingerprint)
    FP_SAVED=$(cat "$SESSION_FILE")
    [ "$FP_NOW" = "$FP_SAVED" ]
}

reset_total_auto() {
rm -f "$SESSION_FILE"
rm -f "$LICENSE_FILE"
reboot
}

verifica_expiracao() {
    [ ! -f "$LICENSE_FILE" ] && return 0
    EXP=$(cat "$LICENSE_FILE")
    NOW=$(date +%s)
    [ "$NOW" -ge "$EXP" ] && reset_total_auto
}

verifica_expiracao

ativar_servidor() {
USER="$1"
PASS="$2"
FP=$(gera_fingerprint)

JSON="{\"username\":\"$USER\",\"password\":\"$PASS\",\"fingerprint\":\"$FP\"}"
RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")

echo "$RESP" | grep -q '"error"' && return 1

EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
[ "$EXP" ] && echo "$EXP" > "$LICENSE_FILE"
return 0
}

###############################################################################
# 🔥 TELA INICIAL
###############################################################################
menu_inicio() {
    clear
    DEVICE=$(getprop ro.product.brand) $(getprop ro.product.device)
    ANDROID=$(getprop ro.build.version.release)

    echo ""
    echo "⟪ PROJECT ALPHA ⚡ ⟫"
    echo "───────────────────────────────"
    echo "📱 Aparelho: $DEVICE"
    echo "🤖 Android: $ANDROID"
    echo ""
    echo "   💠  [1] Login"
    echo "   🔄  [2] Verificar atualização"
    echo "   ❌  [0] Sair"
    echo ""
    echo -n "👉 Escolha: "
    read OP
}

###############################################################################
# ⚡ PULAR LOGIN SE A SESSÃO ESTIVER OK
###############################################################################
if sessao_ok; then
    echo "✔ Sessão detectada — iniciando painel..."
    sleep 0.4
else
    while true; do
        menu_inicio
        case "$OP" in
            1) break ;;
            2) verificar_update_manual ;;
            0) exit ;;
        esac
    done
fi

###############################################################################
# ⚡ LOGIN RÁPIDO (SEM ANIMAÇÃO)
###############################################################################
if ! sessao_ok; then
    tent=0
    while [ $tent -lt 3 ]; do
        clear
        echo "🔐 LOGIN — FERA ALPHA"
        echo -n "Usuário: "
        read USER
        echo -n "Senha : "
        stty -echo
        read PASS
        stty echo
        echo ""

        echo "⏳ Validando..."
        if ativar_servidor "$USER" "$PASS"; then
            echo "✔ Login aprovado!"
            gera_sessao
            sleep 0.4
            break
        fi

        echo "❌ Erro — tente novamente"
        tent=$((tent+1))
        sleep 1
    done

    [ $tent -ge 3 ] && echo "❌ Falha ao autenticar." && exit 1
fi

clear
echo "✔ Painel iniciado."

###############################################################################
# ⚙️ AQUI COMEÇA O PAINEL DE TWEAKS (SEU ARQUIVO ORIGINAL)
###############################################################################
# → Aqui você cola 100% do painel que já está funcionando  
# (menus, input, GPU, USB, Spoof, ativar todos, etc.)  
# Nada precisa ser modificado nessa parte.

# =====================================================
#         🎮 FERA ALPHA – GAMING PERFORMANCE PANEL 🎮
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
SPOOF_FLAG="$MODDIR/spoof_enabled"
SPOOF_FILE="$MODDIR/system.prop"
ORIG_STORE="$MODDIR/original.props"
FLAG_DIR="$MODDIR/disabled_flags"
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

# NOVA FUNÇÃO ICON - Retorna o ícone + o código da cor para o texto
icon() { 
    if "$@"; then 
        printf "${GREEN}${ICON_ON}${RESET} ${GREEN}"; 
    else 
        printf "${RED}${ICON_OFF}${RESET} ${RED}"; 
    fi; 
}

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
        # NOVAS PROPRIEDADES (LATÊNCIA AVANÇADA)
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
press_enter()  { printf "\nPressione ${BOLD}ENTER${RESET} para continuar..."; read -r _; }

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
DESC_7="- Define escala de animação de janela para 0 (desliga a animação)." # NOVO
DESC_8="- Define escala de animação de transição para 0 (desliga a transição)." # NOVO
DESC_9="- Define escala de duração do animador para 0 (desliga animações curtas)." # NOVO

DESC_10="- Habilita raw input USB (eventos sem filtragem), melhora precisão." # ITEM ANTIGO 7
DESC_11="- Força modo USB de baixa latência (reduz buffers USB)." # ITEM ANTIGO 8
DESC_12="- Define prioridade HID para reduzir conflitos entre dispositivos." # ITEM ANTIGO 9
DESC_13="- Tenta forçar USB em high-speed (pode ajudar adaptadores)." # ITEM ANTIGO 10
DESC_14="- Aumenta energia declarada ao controlador USB (estabilidade de periféricos)." # ITEM ANTIGO 11
DESC_15="- Boost do driver de hub USB para estabilidade em setups complexos." # ITEM ANTIGO 12
DESC_16="- Filtro anti-jitter no mouse para reduzir micro-tremores." # ITEM ANTIGO 13

DESC_17="- Resposta linear do mouse (remove curvaturas/curvas de aceleração)."
DESC_18="- Desativa aceleração do ponteiro (1:1 entre movimento e cursor)."
DESC_19="- Suaviza jitter do ponteiro por software (reduz oscilações pequenas)."
DESC_20="- Habilita modo de entrada de baixa latência (prioriza eventos)."
DESC_21="- Ativa alta taxa de atualização de input (dependente do driver)."
DESC_22="- Input boost para priorizar eventos em picos de uso."
DESC_23="- Desativa VSync no HWUI (reduz input lag, pode causar tearing)."
DESC_24="- Configura GPU para baixa latência (pode elevar consumo)."
DESC_25="- Habilita frame boost na GPU (tenta manter FPS curtos mais altos)."
DESC_26="- Mantém o display em 120Hz nativo (min/max 120Hz)."
DESC_27="- Força 120Hz via propriedade (nem sempre funciona em todos OEMs)."
DESC_28="- Ativa duplicação de vídeo para saída externa (espelhamento)."
DESC_29="- Prioriza display externo em relação ao interno (útil em hubs)."
DESC_30="- Habilita saída dual quando suportado pelo driver."
DESC_31="- Reduz latência em gamepads (melhora a leitura de eventos)."
DESC_32="- Força 'polling' mais rápido para dispositivos de interface humana (HID)."
DESC_33="- Habilita o modo de ultra-polling persistente para entradas HID, reduzindo o atraso."
DESC_34="- Ativa o caminho rápido ('fastpath') para eventos de entrada de dispositivos HID (melhora a taxa de eventos)."
DESC_35="- Desativa qualquer filtro de software no sistema de input (recebe o input cru)."
DESC_36="- Desativa o suavizamento de software para 'touchpad' ou ponteiro (para resposta 1:1)."
DESC_37="- Desativa a reamostragem do sistema de input (usa a taxa de evento nativa)."
DESC_38="- Desativa o filtro de 'dejitter' (redução de tremidos) para input, visando resposta máxima."
DESC_39="- Coloca o controlador USB em modo de desempenho máximo (prioriza velocidade/taxa de transferência)."
DESC_40="- Habilita interrupções de baixa latência no USB (reduz o tempo de espera para processar dados)."
DESC_41="- Aumenta a largura de banda máxima permitida no barramento USB (evita gargalos)."
DESC_42="- Prioriza o despacho rápido de eventos de input na fila do sistema."
DESC_43="- Força o processamento imediato de eventos de input, minimizando atrasos."
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
# Submenus (apenas chamadas)
# ITENS 1-6 PERMANECEM IGUAIS
# ITENS 7-9 SÃO NOVOS COMANDOS DE ANIMAÇÃO
# ITENS 10+ SÃO OS ANTIGOS ITENS 7+ RE-NUMERADOS
# =====================================================
submenu_1() { submenu_tela "tap_duration_threshold" "$DESC_1" "settings put secure tap_duration_threshold 70" "settings delete secure tap_duration_threshold"; }
submenu_2() { submenu_tela "long_press_timeout" "$DESC_2" "settings put secure long_press_timeout 300" "settings delete secure long_press_timeout"; }
submenu_3() { submenu_tela "multi_press_timeout" "$DESC_3" "settings put secure multi_press_timeout 130" "settings delete secure multi_press_timeout"; }
submenu_4() { submenu_tela "accessibility_auto_action_delay" "$DESC_4" "settings put secure accessibility_auto_action_delay 200" "settings delete secure accessibility_auto_action_delay"; }
submenu_5() { submenu_tela "block_untrusted_touches" "$DESC_5" "settings put global block_untrusted_touches 0" "settings delete global block_untrusted_touches"; }
submenu_6() { submenu_tela "restricted_device_performance" "$DESC_6" "settings put global restricted_device_performance '0,0'" "settings delete global restricted_device_performance"; }

# NOVOS SUBMENUS DE ANIMAÇÃO (7, 8, 9)
submenu_7() { submenu_tela "Window Animation Scale OFF" "$DESC_7" "settings put global window_animation_scale 0" "settings put global window_animation_scale 1.0"; }
submenu_8() { submenu_tela "Transition Animation Scale OFF" "$DESC_8" "settings put global transition_animation_scale 0" "settings put global transition_animation_scale 1.0"; }
submenu_9() { submenu_tela "Animator Duration Scale OFF" "$DESC_9" "settings put global animator_duration_scale 0" "settings put global animator_duration_scale 1.0"; }

# USB/PERIFÉRICOS (Antigos 7-13, Agora 10-16)
submenu_10() { submenu_tela "USB RAW" "$DESC_10" "setprop vendor.usb.raw_input.enable 1" "setprop vendor.usb.raw_input.enable 0"; }
submenu_11() { submenu_tela "USB Low Latency" "$DESC_11" "setprop persist.usb.low_latency_mode 1" "setprop persist.usb.low_latency_mode 0"; }
submenu_12() { submenu_tela "USB HID Priority" "$DESC_12" "setprop vendor.usb.hid.priority 2" "setprop vendor.usb.hid.priority 1"; }
submenu_13() { submenu_tela "USB High Speed" "$DESC_13" "setprop persist.vendor.usb.high_speed 1" "setprop persist.vendor.usb.high_speed 0"; }
submenu_14() { submenu_tela "USB Power Boost" "$DESC_14" "setprop persist.vendor.usb.power 1" "setprop persist.vendor.usb.power 0"; }
submenu_15() { submenu_tela "USB Hub Boost" "$DESC_15" "setprop vendor.usb.hub.boost 1" "setprop vendor.usb.hub.boost 0"; }
submenu_16() { submenu_tela "USB Mouse AntiJitter" "$DESC_16" "setprop vendor.usb.mouse.jitter_filter 1" "setprop vendor.usb.mouse.jitter_filter 0"; }

# MOUSE / PONTEIRO (Antigos 14-16, Agora 17-19)
submenu_17() { submenu_tela "Mouse Resposta Linear" "$DESC_17" "setprop persist.sys.mouse.linear_response 1" "setprop persist.sys.mouse.linear_response 0"; }
submenu_18() { submenu_tela "Mouse Aceleração OFF" "$DESC_18" "setprop persist.sys.pointer.acceleration 0" "setprop persist.sys.pointer.acceleration 1"; }
submenu_19() { submenu_tela "Mouse Anti-jitter do ponteiro" "$DESC_19" "setprop persist.input.pointer_jitter_smoothing 1" "setprop persist.input.pointer_jitter_smoothing 0"; }

# INPUT (Antigos 17-19, Agora 20-22)
submenu_20() { submenu_tela "Input Low Latency Mode" "$DESC_20" "setprop persist.sys.input.low_latency_mode 1" "setprop persist.sys.input.low_latency_mode 0"; }
submenu_21() { submenu_tela "Input High Update Rate" "$DESC_21" "setprop persist.sys.input.high_update_rate true" "setprop persist.sys.input.high_update_rate false"; }
submenu_22() { submenu_tela "Input Boost" "$DESC_22" "setprop persist.sys.input.boost 1" "setprop persist.sys.input.boost 0"; }

# GPU / DISPLAY (Antigos 20-28, Agora 23-31)
submenu_23() { submenu_tela "VSync OFF" "$DESC_23" "setprop debug.hwui.disable_vsync true" "setprop debug.hwui.disable_vsync false"; }
submenu_24() { submenu_tela "GPU Low Latency" "$DESC_24" "setprop persist.sys.gpu.low_latency 1" "setprop persist.sys.gpu.low_latency 0"; }
submenu_25() { submenu_tela "GPU Frame Boost" "$DESC_25" "setprop persist.sys.gpu.frame_boost 1" "setprop persist.sys.gpu.frame_boost 0"; }
submenu_26() { submenu_tela "Refresh 120Hz Interno" "$DESC_26" "settings put system peak_refresh_rate 120; settings put system min_refresh_rate 120" "settings delete system peak_refresh_rate; settings delete system min_refresh_rate"; }
submenu_27() { submenu_tela "Forçar 120Hz Display" "$DESC_27" "setprop persist.sys.display.force_refresh 120" "setprop persist.sys.display.force_refresh 60"; }
submenu_28() { submenu_tela "Duplicação Externa" "$DESC_28" "setprop persist.video.duplicate.display 1" "setprop persist.video.duplicate.display 0"; }
submenu_29() { submenu_tela "Prioridade Externa" "$DESC_29" "setprop vendor.display.external_priority 1" "setprop vendor.display.external_priority 0"; }
submenu_30() { submenu_tela "Saída Dual" "$DESC_30" "settings put global display_dual_output 1" "settings delete global display_dual_output"; }
submenu_31() { submenu_tela "Gamepad Redução de latência" "$DESC_31" "settings put global gamepad.latency_reduction 1" "settings delete global gamepad.latency_reduction"; }

# LATÊNCIA AVANÇADA (Antigos 29-40, Agora 32-43)
submenu_32() { submenu_tela "HID Busy Polling" "$DESC_32" "setprop persist.sys.hid.busy_polling 1" "setprop persist.sys.hid.busy_polling 0"; }
submenu_33() { submenu_tela "HID Ultra Polling" "$DESC_33" "setprop persist.vendor.hid.ultra_polling 1" "setprop persist.vendor.hid.ultra_polling 0"; }
submenu_34() { submenu_tela "HID Fastpath" "$DESC_34" "setprop vendor.hid.input.fastpath 1" "setprop vendor.hid.input.fastpath 0"; }
submenu_35() { submenu_tela "Input Filter OFF" "$DESC_35" "setprop persist.sys.input.filter 0" "setprop persist.sys.input.filter 1"; }
submenu_36() { submenu_tela "Touchpad Smooth OFF" "$DESC_36" "setprop persist.sys.touchpad.smooth 0" "setprop persist.sys.touchpad.smooth 1"; }
submenu_37() { submenu_tela "Input Resample OFF" "$DESC_37" "setprop persist.sys.input.resample 0" "setprop persist.sys.input.resample 1"; }
submenu_38() { submenu_tela "Input Dejitter OFF" "$DESC_38" "setprop persist.sys.input.dejitter 0" "setprop persist.sys.input.dejitter 1"; }
submenu_39() { submenu_tela "USB Performance Mode" "$DESC_39" "setprop vendor.usb.performance_mode 1" "setprop vendor.usb.performance_mode 0"; }
submenu_40() { submenu_tela "USB Low Latency Interrupts" "$DESC_40" "setprop persist.vendor.usb.low_latency_interrupts 1" "setprop persist.vendor.usb.low_latency_interrupts 0"; }
submenu_41() { submenu_tela "USB Max Bus Bandwidth" "$DESC_41" "setprop vendor.usb.max_bus_bandwidth 1" "setprop vendor.usb.max_bus_bandwidth 0"; }
submenu_42() { submenu_tela "Input Dispatch Fast" "$DESC_42" "setprop persist.sys.input.dispatch_fast 1" "setprop persist.sys.input.dispatch_fast 0"; }
submenu_43() { submenu_tela "Input Dispatch Immediate" "$DESC_43" "setprop persist.sys.input.dispatch_immediate 1" "setprop persist.sys.input.dispatch_immediate 0"; }

# Reset e Spoof (Antigos 41 e 42, Agora 44 e 45)
submenu_44() { 
    # RESET TOTAL (44)
    clear
    printf '\033c' # LIMPEZA FORÇADA
    echo -e "${CYAN}Restaurando todas as configurações padrão...${RESET}"

    # SETTINGS PUT/DELETE (incluindo as novas animações)
    settings delete secure tap_duration_threshold
    settings delete secure long_press_timeout
    settings delete secure multi_press_timeout
    settings delete secure accessibility_auto_action_delay
    settings delete global block_untrusted_touches
    settings delete global restricted_device_performance
    settings put global window_animation_scale 1.0 # NOVO RESET
    settings put global transition_animation_scale 1.0 # NOVO RESET
    settings put global animator_duration_scale 1.0 # NOVO RESET
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
    
    # COMANDOS AVANÇADOS DE RESET
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
    
    # Remove todas as flags de desativação manual
    rm -rf "$FLAG_DIR" 2>/dev/null
    
    # Remove spoof e arquivos de backup
    rm -f "$SPOOF_FILE" "$SPOOF_FLAG" "$ORIG_STORE" 2>/dev/null
    rm -f "$MODDIR/enable_on_boot" # Resetar auto-boot

    echo -e "${GREEN}✔ Todos os valores foram resetados.${RESET}"
    echo -e "${YELLOW}O sistema será reiniciado agora para completar o reset.${RESET}"
    sleep 2
    reboot
}
submenu_45() { submenu_spoof; } # Spoof

# =====================================================
# NOVA FUNÇÃO: REINICIAR (REBOOT)
# =====================================================
submenu_reboot() {
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

    # SETTINGS PUT (incluindo as novas)
    apply_if_enabled "tap_duration_threshold" "settings put secure tap_duration_threshold 70"
    apply_if_enabled "long_press_timeout" "settings put secure long_press_timeout 300"
    apply_if_enabled "multi_press_timeout" "settings put secure multi_press_timeout 130"
    apply_if_enabled "accessibility_auto_action_delay" "settings put secure accessibility_auto_action_delay 200"
    apply_if_enabled "block_untrusted_touches" "settings put global block_untrusted_touches 0"
    apply_if_enabled "restricted_device_performance" "settings put global restricted_device_performance '0,0'"
    apply_if_enabled "Window Animation Scale OFF" "settings put global window_animation_scale 0" # NOVO
    apply_if_enabled "Transition Animation Scale OFF" "settings put global transition_animation_scale 0" # NOVO
    apply_if_enabled "Animator Duration Scale OFF" "settings put global animator_duration_scale 0" # NOVO
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
# MENU INDIVIDUAL (OTIMIZADO + CORES NO TEXTO)
# =====================================================
menu_individual() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    
    # Executa o cache de status AQUI para garantir velocidade máxima no display
    cache_status 
    
    echo -e "${BOLD}${MAGENTA}========== TWEAKS INDIVIDUAIS ==========${RESET}\n"

    # --- TOQUE/TELA & ANIMAÇÕES (1-9) ---
    printf "${CYAN}${BOLD}--- TOQUE / SISTEMA ---${RESET}\n"
    printf " %b 1) Toque: Tempo Mínimo${RESET}\n" "$(icon check_setting secure tap_duration_threshold 70)"
    printf " %b 2) Toque: Longo (Timeout)${RESET}\n" "$(icon check_setting secure long_press_timeout 300)"
    printf " %b 3) Toque: Múltiplos (Fast Tap)${RESET}\n" "$(icon check_setting secure multi_press_timeout 130)"
    printf " %b 4) Acessibilidade: Ação Rápida${RESET}\n" "$(icon check_setting secure accessibility_auto_action_delay 200)"
    printf " %b 5) Sistema: Bloqueio de Toques OFF${RESET}\n" "$(icon check_setting global block_untrusted_touches 0)"
    printf " %b 6) Sistema: Performance Máx${RESET}\n" "$(icon check_setting global restricted_device_performance '0,0')"
    printf " %b 7) Animação: Janela OFF${RESET}\n" "$(icon check_setting global window_animation_scale 0)" # NOVO
    printf " %b 8) Animação: Transição OFF${RESET}\n" "$(icon check_setting global transition_animation_scale 0)" # NOVO
    printf " %b 9) Animação: Duração OFF${RESET}\n" "$(icon check_setting global animator_duration_scale 0)" # NOVO

    # --- USB / PERIFÉRICOS (10-16) ---
    printf "\n${YELLOW}${BOLD}--- USB/PERIFÉRICOS ---${RESET}\n"
    printf " %b 10) USB: Raw Input${RESET}\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
    printf " %b 11) USB: Low Latency Mode${RESET}\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
    printf " %b 12) USB: HID Priority${RESET}\n" "$(icon check_prop vendor.usb.hid.priority 2)"
    printf " %b 13) USB: High Speed${RESET}\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
    printf " %b 14) USB: Power Boost${RESET}\n" "$(icon check_prop persist.vendor.usb.power 1)"
    printf " %b 15) USB: Hub Boost${RESET}\n" "$(icon check_prop vendor.usb.hub.boost 1)"
    printf " %b 16) Mouse: Anti-Jitter USB${RESET}\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"

    # --- MOUSE / PONTEIRO (17-19) ---
    printf "\n${YELLOW}${BOLD}--- MOUSE/PONTEIRO ---${RESET}\n"
    printf " %b 17) Mouse: Resposta Linear${RESET}\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
    printf " %b 18) Mouse: Aceleração OFF${RESET}\n" "$(icon check_prop persist.sys.pointer.acceleration 0)"
    printf " %b 19) Mouse: Suavização Ponteiro${RESET}\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"

    # --- INPUT (20-22) ---
    printf "\n${YELLOW}${BOLD}--- INPUT (LATÊNCIA) ---${RESET}\n"
    printf " %b 20) Input: Low Latency Mode${RESET}\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
    printf " %b 21) Input: High Update Rate${RESET}\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
    printf " %b 22) Input: Boost (Picos)${RESET}\n" "$(icon check_prop persist.sys.input.boost 1)"

    # --- GPU / DISPLAY (23-31) ---
    printf "\n${YELLOW}${BOLD}--- GRÁFICOS / DISPLAY ---${RESET}\n"
    printf " %b 23) GPU: VSync OFF (HWUI)${RESET}\n" "$(icon check_prop debug.hwui.disable_vsync true)"
    printf " %b 24) GPU: Low Latency${RESET}\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
    printf " %b 25) GPU: Frame Boost${RESET}\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
    printf " %b 26) Display: Refresh Interno 120Hz${RESET}\n" "$(icon check_setting system peak_refresh_rate 120)"
    printf " %b 27) Display: Forçar Refresh 120Hz${RESET}\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
    printf " %b 28) Display: Duplicação Externa${RESET}\n" "$(icon check_prop persist.video.duplicate.display 1)"
    printf " %b 29) Display: Prioridade Externa${RESET}\n" "$(icon check_prop vendor.display.external_priority 1)"
    printf " %b 30) Display: Saída Dual${RESET}\n" "$(icon check_setting global display_dual_output 1)"
    printf " %b 31) Gamepad: Redução de Latência${RESET}\n" "$(icon check_setting global gamepad.latency_reduction 1)"
    
    # --- LATÊNCIA AVANÇADA (32-43) ---
    printf "\n${YELLOW}${BOLD}--- INPUT AVANÇADO / HID ---${RESET}\n" 
    printf " %b 32) HID: Busy Polling (Sondagem)${RESET}\n" "$(icon check_prop persist.sys.hid.busy_polling 1)"
    printf " %b 33) HID: Ultra Polling${RESET}\n" "$(icon check_prop persist.vendor.hid.ultra_polling 1)"
    printf " %b 34) HID: Fastpath (Caminho Rápido)${RESET}\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
    printf " %b 35) Input: Filtro OFF (RAW)${RESET}\n" "$(icon check_prop persist.sys.input.filter 0)"
    printf " %b 36) Input: Touchpad Smooth OFF${RESET}\n" "$(icon check_prop persist.sys.touchpad.smooth 0)"
    printf " %b 37) Input: Resample OFF${RESET}\n" "$(icon check_prop persist.sys.input.resample 0)"
    printf " %b 38) Input: Dejitter OFF${RESET}\n" "$(icon check_prop persist.sys.input.dejitter 0)"
    printf " %b 39) USB: Performance Mode${RESET}\n" "$(icon check_prop vendor.usb.performance_mode 1)"
    printf " %b 40) USB: Low Latency Interrupts${RESET}\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
    printf " %b 41) USB: Max Bus Bandwidth${RESET}\n" "$(icon check_prop vendor.usb.max_bus_bandwidth 1)"
    printf " %b 42) Input: Despacho Rápido${RESET}\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
    printf " %b 43) Input: Despacho Imediato${RESET}\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"

    # RESET / SPOOF
    printf "\n${RED}${BOLD}--- UTILIDADES ---${RESET}\n"
    printf " %b 44) Reset total (restaura tudo + reboot)\n" "${RED}${ICON_OFF}${RESET}"
    if spoof_status; then
        SPOOF_ICON="${GREEN}${ICON_ON}${RESET}"
    else
        SPOOF_ICON="${RED}${ICON_OFF}${RESET}"
    fi
    printf " %b 45) Ativar / Desativar Spoof 120 FPS\n" "$SPOOF_ICON"

    echo -e "\n 0) Voltar\n"
    read_prompt "> " item

    case "$item" in
        1) submenu_1 ;; 2) submenu_2 ;; 3) submenu_3 ;; 4) submenu_4 ;; 5) submenu_5 ;; 6) submenu_6 ;;
        7) submenu_7 ;; 8) submenu_8 ;; 9) submenu_9 ;; # NOVOS ITENS
        10) submenu_10 ;; 11) submenu_11 ;; 12) submenu_12 ;; 13) submenu_13 ;; 14) submenu_14 ;; 15) submenu_15 ;; 16) submenu_16 ;;
        17) submenu_17 ;; 18) submenu_18 ;; 19) submenu_19 ;; 
        20) submenu_20 ;; 21) submenu_21 ;; 22) submenu_22 ;;
        23) submenu_23 ;; 24) submenu_24 ;; 25) submenu_25 ;; 26) submenu_26 ;; 27) submenu_27 ;; 28) submenu_28 ;; 29) submenu_29 ;; 30) submenu_30 ;; 31) submenu_31 ;;
        32) submenu_32 ;; 33) submenu_33 ;; 34) submenu_34 ;; 35) submenu_35 ;; 36) submenu_36 ;; 37) submenu_37 ;; 38) submenu_38 ;; 39) submenu_39 ;; 40) submenu_40 ;; 41) submenu_41 ;; 42) submenu_42 ;; 43) submenu_43 ;;
        44) submenu_44 ;;
        45) submenu_45 ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida...${RESET}"; sleep 1 ;;
    esac
done
}

# =====================================================
# MENUS POR CATEGORIA (rápidos) - Atualizado
# =====================================================

menu_categoria_toque() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- TOQUE / ANIMAÇÕES ---${RESET}\n"
    printf " %b 1) Toque: Tempo Mínimo${RESET}\n" "$(icon check_setting secure tap_duration_threshold 70)"
    printf " %b 2) Toque: Longo (Timeout)${RESET}\n" "$(icon check_setting secure long_press_timeout 300)"
    printf " %b 3) Toque: Múltiplos (Fast Tap)${RESET}\n" "$(icon check_setting secure multi_press_timeout 130)"
    printf " %b 4) Animação: Janela OFF${RESET}\n" "$(icon check_setting global window_animation_scale 0)" # NOVO
    printf " %b 5) Animação: Transição OFF${RESET}\n" "$(icon check_setting global transition_animation_scale 0)" # NOVO
    printf " %b 6) Animação: Duração OFF${RESET}\n" "$(icon check_setting global animator_duration_scale 0)" # NOVO
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_1 ;;
        2) submenu_2 ;;
        3) submenu_3 ;;
        4) submenu_7 ;; # NOVO
        5) submenu_8 ;; # NOVO
        6) submenu_9 ;; # NOVO
        0) return ;;
        *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

# Resto das categorias (menu_categoria_usb, mouse, input, gpu, etc.) com a atualização visual
menu_categoria_usb() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
    cache_status
    echo -e "${BOLD}${CYAN}--- USB & HID ---${RESET}\n"
    printf " %b 1) USB: Raw Input${RESET}\n" "$(icon check_prop vendor.usb.raw_input.enable 1)"
    printf " %b 2) USB: Low Latency Mode${RESET}\n" "$(icon check_prop persist.usb.low_latency_mode 1)"
    printf " %b 3) USB: HID Priority${RESET}\n" "$(icon check_prop vendor.usb.hid.priority 2)"
    printf " %b 4) USB: High Speed${RESET}\n" "$(icon check_prop persist.vendor.usb.high_speed 1)"
    printf " %b 5) USB: Power Boost${RESET}\n" "$(icon check_prop persist.vendor.usb.power 1)"
    printf " %b 6) USB: Hub Boost${RESET}\n" "$(icon check_prop vendor.usb.hub.boost 1)"
    printf " %b 7) Mouse: Anti-Jitter USB${RESET}\n" "$(icon check_prop vendor.usb.mouse.jitter_filter 1)"
    printf " %b 8) USB: Performance Mode${RESET}\n" "$(icon check_prop vendor.usb.performance_mode 1)"
    printf " %b 9) USB: Low Latency Interrupts${RESET}\n" "$(icon check_prop persist.vendor.usb.low_latency_interrupts 1)"
    printf " %b 10) USB: Max Bus Bandwidth${RESET}\n" "$(icon check_prop vendor.usb.max_bus_bandwidth 1)"
    printf " %b 11) HID: Busy Polling (Sondagem)${RESET}\n" "$(icon check_prop persist.sys.hid.busy_polling 1)"
    printf " %b 12) HID: Ultra Polling${RESET}\n" "$(icon check_prop persist.vendor.hid.ultra_polling 1)"
    printf " %b 13) HID: Fastpath (Caminho Rápido)${RESET}\n" "$(icon check_prop vendor.hid.input.fastpath 1)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_10 ;; 2) submenu_11 ;; 3) submenu_12 ;; 4) submenu_13 ;; 5) submenu_14 ;; 6) submenu_15 ;; 7) submenu_16 ;;
        8) submenu_39 ;; 9) submenu_40 ;; 10) submenu_41 ;; 11) submenu_32 ;; 12) submenu_33 ;; 13) submenu_34 ;;
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
    printf " %b 1) Resposta Linear${RESET}\n" "$(icon check_prop persist.sys.mouse.linear_response 1)"
    printf " %b 2) Aceleração OFF${RESET}\n" "$(icon check_prop persist.sys.pointer.acceleration 0)"
    printf " %b 3) Anti-jitter Ponteiro${RESET}\n" "$(icon check_prop persist.input.pointer_jitter_smoothing 1)"
    printf " %b 4) Touchpad Smooth OFF${RESET}\n" "$(icon check_prop persist.sys.touchpad.smooth 0)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_17 ;; 2) submenu_18 ;; 3) submenu_19 ;;
        4) submenu_36 ;;
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
    printf " %b 1) Low Latency Mode${RESET}\n" "$(icon check_prop persist.sys.input.low_latency_mode 1)"
    printf " %b 2) High Update Rate${RESET}\n" "$(icon check_prop persist.sys.input.high_update_rate true)"
    printf " %b 3) Input Boost${RESET}\n" "$(icon check_prop persist.sys.input.boost 1)"
    printf " %b 4) Filtro OFF (RAW)${RESET}\n" "$(icon check_prop persist.sys.input.filter 0)"
    printf " %b 5) Resample OFF${RESET}\n" "$(icon check_prop persist.sys.input.resample 0)"
    printf " %b 6) Dejitter OFF${RESET}\n" "$(icon check_prop persist.sys.input.dejitter 0)"
    printf " %b 7) Despacho Rápido${RESET}\n" "$(icon check_prop persist.sys.input.dispatch_fast 1)"
    printf " %b 8) Despacho Imediato${RESET}\n" "$(icon check_prop persist.sys.input.dispatch_immediate 1)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_20 ;; 2) submenu_21 ;; 3) submenu_22 ;;
        4) submenu_35 ;; 5) submenu_37 ;; 6) submenu_38 ;; 7) submenu_42 ;; 8) submenu_43 ;;
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
    printf " %b 1) GPU Low Latency${RESET}\n" "$(icon check_prop persist.sys.gpu.low_latency 1)"
    printf " %b 2) GPU Frame Boost${RESET}\n" "$(icon check_prop persist.sys.gpu.frame_boost 1)"
    printf " %b 3) VSync OFF (HWUI)${RESET}\n" "$(icon check_prop debug.hwui.disable_vsync true)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_24 ;; 2) submenu_25 ;; 3) submenu_23 ;;
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
    printf " %b 1) Refresh interno 120Hz${RESET}\n" "$(icon check_setting system peak_refresh_rate 120)"
    printf " %b 2) Forçar refresh 120Hz${RESET}\n" "$(icon check_prop persist.sys.display.force_refresh 120)"
    printf " %b 3) Duplicação externa${RESET}\n" "$(icon check_prop persist.video.duplicate.display 1)"
    printf " %b 4) Prioridade externa${RESET}\n" "$(icon check_prop vendor.display.external_priority 1)"
    printf " %b 5) Saída dual${RESET}\n" "$(icon check_setting global display_dual_output 1)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_26 ;; 2) submenu_27 ;; 3) submenu_28 ;; 4) submenu_29 ;; 5) submenu_30 ;;
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
    printf " %b 1) Redução de latência (gamepad)${RESET}\n" "$(icon check_setting global gamepad.latency_reduction 1)"
    echo -e "\n0) Voltar\n"
    read_prompt "> " __op
    case "$__op" in
        1) submenu_31 ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

# O restante do código (menu_misc, submenu_boot, menu) permanece inalterado,
# apenas com os novos números de item (44, 45) onde aplicável.
menu_misc() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA
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
                submenu_44
            fi
            ;;
        3) submenu_boot ;;
        4) submenu_reboot ;;
        0) return ;;
        *) echo -e "${RED}Opção inválida${RESET}"; sleep 1 ;;
    esac
done
}

submenu_boot() {
clear
printf '\033c' # LIMPEZA FORÇADA
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

menu() {
while true; do
    clear
    printf '\033c' # LIMPEZA FORÇADA

    echo -e "${NEGRITO_VERDE}${NEGRITO}"
echo "══════════════════  F E R A   A L P H A  ══════════════════"
echo "        O Módulo Definitivo de Performance e Latência"
echo "     Aceleração Total • FPS Máximo • Input Instantâneo"
echo "   Zero Delay • Toque Preciso • USB Turbo • GPU Boost"
echo "═══════════════════════════════════════════════════════════"
echo -e "${RESET}\n"

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
        4) submenu_45 ;; # Spoof
        5)
           while true; do
               clear
               printf '\033c' # LIMPEZA FORÇADA
               echo -e "${BOLD}${CYAN}--- CATEGORIAS RÁPIDAS ---${RESET}\n"
               echo "1) Toque / Animações"
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

# =====================================================
# START
# =====================================================

# Otimização: Preenche o cache de status AQUI, se não for a chamada --ativar-todos
if [ "$1" != "--ativar-todos" ]; then
    cache_status 2>/dev/null
fi

menu
NEGRITO}${NEGRITO_CIANO}--- UTILIDADES ---${RESET}\n"
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

echo -e "${NEGRITO_VERDE}${NEGRITO}"
echo "══════════════════  F E R A   A L P H A  ══════════════════"
echo "        O Módulo Definitivo de Performance e Latência"
echo "     Aceleração Total • FPS Máximo • Input Instantâneo"
echo "   Zero Delay • Toque Preciso • USB Turbo • GPU Boost"
echo "═══════════════════════════════════════════════════════════"
echo -e "${RESET}\n"

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
