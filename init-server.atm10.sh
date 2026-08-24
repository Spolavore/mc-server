#!/usr/bin/env bash
# Sobe o servidor de teste do All the Mods 10 (NeoForge 1.21.1, 455 mods).
# Os mods vem do server pack OFICIAL do pack, nao da pasta mods/ do cliente:
# o cliente tem 27 jars client-only que quebram servidor dedicado.
set -euo pipefail
cd "$(dirname "$0")"

# fileID do server pack do ATM10 8.0, tirado de serverPackFileId no minecraftinstance.json
# da instancia do CurseForge. O CDN da Overwolf serve sem API key.
ZIP=.cache/ServerFiles-8.0.zip
ZIP_URL="https://mediafilez.forgecdn.net/files/8649/107/ServerFiles-8.0.zip"

if [ ! -f .env ]; then
  cp .env.example .env
  senha=$(head -c 18 /dev/urandom | base64 | tr -d '/+=')
  sed -i "s|^RCON_PASSWORD=.*|RCON_PASSWORD=${senha}|" .env
  echo ".env criado com RCON_PASSWORD aleatoria — coloque seu nick em OPS"
fi

if docker ps --format '{{.Names}}' | grep -qx minecraft-server; then
  echo "ERRO: o servidor 'Guerra dos Rapazes' esta rodando e os dois nao cabem na RAM deste host."
  echo "      Pare ele primeiro:  docker compose -f compose.yaml down"
  exit 1
fi

if [ ! -d server-data-atm10/mods ]; then
  mkdir -p .cache
  if [ ! -f "$ZIP" ]; then
    echo "baixando server pack do ATM10 (1.2 GB)..."
    curl -L -C - --retry 3 -o "$ZIP" "$ZIP_URL"
  fi
  echo "extraindo server pack..."
  mkdir -p server-data-atm10
  unzip -q -o "$ZIP" -d server-data-atm10
  # itzg instala o NeoForge e monta os argumentos de JVM sozinho; os scripts do pack ficam
  # guardados so para consulta, se ficarem soltos alguem sobe um segundo servidor por engano
  mkdir -p server-data-atm10/.pack-launcher-original
  for f in startserver.sh startserver.bat user_jvm_args.txt neoforge-21.1.247-installer.jar; do
    [ -f "server-data-atm10/$f" ] && mv "server-data-atm10/$f" server-data-atm10/.pack-launcher-original/
  done
  echo "server pack pronto: $(ls server-data-atm10/mods/*.jar | wc -l) mods"
fi

docker compose -f compose.atm10.yaml up -d
echo "subindo na porta 25566 — primeiro boot demora vários minutos (KubeJS + 455 mods)"
echo "acompanhe com: docker compose -f compose.atm10.yaml logs -f"
