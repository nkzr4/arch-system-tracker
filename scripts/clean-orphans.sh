#!/bin/bash
# clean-orphans.sh - Remove pacotes órfãos

echo "🔍 Buscando pacotes órfãos..."
echo ""
echo "ℹ️  Pacotes órfãos são dependências que não são mais necessárias"
echo ""

ORPHANS=$(pacman -Qtdq 2>/dev/null)

if [ -z "$ORPHANS" ]; then
    echo "✓ Nenhum pacote órfão encontrado"
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
    echo "✓ Pacotes órfãos removidos"
    
    # Snapshot automático
    ~/arch-system-tracker/scripts/snapshot.sh
else
    echo "✗ Operação cancelada"
fi
