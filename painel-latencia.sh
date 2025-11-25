#!/system/bin/sh

###############################################################################
# 🔄 AUTO-UPDATE DO PAINEL (GIT HUB)
###############################################################################

PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh?$(date +%s)"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt?$(date +%s)"

SELF="$0"
LOCAL_HASH="/data/local/tmp/painel_hash"
TMP_DL="/data/local/tmp/painel_dl.sh"

[ ! -f "$LOCAL_HASH" ] && echo "0" > "$LOCAL_HASH"
LOCAL=$(cat "$LOCAL_HASH")

REMOTE=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

if [ "$REMOTE" != "$LOCAL" ] && [ -n "$REMOTE" ]; then
    clear
    echo "==============================================="
    echo "      🔄 Atualização disponível — FERA ALPHA"
    echo "==============================================="
    echo ""
    echo "Baixando nova versão..."
    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ -s "$TMP_DL" ]; then
        NEW=$(sha256sum "$TMP_DL" | awk '{print $1}')
        if [ "$NEW" = "$REMOTE" ]; then
            cp -f "$TMP_DL" "$SELF"
            chmod 755 "$SELF"
            echo "$REMOTE" > "$LOCAL_HASH"
            echo ""
            echo "✔ Atualizado com sucesso!"
            echo "Reabra o painel:"
            echo ""
            echo "  sh painel-latencia.sh"
            exit
        else
            echo "❌ Erro: hash incorreto. Abortando atualização."
        fi
    else
        echo "❌ Falha ao baixar arquivo."
    fi
fi

###############################################################################
# RESTO DO SISTEMA — SUA BASE ORIGINAL MANTIDA
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

  if command -v md5sum >/dev/null 2>&1; then
    echo -n "$FP_RAW" | md5sum | awk '{print $1}'
  else
    echo -n "$FP_RAW"
  fi
}

reset_total_auto() {
    echo "⚠ RESET AUTOMÁTICO — LICENÇA EXPIRADA" > /dev/kmsg
    rm -f "$MODDIR/license_info"
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
  JSON="{\"username\":\"$1\",\"password\":\"$2\",\"fingerprint\":\"$(gera_fingerprint)\"}"

  RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")

  if echo "$RESP" | grep -q '"status":"error"'; then
    MSG=$(echo "$RESP" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
    echo -e "\033[1;31m❌ Erro: ${MSG:-Credenciais inválidas}\033[0m"
    return 1
  fi

  EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
  [ -n "$EXP" ] && echo "$EXP" > "$MODDIR/license_info"

  return 0
}

###############################################################################
# 🎨 INTERFACE PREMIUM FERA ALPHA — REWORK TOTAL
###############################################################################

loading_bar() {
  clear
  echo -e "\n\033[1;36mINICIANDO SISTEMA FERA ALPHA...\033[0m\n"
  bar=""
  max=35
  i=1
  while [ $i -le $max ]; do
    bar="${bar}█"
    pct=$(( i * 100 / max ))
    printf "\r\033[1;32m[%-35s] %d%%\033[0m" "$bar" "$pct"
    sleep 0.02
    i=$((i+1))
  done
  sleep 0.3
  clear
}

header_anim() {
  cols=$(stty size | awk '{print $2}')
  TITLE="FERA ALPHA LOGIN"
  PAD=$(( (cols - ${#TITLE}) / 2 ))
  printf "%${PAD}s" " "
  echo -e "\033[1;35m$TITLE\033[0m"
  sleep 0.05
}

login_caixa() {
  echo -e "\033[1;34m┌─────────────────────────────┐\033[0m"
  echo -e "\033[1;34m│     🔐 ACESSO RESTRITO       │\033[0m"
  echo -e "\033[1;34m└─────────────────────────────┘\033[0m"
}

input_login() {
  echo -e "\033[1;36mUsuário:\033[0m"
  printf "> "
  read USER

  echo -e "\033[1;36mSenha:\033[0m"
  printf "> "
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
  sleep 0.8
  clear
}

###############################################################################
# LOGIN PRINCIPAL COM INTERFACE PRO
###############################################################################

painel_login() {
  loading_bar
  header_anim
  login_caixa
  input_login

  echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"
  sleep 0.4

  ativar_servidor "$USER" "$PASS"
  if [ $? -ne 0 ]; then
      erro_login
      return 1
  fi

  bem_vindo
  return 0
}

###############################################################################
# Tentativas
###############################################################################

tent=0
while [ $tent -lt 3 ]; do
  painel_login
  [ $? -eq 0 ] && break
  tent=$((tent+1))
  echo -e "\033[1;33mTentativas restantes: $((3-tent))\033[0m"
done

[ $tent -ge 3 ] && {
  echo -e "\033[1;31m❌ Falha ao autenticar.\033[0m"
  exit 1
}

clear
echo "✔ Painel carregado!"
sleep 1
