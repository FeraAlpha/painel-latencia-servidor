#!/system/bin/sh
MODDIR=${0%/*}

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
