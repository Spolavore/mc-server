#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ZIP=.cache/ServerFiles-8.0.zip
ZIP_URL="https://mediafilez.forgecdn.net/files/8649/107/ServerFiles-8.0.zip"

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

preparar_env
exigir_parado minecraft-server mc-paper mc-neoforge

if [ ! -d server-data-atm10/mods ]; then
  mkdir -p .cache server-data-atm10
  if [ ! -f "$ZIP" ]; then
    echo "baixando server pack do ATM10 (1.2 GB)..."
    baixar "$ZIP" "$ZIP_URL"
  fi
  echo "extraindo server pack..."
  extrair "$ZIP" server-data-atm10
  mkdir -p server-data-atm10/.pack-launcher-original
  for f in startserver.sh startserver.bat user_jvm_args.txt neoforge-21.1.247-installer.jar; do
    if [ -f "server-data-atm10/$f" ]; then
      mv "server-data-atm10/$f" server-data-atm10/.pack-launcher-original/
    fi
  done
  echo "server pack pronto: $(ls server-data-atm10/mods/*.jar | wc -l) mods"
fi

subir atm10
echo "porta 25566; primeiro boot demora varios minutos (KubeJS + 455 mods)"
