#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

preparar_env
exigir_parado minecraft-server mc-neoforge mc-atm10
mkdir -p server-data
subir paper
