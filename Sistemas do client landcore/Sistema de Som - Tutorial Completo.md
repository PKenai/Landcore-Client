# Sistema de Som - Tutorial Completo
## Landcore Client

**Data:** Janeiro 2026
**Versao:** 1.0
**Autor:** Sistema de IA Landcore

---

## Indice

1. [Introducao](#introducao)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Como Usar no Servidor](#como-usar-no-servidor)
4. [Integracao com Notificacoes](#integracao-com-notificacoes)
5. [Sons Personalizados](#sons-personalizados)
6. [Exemplos Praticos](#exemplos-praticos)
7. [Troubleshooting](#troubleshooting)
8. [API Reference](#api-reference)

---

## Introducao

O **Sistema de Som** do Landcore Client permite reproduzir efeitos sonoros automaticamente durante o jogo. O sistema e totalmente integrado com o sistema de notificacoes do servidor, garantindo que toda notificacao enviada aos jogadores seja acompanhada de feedback sonoro.

### Principais Caracteristicas

- **Integracao automatica** com notificacoes
- **Facil implementacao** em scripts Lua
- **Sons personalizaveis** por evento
- **Performance otimizada**
- **Compatibilidade total** com codigo existente

---

## Arquitetura do Sistema

### Estrutura de Arquivos

```
Landcore-Client/
├── modules/
│   └── game_sounds/
│       ├── sounds.lua       # Handler principal do cliente
│       └── sounds.otmod     # Definicao do modulo
├── data/sounds/
│   ├── notification.ogg     # Som padrao das notificacoes
│   ├── level_up.ogg         # Exemplo de som personalizado
│   └── README.md           # Documentacao dos sons
└── Sistemas do client landcore/
    └── Sistema de Som - Tutorial Completo.md  # Este arquivo
```

### Fluxo de Funcionamento

1. **Servidor** envia notificacao via `sendPlayerNotification()`
2. **Servidor** automaticamente adiciona chamada de som
3. **Cliente** recebe opcode 134 com nome do arquivo de som
4. **Cliente** localiza e reproduz o arquivo `.ogg`
5. **Som** e reproduzido com duracao especificada

---

## Como Usar no Servidor

### Uso Basico - Notificacoes com Som Automatico

```lua
-- QUALQUER notificacao agora inclui som automaticamente!
sendPlayerNotification(player, "Mensagem importante!", 5, "text", "icone", {})

-- Funciona com todos os tipos de notificacao:
sendPlayerNotification(player, "Level up!", 3, "text", "level", {})
sendPlayerNotification(player, "Item encontrado!", 4, "image", "/images/item.png", {})
sendPlayerNotification(player, "Missao completa!", 6, "text", "check", {})
```

### Sons Personalizados Adicionais

```lua
-- Notificacao + som personalizado extra
sendPlayerNotification(player, "Parabens!", 5, "text", "parabens", {})
sound.sendSoundOtc(player, "level_up", 4)  -- Som adicional personalizado

-- Apenas som personalizado (sem notificacao)
sound.sendSoundOtc(player, "quest_complete", 2)
```

### Notificacoes Globais

```lua
-- Notificacao global para TODOS os jogadores online
sendGlobalNotification("Servidor reiniciando em 5 minutos!", 10, "text", "aviso", {})
-- Todos ouvem o som automaticamente!
```

---

## Integracao com Notificacoes

### Sistema Modificado

O arquivo `notify.lua` foi modificado para incluir som automatico:

```lua
function sendPlayerNotification(player, message, timer, iconType, iconValue, buttonData)
    -- ... codigo original ...

    -- SOM AUTOMATICO - adicionado automaticamente
    if sound and sound.sendSoundOtc then
        sound.sendSoundOtc(player, "notification", timer or 3)
    end

    return true
end
```

### Beneficios da Integracao

- **Zero mudancas** no codigo existente
- **Som automatico** em todas as notificacoes
- **Compatibilidade total** com scripts antigos
- **Facil manutencao**

---

## Sons Personalizados

### Localizacao dos Arquivos

Todos os sons devem estar em:
/data/sounds/nome_do_som.ogg

### Arquivos Disponiveis

| Arquivo | Uso | Duracao | Descricao |
|---------|-----|---------|-----------|
| `notification.ogg` | Automatico | 2-5s | Todas as notificacoes |
| `level_up.ogg` | Personalizado | 2-4s | Subida de nivel |
| `quest_complete.ogg` | Personalizado | 1-3s | Missao concluida |
| `item_found.ogg` | Personalizado | 1-2s | Item encontrado |

### Como Adicionar Novos Sons

1. **Grave/baixe** o efeito sonoro
2. **Converta** para formato **OGG Vorbis**
3. **Nomeie** o arquivo: `meu_som.ogg`
4. **Coloque** em `/data/sounds/`
5. **Use** no servidor: `sound.sendSoundOtc(player, "meu_som", 3)`

### Formato Recomendado

- **Formato:** OGG Vorbis
- **Qualidade:** 128kbps ou superior
- **Canais:** Mono ou Stereo
- **Duracao:** 1-10 segundos para efeitos sonoros
- **Codec:** libvorbis

---

## Exemplos Praticos

### Eventos de Jogo

```lua
-- Level Up
if player:getLevel() > oldLevel then
    sendPlayerNotification(player,
        "Parabens! Voce subiu para o nivel " .. player:getLevel() .. "!",
        8, "text", "level", {})
end

-- Item Encontrado
sendPlayerNotification(player, "Novo item encontrado!", 4, "image", "/images/item.png", {})

-- Missao Completa
sendPlayerNotification(player, "Missao concluida!", 6, "text", "check", {})
```

### Sistema de Pesca (Implementado)

```lua
-- No fishing_server.lua (ja implementado)
if delivered then
    sendPlayerNotification(player,
        "Peixe pescado!",
        5, "text", "fish", {})
    -- Som automatico incluido!
end
```

### Sistema Economico

```lua
-- Compra realizada
sendPlayerNotification(player,
    "Compra realizada! " .. ItemType(itemId):getName(),
    4, "text", "money", {})

-- Venda de item
sendPlayerNotification(player,
    "Item vendido por " .. price .. " gold!",
    4, "text", "money", {})
```

---

## Troubleshooting

### Problemas Comuns

#### Som nao toca
- Verificar se arquivo `.ogg` existe em `/data/sounds/`?
- Verificar nome correto (sem `.ogg` na chamada)?
- Cliente tem suporte a som ativado?
- Volume do sistema esta ligado?

#### Modulo nao carrega
- Arquivos `sounds.lua` e `sounds.otmod` existem?
- `gameinterface.lua` foi modificado corretamente?
- Console mostra mensagens de carregamento?
- Sem erros de sintaxe no arquivo Lua?

#### Notificacoes sem som
- `notify.lua` foi modificado?
- Funcao usa `sound.sendSoundOtc()`?
- Sistema de som esta carregado no servidor?

---

## API Reference

### Funcoes do Servidor

#### `sound.sendSoundOtc(player, soundName, duration)`

**Parametros:**
- `player` - Objeto Player
- `soundName` - String com nome do arquivo (sem .ogg)
- `duration` - Numero em segundos (padrao: 3)

**Exemplos:**
```lua
sound.sendSoundOtc(player, "notification", 5)
sound.sendSoundOtc(player, "level_up", 3)
sound.sendSoundOtc(player, "Default", 0)  -- Para todos os sons
```

#### `sendPlayerNotification(player, message, timer, iconType, iconValue, buttonData)`

**Parametros:**
- `player` - Objeto Player
- `message` - String com mensagem
- `timer` - Numero em segundos (padrao: 3)
- `iconType` - "text", "image", etc.
- `iconValue` - Emoji ou caminho da imagem
- `buttonData` - Tabela com dados do botao (opcional)

**Exemplos:**
```lua
sendPlayerNotification(player, "Ola!", 5, "text", "ola", {})
sendPlayerNotification(player, "Item!", 3, "image", "/images/item.png", {})
```

#### `sendGlobalNotification(message, timer, iconType, iconValue, buttonData)`

**Parametros:** Mesmos da funcao individual

**Exemplo:**
```lua
sendGlobalNotification("Anuncio global!", 10, "text", "anuncio", {})
```

---

## Conclusao

O **Sistema de Som** esta totalmente integrado e funcionando! Agora toda notificacao enviada aos jogadores sera acompanhada de feedback sonoro automatico, tornando a experiencia de jogo muito mais imersiva e profissional.

### Proximos Passos

- [ ] Adicionar mais sons personalizados
- [ ] Integrar com outros sistemas (combate, loot, etc.)
- [ ] Criar sons tematicos por evento
- [ ] Otimizar performance para muitos jogadores

### Suporte

Para duvidas ou problemas:
1. Consulte este tutorial
2. Verifique checklist de implementacao
3. Teste com comandos `/notify`
4. Verifique logs do console

---

**Sistema desenvolvido para Landcore**