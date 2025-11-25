#!/system/bin/sh
# Painel FERA ALPHA — Completo com Auto-Update + Login Premium

###############################################################################
# 🔄 SISTEMA DE AUTO-UPDATE DIRETO DO GITHUB
###############################################################################

PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh?$(date +%s)"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt?$(date +%s)"

THIS_PANEL="$0"
LOCAL_HASH_FILE="/data/local/tmp/painel_hash"
TMP_NEW="/data/local/tmp/painel_new.sh"

# Se não existir hash local → cria
[ ! -f "$LOCAL_HASH_FILE" ] && echo "0" > "$LOCAL_HASH_FILE"

LOCAL_HASH=$(cat "$LOCAL_HASH_FILE")
REMOTE_HASH=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
    echo ""
    echo "🔄 Atualização detectada! Baixando nova versão..."
    curl -fsSL "$PAINEL_URL" -o "$TMP_NEW"

    if [ -s "$TMP_NEW" ]; then
        NEW_HASH=$(sha256sum "$TMP_NEW" | awk '{print $1}')

        if [ "$NEW_HASH" = "$REMOTE_HASH" ]; then
            cp -f "$TMP_NEW" "$THIS_PANEL"
            chmod 755 "$THIS_PANEL"
            echo "$REMOTE_HASH" > "$LOCAL_HASH_FILE"
            echo "✔ Atualização concluída! Reinicie o painel."
            exit
        else
            echo "❌ Hash incorreto! Arquivo corrompido."
        fi
    else
        echo "❌ Falha ao baixar atualização."
    fi
fi


###############################################################################
# 🔐 LOGIN OBRIGATÓRIO — FERA ALPHA
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

###############################################################################
# ⚠ SISTEMA DE EXPIRAÇÃO
###############################################################################

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


###############################################################################
# 🌐 Autenticação com Servidor
###############################################################################

ativar_servidor() {
  USER="$1"
  PASS="$2"
  FP=$(gera_fingerprint)

  JSON="{\"username\":\"$USER\",\"password\":\"$PASS\",\"fingerprint\":\"$FP\"}"

  echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"
  RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON" "$SERVER/activate")

  if echo "$RESP" | grep -q '"status":"error"'; then
    REASON=$(echo "$RESP" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
    echo -e "\033[1;31m❌ Erro: ${REASON:-Credenciais inválidas}\033[0m"
    return 1
  fi

  echo -e "\033[1;32m✔ Login aprovado!\033[0m"

  EXP=$(echo "$RESP" | sed -n 's/.*"expires_at":\([0-9]*\).*/\1/p')
  [ -n "$EXP" ] && echo "$EXP" > "$LICENSE_FILE"
  return 0
}

###############################################################################
# 🖥 INTERFACE PREMIUM DE LOGIN
###############################################################################

painel_login() {
  clear
  CYAN="\033[1;36m"
  GREEN="\033[1;32m"
  RED="\033[1;31m"
  RESET="\033[0m"
  YELLOW="\033[1;33m"

  echo -e "$CYAN┌──────────────────────────────────────────┐$RESET"
  echo -e "$CYAN│$RESET        🔐  FERA ALPHA — LOGIN           $CYAN│$RESET"
  echo -e "$CYAN└──────────────────────────────────────────┘$RESET"
  echo ""

  echo -e "$CYAN[>]$RESET Usuário:"
  printf "> "
  read USER

  echo ""
  echo -e "$CYAN[>]$RESET Senha:"
  printf "> "
  stty -echo
  read PASS
  stty echo
  echo ""

  echo ""
  echo -e "$YELLOW⏳ Validando com o servidor...$RESET"
  echo ""

  ativar_servidor "$USER" "$PASS"
  return $?
}

###############################################################################
# 🔁 SISTEMA DE TENTATIVAS
###############################################################################

tent=0
while [ $tent -lt 3 ]; do
  painel_login
  [ $? -eq 0 ] && break
  tent=$((tent+1))
  echo -e "\033[1;33mTentativas restantes: $((3-tent))\033[0m"
done

[ $tent -ge 3 ] && {
  echo -e "\033[1;31m❌ Falha ao autenticar. Saindo.\033[0m"
  exit 1
}

###############################################################################
# 🎉 LOGIN OK — CONTINUA PARA O PAINEL COMPLETO
###############################################################################

clear
echo "✔ Bem-vindo ao Painel FERA ALPHA!"
echo "Carregando..."
sleep 1
