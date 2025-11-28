#!/bin/bash
# log-action.sh - Registra ação manual no sistema

LOG_FILE="$HOME/arch-system-tracker/logs/manual-actions.jsonl"

# JSONL = JSON Lines (um JSON por linha, fácil de processar)
echo "📝 Registrar ação manual"
echo ""
echo "Exemplos:"
echo "  - Instalei pacote X via yay"
echo "  - Configurei tema Y no Hyprland"
echo "  - Copiei arquivo Z para /etc/..."
echo ""
echo -n "Descreva a ação: "
read -r action

if [ -z "$action" ]; then
    echo "✗ Ação vazia, cancelando"
    exit 1
fi

# Adicionar ao log
echo "{\"timestamp\": \"$(date -Iseconds)\", \"action\": \"$action\"}" >> "$LOG_FILE"

echo "✓ Ação registrada"

# Commit no git
cd ~/arch-system-tracker
git add logs/
git commit -m "Log: $action" --quiet 2>/dev/null || true
