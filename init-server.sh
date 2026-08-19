mkdir ./server-data ./server-data/plugins
cp -fr ./plugins/* ./server-data/plugins

docker compose -f compose.yaml up -d