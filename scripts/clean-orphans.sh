#!/bin/bash
# clean-orphans.sh - Remove pacotes órfãos

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

log INFO "Buscando pacotes órfãos..."
echo ""
echo "ℹ️  Pacotes órfãos são dependências que não são mais necessárias"
echo ""

ORPHANS=$(pacman -Qtdq 2>/dev/null)

if [ -z "$ORPHANS" ]; then
    log INFO "Nenhum pacote órfão encontrado."
    exit 0
fi

echo "📦 Pacotes órfãos encontrados:"
echo "$ORPHANS" | sed 's/^/  - /'
echo ""
echo "Total: $(echo "$ORPHANS" | wc -l) pacotes"
echo ""
echo -n "Remover todos? (s/N): "
read -r response

if [[ "$response" =~ ^[Ss]$ ]]; then
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm
    echo ""
    log SUCESSO "Pacotes órfãos removidos!"
    
    log INFO "Iniciando snapshot automatico.." 
    ~/arch-system-tracker/scripts/snapshot.sh
else
    log INFO "Operação cancelada."
fi
