#!/bin/bash
# snapshot.sh - Captura estado completo do sistema em JSON

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_FILE="$HOME/arch-system-tracker/snapshots/system-$TIMESTAMP.json"

echo "📸 Criando snapshot do sistema..."

# Gerar JSON completo
cat > "$SNAPSHOT_FILE" << EOF
{
  "metadata": {
    "timestamp": "$TIMESTAMP",
    "hostname": "$(hostname)",
    "kernel": "$(uname -r)",
    "architecture": "$(uname -m)"
  },
  "packages": {
    "explicit": $(pacman -Qe | jq -R -s 'split("\n") | map(select(length > 0) | split(" ") | {name: .[0], version: .[1]})'),
    "all": $(pacman -Q | jq -R -s 'split("\n") | map(select(length > 0) | split(" ") | {name: .[0], version: .[1]})'),
    "aur": $(pacman -Qm | jq -R -s 'split("\n") | map(select(length > 0) | split(" ") | {name: .[0], version: .[1]})'),
    "orphans": $(pacman -Qtdq 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))' || echo '[]'),
    "count": {
      "explicit": $(pacman -Qe | wc -l),
      "total": $(pacman -Q | wc -l),
      "aur": $(pacman -Qm | wc -l)
    }
  },
  "services": {
    "enabled": $(systemctl list-unit-files --state=enabled --no-pager --no-legend | awk '{print $1}' | jq -R -s 'split("\n") | map(select(length > 0))')
  },
  "graphics": {
    "card": "$(lspci | grep -i vga | cut -d: -f3 | xargs)",
    "driver_loaded": $(lsmod | grep -E 'i915|intel|nvidia|amdgpu' | awk '{print $1}' | jq -R -s 'split("\n") | map(select(length > 0))')
  },
  "shell": {
    "default": "$(basename $SHELL)",
    "fish_installed": $(command -v fish &> /dev/null && echo 'true' || echo 'false')
  },
  "display_server": {
    "wayland": $(pgrep -x Hyprland &> /dev/null && echo 'true' || echo 'false'),
    "compositor": "$(pgrep -l Hyprland | awk '{print $2}')"
  }
}
EOF

# Formatar JSON (corrigir possíveis erros)
jq '.' "$SNAPSHOT_FILE" > "${SNAPSHOT_FILE}.tmp" && mv "${SNAPSHOT_FILE}.tmp" "$SNAPSHOT_FILE"

# Criar link para "latest"
ln -sf "$SNAPSHOT_FILE" "$HOME/arch-system-tracker/snapshots/latest.json"

echo "✓ Snapshot salvo: $SNAPSHOT_FILE"

# Auto-commit no git
cd ~/arch-system-tracker
git add snapshots/
git commit -m "Snapshot: $TIMESTAMP" --quiet 2>/dev/null || true

echo "✓ Snapshot commitado no Git"
