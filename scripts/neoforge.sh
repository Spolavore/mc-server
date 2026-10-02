#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

preparar_env
exigir_parado minecraft-server mc-paper mc-atm10

mkdir -p server-data-neoforge/config
cp -r config-overrides/. server-data-neoforge/config/
echo "configs de config-overrides/ aplicados"

subir neoforge
