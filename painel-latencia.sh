###############################################################################
# 🖥 INTERFACE PREMIUM — FERA ALPHA LOGIN (VER. PRO)
###############################################################################
painel_login() {
  clear
  
  # Paleta de cores (neon / premium)
  CYAN="\033[96m"
  BLUE="\033[94m"
  PURPLE="\033[95m"
  GREEN="\033[92m"
  RED="\033[91m"
  RESET="\033[0m"
  BOLD="\033[1m"

  # Logo FERA ALPHA Premium
  echo -e "$PURPLE$BOLD"
  echo "███████╗███████╗██████╗  █████╗      █████╗ ██╗     ██████╗ ██╗  ██╗ █████╗"
  echo "██╔════╝██╔════╝██╔══██╗██╔══██╗    ██╔══██╗██║     ██╔══██╗██║ ██╔╝██╔══██╗"
  echo "█████╗  █████╗  ██║  ██║███████║    ███████║██║     ██████╔╝█████╔╝ ███████║"
  echo "██╔══╝  ██╔══╝  ██║  ██║██╔══██║    ██╔══██║██║     ██╔══██╗██╔═██╗ ██╔══██║"
  echo "██║     ███████╗██████╔╝██║  ██║    ██║  ██║███████╗██║  ██║██║  ██╗██║  ██║"
  echo -e "╚═╝     ╚══════╝╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝$RESET"
  echo ""

  # Moldura do painel
  echo -e "$CYAN┌────────────────────────────────────────────┐$RESET"
  echo -e "$CYAN│$RESET             🔐  LOGIN DE ACESSO               $CYAN│$RESET"
  echo -e "$CYAN└────────────────────────────────────────────┘$RESET"
  echo ""

  # Entrada usuário
  echo -e "$BLUE[ $RESETDigite seu usuário $BLUE]$RESET"
  printf "$PURPLE> $RESET"
  read USER

  # Entrada senha
  echo ""
  echo -e "$BLUE[ $RESETDigite sua senha $BLUE]$RESET"
  printf "$PURPLE> $RESET"
  stty -echo
  read PASS
  stty echo
  echo ""

  # Animação de validação
  echo ""
  echo -e "$CYAN⏳ Validando no servidor..."
  sleep 0.4
  echo -e "$CYAN⏳ Validando no servidor.."
  sleep 0.4
  echo -e "$CYAN⏳ Validando no servidor..."
  sleep 0.4
  echo ""

  ativar_servidor "$USER" "$PASS"
  return $?
}
