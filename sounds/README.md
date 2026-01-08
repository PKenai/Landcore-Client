# Sistema de Sons - Landcore Client

Este diretório contém os arquivos de áudio (.ogg) usados pelo sistema de sons do jogo.

## Sistema Integrado

O sistema de sons está integrado com o sistema de notificações do servidor. Sempre que uma notificação é enviada usando `sendPlayerNotification()` ou `sendGlobalNotification()`, o som "notification.ogg" é tocado automaticamente.

## Arquivos de Som

### notification.ogg
- **Uso:** Tocada automaticamente com todas as notificações
- **Duração recomendada:** 2-5 segundos
- **Volume:** Médio (não muito alto para não incomodar)

## Como Adicionar Novos Sons

1. **Converta seu áudio** para formato OGG
2. **Nomeie o arquivo** com o nome que será usado no servidor (ex: `level_up.ogg`)
3. **Coloque na pasta** `/data/sounds/`
4. **Use no servidor** com: `sound.sendSoundOtc(player, "level_up", 3)`

## Exemplos de Uso no Servidor

```lua
-- Notificação com som automático (sempre toca notification.ogg)
sendPlayerNotification(player, "Level up!", 5, "text", "⬆️", {})

-- Som personalizado adicional
sound.sendSoundOtc(player, "level_up", 3)

-- Parar todos os sons
sound.sendSoundOtc(player, "Default", 0)

-- Eventos comuns onde usar sons:
-- Level up
if player:getLevel() > oldLevel then
    sendPlayerNotification(player, "Parabéns! Você subiu de nível!", 8, "text", "⬆️", {})
end

-- Item encontrado
sendPlayerNotification(player, "Novo item encontrado!", 4, "image", "/images/item.png", {})

-- Missão completa
sendPlayerNotification(player, "Missão concluída!", 6, "text", "✅", {})

-- Alerta de perigo
sendPlayerNotification(player, "Cuidado! Monstro perigoso!", 3, "text", "⚠️", {})
```

## Formato Recomendado

- **Formato:** OGG Vorbis
- **Qualidade:** 128kbps ou superior
- **Canais:** Mono ou Stereo
- **Duração:** 1-10 segundos para efeitos sonoros
- **Codec:** libvorbis