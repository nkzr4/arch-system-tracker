#!/bin/bash
# compare.sh - Compara dois snapshots

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

log INFO "Iniciando comparação de snapshots..."
SNAPSHOT_DIR="$HOME/.local/share/arch-system-tracker/snapshots"

log INFO "Snapshots disponíveis..."
snapshots=($(ls -1t "$SNAPSHOT_DIR"/system-*.json))
for i in "${!snapshots[@]}"; do
    basename="${snapshots[$i]}"
    timestamp=$(echo "$basename" | sed 's/system-//; s/.json//')
    echo "  [$((i+1))] $timestamp"
done

log INFO "Definindo snapshots para comparação..."
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
    exit 1
fi

log INFO "Comparando snapshots..."
echo ""
echo "🔍 Comparando:"
echo "  Antigo: $(basename $OLD_SNAP)"
echo "  Novo:   $(basename $NEW_SNAP)"
echo ""

# =============================================================================
# PACOTES EXPLÍCITOS
# =============================================================================
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

# =============================================================================
# TOTAL
# =============================================================================
old_count=$(jq '.packages.count.total' "$OLD_SNAP")
new_count=$(jq '.packages.count.total' "$NEW_SNAP")
diff_count=$((new_count - old_count))

echo ""
echo "📊 Total: $old_count → $new_count (${diff_count:+$diff_count})"

# =============================================================================
# COMPARAR AUR VIA YAY
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 AUR via YAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

jq -r '.packages.yay[]?.name' "$OLD_SNAP" 2>/dev/null | sort > /tmp/old_yay.txt || echo > /tmp/old_yay.txt
jq -r '.packages.yay[]?.name' "$NEW_SNAP" 2>/dev/null | sort > /tmp/new_yay.txt || echo > /tmp/new_yay.txt

added_yay=$(comm -13 /tmp/old_yay.txt /tmp/new_yay.txt)
removed_yay=$(comm -23 /tmp/old_yay.txt /tmp/new_yay.txt)

if [ -n "$added_yay" ]; then
    echo ""
    echo "➕ ADICIONADOS:"
    echo "$added_yay" | sed 's/^/  - /'
fi

if [ -n "$removed_yay" ]; then
    echo ""
    echo "➖ REMOVIDOS:"
    echo "$removed_yay" | sed 's/^/  - /'
fi

if [ -z "$added_yay" ] && [ -z "$removed_yay" ]; then
    echo "  (sem mudanças ou yay ausente)"
fi

# =============================================================================
# COMPARAR AUR VIA PARU
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 AUR via PARU"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

jq -r '.packages.paru[]?.name' "$OLD_SNAP" 2>/dev/null | sort > /tmp/old_paru.txt || echo > /tmp/old_paru.txt
jq -r '.packages.paru[]?.name' "$NEW_SNAP" 2>/dev/null | sort > /tmp/new_paru.txt || echo > /tmp/new_paru.txt

added_paru=$(comm -13 /tmp/old_paru.txt /tmp/new_paru.txt)
removed_paru=$(comm -23 /tmp/old_paru.txt /tmp/new_paru.txt)

if [ -n "$added_paru" ]; then
    echo ""
    echo "➕ ADICIONADOS:"
    echo "$added_paru" | sed 's/^/  - /'
fi

if [ -n "$removed_paru" ]; then
    echo ""
    echo "➖ REMOVIDOS:"
    echo "$removed_paru" | sed 's/^/  - /'
fi

if [ -z "$added_paru" ] && [ -z "$removed_paru" ]; then
    echo "  (sem mudanças ou paru ausente)"
fi

# =============================================================================
# COMPARAR HELPERS INSTALADOS
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛠 HELPERS DISPONÍVEIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

old_yay_flag=$(jq '.helpers.yay_installed' "$OLD_SNAP")
new_yay_flag=$(jq '.helpers.yay_installed' "$NEW_SNAP")

old_paru_flag=$(jq '.helpers.paru_installed' "$OLD_SNAP")
new_paru_flag=$(jq '.helpers.paru_installed' "$NEW_SNAP")

if [ "$old_yay_flag" != "$new_yay_flag" ]; then
    echo "YAY: $old_yay_flag → $new_yay_flag"
fi

if [ "$old_paru_flag" != "$new_paru_flag" ]; then
    echo "PARU: $old_paru_flag → $new_paru_flag"
fi

if [ "$old_yay_flag" = "$new_yay_flag" ] && [ "$old_paru_flag" = "$new_paru_flag" ]; then
    echo "  (sem mudanças)"
fi

# =============================================================================
# COMPARAR VERSÕES DOS HELPERS
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧩 VERSÕES DOS HELPERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

old_yay_ver=$(jq -r '.helpers.versions.yay'  "$OLD_SNAP")
new_yay_ver=$(jq -r '.helpers.versions.yay'  "$NEW_SNAP")

old_paru_ver=$(jq -r '.helpers.versions.paru' "$OLD_SNAP")
new_paru_ver=$(jq -r '.helpers.versions.paru' "$NEW_SNAP")

if [ "$old_yay_ver" != "$new_yay_ver" ]; then
    echo "YAY: $old_yay_ver → $new_yay_ver"
fi

if [ "$old_paru_ver" != "$new_paru_ver" ]; then
    echo "PARU: $old_paru_ver → $new_paru_ver"
fi

if [ "$old_yay_ver" = "$new_yay_ver" ] && [ "$old_paru_ver" = "$new_paru_ver" ]; then
    echo "  (sem mudanças)"
fi

# =============================================================================
# SERVIÇOS
# =============================================================================
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
rm /tmp/old_packages.txt /tmp/new_packages.txt /tmp/old_services.txt /tmp/new_services.txt \
   /tmp/old_yay.txt /tmp/new_yay.txt /tmp/old_paru.txt /tmp/new_paru.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log SUCESSO "Comparação finalizada!"
