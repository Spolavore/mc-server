#!/usr/bin/env bash
# Sobe o servidor NeoForge 1.21.1 (modpack Guerra dos Rapazes).
# Os 71 mods sao montados direto de ./mods para /data/mods — nao precisa copiar.
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] || { echo "crie o .env a partir do .env.example"; exit 1; }

mkdir -p server-data-neoforge
docker compose -f compose.yaml up -d
echo "subindo... acompanhe com: docker compose logs -f"
