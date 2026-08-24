# Servidor Guerra dos Rapazes — NeoForge 1.21.1

Servidor modded (71 jars) rodando em container `itzg/minecraft-server`.

## Subir / parar

    ./init-server.sh              # sobe
    docker compose logs -f        # acompanha
    docker compose down           # para
    docker compose exec mc-server rcon-cli "list"   # console via RCON

O `.env` guarda `RCON_PASSWORD` (gerada automaticamente) e `OPS`.
**Coloque seu nick em `OPS`** e recrie o container (`docker compose up -d`) para virar operador.

## Ícone do servidor

O que aparece do lado do nome na lista de servidores é um **PNG de exatamente 64x64** chamado
`server-icon.png`. Coloque o arquivo na raiz do repo — o `init-server.sh` copia para
`server-data-neoforge/` a cada subida, então ele sobrevive a clone e a máquina nova.

Converter qualquer foto para o formato certo (ImageMagick):

    magick foto.jpg -resize 64x64^ -gravity center -extent 64x64 server-icon.png

O `-resize 64x64^` + `-extent` corta pelo centro em vez de espremer a imagem.

Depois: commit, `git pull` na máquina do servidor, `./init-server.sh` e **reinicie o container** —
o ícone só é lido no boot (`docker compose restart`).

## Rodar em outra máquina

    git clone <este repo> && cd mc-server && ./init-server.sh

Funciona direto porque:

- os **71 jars estão versionados** em `mods/` (o repo tem ~250 MB por causa disso);
- o `.env` é criado sozinho a partir do `.env.example`, com `RCON_PASSWORD` aleatória;
- os configs de PvP vêm de **`config-overrides/`**, que o `init-server.sh` copia para
  `server-data-neoforge/config/` a cada subida.

**Regra importante:** edite config em `config-overrides/` e faça commit. Editar direto em
`server-data-neoforge/config/` funciona até a próxima subida, quando é sobrescrito — e não sobrevive
a um clone novo, porque `server-data-neoforge/` está no `.gitignore`.

O que **não** vai junto: `server-data-neoforge/` inteiro. Numa máquina nova o NeoForge e o jar do
Minecraft são baixados de novo (alguns minutos) e o **mundo `guerra` é gerado do zero, com outra
seed**. Para levar o mundo, copie a pasta na mão:

    rsync -a server-data-neoforge/guerra/ outro-pc:~/homelab/mc-server/server-data-neoforge/guerra/

Na outra máquina precisa de: docker + compose, ~8 GB de RAM (heap 5G + overhead) e as portas
25565/tcp e 24454/udp liberadas.

## Como está configurado

| Item | Valor | Por quê |
|---|---|---|
| Imagem | `itzg/minecraft-server:java21` | NeoForge 21.1.248 / MC 1.21.1 exige Java 21 |
| Heap | 5G (limite do container 7G) | com 6G o RSS encostava em 6.6G/7G e arriscava OOM-kill |
| CPU | limite 3.5, `-XX:ActiveProcessorCount=3` | host tem 4 núcleos; 1 fica para o SO |
| Mundo | `guerra` | |
| Mods | `./mods` montado em `/data/mods` | não precisa copiar nada |
| Portas | 25565/tcp, **24454/udp** | a UDP é do Simple Voice Chat |
| view / simulation distance | 10 / 6 | worldgen é o gargalo desse pack em 4 CPUs |
| `max-tick-time` | -1 | evita watchdog matar o servidor durante geração de chunk |
| PvP | true, `spawn-protection=0` | |
| `allow-flight` | true | evita kick falso com contraption do Create e elytra |

O compose antigo (Paper 26.2) está preservado em `compose.paper.yaml`, e os dados dele
continuam intactos em `server-data/`. O servidor NeoForge usa `server-data-neoforge/`.
Os plugins Bukkit em `plugins/` não têm efeito nenhum aqui — plugin de Paper não roda em NeoForge.

## Iron Furnaces: trocado de fork

`Iron Furnace Reburn-neoforge-1.21.1-0.4.8.jar` **derrubava o servidor dedicado**: o entrypoint dele
carrega `BlockEntityRenderer`, classe só de cliente.

    Attempted to load class net/minecraft/client/renderer/blockentity/BlockEntityRenderer
    for invalid dist DEDICATED_SERVER

Substituído pelo mod original **Iron Furnaces 4.3.2** (XenoMustache), mesmo modId `ironfurnaces`,
mesmas fornalhas tunadas. Sobe limpo no servidor dedicado e não colide com receita nenhuma.
O jar do Reburn ficou em `mods-disabled/` dos dois lados; cliente e servidor estão com listas idênticas.

## Mundo: BetterX, não vanilla

`level-type` no server.properties é `minecraft:normal`, mas o WorldWeaver tem
`server.force_default_world_preset: true` e sobrescreveu: o `level.dat` do mundo `guerra` está com
`wover:betterx` no Nether e no End. **É o que você quer**, senão o BetterEnd não geraria.

Para forçar mundo vanilla: `config/wover/main.json` → `force_default_world_preset: false`, e apagar
o mundo `guerra` para gerar de novo.

## Configs de PvP já aplicadas

**SecurityCraft** (`server-data-neoforge/config/securitycraft-server.toml`, original salvo em `.orig`):

    allow_breaking_non_owned_blocks = true    # era false: base reforçada era inraidável
    non_owned_breaking_slowdown    = 3.0      # não-dono mina 3x mais devagar
    enable_team_ownership          = true     # aliado do FTB Teams acessa o que é do time

Bloco reforçado continua imune a explosão — máquina de cerco não abre buraco nele, só picareta.

**Corpse** (`config/corpse-server.toml`): `only_owner = false` já vinha assim, ou seja, quem matou
consegue saquear o corpo. O que continua no padrão é `corpse.despawn.force_time = -1`: corpo com item
dentro **nunca some**, então o derrotado pode voltar e recuperar o próprio equipamento. Se quiser que
a kill transfira o loot de verdade, põe algo como `force_time = 6000` (5 min) — mas atenção, aí o
conteúdo some junto quando o tempo estoura.

## Servidor de teste: All the Mods 10 (stack separada)

    ./init-server.atm10.sh                                  # sobe na porta 25566
    docker compose -f compose.atm10.yaml logs -f            # acompanha
    docker compose -f compose.atm10.yaml down               # para

Conecta em `localhost:25566` (ou `IP-do-host:25566`). É uma stack **independente** do guerra:
container `minecraft-atm10`, dados em `server-data-atm10/`, mundo `atm10`. Nada do guerra é tocado.

**Os dois não rodam juntos** — os heaps somados não cabem na RAM do host. O
`init-server.atm10.sh` se recusa a subir se o container `minecraft-server` estiver de pé.

### Os mods vêm do server pack oficial, não da pasta do cliente

A instância do CurseForge tem **482 jars**; o server pack do ATM10 8.0 tem **455**. Os 27 de
diferença são client-only e derrubam servidor dedicado com o mesmo erro do Iron Furnaces Reburn
(`invalid dist DEDICATED_SERVER`) — Sodium, Iris, FancyMenu, JustZoom, NotEnoughAnimations e
companhia; nenhum mod novo entra no sentido contrário. Copiar
`mods/` do cliente é caçar crash um por um; o server pack já vem certo, com `config/`,
`defaultconfigs/`, `kubejs/` e `datapacks/` do pack.

O `fileID` do server pack sai do próprio CurseForge: campo `serverPackFileId` em
`minecraftinstance.json` da instância (`8649107` para o 8.0). O CDN serve sem API key:

    https://mediafilez.forgecdn.net/files/8649/107/ServerFiles-8.0.zip

O `init-server.atm10.sh` baixa esse zip para `.cache/` e extrai na primeira subida, então
**clone novo funciona sozinho** — só precisa de banda para 1.2 GB. Os 455 jars **não** estão no
git (ao contrário dos 71 do guerra): `.cache/` e `server-data-atm10/` estão no `.gitignore`.
Não é só tamanho de repo — o GitHub rejeita arquivo acima de 100 MB, e o zip tem 1.2 GB. O que vai
para a VM pelo git é só o script e o compose; o pack a VM baixa sozinha na primeira subida.

Na VM não precisa de `unzip` nem de `curl`: o script usa o que existir, na ordem
`curl`/`wget` para baixar e `unzip`/`python3` para extrair, e cai num container `busybox`
se não houver nenhum dos dois — docker está garantido, é o que roda o servidor.

`startserver.sh`, `user_jvm_args.txt` e o installer do NeoForge que vêm no zip foram movidos para
`server-data-atm10/.pack-launcher-original/` — o itzg instala o NeoForge e monta os flags de JVM
sozinho, e script solto na raiz é convite para subir um segundo servidor com outra config.

### Como está configurado

| Item | Valor | Por quê |
|---|---|---|
| Porta | **25566**/tcp | 25565 é do guerra |
| NeoForge | 21.1.247 | versão que o server pack do 8.0 fixa (o guerra usa 248) |
| Heap | `ATM10_MEMORY` (4G) / limite `ATM10_MEM_LIMIT` (6G) | os 455 mods custam ~1.4G de metaspace/GC/code cache **em cima** do heap, e o Aikar commita o heap inteiro: 6G de heap deu 7.4G de RSS medidos |
| CPU | `ATM10_CPUS` (3.5), `ATM10_APC` (3) | VM tem 4 núcleos; 1 fica para o SO |

Os defaults são os da VM (4 CPUs, 8 GB). Heap, limite e núcleos vêm do `.env`, que **não vai para
o git**, então cada máquina usa os seus: neste desktop de 14 GB dá para subir para
`ATM10_MEMORY=6G` / `ATM10_MEM_LIMIT=9G` / `ATM10_CPUS=6.0` / `ATM10_APC=6`.
Passar do limite do container é OOM-kill, não swap.
| Mundo | `atm10` | |
| Mods | `server-data-atm10/mods` dentro do volume | sem bind mount separado: a fonte é o zip |
| view / simulation | 8 / 6 | ATM10 é bem mais pesado que o pack do guerra |
| `max-tick-time` | -1 | primeiro boot com KubeJS + 455 mods estoura o watchdog |
| Voice chat | sem porta UDP | o ATM10 não traz o Simple Voice Chat |

Primeiro boot demora vários minutos (instala NeoForge, roda KubeJS, gera o mundo). Sem
whitelist e sem RCON exposto — o `.env` de `RCON_PASSWORD`/`OPS` é o mesmo do guerra.

## O que falta decidir antes da guerra

1. **FTB Chunks** (`config/ftbchunks-world.snbt`): `disable_protection: false` hoje — certo para a fase
   de preparo. Na fase 2 vira `true`, senão claim bloqueia dano de bloco e o raid não acontece.
2. **Whitelist**: está desligada. Para servidor de amigos vale `ENABLE_WHITELIST: "true"` +
   `WHITELIST: "nick1,nick2"` no compose.
3. **Pré-gerar o mundo** com o Chunky antes da primeira sessão — worldgen é o pior caso de TPS aqui.
4. **Backup**: `server-data-neoforge/` não está no git (gitignore). Vale um cron de tar.
