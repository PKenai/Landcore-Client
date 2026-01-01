# Player Ranks Module

Este módulo adiciona ícones de rank ao lado dos nomes dos jogadores baseado no nível do personagem.

## Funcionalidades

- Mostra ícones de rank diferentes baseado no nível do jogador
- Ícones têm tamanho de 20x21 pixels
- Suporte a 5 ranks diferentes:
  - Normal (0-24): `RankNormal.png`
  - Bronze (25-49): `RankBronze.png`
  - Silver (50-74): `RankSilver.png`
  - Gold (75-99): `RankGold.png`
  - Diamond (100-150): `RankDiamond.png`

## Arquivos Necessários

### Imagens
- `data/images/landcore/rank/RankNormal.png`
- `data/images/landcore/rank/RankBronze.png`
- `data/images/landcore/rank/RankSilver.png`
- `data/images/landcore/rank/RankGold.png`
- `data/images/landcore/rank/RankDiamond.png`

### Arquivos do Módulo
- `modules/game_player_ranks/player_ranks.otmod`
- `modules/game_player_ranks/player_ranks.lua`
- `modules/game_player_ranks/README.md`

## Implementação no Servidor

Para o módulo funcionar completamente, é necessário implementar o sistema de opcodes no servidor. O módulo usa o extended opcode 150 para comunicação.

### Estrutura dos Pacotes

#### Solicitar ranks de todos os jogadores
```
Extended Opcode: 150
Data: "REQUEST_ALL_RANKS"
```

#### Solicitar rank de um jogador específico
```
Extended Opcode: 150
Data: "REQUEST_RANK"
Creature ID: uint32
```

#### Resposta com rank de um jogador
```json
{
    "action": "UPDATE_RANK",
    "creatureId": 12345,
    "level": 75
}
```

#### Resposta com ranks múltiplos
```json
{
    "action": "UPDATE_MULTIPLE_RANKS",
    "ranks": [
        {"creatureId": 12345, "level": 75},
        {"creatureId": 12346, "level": 120}
    ]
}
```

## Como Usar

1. Certifique-se de que todos os arquivos de imagem estão no lugar correto
2. O módulo é carregado automaticamente quando o cliente inicia
3. Os ranks são exibidos automaticamente ao lado dos nomes dos jogadores quando eles aparecem no mapa

## Desenvolvimento

Para desenvolvimento e testes, o módulo inclui ranks de teste que são definidos automaticamente. Em produção, remova a função `setupTestRanks()` e implemente a comunicação completa com o servidor.

## Configuração

O módulo pode ser configurado modificando as constantes em `player_ranks.lua`:

- `RANK_CONFIG`: Define os ranges de nível e texturas correspondentes
- Extended opcode 150: Pode ser alterado se necessário
