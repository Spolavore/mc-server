cd "$(dirname "${BASH_SOURCE[0]}")/.."

preparar_env() {
  if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env criado a partir do .env.example; coloque seu nick em OPS"
  fi
}

exigir_parado() {
  local nome
  for nome in "$@"; do
    if docker ps --format '{{.Names}}' | grep -qx "$nome"; then
      echo "ERRO: o container '$nome' esta rodando e disputa porta/RAM com este servidor." >&2
      if [ "$nome" = minecraft-server ]; then
        echo "      Container do layout antigo; pare com: docker compose -p mc-server down" >&2
      else
        echo "      Pare com: docker stop $nome" >&2
      fi
      exit 1
    fi
  done
}

subir() {
  docker compose --env-file .env -f "compose/$1.yaml" up -d
  echo "acompanhe com: docker compose -f compose/$1.yaml logs -f"
}
