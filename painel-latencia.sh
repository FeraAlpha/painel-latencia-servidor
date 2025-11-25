#!/system/bin/sh

###############################################################################
# 🔄 SISTEMA DE UPDATE (MANUAL + AUTO)
###############################################################################

PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh?$(date +%s)"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt?$(date +%s)"

SELF="$0"
LOCAL_HASH="/data/local/tmp/painel_hash"
TMP_DL="/data/local/tmp/painel_new.sh"

[ ! -f "$LOCAL_HASH" ] && echo "0" > "$LOCAL_HASH"

center() {
    txt="$1"
    COLS=$(stty size | awk '{print $2}')
    PAD=$(( (COLS - ${#txt}) / 2 ))
    [ $PAD -lt 0 ] && PAD=0
    printf "%${PAD}s%s\n" "" "$txt"
}

update_check() {
    clear
    center "───────────────────────────────────────"
    center "        FERA ALPHA — UPDATE"
    center "───────────────────────────────────────"
    echo ""

    center "Verificando atualização..."
    sleep 0.2

    LOCAL=$(cat "$LOCAL_HASH")
    REMOTO=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

    if [ -z "$REMOTO" ]; then
        center "Não foi possível verificar."
        sleep 1
        return
    fi

    if [ "$LOCAL" = "$REMOTO" ]; then
        center "Você já está na versão mais recente."
        sleep 1
        return
    fi

    center "Nova versão encontrada!"
    center "Baixando atualização..."
    sleep 0.3

    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ ! -s "$TMP_DL" ]; then
        center "Falha no download."
        sleep 1
        return
    fi

    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        center "Hash incorreto. Atualização rejeitada."
        sleep 1
        return
    fi

    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"

    clear
    center "Atualizado com sucesso!"
    center "Reabra o painel:"
    echo ""
    center "sh $SELF"
    exit
}

###############################################################################
# 🔐 SEGURANÇA ORIGINAL (INALTERADA)
###############################################################################

MODDIR=${0%/*}
SERVER="https://painel-licenca-server.onrender.com"
LICENSE_FILE="$MODDIR/license_info"
RESET_SCRIPT="$MODDIR/reset_auto.sh"

gera_fingerprint() {
  ANDROID_ID=$(settings get secure android_id 2>/dev/null || echo "")
  SERIAL=$(getprop ro.serialno 2>/dev/null || echo "")
  MODEL=$(getprop ro.product.model 2>/dev/null || echo "")
  FP_RAW="${ANDROID_ID}-${SERIAL}-${MODEL}"
  echo -n "$FP_RAW" | md5sum | awk '{print $1}'
}

verifica_expiracao() {
    [ ! -f "$LICENSE_FILE" ] && return
    EXP=$(cat "$LICENSE_FILE")
    NOW=$(date +%s)
    [ "$NOW" -ge "$EXP" ] && reset_total_auto
}

verifica_expiracao

ativar_servidor() {
  JSON="{\"username\":\"$1\",\"password\":\"$2\",\"fingerprint\":\"$(gera_fingerprint)\"}"
  RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")
  echo "$RESP" | grep -q '"status":"error"' && return 1
  EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
  [ -n "$EXP" ] && echo "$EXP" > "$MODDIR/license_info"
  return 0
}

###############################################################################
# ⚡ INTERFACE MAIS RÁPIDA + PROFISSIONAL
###############################################################################

loading_bar() {
  clear
  echo -e "\n\033[1;36mIniciando FERA ALPHA...\033[0m\n"
  bar=""
  max=18
  for i in $(seq 1 $max); do
    bar="${bar}█"
    pct=$(( i * 100 / max ))
    printf "\r\033[1;32m[%-18s] %d%%\033[0m" "$bar" "$pct"
    sleep 0.01
  done
  sleep 0.1
  clear
}

print_header() {
    clear
    center "═══════════════════════════════════"
    center "           FERA ALPHA"
    center "═══════════════════════════════════"
    echo ""
}

###############################################################################
# MENU ANTES DO LOGIN
###############################################################################

menu_inicio() {
    clear
    print_header
    center "[1] Fazer login"
    center "[2] Verificar atualização"
    center "[0] Sair"
    echo ""
    center "Escolha:"
    read OP
}

###############################################################################
# LOGIN NORMAL
###############################################################################

input_login() {
  echo -e "\033[1;34mUsuário:\033[0m"
  read -p "> " USER

  echo -e "\033[1;34mSenha:\033[0m"
  stty -echo
  read -p "> " PASS
  stty echo
  echo ""
}

erro_login() {
  center "Acesso negado."
  sleep 1
}

bem_vindo() {
  center "Login autorizado."
  sleep 0.5
}

painel_login() {
  loading_bar
  print_header
  input_login
  ativar_servidor "$USER" "$PASS"
}

###############################################################################
# LOOP PRINCIPAL
###############################################################################

while true; do
    menu_inicio

    case "$OP" in
        1)
            tent=0
            while [ $tent -lt 3 ]; do
                painel_login && { bem_vindo; break; }
                erro_login
                tent=$((tent+1))
            done
            [ $tent -ge 3 ] && exit
            break
        ;;
        2)
            update_check
        ;;
        0)
            exit
        ;;
    esac
done

clear
