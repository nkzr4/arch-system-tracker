#!/bin/bash
# snapshot.sh - Captura estado completo do sistema em JSON

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

log INFO "Iniciando criação de snapshot..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_FILE="$HOME/arch-system-tracker/snapshots/system-$TIMESTAMP.json"

log INFO "Gerando arquivo JSON: $SNAPSHOT_FILE"
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

log INFO "Formatando JSON..."
jq '.' "$SNAPSHOT_FILE" > "${SNAPSHOT_FILE}.tmp" && mv "${SNAPSHOT_FILE}.tmp" "$SNAPSHOT_FILE"

log INFO "Criando link para 'latest'..."
ln -sf "$SNAPSHOT_FILE" "$HOME/arch-system-tracker/snapshots/latest.json"

log SUCESSO "Snapshot criado com sucesso em: $SNAPSHOT_FILE"

log INFO "Obtendo descrição para o commit..."
read -rp "Digite uma breve descrição para este snapshot (opcional): " COMMIT_DESC
if [[ -z "$COMMIT_DESC" ]]; then
    COMMIT_MSG="Snapshot: $TIMESTAMP"
else
    COMMIT_MSG="Snapshot: $TIMESTAMP - $COMMIT_DESC"
fi

log INFO "Comitando no Git..."
cd ~/arch-system-tracker || exit 1
git add snapshots/
git commit -m "$COMMIT_MSG" --quiet 2>/dev/null || log ERRO "Falha ao criar commit"

log SUCESSO "Commit criado com sucesso: \"$COMMIT_MSG\""
