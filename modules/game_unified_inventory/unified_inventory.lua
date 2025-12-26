-- Unified Inventory Module
-- Combines standard equipment slots with a large virtual backpack

g_logger.info("=========================================")
g_logger.info("[UnifiedInventory] Script file loaded!")
g_logger.info("=========================================")

local unifiedInventoryWindow = nil
local inventoryPanel = nil
local backpackPanel = nil
local favoritesPanel = nil
local unifiedInventoryButton = nil

-- Virtual backpack storage (slot index -> item)
local virtualBackpack = {}
local FAVORITES_SLOTS = 8  -- Number of slots in favorites area
local BACKPACK_COLUMNS = 8  -- Number of columns in backpack grid
local BACKPACK_ROWS = 8     -- Number of rows in normal backpack area
local TOTAL_BACKPACK_SLOTS = FAVORITES_SLOTS + (BACKPACK_COLUMNS * BACKPACK_ROWS)

-- Inventory slot styles mapping
local InventorySlotStyles = {
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot"
}

function init()
  g_logger.info("[UnifiedInventory] Module init() called")
  
  if not modules.client_topmenu then
    g_logger.error("[UnifiedInventory] client_topmenu module not found!")
    return
  end
  
  if not modules.game_interface then
    g_logger.error("[UnifiedInventory] game_interface module not found!")
    return
  end

  g_logger.info("[UnifiedInventory] Loading UI first...")
  -- Load UI BEFORE connecting events
  local rootPanel = modules.game_interface.getRootPanel()
  if not rootPanel then
    g_logger.error("[UnifiedInventory] Could not get root panel!")
    return
  end
  
  -- Try to load UI file first
  g_logger.info("[UnifiedInventory] Trying to load UI: unified_inventory")
  unifiedInventoryWindow = g_ui.loadUI('unified_inventory', rootPanel)
  
  -- If loading from file fails, create window programmatically
  if not unifiedInventoryWindow then
    g_logger.warning("[UnifiedInventory] Failed to load from OTUI file, creating window programmatically...")
    
    -- Create window directly
    unifiedInventoryWindow = g_ui.createWidget('UIWindow', rootPanel)
    unifiedInventoryWindow:setId('unifiedInventoryWindow')
    unifiedInventoryWindow:setText(tr('Unified Inventory'))
    unifiedInventoryWindow:resize(420, 700)
    
    -- Center window manually
    local screenSize = rootPanel:getSize()
    unifiedInventoryWindow:setPosition({
      (screenSize.width - 420) / 2,
      (screenSize.height - 700) / 2
    })
    
    -- Make sure window is visible
    unifiedInventoryWindow:setVisible(true)
    
    unifiedInventoryWindow.onClose = function()
      modules.game_unified_inventory.onMiniWindowClose()
    end
    
    -- Create main panel
    local mainPanel = g_ui.createWidget('Panel', unifiedInventoryWindow)
    mainPanel:setId('mainPanel')
    mainPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    mainPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    mainPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    mainPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    mainPanel:setPadding(3)
    
    -- Create equipment panel
    local equipmentPanel = g_ui.createWidget('Panel', mainPanel)
    equipmentPanel:setId('equipmentPanel')
    equipmentPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    equipmentPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    equipmentPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    equipmentPanel:setHeight(280)
    equipmentPanel:setPadding(5)
    equipmentPanel:setBackgroundColor('#00000088')
    equipmentPanel:setBorderWidth(1)
    equipmentPanel:setBorderColor('#333333')
    
    -- Create inventory panel
    inventoryPanel = g_ui.createWidget('Panel', equipmentPanel)
    inventoryPanel:setId('inventoryPanel')
    inventoryPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    inventoryPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    inventoryPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    inventoryPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    inventoryPanel:setMargin(5)
    
    -- Create equipment slots manually with proper positioning
    createEquipmentSlots()
    
    -- Create favorites container
    local favoritesContainer = g_ui.createWidget('Panel', mainPanel)
    favoritesContainer:setId('favoritesContainer')
    favoritesContainer:addAnchor(AnchorTop, 'equipmentPanel', AnchorBottom)
    favoritesContainer:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    favoritesContainer:addAnchor(AnchorRight, 'parent', AnchorRight)
    favoritesContainer:setHeight(50)
    favoritesContainer:setPadding(3)
    favoritesContainer:setBackgroundColor('#1a1a1a88')
    favoritesContainer:setBorderWidth(1)
    favoritesContainer:setBorderColor('#444444')
    
    local favoritesLabel = g_ui.createWidget('Label', favoritesContainer)
    favoritesLabel:setId('favoritesLabel')
    favoritesLabel:setText(tr('Favorites'))
    favoritesLabel:setColor('#FFFF00')
    favoritesLabel:setMarginLeft(3)
    favoritesLabel:setMarginTop(3)
    
    favoritesPanel = g_ui.createWidget('Panel', favoritesContainer)
    favoritesPanel:setId('favoritesPanel')
    favoritesPanel:addAnchor(AnchorTop, 'favoritesLabel', AnchorBottom)
    favoritesPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    favoritesPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    favoritesPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    favoritesPanel:setMarginTop(2)
    
    -- Create backpack container
    local backpackContainer = g_ui.createWidget('Panel', mainPanel)
    backpackContainer:setId('backpackContainer')
    backpackContainer:addAnchor(AnchorTop, 'favoritesContainer', AnchorBottom)
    backpackContainer:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    backpackContainer:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    backpackContainer:addAnchor(AnchorRight, 'parent', AnchorRight)
    backpackContainer:setPadding(3)
    backpackContainer:setBackgroundColor('#00000088')
    backpackContainer:setBorderWidth(1)
    backpackContainer:setBorderColor('#333333')
    
    backpackPanel = g_ui.createWidget('Panel', backpackContainer)
    backpackPanel:setId('backpackPanel')
    backpackPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    backpackPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    backpackPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    backpackPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    backpackPanel:setMargin(3)
    
    g_logger.info("[UnifiedInventory] Window created programmatically!")
    -- Panels are already created as global variables (inventoryPanel, favoritesPanel, backpackPanel)
  else
    g_logger.info("[UnifiedInventory] UI loaded successfully from file!")
    -- Center window after loading
    local screenSize = rootPanel:getSize()
    unifiedInventoryWindow:setPosition({
      (screenSize.width - 420) / 2,
      (screenSize.height - 700) / 2
    })
    
    -- Get panels from loaded UI
    inventoryPanel = unifiedInventoryWindow:getChildById('inventoryPanel')
    favoritesPanel = unifiedInventoryWindow:getChildById('favoritesPanel')
    backpackPanel = unifiedInventoryWindow:getChildById('backpackPanel')
  end
  
  unifiedInventoryWindow:hide()
  
  -- Verify panels exist
  if not inventoryPanel then
    g_logger.error("[UnifiedInventory] inventoryPanel not found!")
    return -- Exit if critical panel is missing
  end
  if not favoritesPanel then
    g_logger.warning("[UnifiedInventory] favoritesPanel not found!")
  end
  if not backpackPanel then
    g_logger.warning("[UnifiedInventory] backpackPanel not found!")
  end
  
  g_logger.info("[UnifiedInventory] Panels retrieved successfully")
  
  -- NOW connect events after UI is loaded
  g_logger.info("[UnifiedInventory] Connecting to events...")
  connect(LocalPlayer, {
    onInventoryChange = onInventoryChange
  })
  connect(g_game, { 
    onGameStart = refresh,
    onGameEnd = clearBackpack
  })
  
  -- Setup window handlers
  unifiedInventoryWindow.onDrop = function(self, widget, mousePos)
    -- If dropping on empty space, try to add to backpack
    if widget and widget.item then
      local emptySlot = findEmptyBackpackSlot()
      if emptySlot then
        setBackpackItem(emptySlot, widget.item)
        return true
      end
    end
    return false
  end
  
  g_logger.info("[UnifiedInventory] Initializing backpack slots...")
  -- Initialize virtual backpack slots
  initializeBackpackSlots()
  
  g_logger.info("[UnifiedInventory] Adding button to top menu...")
  -- Add button to top menu
  unifiedInventoryButton = modules.client_topmenu.addRightGameToggleButton(
    'unifiedInventoryButton', 
    tr('Unified Inventory'), 
    '/images/landcore/inventory_icon', 
    toggle
  )
  
  if not unifiedInventoryButton then
    g_logger.error("[UnifiedInventory] Failed to create top menu button!")
  else
    g_logger.info("[UnifiedInventory] Button created successfully")
    unifiedInventoryButton:setOn(false)
  end
  
  -- Bind keyboard shortcut
  g_keyboard.bindKeyDown('Ctrl+U', toggle)
  g_logger.info("[UnifiedInventory] Keyboard shortcut bound (Ctrl+U)")
  
  if g_game.isOnline() then
    g_logger.info("[UnifiedInventory] Game is online, refreshing...")
    refresh()
  end
  
  g_logger.info("[UnifiedInventory] Module initialized successfully!")
end

function terminate()
  g_logger.info("[UnifiedInventory] Module terminate() called")
  
  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange
  })
  disconnect(g_game, { 
    onGameStart = refresh,
    onGameEnd = clearBackpack
  })
  
  g_keyboard.unbindKeyDown('Ctrl+U')
  
  if unifiedInventoryWindow then
    unifiedInventoryWindow:destroy()
  end
  
  if unifiedInventoryButton then
    unifiedInventoryButton:destroy()
  end
  
  virtualBackpack = {}
  g_logger.info("[UnifiedInventory] Module terminated")
end

function createEquipmentSlots()
  if not inventoryPanel then 
    g_logger.warning("[UnifiedInventory] Cannot create equipment slots - inventoryPanel is nil")
    return 
  end
  
  g_logger.info("[UnifiedInventory] Creating equipment slots with exact inventory positions...")
  
  -- Create slots using the exact same styles and positions as the standard inventory
  -- Based on 40-inventory.otui layout
  
  -- Head slot (slot1) - center top
  local headSlot = g_ui.createWidget('HeadSlot', inventoryPanel)
  headSlot:setId('slot1')
  headSlot:addAnchor(AnchorTop, 'parent', AnchorTop)
  headSlot:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  headSlot:setMarginTop(3)
  
  -- Body slot (slot4) - below head
  local bodySlot = g_ui.createWidget('BodySlot', inventoryPanel)
  bodySlot:setId('slot4')
  bodySlot:addAnchor(AnchorTop, 'slot1', AnchorBottom)
  bodySlot:addAnchor(AnchorHorizontalCenter, 'slot1', AnchorHorizontalCenter)
  bodySlot:setMarginTop(3)
  
  -- Leg slot (slot7) - below body
  local legSlot = g_ui.createWidget('LegSlot', inventoryPanel)
  legSlot:setId('slot7')
  legSlot:addAnchor(AnchorTop, 'slot4', AnchorBottom)
  legSlot:addAnchor(AnchorHorizontalCenter, 'slot4', AnchorHorizontalCenter)
  legSlot:setMarginTop(3)
  
  -- Feet slot (slot8) - below leg
  local feetSlot = g_ui.createWidget('FeetSlot', inventoryPanel)
  feetSlot:setId('slot8')
  feetSlot:addAnchor(AnchorTop, 'slot7', AnchorBottom)
  feetSlot:addAnchor(AnchorHorizontalCenter, 'slot7', AnchorHorizontalCenter)
  feetSlot:setMarginTop(3)
  
  -- Neck slot (slot2) - left of head
  local neckSlot = g_ui.createWidget('NeckSlot', inventoryPanel)
  neckSlot:setId('slot2')
  neckSlot:addAnchor(AnchorTop, 'slot1', AnchorTop)
  neckSlot:addAnchor(AnchorRight, 'slot1', AnchorLeft)
  neckSlot:setMarginTop(13)
  neckSlot:setMarginRight(5)
  
  -- Left slot (slot6) - below neck
  local leftSlot = g_ui.createWidget('LeftSlot', inventoryPanel)
  leftSlot:setId('slot6')
  leftSlot:addAnchor(AnchorTop, 'slot2', AnchorBottom)
  leftSlot:addAnchor(AnchorHorizontalCenter, 'slot2', AnchorHorizontalCenter)
  leftSlot:setMarginTop(3)
  
  -- Finger slot (slot9) - below left
  local fingerSlot = g_ui.createWidget('FingerSlot', inventoryPanel)
  fingerSlot:setId('slot9')
  fingerSlot:addAnchor(AnchorTop, 'slot6', AnchorBottom)
  fingerSlot:addAnchor(AnchorHorizontalCenter, 'slot6', AnchorHorizontalCenter)
  fingerSlot:setMarginTop(3)
  
  -- Back slot (slot3) - right of head
  local backSlot = g_ui.createWidget('BackSlot', inventoryPanel)
  backSlot:setId('slot3')
  backSlot:addAnchor(AnchorTop, 'slot1', AnchorTop)
  backSlot:addAnchor(AnchorLeft, 'slot1', AnchorRight)
  backSlot:setMarginTop(13)
  backSlot:setMarginLeft(5)
  
  -- Right slot (slot5) - below back
  local rightSlot = g_ui.createWidget('RightSlot', inventoryPanel)
  rightSlot:setId('slot5')
  rightSlot:addAnchor(AnchorTop, 'slot3', AnchorBottom)
  rightSlot:addAnchor(AnchorHorizontalCenter, 'slot3', AnchorHorizontalCenter)
  rightSlot:setMarginTop(3)
  
  -- Ammo slot (slot10) - below right
  local ammoSlot = g_ui.createWidget('AmmoSlot', inventoryPanel)
  ammoSlot:setId('slot10')
  ammoSlot:addAnchor(AnchorTop, 'slot5', AnchorBottom)
  ammoSlot:addAnchor(AnchorHorizontalCenter, 'slot5', AnchorHorizontalCenter)
  ammoSlot:setMarginTop(3)
  
  g_logger.info("[UnifiedInventory] Equipment slots created with standard inventory layout!")
end

function initializeBackpackSlots()
  g_logger.info("[UnifiedInventory] Initializing " .. FAVORITES_SLOTS .. " favorite slots...")
  
  if not favoritesPanel then
    g_logger.error("[UnifiedInventory] favoritesPanel is nil!")
    return
  end
  
  -- Initialize favorites area
  for i = 0, FAVORITES_SLOTS - 1 do
    local itemWidget = g_ui.createWidget('Item', favoritesPanel)
    if not itemWidget then
      g_logger.error("[UnifiedInventory] Failed to create favorite slot " .. i)
    else
      itemWidget:setId('favoriteSlot' .. i)
      itemWidget:setItem(nil)
      itemWidget:setMargin(0)
      virtualBackpack[i] = nil
      
      -- Setup drag & drop handlers
      setupBackpackSlotHandlers(itemWidget, i)
    end
  end
  
  g_logger.info("[UnifiedInventory] Initializing " .. (TOTAL_BACKPACK_SLOTS - FAVORITES_SLOTS) .. " backpack slots...")
  
  if not backpackPanel then
    g_logger.error("[UnifiedInventory] backpackPanel is nil!")
    return
  end
  
  -- Initialize normal backpack area
  for i = FAVORITES_SLOTS, TOTAL_BACKPACK_SLOTS - 1 do
    local itemWidget = g_ui.createWidget('Item', backpackPanel)
    if not itemWidget then
      g_logger.error("[UnifiedInventory] Failed to create backpack slot " .. i)
    else
      itemWidget:setId('backpackSlot' .. i)
      itemWidget:setItem(nil)
      itemWidget:setMargin(0)
      virtualBackpack[i] = nil
      
      -- Setup drag & drop handlers
      setupBackpackSlotHandlers(itemWidget, i)
    end
  end
  
  g_logger.info("[UnifiedInventory] Backpack slots initialization complete!")
end


function setupBackpackSlotHandlers(widget, slotIndex)
  -- Handle item drop on backpack slot
  widget.onDrop = function(self, droppedWidget, mousePos)
    if not droppedWidget or not droppedWidget.item then
      return false
    end
    
    local item = droppedWidget.item
    local currentItem = virtualBackpack[slotIndex]
    
    -- Find where the dropped item came from (if it's already in backpack)
    local sourceSlot = findItemInBackpack(item)
    
    -- If slot is empty, accept the item
    if not currentItem then
      -- Remove from source slot first (if it was in another backpack slot)
      if sourceSlot and sourceSlot ~= slotIndex then
        setBackpackItem(sourceSlot, nil)
      end
      setBackpackItem(slotIndex, item)
      return true
    end
    
    -- If slot has item, swap items
    if currentItem then
      if sourceSlot and sourceSlot ~= slotIndex then
        -- Swap items between two backpack slots
        setBackpackItem(sourceSlot, currentItem)
        setBackpackItem(slotIndex, item)
        return true
      end
    end
    
    return false
  end
  
  -- Handle item use
  widget.onDoubleClick = function(self)
    local item = virtualBackpack[slotIndex]
    if item then
      g_game.use(item)
    end
  end
end

function removeItemFromBackpack(item)
  for i = 0, TOTAL_BACKPACK_SLOTS - 1 do
    if virtualBackpack[i] == item then
      setBackpackItem(i, nil)
      return true
    end
  end
  return false
end

function findItemInBackpack(item)
  for i = 0, TOTAL_BACKPACK_SLOTS - 1 do
    if virtualBackpack[i] == item then
      return i
    end
  end
  return nil
end

function toggle()
  g_logger.info("[UnifiedInventory] toggle() called")
  
  if not unifiedInventoryButton then
    g_logger.error("[UnifiedInventory] unifiedInventoryButton is nil!")
    return
  end
  
  if not unifiedInventoryWindow then
    g_logger.error("[UnifiedInventory] unifiedInventoryWindow is nil!")
    return
  end
  
  if unifiedInventoryButton:isOn() then
    g_logger.info("[UnifiedInventory] Closing window...")
    unifiedInventoryWindow:hide()
    unifiedInventoryButton:setOn(false)
  else
    g_logger.info("[UnifiedInventory] Opening window...")
    if unifiedInventoryWindow then
      unifiedInventoryWindow:setVisible(true)
      unifiedInventoryWindow:show()
      unifiedInventoryWindow:raise()
      unifiedInventoryWindow:focus()
      g_logger.info("[UnifiedInventory] Window shown, visible: " .. tostring(unifiedInventoryWindow:isVisible()))
      g_logger.info("[UnifiedInventory] Window position: " .. tostring(unifiedInventoryWindow:getPosition().x) .. ", " .. tostring(unifiedInventoryWindow:getPosition().y))
      g_logger.info("[UnifiedInventory] Window size: " .. tostring(unifiedInventoryWindow:getSize().width) .. "x" .. tostring(unifiedInventoryWindow:getSize().height))
    end
    unifiedInventoryButton:setOn(true)
    refresh()
  end
end

function onMiniWindowClose()
  if unifiedInventoryButton then
    unifiedInventoryButton:setOn(false)
  end
end

function refresh()
  if not g_game.isOnline() then
    return
  end
  
  if not inventoryPanel then
    g_logger.warning("[UnifiedInventory] refresh() called but inventoryPanel is nil")
    return
  end
  
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end
  
  -- Refresh equipment slots
  for slot = InventorySlotFirst, InventorySlotLast do
    local item = player:getInventoryItem(slot)
    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if itemWidget then
      if item then
        -- Item is equipped, show it
        itemWidget:setItem(item)
      else
        -- Slot is empty, item widget already has the slot image from OTUI
        itemWidget:setItem(nil)
      end
    end
  end
end

function onInventoryChange(player, slot, item, oldItem)
  if slot > InventorySlotLast then
    return
  end
  
  if not inventoryPanel then
    return
  end
  
  local itemWidget = inventoryPanel:getChildById('slot' .. slot)
  if not itemWidget then
    return
  end
  
  if item then
    -- Item is equipped, show it
    itemWidget:setItem(item)
  else
    -- Slot is empty, item widget already has the slot image from OTUI
    itemWidget:setItem(nil)
  end
end

function clearBackpack()
  -- Check if panels exist
  if not favoritesPanel or not backpackPanel then
    return
  end
  
  -- Clear all virtual backpack slots
  for i = 0, TOTAL_BACKPACK_SLOTS - 1 do
    local widget = nil
    if i < FAVORITES_SLOTS then
      if favoritesPanel then
        widget = favoritesPanel:getChildById('favoriteSlot' .. i)
      end
    else
      if backpackPanel then
        widget = backpackPanel:getChildById('backpackSlot' .. i)
      end
    end
    
    if widget then
      widget:setItem(nil)
    end
    virtualBackpack[i] = nil
  end
end

-- Get item from virtual backpack slot
function getBackpackItem(slot)
  if slot < 0 or slot >= TOTAL_BACKPACK_SLOTS then
    return nil
  end
  return virtualBackpack[slot]
end

-- Set item in virtual backpack slot
function setBackpackItem(slot, item)
  if slot < 0 or slot >= TOTAL_BACKPACK_SLOTS then
    return false
  end
  
  virtualBackpack[slot] = item
  
  -- Check if panels exist
  if not favoritesPanel or not backpackPanel then
    return false
  end
  
  local widget = nil
  if slot < FAVORITES_SLOTS then
    if favoritesPanel then
      widget = favoritesPanel:getChildById('favoriteSlot' .. slot)
    end
  else
    if backpackPanel then
      widget = backpackPanel:getChildById('backpackSlot' .. slot)
    end
  end
  
  if widget then
    widget:setItem(item)
  end
  
  return true
end

-- Find first empty slot in backpack
function findEmptyBackpackSlot()
  for i = 0, TOTAL_BACKPACK_SLOTS - 1 do
    if not virtualBackpack[i] then
      return i
    end
  end
  return nil
end

