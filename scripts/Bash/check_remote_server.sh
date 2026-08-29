#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Подключается к удалённому VPS по SSH и собирает
# базовую информацию о состоянии сервера.
# Использование: ./check_remote_server.sh <user@host> [ssh_key_path]
# ─────────────────────────────────────────────

REMOTE="${1:-}"
SSH_KEY="${2:-}"

if [ -z "$REMOTE" ]; then
    echo "Usage: $0 <user@host> [ssh_key_path]"
    echo "Example: $0 root@192.168.1.10 ~/.ssh/id_rsa"
    exit 1
fi

SSH_OPTS=(-o ConnectTimeout=5 -o StrictHostKeyChecking=no)
if [ -n "$SSH_KEY" ]; then
    SSH_OPTS+=(-i "$SSH_KEY")
fi

echo "── Connecting to $REMOTE ──────────────────────"

if ! ssh "${SSH_OPTS[@]}" "$REMOTE" "echo ok" &>/dev/null; then
    echo "❌ Cannot connect to $REMOTE"
    exit 1
fi
echo "✅ Connection established"

echo ""
echo "── System info ─────────────────────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "hostnamectl 2>/dev/null || uname -a"

echo ""
echo "── Uptime & load average ───────────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "uptime"

echo ""
echo "── Memory usage ────────────────────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "free -h"

echo ""
echo "── Disk usage ───────────────────────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "df -h --output=source,size,used,avail,pcent,target | grep -v tmpfs"

echo ""
echo "── CPU info ─────────────────────────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "nproc --all && grep 'model name' /proc/cpuinfo | head -1"

echo ""
echo "── Top 5 processes by memory ───────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "ps aux --sort=-%mem | head -6"

echo ""
echo "── Listening ports ─────────────────────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "ss -tulnp 2>/dev/null || netstat -tulnp"

echo ""
echo "── Failed systemd services (if any) ────────────"
ssh "${SSH_OPTS[@]}" "$REMOTE" "systemctl --failed --no-legend 2>/dev/null || echo 'systemd not available'"

echo ""
echo "── Done ──────────────────────────────────────────"