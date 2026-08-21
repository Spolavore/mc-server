#!/usr/bin/env bash
# Sobe o servidor NeoForge 1.21.1 (modpack Guerra dos Rapazes).
# Os 71 mods sao montados direto de ./mods para /data/mods — nao precisa copiar.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  cp .env.example .env
  senha=$(head -c 18 /dev/urandom | base64 | tr -d '/+=')
  sed -i "s|^RCON_PASSWORD=.*|RCON_PASSWORD=${senha}|" .env
  echo ".env criado com RCON_PASSWORD aleatoria — coloque seu nick em OPS"
fi

mkdir -p server-data-neoforge/config

# server-data-neoforge/ nao vai para o git, entao config editado a mao morre num clone novo.
# A fonte de verdade e config-overrides/, reaplicada a cada subida.
# Edite em config-overrides/, nunca direto em server-data-neoforge/config/.
if [ -d config-overrides ]; then
  cp -r config-overrides/. server-data-neoforge/config/
  echo "configs de config-overrides/ aplicados"
fi

docker compose -f compose.yaml up -d
echo "subindo... acompanhe com: docker compose logs -f"
