# Exemplos de Uso - Sistema de Som
## Casos Praticos para Scripts Landcore

---

## Eventos de Jogador

### Level Up com Som Personalizado

```lua
-- Em qualquer script onde o level aumenta
local oldLevel = player:getLevel()

-- ... logica que aumenta o level ...

if player:getLevel() > oldLevel then
    -- Notificacao com som automatico
    sendPlayerNotification(player,
        "Parabens! Voce subiu para o nivel " .. player:getLevel() .. "!",
        8, "text", "level", {})

    -- Som adicional personalizado (opcional)
    sound.sendSoundOtc(player, "level_up", 4)
end
```

### Login com Boas-Vindas

```lua
-- No login.lua (ja implementado)
sendPlayerNotification(player,
    "Bem-vindo ao Landcore!",
    8, "image", "/images/landcore/logo.png", {})
-- Som automatico incluido!
```

---

## Sistema de Pesca

```lua
-- Para adicionar som na pesca, use:
if delivered then
    sendPlayerNotification(player,
        "Peixe pescado!",
        5, "text", "fish", {})
    -- Som automatico incluido!
end
```

---

## Sistema Economico

### Compra Realizada

```lua
function onBuyItem(player, itemId, price)
    -- Remove dinheiro
    player:removeMoney(price)

    -- Da o item
    player:addItem(itemId, 1)

    -- Notificacao com som
    sendPlayerNotification(player,
        "Compra realizada! " .. ItemType(itemId):getName(),
        4, "text", "money", {})
end
```

### Venda de Item

```lua
function onSellItem(player, itemId, price)
    -- Remove item
    player:removeItem(itemId, 1)

    -- Da dinheiro
    player:addMoney(price)

    -- Notificacao com som
    sendPlayerNotification(player,
        "Item vendido por " .. price .. " gold!",
        4, "text", "money", {})
end
```

---

## Sistema de Combate

### Dano Critico

```lua
function onCriticalHit(player, damage)
    -- Aplica dano critico
    target:addHealth(-damage * 2)

    -- Notificacao com som
    sendPlayerNotification(player,
        "DANO CRITICO! " .. (damage * 2) .. " de dano!",
        2, "text", "critical", {})
end
```

### Cura Recebida

```lua
function onHealReceived(player, healAmount)
    player:addHealth(healAmount)

    sendPlayerNotification(player,
        "+" .. healAmount .. " HP recuperados!",
        3, "text", "heal", {})
end
```

---

## Missoes/Quests

### Missao Iniciada

```lua
function startQuest(player, questId)
    -- Logica para iniciar quest
    player:setStorageValue(questId, 1)

    sendPlayerNotification(player,
        "Nova missao iniciada!",
        5, "text", "quest", {})
end
```

### Missao Completa

```lua
function completeQuest(player, questId)
    -- Logica para completar quest
    player:setStorageValue(questId, 2)

    -- Recompensas
    player:addExperience(1000)
    player:addItem(2160, 5)  -- Crystal coins

    sendPlayerNotification(player,
        "Missao concluida! Recompensas recebidas.",
        6, "text", "complete", {})

    -- Som extra personalizado
    sound.sendSoundOtc(player, "quest_complete", 3)
end
```

---

## Sistema de Casas

### Compra de Casa

```lua
function buyHouse(player, houseId)
    local house = House(houseId)
    local price = house:getPrice()

    if player:getMoney() >= price then
        player:removeMoney(price)
        house:setOwner(player)

        sendPlayerNotification(player,
            "Casa comprada com sucesso!",
            8, "text", "house", {})
    end
end
```

### Acesso Negado

```lua
function onHouseAccessDenied(player, houseId)
    sendPlayerNotification(player,
        "Voce nao tem permissao para entrar nesta casa!",
        4, "text", "denied", {})
end
```

---

## Sistema Social

### Amigo Online

```lua
function onFriendOnline(player, friendName)
    sendPlayerNotification(player,
        friendName .. " entrou no jogo!",
        3, "text", "friend", {})
end
```

### Mensagem Privada

```lua
function onPrivateMessage(player, fromPlayer, message)
    sendPlayerNotification(player,
        "Mensagem de " .. fromPlayer .. ": " .. message,
        5, "text", "message", {})
end
```

---

## Eventos Especiais

### Aniversario do Servidor

```lua
function serverAnniversaryEvent()
    sendGlobalNotification(
        "FELIZ ANIVERSARIO! Todos recebem bonus duplo de EXP por 1 hora!",
        15, "text", "party", {})
end
```

### Evento de Halloween

```lua
function halloweenEventNotification()
    sendGlobalNotification(
        "Evento de Halloween! Monstros dropam doces!",
        10, "text", "halloween", {})
end
```

---

## Sistema Administrativo

### Anuncio do Admin

```lua
function adminBroadcast(message)
    sendGlobalNotification(
        "[ADMIN] " .. message,
        10, "text", "admin", {})
end
```

### Manutencao Programada

```lua
function maintenanceWarning(minutes)
    sendGlobalNotification(
        "Manutencao em " .. minutes .. " minutos! Salve seu progresso.",
        30, "text", "warning", {})
end
```

---

## Sistema de Rankings

### Novo Recorde

```lua
function newHighScore(player, score, category)
    -- Atualiza ranking
    updateRanking(player, score, category)

    sendGlobalNotification(
        "Novo recorde! " .. player:getName() .. " fez " .. score .. " pontos em " .. category .. "!",
        8, "text", "record", {})
end
```

---

## Sistema de Jogos/Minigames

### Vitoria em Minigame

```lua
function minigameVictory(player, gameName, reward)
    player:addItem(reward.itemId, reward.count)

    sendPlayerNotification(player,
        "Vitoria em " .. gameName .. "! Recompensa: " .. ItemType(reward.itemId):getName(),
        6, "text", "victory", {})
end
```

### Derrota em Minigame

```lua
function minigameDefeat(player, gameName)
    sendPlayerNotification(player,
        "Derrota em " .. gameName .. ". Tente novamente!",
        4, "text", "defeat", {})
end
```

---

## Dicas para Implementacao

### 1. Consistencia Visual
- Use icones consistentes para tipos similares de evento
- Mantenha padroes de cores e estilos

### 2. Timing Adequado
- Notificacoes importantes: 5-8 segundos
- Notificacoes rapidas: 2-3 segundos
- Avisos urgentes: 1-2 segundos

### 3. Hierarquia de Som
```lua
-- Notificacoes normais: notification.ogg (automatico)
-- Eventos especiais: som personalizado adicional
-- Eventos globais: notification.ogg para todos
```

### 4. Performance
- Evite spam de notificacoes
- Use timers para agrupar notificacoes similares
- Considere volume/duracao dos sons

### 5. Acessibilidade
- Sons nao devem ser muito altos
- Considere jogadores com necessidades especiais
- Mantenha opcao de desabilitar sons (futuro)

---

## Exemplos de Codigo Completo

### Sistema de Level Up Avancado

```lua
function checkLevelUp(player)
    local oldLevel = player:getLevel()
    local oldExperience = player:getExperience()

    -- Simula ganho de exp
    player:addExperience(1000)

    if player:getLevel() > oldLevel then
        -- Notificacao basica com som automatico
        sendPlayerNotification(player,
            "LEVEL UP! " .. oldLevel .. " -> " .. player:getLevel(),
            8, "text", "level", {})

        -- Som personalizado adicional baseado no level
        if player:getLevel() >= 50 then
            sound.sendSoundOtc(player, "major_level_up", 5)
        elseif player:getLevel() >= 20 then
            sound.sendSoundOtc(player, "level_up", 3)
        else
            sound.sendSoundOtc(player, "minor_level_up", 2)
        end

        -- Bonus por level up
        player:addHealth(player:getMaxHealth())
        sendPlayerNotification(player,
            "Vida totalmente recuperada!",
            3, "text", "heal", {})
    end
end
```

---

**Lembre-se: Todo `sendPlayerNotification()` ja inclui som automaticamente!**