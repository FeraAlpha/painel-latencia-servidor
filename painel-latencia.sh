#!/system/bin/sh

###############################################################################
# 🔄 VERIFICAÇÃO DE UPDATE ANTES DO LOGIN
###############################################################################

PAINEL_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/painel-latencia.sh?$(date +%s)"
HASH_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main/hash.txt?$(date +%s)"

SELF="$0"
LOCAL_HASH="/data/local/tmp/painel_hash"
TMP_DL="/data/local/tmp/painel_new.sh"

[ ! -f "$LOCAL_HASH" ] && echo "0" > "$LOCAL_HASH"

verificar_update() {
    clear
    echo -e "\033[1;36m🔍 Verificando atualização do painel...\033[0m"
    sleep 0.5

    LOCAL=$(cat "$LOCAL_HASH")
    REMOTO=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

    if [ -z "$REMOTO" ]; then
        echo -e "\033[1;33m⚠ Não foi possível verificar atualização.\033[0m"
        sleep 0.7
        return 0
    fi

    if [ "$LOCAL" = "$REMOTO" ]; then
        echo -e "\033[1;32m✔ Painel já está atualizado!\033[0m"
        sleep 0.7
        return 0
    fi

    echo -e "\033[1;34m🔄 Nova versão encontrada! Baixando...\033[0m"
    sleep 0.3

    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ ! -s "$TMP_DL" ]; then
        echo -e "\033[1;31m❌ Erro ao baixar nova versão.\033[0m"
        sleep 1
        return 0
    fi

    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        echo -e "\033[1;31m❌ Hash incorreto. Atualização abortada.\033[0m"
        sleep 1
        return 0
    fi

    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"

    clear
    echo -e "\033[1;32m✔ Painel atualizado com sucesso!\033[0m"
    echo ""
    echo "Reabra o painel:"
    echo -e "\033[1;36msh $SELF\033[0m"
    exit
}

verificar_update

###############################################################################
# RESTO DO SEU SISTEMA (NÃO ALTERADO)
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
# 🎨 INTERFACE COM ANIMAÇÃO MAIS RÁPIDA
###############################################################################

loading_bar() {
  clear
  echo -e "\n\033[1;36mCarregando Painel FERA ALPHA...\033[0m\n"

  bar=""
  max=20
  i=1

  while [ $i -le $max ]; do
    bar="${bar}█"
    pct=$(( i * 100 / max ))
    printf "\r\033[1;32m[%-20s] %d%%\033[0m" "$bar" "$pct"
    sleep 0.015
    i=$((i+1))
  done

  sleep 0.2
  clear
}

print_header() {
  clear
  cols=$(stty size | awk '{print $2}')

  t1="FERA ALPHA"
  t2="LOGIN"

  line=$(printf "%${#t1}s" | tr " " "=")

  printf "%$(( (cols - ${#t1}*3 ) / 2 ))s"
  echo -e "\033[1;35m$line  $t1  $line\033[0m"

  sleep 0.03

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
  sleep 0.3
  clear
}

painel_login() {
  loading_bar
  print_header
  input_login

  echo -e "\033[1;36m⏳ Validando no servidor...\033[0m"

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

if [ $tent -ge 3 ]; then
  echo -e "\033[1;31m❌ Falha ao autenticar. Saindo.\033[0m"
  exit 1
fi

clear
echo "✔ Painel carregado!"
sleep 1
