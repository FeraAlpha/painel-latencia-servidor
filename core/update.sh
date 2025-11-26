#!/system/bin/sh

MODDIR=${0%/*}
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
    sleep 0.3

    LOCAL=$(cat "$LOCAL_HASH")
    REMOTO=$(curl -fsSL "$HASH_URL" | sed 's/[^0-9a-fA-F]//g')

    if [ -z "$REMOTO" ]; then
        echo "⚠ Não foi possível verificar atualização."
        sleep 1
        return
    fi

    if [ "$LOCAL" = "$REMOTO" ]; then
        echo "✔ Já está na versão mais recente."
        sleep 1
        return
    fi

    echo "🔄 Nova versão detectada! Baixando..."
    sleep 0.3

    curl -fsSL "$PAINEL_URL" -o "$TMP_DL"

    if [ ! -s "$TMP_DL" ]; then
        echo "❌ Falha no download."
        sleep 1
        return
    fi

    NEW_HASH=$(sha256sum "$TMP_DL" | awk '{print $1}')
    if [ "$NEW_HASH" != "$REMOTO" ]; then
        echo "❌ Hash incorreto. Atualização cancelada."
        sleep 1
        return
    fi

    cp -f "$TMP_DL" "$SELF"
    chmod 755 "$SELF"
    echo "$REMOTO" > "$LOCAL_HASH"

    clear
    echo "✔ Painel atualizado com sucesso!"
    echo ""
    echo "Reabra usando:"
    echo "sh $SELF"
    exit
}
