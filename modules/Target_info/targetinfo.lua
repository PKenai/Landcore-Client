local ui
local creatureWidget
local healthBar
local healthText
local baseHealthWidth = 120
local gameConn
local creatureConn

local function disconnectCreature()
  if creatureConn and creatureWidget and creatureWidget.creature then
    print("[targetinfo] disconnecting creature signals")
    disconnect(creatureWidget.creature, creatureConn)
  end
  creatureConn = nil
end

local function updateHealth(creature, tag)
  if not (creature and healthBar and healthText) then
    print("[targetinfo] updateHealth skipped (missing widgets/creature)")
    return
  end
  local hp = creature:getHealthPercent() or 100
  healthText:setText(hp .. "%")
  healthBar:setWidth(math.floor(baseHealthWidth * hp / 100))
  print(string.format("[targetinfo] %s hp=%d baseWidth=%d", tag or "update", hp, baseHealthWidth))
end

local function setCreature(creature)
  disconnectCreature()
  if not creature then
    print("[targetinfo] setCreature nil -> hide UI")
    if ui then ui:hide() end
    return
  end

  print(string.format("[targetinfo] setCreature %s id=%s", creature:getName() or "?", tostring(creature:getId())))

  local outfit = creature:getOutfit()
  if outfit then
    creatureWidget:setOutfit(outfit)
  else
    print("[targetinfo] no outfit available")
  end
  creatureWidget:setCreature(creature)
  creatureWidget:setVisible(true)

  updateHealth(creature, "initial")

  creatureConn = connect(creature, {
    onHealthPercentChange = function(_, percent)
      if not creature then return end
      local hp = percent or creature:getHealthPercent() or 100
      healthText:setText(hp .. "%")
      healthBar:setWidth(math.floor(baseHealthWidth * hp / 100))
      print(string.format("[targetinfo] onHealthPercentChange hp=%d", hp))
    end
  })

  ui:show()
end

function init()
  print("[targetinfo] init")

  if g_game.isOnline() then
    createInterface()
  else
    gameConn = connect(g_game, { onGameStart = createInterface })
  end
end

function terminate()
  print("[targetinfo] terminate")
  disconnectCreature()
  if gameConn then
    disconnect(g_game, gameConn)
    gameConn = nil
  end
  if ui then
    ui:destroy()
    ui = nil
  end
  print("[targetinfo] unloaded")
end

function createInterface()
  print("[targetinfo] createInterface")

  if ui then
    print("[targetinfo] ui already exists")
    return
  end
  if not modules.game_interface then
    print("[targetinfo] modules.game_interface missing")
    return
  end

  local rootPanel = modules.game_interface.getRootPanel()
  if not rootPanel then
    print("[targetinfo] rootPanel missing")
    return
  end

  ui = g_ui.loadUI("targetinfo.otui", rootPanel)
  if not ui then
    print("[targetinfo] ERROR: failed to load targetinfo.otui")
    return
  end

  creatureWidget = ui:recursiveGetChildById("creature")
  healthBar     = ui:recursiveGetChildById("health")
  healthText    = ui:recursiveGetChildById("healthText")

  if not (creatureWidget and healthBar and healthText) then
    print("[targetinfo] ERROR: widgets not found")
    return
  end

  baseHealthWidth = healthBar:getWidth() > 0 and healthBar:getWidth() or 120
  print(string.format("[targetinfo] baseHealthWidth=%d", baseHealthWidth))

  ui:hide()

  connect(g_game, {
    onAttackingCreatureChange = function(creature)
      print("[targetinfo] onAttackingCreatureChange")
      setCreature(creature)
    end
  })
end