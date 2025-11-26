#!/system/bin/sh

# =============================================
#  FERA ALPHA – Instalador Automático do Painel
# =============================================

BASE_URL="https://raw.githubusercontent.com/FeraAlpha/painel-latencia-servidor/main"
TARGET_DIR="/data/local/tmp/painel"

echo ""
echo "🔥 Instalando Painel FERA ALPHA..."
echo ""

# Criar pastas
mkdir -p "$TARGET_DIR/core"

# Baixar arquivo principal
echo "📥 Baixando painel-latencia.sh..."
curl -fsSL "$BASE_URL/painel-latencia.sh" -o "$TARGET_DIR/painel.sh" || {
    echo "❌ Falha ao baixar painel principal."
    exit 1
}

# Lista de módulos
MODULES="update.sh login.sh tweaks.sh spoof.sh menu.sh boot.sh"

# Baixar módulos
for file in $MODULES; do
    echo "📥 Baixando core/$file..."
    curl -fsSL "$BASE_URL/core/$file" -o "$TARGET_DIR/core/$file" || {
        echo "❌ Falha ao baixar módulo: $file"
        exit 1
    }
done

# Permissões
chmod -R 755 "$TARGET_DIR"

echo ""
echo "✔ Instalação concluída!"
echo "👉 Para abrir o painel, execute:"
echo ""
echo "sh $TARGET_DIR/painel.sh"
echo ""
