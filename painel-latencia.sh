#!/system/bin/sh

###############################################################################
# 🔄 VERIFICAÇÃO DE UPDATE MANUAL
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
    echo "          FERA ALPHA — Verificar Update       "
    echo "──────────────────────────────────────────────"
    echo ""
    echo "Verificando servidor..."
    sleep 0.3

    LOCAL=$(cat "$LOCAL_HASH")
    REMOTO=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

    if [ -z "$REMOTO" ]; then
        echo "Não foi possível verificar atualização."
        sleep 1
        return
    fi

    if [ "$LOCAL" = "$REMOTO" ]; then
        echo "Você já está na versão mais recente."
        sleep 1
        return
    fi

    echo "Nova versão detectada! Baixando..."
    sleep 0.3

    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ ! -s "$TMP_DL" ]; then
        echo "Falha no download."
        sleep 1
        return
    fi

    NOVO_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NOVO_HASH" != "$REMOTO" ]; then
        echo "Hash inválido. Atualização cancelada."
        sleep 1
        return
    fi

    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"

    clear
    echo "Painel atualizado com sucesso!"
    echo ""
    echo "Reabra usando:"
    echo "sh $SELF"
    exit
}

###############################################################################
#                  🔐 LOGIN OBRIGATÓRIO SEMPRE
###############################################################################

MODDIR=${0%/*}
SERVER="https://painel-licenca-server.onrender.com"
LICENSE_FILE="$MODDIR/license_info"
RESET_SCRIPT="$MODDIR/reset_auto.sh"

###############################################################
# Fingerprint (SEGURANÇA)
###############################################################
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
# Expiração + Reset Total (SEGURANÇA)
###############################################################
reset_total_auto() {
    echo "⚠ RESET AUTOMÁTICO — LICENÇA EXPIRADA" > /dev/kmsg

cat > "$RESET_SCRIPT" <<'EOF'
#!/system/bin/sh

# RESET COMPLETO DA LICENÇA

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

# FLAGS E LICENÇA
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

###############################################################
# Autenticação (SEGURANÇA)
###############################################################
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

###############################################################
# VISUAL — 100% COMPATÍVEL MKSH
###############################################################

# Loading Bar (AGORA MAIS RÁPIDO)
loading_bar() {
  clear
  echo -e "\n\033[1;36mIniciando Painel FERA ALPHA...\033[0m\n"
  bar=""
  max=18
  i=1
  while [ $i -le $max ]; do
    bar="${bar}█"
    pct=$(( i * 100 / max ))
    printf "\r\033[1;32m[%-18s] %d%%\033[0m" "$bar" "$pct"
    sleep 0.01
    i=$((i+1))
  done

  echo -e "\n\033[1;32m✔ Sistema carregado!\033[0m"
  sleep 0.2
  clear
}

# HEADER ANIMADO
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
  [ $pad -lt 0 ] && pad=0

  printf "%${pad}s" " "
  type_anim "\033[1;34m$line  $t1  $line\033[0m"

  sleep 0.01

  login_pad=$(( (cols - ${#t2}) / 2 ))
  printf "%${login_pad}s" " "
  type_anim "\033[1;37m$t2\033[0m"

  echo ""
}

# Entrada usuário/senha
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
# MENU PROFISSIONAL ANTES DO LOGIN
###############################################################################

menu_inicio() {
    clear
    echo ""
    echo "──────────────────────────────────────────────"
    echo "                  FERA ALPHA                  "
    echo "──────────────────────────────────────────────"
    echo ""
    echo "[1] Fazer login"
    echo "[2] Verificar atualização"
    echo "[0] Sair"
    echo ""
    read -p "Escolha: " OP
}

while true; do
    menu_inicio
    case "$OP" in
        1) break ;;
        2) verificar_update_manual ;;
        0) exit ;;
    esac
done

###############################################################################
# Painel Login
###############################################################################

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

clear
