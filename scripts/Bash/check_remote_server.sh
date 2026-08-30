#!/usr/bin/env bash

# Simple SSH connection check
# Usage: ./check_ssh.sh user@host

# Цвета для красивого вывода в терминале
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color — сброс цвета обратно

HOST="$1"

if [ -z "$HOST" ]; then
    echo "Usage: $0 user@host"
    exit 1
fi

echo "Checking connection to $HOST..."
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

if ssh -o ConnectTimeout=5 "$HOST" "echo Connection successful"; then
    echo -e "${GREEN}✅ SSH is working${NC}"
    echo -e "${GREEN}────────────────────────${NC}"
else
    echo -e "${RED}❌ Could not connect${NC}"
    echo -e "${RED}────────────────────────${NC}"
fi