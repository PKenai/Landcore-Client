-- Monster Loot Virtual Inventory Module
-- Displays monster loot in a horizontal 6-slot interface above the spell bar

-- Monster Loot Virtual Inventory Module
-- Displays monster loot in a horizontal 6-slot interface above the spell bar

local monsterLootWindow = nil
local lootSlots = {}  -- Array of 6 slot widgets
local currentMonsterId = nil  -- ID of monster whose loot we're displaying

-- Constants
local NUM_LOOT_SLOTS = 6
local SLOT_SIZE = 34
local SLOT_SPACING = 3

function init()
  -- Check dependencies
  if not modules.game_interface then
    return
  end

  -- Enable ExtendedOpcode feature
  g_game.enableFeature(GameExtendedOpcode)

  -- Create the loot window
  monsterLootWindow = g_ui.createWidget('UIWidget', modules.game_interface.getRootPanel())
  monsterLootWindow:setId('monsterLootWindow')
  monsterLootWindow:setVisible(false)  -- Hidden by default

  -- Try to position it above the spell bar
  positionLootWindow()

  -- Set window properties
  monsterLootWindow:setWidth(NUM_LOOT_SLOTS * (SLOT_SIZE + SLOT_SPACING) - SLOT_SPACING)
  monsterLootWindow:setHeight(SLOT_SIZE)
  monsterLootWindow:setPhantom(false)
  monsterLootWindow:setFocusable(false)

  -- Create loot slots
  createLootSlots()


  -- Connect events
  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = hideLootWindow,
    onClientVersionChange = onClientVersionChange
  })


  -- Listen for extended opcodes to receive monster loot data
  -- Connect later when game is fully initialized
  connect(g_game, {
    onGameStart = function()
      -- Hook into the protocol game extended opcode handler
      local originalOnExtendedOpcode = ProtocolGame.onExtendedOpcode
      ProtocolGame.onExtendedOpcode = function(self, opcode, buffer)
        -- Call original handler first
        if originalOnExtendedOpcode then
          originalOnExtendedOpcode(self, opcode, buffer)
        end

        -- Handle our monster loot opcodes
        if opcode == 0x03 or opcode == 0x04 then
          onExtendedOpcode(opcode, buffer)
        end
      end
    end
  })

end

function terminate()

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = hideLootWindow,
    onClientVersionChange = onClientVersionChange
  })

  -- Note: We don't need to clean up the hook as the module will be unloaded
  -- The original method will be restored automatically

  if monsterLootWindow then
    monsterLootWindow:destroy()
    monsterLootWindow = nil
  end

  lootSlots = {}
  currentMonsterId = nil

end

function createLootSlots()
  if not monsterLootWindow then
    return
  end

  -- Create 6 horizontal slots
  for i = 0, NUM_LOOT_SLOTS - 1 do
    local slotWidget = g_ui.createWidget('Item', monsterLootWindow)
    slotWidget:setId('lootSlot' .. i)
    slotWidget:setItem(nil)
    slotWidget:resize(SLOT_SIZE, SLOT_SIZE)
    slotWidget:setPhantom(false)
    slotWidget:setVisible(true)
    slotWidget:setVirtual(false)
    slotWidget:setBorderWidth(0)
    if slotWidget.setBorderColor then
      slotWidget:setBorderColor('#00000000')  -- Transparent border
    end

    -- Set background image
    slotWidget:setImageSource('/images/landcore/inventoryicon')

    -- Position slots horizontally
    if i == 0 then
      slotWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
      slotWidget:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    else
      local prevSlotId = 'lootSlot' .. (i - 1)
      slotWidget:addAnchor(AnchorLeft, prevSlotId, AnchorRight)
      slotWidget:addAnchor(AnchorVerticalCenter, prevSlotId, AnchorVerticalCenter)
      slotWidget:setMarginLeft(SLOT_SPACING)
    end

    -- Setup click handlers
    setupLootSlotHandlers(slotWidget, i)

    lootSlots[i] = slotWidget
  end
end

function setupLootSlotHandlers(widget, slotIndex)
  -- Handle double-click to loot item
  widget.onDoubleClick = function(self)
    lootItem(slotIndex)
  end

  -- Handle right-click (optional, for future use)
  widget.onMouseRelease = function(self, mousePos, mouseButton)
    if mouseButton == MouseButtonRight then
      -- Could add context menu here if needed
      return true
    end
    return false
  end

  -- Allow dropping items from player inventory to loot slots (if needed)
  widget.canAcceptDrop = function(self, droppedWidget, mousePos)
    -- For now, don't accept drops - this is display only
    return false
  end
end

function positionLootWindow()
  if not monsterLootWindow then
    return
  end

  -- Try to position it above the spell bar
  local spellBar = modules.game_tspellbar and modules.game_tspellbar.getSpellBarWidget()
  if spellBar then
    monsterLootWindow:addAnchor(AnchorBottom, spellBar, AnchorTop)
    monsterLootWindow:addAnchor(AnchorHorizontalCenter, spellBar, AnchorHorizontalCenter)
    monsterLootWindow:setMarginBottom(5)
  else
    -- Fallback positioning
    monsterLootWindow:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    monsterLootWindow:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    monsterLootWindow:setMarginBottom(150)
  end
end

function onGameStart()
  -- Enable ExtendedOpcode when game starts
  if not g_game.getFeature(GameExtendedOpcode) then
    g_game.enableFeature(GameExtendedOpcode)
  end

  -- Try to reposition the loot window now that all modules should be loaded
  positionLootWindow()

  hideLootWindow()
end

function onClientVersionChange(version)
  -- Re-enable ExtendedOpcode when client version changes
  if not g_game.getFeature(GameExtendedOpcode) then
    g_game.enableFeature(GameExtendedOpcode)
  end
end

function onExtendedOpcode(opcode, buffer)
  if opcode == 0x03 then  -- Monster loot data opcode
    handleMonsterLootData(buffer)
  elseif opcode == 0x04 then  -- Clear monster loot opcode
    if buffer == "clear" then
      clearMonsterLoot()
    end
  end
end

function handleMonsterLootData(buffer)
  -- Parse monster loot data from server
  -- Format: monsterId:itemId1,count1;itemId2,count2;...
  local data = buffer:split(':')
  if #data < 2 then
    return
  end

  local monsterId = tonumber(data[1])
  if not monsterId then
    return
  end

  currentMonsterId = monsterId

  -- Clear existing loot
  clearLootSlots()

  -- Parse loot items
  local lootData = data[2]:split(';')

  for i, itemStr in ipairs(lootData) do
    if i > NUM_LOOT_SLOTS then
      break  -- Only show first 6 items
    end

    local itemData = itemStr:split(',')
    if #itemData >= 2 then
      local itemId = tonumber(itemData[1])
      local count = tonumber(itemData[2]) or 1

      if itemId and itemId > 0 then
        local item = Item.create(itemId, count)
        if item then
          lootSlots[i-1]:setItem(item)
        end
      end
    end
  end

  -- Show the loot window
  showLootWindow()
end

function clearMonsterLoot()
  clearLootSlots()
  hideLootWindow()
  currentMonsterId = nil
end

function clearLootSlots()
  for i = 0, NUM_LOOT_SLOTS - 1 do
    if lootSlots[i] then
      lootSlots[i]:setItem(nil)
    end
  end
end

function showLootWindow()
  if monsterLootWindow then
    monsterLootWindow:setVisible(true)
  end
end

function hideLootWindow()
  if monsterLootWindow then
    monsterLootWindow:setVisible(false)
  end
end

function lootItem(slotIndex)
  if not currentMonsterId or not lootSlots[slotIndex] then
    return
  end

  local item = lootSlots[slotIndex]:getItem()
  if not item then
    return
  end

  -- Send extended opcode to server to loot the item
  -- Format: lootItem:monsterId:slotIndex
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(0x05, string.format("lootItem:%d:%d", currentMonsterId, slotIndex))
  end

  -- Clear the slot immediately (optimistic update)
  lootSlots[slotIndex]:setItem(nil)

  -- Check if all slots are empty, hide window if so
  local hasItems = false
  for i = 0, NUM_LOOT_SLOTS - 1 do
    if lootSlots[i] and lootSlots[i]:getItem() then
      hasItems = true
      break
    end
  end

  if not hasItems then
    hideLootWindow()
  end
end

-- Public API functions
function isVisible()
  return monsterLootWindow and monsterLootWindow:isVisible()
end

function getCurrentMonsterId()
  return currentMonsterId
end

-- Module loaded confirmation
