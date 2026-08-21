# Servidor Guerra dos Rapazes — NeoForge 1.21.1

Servidor modded (71 jars) rodando em container `itzg/minecraft-server`.

## Subir / parar

    ./init-server.sh              # sobe
    docker compose logs -f        # acompanha
    docker compose down           # para
    docker compose exec mc-server rcon-cli "list"   # console via RCON

O `.env` guarda `RCON_PASSWORD` (gerada automaticamente) e `OPS`.
**Coloque seu nick em `OPS`** e recrie o container (`docker compose up -d`) para virar operador.

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

## O que falta decidir antes da guerra

1. **FTB Chunks** (`config/ftbchunks-world.snbt`): `disable_protection: false` hoje — certo para a fase
   de preparo. Na fase 2 vira `true`, senão claim bloqueia dano de bloco e o raid não acontece.
2. **Whitelist**: está desligada. Para servidor de amigos vale `ENABLE_WHITELIST: "true"` +
   `WHITELIST: "nick1,nick2"` no compose.
3. **Pré-gerar o mundo** com o Chunky antes da primeira sessão — worldgen é o pior caso de TPS aqui.
4. **Backup**: `server-data-neoforge/` não está no git (gitignore). Vale um cron de tar.
