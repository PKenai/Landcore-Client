local OPCODE_MONSTER_ICON = 136
local monsterIcons = {} -- creatureId -> iconWidget
local pendingRequests = {} -- creatureId -> true (to avoid duplicate requests)

function init()
  -- Connect to game events
  connect(g_game, { onGameStart = onGameStart })

  -- Connect to creature events
  connect(Creature, {
    onAppear = onCreatureAppear,
    onDisappear = onCreatureDisappear
  })
end

function onGameStart()
  ProtocolGame.registerExtendedOpcode(OPCODE_MONSTER_ICON, onMonsterIconResponse)
end

function terminate()
  -- Unregister extended opcode
  ProtocolGame.unregisterExtendedOpcode(OPCODE_MONSTER_ICON)

  -- Disconnect game events
  disconnect(g_game, { onGameStart = onGameStart })

  -- Disconnect creature events
  disconnect(Creature, {
    onAppear = onCreatureAppear,
    onDisappear = onCreatureDisappear
  })

  -- Clean up all existing icons
  -- Textures are automatically managed by the creature system
  for creatureId, _ in pairs(monsterIcons) do
    local creature = g_map.getCreatureById(creatureId)
    if creature then
      -- Textures will be cleared when creatures are destroyed
    end
  end
  monsterIcons = {}
  pendingRequests = {}
end

function onCreatureAppear(creature)
  -- Only send requests for monsters
  if not creature:isMonster() then
    return
  end

  local creatureId = creature:getId()

  -- Avoid duplicate requests
  if pendingRequests[creatureId] or monsterIcons[creatureId] then
    return
  end

  pendingRequests[creatureId] = true

  -- Send request to server
  local request = {
    creature = creatureId
  }

  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    local jsonString = json.encode(request)
    protocolGame:sendExtendedOpcode(OPCODE_MONSTER_ICON, jsonString)
  else
    -- Remove from pending if protocol not available
    pendingRequests[creatureId] = nil
  end
end

function onCreatureDisappear(creature)
  -- Clear monster icon texture if creature disappears
  local creatureId = creature:getId()
  if monsterIcons[creatureId] then
    -- The texture will be automatically cleared when creature is destroyed
    monsterIcons[creatureId] = nil
  end

  -- Also remove from pending requests
  pendingRequests[creatureId] = nil
end

function onMonsterIconResponse(protocol, opcode, buffer)
  -- Decode JSON response
  local status, response = pcall(function()
    return json.decode(buffer)
  end)

  if not status or not response then
    return
  end

  -- Check if it's our expected response type
  if response.response ~= "SetMonsterIcon" then
    return
  end

  local creatureId = response.creatureId
  local iconFile = response.icon

  if not creatureId or not iconFile then
    return
  end

  -- Remove from pending requests
  pendingRequests[creatureId] = nil

  -- Get creature
  local creature = g_map.getCreatureById(creatureId)
  if not creature then
    return
  end

  -- Set the monster icon texture using the native system
  local iconPath = "/images/landcore/monstericons/" .. iconFile
  creature:setMonsterIconTexture(iconPath)

  -- Store reference for cleanup
  monsterIcons[creatureId] = true
end
