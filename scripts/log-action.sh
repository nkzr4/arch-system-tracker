#!/bin/bash
# log-action.sh - Registra ação manual no sistema

# Função de logging
log() {
    local level="$1"
    local msg="$2"
    case "$level" in
        INFO)    echo "[INFO] $msg" ;;
        SUCESSO) echo "[SUCESSO] $msg" ;;
        ERRO)    echo "[ERRO] $msg" >&2 ;;
    esac
}

# Tratamento de erros
handle_error() {
    log ERRO "Ocorreu um erro inesperado durante a execução do script."
    exit 1
}
trap handle_error ERR

log INFO "Iniciando log de alteração manual..."
LOG_FILE="$HOME/arch-system-tracker/logs/manual-actions.jsonl"

log INFO "Registrando alteração manual..."
echo ""
echo "Exemplos:"
echo "  - Instalei pacote X via yay"
echo "  - Configurei tema Y no Hyprland"
echo "  - Copiei arquivo Z para /etc/..."
echo ""
echo -n "Descreva a ação: "
read -r action

if [ -z "$action" ]; then
    exit 1
fi

log INFO "Adicionando alteração ao log..."
echo "{\"timestamp\": \"$(date -Iseconds)\", \"action\": \"$action\"}" >> "$LOG_FILE"

log SUCESSO "Alteração adicionada com sucesso em: $LOG_FILE"

log INFO "Comitando no Git..."
cd ~/arch-system-tracker
git add logs/
git commit -m "Log: $action" --quiet 2>/dev/null || true

log SUCESSO "Commit criado com sucesso: \"Log: $action\""