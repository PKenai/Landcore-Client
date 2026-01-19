local PROFICIENCY_OPCODE = 101
local proficiencyData = {}
local refreshTimer = nil

function init()
  ProtocolGame.registerExtendedOpcode(PROFICIENCY_OPCODE, onProficiencyUpdate)
  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })
  connect(LocalPlayer, {
    onInventoryChange = onLocalPlayerInventoryChange
  })
  
  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(PROFICIENCY_OPCODE)
  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })
  disconnect(LocalPlayer, {
    onInventoryChange = onLocalPlayerInventoryChange
  })
  stopRefreshTimer()
  proficiencyData = {}
end

function onGameStart()
  clearAllSlots()
  startRefreshTimer()
end

function onGameEnd()
  stopRefreshTimer()
  clearAllSlots()
end

function startRefreshTimer()
  stopRefreshTimer()
  -- Refresh every 2 seconds for a minute after login/change to catch loading items
  refreshTimer = cycleEvent(refreshAllProficiencyUI, 2000)
  -- Automatically stop after 60 seconds to save performance
  scheduleEvent(stopRefreshTimer, 60000)
end

function stopRefreshTimer()
  if refreshTimer then
    removeEvent(refreshTimer)
    refreshTimer = nil
  end
end

function onLocalPlayerInventoryChange(player, slot, item, oldItem)
  if not item then
    proficiencyData[slot] = nil
    updateProficiencyUI(slot, 0, 0, 0)
  else
    local data = proficiencyData[slot]
    if data then
      updateProficiencyUI(slot, data.level, data.exp, data.nextExp)
      -- If name is still missing, trigger a few retries
      startRefreshTimer()
    else
      updateProficiencyUI(slot, 0, 0, 0)
    end
  end
end

function onProficiencyUpdate(protocol, opcode, buffer)
  if opcode ~= PROFICIENCY_OPCODE then return end
  -- Parse format: "slot:level:exp:nextExp:name"
  local parts = string.split(buffer, ":")
  if #parts < 4 then return end
  
  local slot = tonumber(parts[1])
  local level = tonumber(parts[2])
  local exp = tonumber(parts[3])
  local nextExp = tonumber(parts[4])
  local name = parts[5] or "ITEM"
  
  proficiencyData[slot] = { level = level, exp = exp, nextExp = nextExp, name = name }
  updateProficiencyUI(slot, level, exp, nextExp, name)
  startRefreshTimer() -- Ensure UI reflects this even if panels weren't ready
end

function refreshAllProficiencyUI()
  local anyFound = false
  for slot, data in pairs(proficiencyData) do
    if data then
      updateProficiencyUI(slot, data.level, data.exp, data.nextExp, data.name)
      anyFound = true
    end
  end
  if not anyFound then stopRefreshTimer() end
end

function updateProficiencyUI(slot, level, exp, nextExp, name)
  local inventoryPanel = nil
  if modules.game_interface then
    local rootPanel = modules.game_interface.getRootPanel()
    if rootPanel then
      local unifiedWindow = rootPanel:getChildById('unifiedInventoryWindow')
      if unifiedWindow and unifiedWindow:isVisible() then
        inventoryPanel = unifiedWindow:recursiveGetChildById('inventoryPanel')
      end
    end
    if not inventoryPanel then
      local rightPanel = modules.game_interface.getRightPanel()
      local inventoryWindow = rightPanel and rightPanel:getChildById('inventoryWindow')
      if inventoryWindow then
        inventoryPanel = inventoryWindow:recursiveGetChildById('inventoryPanel')
      end
    end
  end
  
  if not inventoryPanel then
    if modules.game_unified_inventory and modules.game_unified_inventory.inventoryPanel then
      inventoryPanel = modules.game_unified_inventory.inventoryPanel
    elseif modules.game_inventory and modules.game_inventory.inventoryPanel then
      inventoryPanel = modules.game_inventory.inventoryPanel
    end
  end
  
  if not inventoryPanel then return end
  local itemWidget = inventoryPanel:getChildById('slot' .. slot)
  if not itemWidget then return end
  
  local levelLabel = itemWidget:getChildById('proficiencyLevel')
  local progressBar = itemWidget:getChildById('proficiencyBar')
  
  if not levelLabel then
    levelLabel = g_ui.createWidget('Label', itemWidget)
    levelLabel:setId('proficiencyLevel')
    levelLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
    levelLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    levelLabel:setMarginTop(1)
    levelLabel:setMarginLeft(2)
    levelLabel:setFont('cipsoftFont')
    levelLabel:setColor('#FFFFFF')
    levelLabel:setPhantom(true)
    levelLabel:raise()
  end
  
  if not progressBar then
    progressBar = g_ui.createWidget('ProgressBar', itemWidget)
    progressBar:setId('proficiencyBar')
    progressBar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    progressBar:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    progressBar:setMarginBottom(2)
    progressBar:setWidth(15)
    progressBar:setHeight(3)
    progressBar:setBackgroundColor('#00ff00')
    progressBar:setBorderWidth(1)
    progressBar:setBorderColor('#000000')
    progressBar:setPhantom(true)
    progressBar:raise()
  end

  if levelLabel then
    levelLabel:setText(level > 0 and level or "")
    levelLabel:setVisible(level > 0)
  end
  
  if progressBar then
    if level > 0 then
      local percent = 0
      if nextExp > 0 then
        percent = (exp / nextExp) * 100
      else
        percent = 100
      end
      progressBar:setPercent(math.min(100, percent))
      progressBar:setVisible(true)

      -- Tooltip logic using server-provided name
      local displayName = (name and name ~= "" and name:lower() ~= "item") and name:upper() or "ITEM"
      local nextLevel = level < 10 and (level + 1) or "MAX"
      local tooltip = string.format("%s\nPROFICIENCY %d\n%d%% TO LEVEL TO %s", displayName, level, math.floor(percent), tostring(nextLevel))
      itemWidget:setTooltip(tooltip)
    else
      progressBar:setVisible(false)
      itemWidget:setTooltip("")
    end
  end
end

function clearAllSlots()
  for i = 1, 10 do
    updateProficiencyUI(i, 0, 0, 0)
  end
end

