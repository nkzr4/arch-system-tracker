#!/bin/bash
# compare.sh - Compara dois snapshots

SNAPSHOT_DIR="$HOME/arch-system-tracker/snapshots"

# Listar snapshots
echo "📊 Snapshots disponíveis:"
snapshots=($(ls -1t "$SNAPSHOT_DIR"/system-*.json))
for i in "${!snapshots[@]}"; do
    basename="${snapshots[$i]}"
    timestamp=$(echo "$basename" | sed 's/system-//; s/.json//')
    echo "  [$((i+1))] $timestamp"
done

echo ""
echo -n "Snapshot ANTIGO (número ou Enter para penúltimo): "
read -r old_num
echo -n "Snapshot NOVO (número ou Enter para último): "
read -r new_num

# Defaults
old_num=${old_num:-2}
new_num=${new_num:-1}

OLD_SNAP="${snapshots[$((old_num-1))]}"
NEW_SNAP="${snapshots[$((new_num-1))]}"

if [ ! -f "$OLD_SNAP" ] || [ ! -f "$NEW_SNAP" ]; then
    echo "✗ Snapshots inválidos"
    exit 1
fi

echo ""
echo "🔍 Comparando:"
echo "  Antigo: $(basename $OLD_SNAP)"
echo "  Novo:   $(basename $NEW_SNAP)"
echo ""

# Comparar pacotes explícitos
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 PACOTES EXPLÍCITOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

jq -r '.packages.explicit[].name' "$OLD_SNAP" | sort > /tmp/old_packages.txt
jq -r '.packages.explicit[].name' "$NEW_SNAP" | sort > /tmp/new_packages.txt

added=$(comm -13 /tmp/old_packages.txt /tmp/new_packages.txt)
removed=$(comm -23 /tmp/old_packages.txt /tmp/new_packages.txt)

if [ -n "$added" ]; then
    echo ""
    echo "➕ ADICIONADOS:"
    echo "$added" | sed 's/^/  - /'
fi

if [ -n "$removed" ]; then
    echo ""
    echo "➖ REMOVIDOS:"
    echo "$removed" | sed 's/^/  - /'
fi

if [ -z "$added" ] && [ -z "$removed" ]; then
    echo "  (sem mudanças)"
fi

# Comparar total de pacotes
old_count=$(jq '.packages.count.total' "$OLD_SNAP")
new_count=$(jq '.packages.count.total' "$NEW_SNAP")
diff_count=$((new_count - old_count))

echo ""
echo "📊 Total: $old_count → $new_count (${diff_count:+$diff_count})"

# Comparar serviços
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  SERVIÇOS HABILITADOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

jq -r '.services.enabled[]' "$OLD_SNAP" | sort > /tmp/old_services.txt
jq -r '.services.enabled[]' "$NEW_SNAP" | sort > /tmp/new_services.txt

added_srv=$(comm -13 /tmp/old_services.txt /tmp/new_services.txt)
removed_srv=$(comm -23 /tmp/old_services.txt /tmp/new_services.txt)

if [ -n "$added_srv" ]; then
    echo ""
    echo "➕ HABILITADOS:"
    echo "$added_srv" | sed 's/^/  - /'
fi

if [ -n "$removed_srv" ]; then
    echo ""
    echo "➖ DESABILITADOS:"
    echo "$removed_srv" | sed 's/^/  - /'
fi

if [ -z "$added_srv" ] && [ -z "$removed_srv" ]; then
    echo "  (sem mudanças)"
fi

# Limpar temporários
rm /tmp/old_packages.txt /tmp/new_packages.txt /tmp/old_services.txt /tmp/new_services.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
