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

# VM enxuta nao tem unzip nem curl garantidos; docker tem, porque e o que roda o servidor.
# O --user evita o zip sair extraido com dono root e o itzg (uid 1000) nao conseguir escrever.
baixar() {
  if command -v curl >/dev/null 2>&1; then curl -L -C - --retry 3 -o "$1" "$2"
  elif command -v wget >/dev/null 2>&1; then wget -c -O "$1" "$2"
  else docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/.cache:/c" busybox \
         wget -c -O "/c/$(basename "$1")" "$2"
  fi
}

extrair() {
  if command -v unzip >/dev/null 2>&1; then unzip -q -o "$1" -d "$2"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$1" "$2"
  else docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/w" -w /w busybox \
         unzip -q -o "$1" -d "$2"
  fi
}

if [ ! -d server-data-atm10/mods ]; then
  mkdir -p .cache server-data-atm10
  if [ ! -f "$ZIP" ]; then
    echo "baixando server pack do ATM10 (1.2 GB)..."
    baixar "$ZIP" "$ZIP_URL"
  fi
  echo "extraindo server pack..."
  extrair "$ZIP" server-data-atm10
  # itzg instala o NeoForge e monta os argumentos de JVM sozinho; os scripts do pack ficam
  # guardados so para consulta, se ficarem soltos alguem sobe um segundo servidor por engano
  mkdir -p server-data-atm10/.pack-launcher-original
  for f in startserver.sh startserver.bat user_jvm_args.txt neoforge-21.1.247-installer.jar; do
    if [ -f "server-data-atm10/$f" ]; then
      mv "server-data-atm10/$f" server-data-atm10/.pack-launcher-original/
    fi
  done
  echo "server pack pronto: $(ls server-data-atm10/mods/*.jar | wc -l) mods"
fi

docker compose -f compose.atm10.yaml up -d
echo "subindo na porta 25566 — primeiro boot demora vários minutos (KubeJS + 455 mods)"
echo "acompanhe com: docker compose -f compose.atm10.yaml logs -f"
