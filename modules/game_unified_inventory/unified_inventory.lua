-- Unified Inventory Module
-- Combines standard equipment slots with a large virtual backpack

local unifiedInventoryWindow = nil
local inventoryPanel = nil
local backpackPanel = nil
local unifiedInventoryButton = nil

-- Virtual backpack storage (slot index -> item)
local virtualBackpack = {}

-- Bank gold display
local bankGold = 0
local bankGoldLabel = nil

-- Track last known container item count for change detection

-- Pending item moves (waiting for container to open)
local pendingMoves = {}  -- {item, backpackId, slotIndex}
local BACKPACK_COLUMNS = 11  -- Number of columns in backpack grid
local BACKPACK_ROWS = 11    -- Number of rows in normal backpack area
local TOTAL_BACKPACK_SLOTS = BACKPACK_COLUMNS * BACKPACK_ROWS


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
  -- Enable ExtendedOpcode feature
  g_game.enableFeature(GameExtendedOpcode)
  
  if not modules.client_topmenu then
    return
  end
  
  if not modules.game_interface then
    return
  end

  -- Load UI BEFORE connecting events
  local rootPanel = modules.game_interface.getRootPanel()
  if not rootPanel then
    return
  end
  
  -- Try to load UI file first
  -- OTClient automatically searches in the module directory, so just use the filename
  unifiedInventoryWindow = g_ui.loadUI('unified_inventory', rootPanel)
  
  -- If loading from file fails, create window programmatically
  if not unifiedInventoryWindow then
    
    -- Create window directly
    unifiedInventoryWindow = g_ui.createWidget('UIWindow', rootPanel)
    unifiedInventoryWindow:setId('unifiedInventoryWindow')
    unifiedInventoryWindow:setText('')
    unifiedInventoryWindow:resize(413, 560)
    
    -- Anchor window to center of screen, but move 60 pixels down
    unifiedInventoryWindow:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    unifiedInventoryWindow:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    unifiedInventoryWindow:setMarginTop(60)
    
    -- Make sure window is visible
    unifiedInventoryWindow:setVisible(true)
    
    unifiedInventoryWindow.onClose = function()
      modules.game_unified_inventory.onMiniWindowClose()
    end
    
    -- Create background image widget (behind everything, original size)
    local backgroundImage = g_ui.createWidget('UIWidget', unifiedInventoryWindow)
    backgroundImage:setId('backgroundImage')
    backgroundImage:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    backgroundImage:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    backgroundImage:setMarginTop(-55)  -- Move image 55 pixels up
    backgroundImage:resize(505, 675)
    backgroundImage:setImageSource('/images/landcore/inventory')
    if backgroundImage.setImageAutoResize then
      backgroundImage:setImageAutoResize(false)
    end
    
    -- Create main panel
    local mainPanel = g_ui.createWidget('Panel', unifiedInventoryWindow)
    mainPanel:setId('mainPanel')
    mainPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    mainPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    mainPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    mainPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    mainPanel:setPadding(3)
    
    -- Create equipment panel container (horizontal layout)
    local equipmentContainer = g_ui.createWidget('Panel', mainPanel)
    equipmentContainer:setId('equipmentContainer')
    equipmentContainer:addAnchor(AnchorTop, 'parent', AnchorTop)
    equipmentContainer:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    equipmentContainer:addAnchor(AnchorRight, 'parent', AnchorRight)
    equipmentContainer:setMarginTop(-25)  -- Margem negativa maior para subir o painel
    equipmentContainer:setHeight(155)
    equipmentContainer:setPadding(5)
    equipmentContainer:setBackgroundColor('#00000000')
    equipmentContainer:setBorderWidth(0)
    
    -- Create outfit viewer on the left
    local outfitViewer = g_ui.createWidget('UICreature', equipmentContainer)
    outfitViewer:setId('outfitViewer')
    outfitViewer:addAnchor(AnchorTop, 'parent', AnchorTop)
    outfitViewer:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    outfitViewer:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    outfitViewer:setWidth(140)  -- Increased to make character bigger
    outfitViewer:setHeight(165)  -- Increased to make character bigger
    outfitViewer:setMarginTop(-10)  -- Move up (negative margin)
    outfitViewer:setMarginLeft(25)  -- Move right (increased from 10 to 14)
    outfitViewer:setMarginBottom(5)
    outfitViewer:setMarginRight(5)
    outfitViewer:setPhantom(false)
    outfitViewer:setVisible(true)
    
    -- Update outfit viewer with local player
    if g_game.isOnline() and LocalPlayer then
      outfitViewer:setCreature(LocalPlayer)
    end

    -- Create bank gold label below outfit viewer
    bankGoldLabel = g_ui.createWidget('Label', equipmentContainer)
    bankGoldLabel:setId('bankGoldLabel')
    bankGoldLabel:addAnchor(AnchorTop, 'outfitViewer', AnchorBottom)
    bankGoldLabel:addAnchor(AnchorHorizontalCenter, 'outfitViewer', AnchorHorizontalCenter)
    bankGoldLabel:setMarginTop(-7)
    bankGoldLabel:setMarginLeft(-50)
    bankGoldLabel:setText("Bank: 0 gold")
    bankGoldLabel:setColor('#7C7163')  -- Brown color
    bankGoldLabel:setFont('verdana-11px-antialised')
    bankGoldLabel:setTextAlign(AlignLeft)
    bankGoldLabel:setVisible(true)
    
    -- Create equipment panel (moved to the right)
    local equipmentPanel = g_ui.createWidget('Panel', equipmentContainer)
    equipmentPanel:setId('equipmentPanel')
    equipmentPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    equipmentPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    equipmentPanel:addAnchor(AnchorLeft, 'outfitViewer', AnchorRight)
    equipmentPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    equipmentPanel:setMargin(5, 5, 5, 5)
    
    -- Create inventory panel (inside equipment panel, aligned to right)
    inventoryPanel = g_ui.createWidget('Panel', equipmentPanel)
    inventoryPanel:setId('inventoryPanel')
    inventoryPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    inventoryPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    inventoryPanel:addAnchor(AnchorRight, 'parent', AnchorRight)  -- Aligned to right
    inventoryPanel:setWidth(110)  -- Fixed width to keep slots together on the right
    inventoryPanel:setMarginTop(-5)  -- Negative margin to move slots up
    inventoryPanel:setMarginBottom(5)
    inventoryPanel:setMarginLeft(5)
    inventoryPanel:setMarginRight(15)  -- Increased right margin to move slots left
    inventoryPanel:setPhantom(false)
    inventoryPanel:setVisible(true)
    
    -- Create equipment slots manually with proper positioning
    createEquipmentSlots()
    
    -- Create backpack container (directly below equipment container)
    local backpackContainer = g_ui.createWidget('Panel', mainPanel)
    backpackContainer:setId('backpackContainer')
    backpackContainer:addAnchor(AnchorTop, 'equipmentContainer', AnchorBottom)
    backpackContainer:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    backpackContainer:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    backpackContainer:addAnchor(AnchorRight, 'parent', AnchorRight)
    backpackContainer:setPadding(3)
    backpackContainer:setBackgroundColor('#00000000')
    backpackContainer:setBorderWidth(0)
    
    -- Create backpack panel - will use anchors to fill container
    backpackPanel = g_ui.createWidget('Panel', backpackContainer)
    backpackPanel:setId('backpackPanel')
    -- Anchor to fill the container
    backpackPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    backpackPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    backpackPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    backpackPanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    backpackPanel:setMargin(3)
    backpackPanel:setPhantom(false)
    backpackPanel:setVisible(true)
    -- Disable clipping to ensure all slots are visible
    if backpackPanel.setClipping then
      backpackPanel:setClipping(false)
    end
    -- Panels are already created as global variables (inventoryPanel, backpackPanel)
  else
    -- Anchor window to center of screen, but move 60 pixels down
    unifiedInventoryWindow:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    unifiedInventoryWindow:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    unifiedInventoryWindow:setMarginTop(60)
    
    -- Move background image 55 pixels up
    local backgroundImage = unifiedInventoryWindow:getChildById('backgroundImage')
    if backgroundImage then
      backgroundImage:setMarginTop(-55)
    end
    
    -- Get panels from loaded UI
    inventoryPanel = unifiedInventoryWindow:getChildById('inventoryPanel')
    backpackPanel = unifiedInventoryWindow:getChildById('backpackPanel')
  end
  
  unifiedInventoryWindow:hide()
  
  -- Verify panels exist
  if not inventoryPanel then
    return -- Exit if critical panel is missing
  end
  
  -- NOW connect events after UI is loaded
  connect(LocalPlayer, {
    onInventoryChange = onInventoryChange
  })
  connect(g_game, {
    onGameStart = function()
      -- Enable ExtendedOpcode feature when game starts (if not already enabled)
      if not g_game.getFeature(GameExtendedOpcode) then
        g_game.enableFeature(GameExtendedOpcode)
      end
      refresh()
    end,
    onClientVersionChange = function(version)
      -- Also enable when client version changes (when connecting to server)
      if not g_game.getFeature(GameExtendedOpcode) then
        g_game.enableFeature(GameExtendedOpcode)
      end
    end,
    onGameEnd = clearBackpack,
    onResourceBalance = onResourceBalance
  })
  connect(Container, {
    onOpen = onContainerOpen,
    onUpdateItem = onContainerUpdateItem,
    onSizeChange = onContainerChangeSize
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
  
  -- Initialize virtual backpack slots
  initializeBackpackSlots()
  
  -- Add button to top menu
  unifiedInventoryButton = modules.client_topmenu.addRightGameToggleButton(
    'unifiedInventoryButton', 
    tr('Unified Inventory'), 
    '/images/landcore/inventory_icon', 
    toggle
  )
  
  if unifiedInventoryButton then
    unifiedInventoryButton:setOn(false)
  end
  
  -- Bind keyboard shortcut
  g_keyboard.bindKeyDown('Ctrl+U', toggle)
  
  -- Update outfit viewer when game starts
  if g_game.isOnline() and LocalPlayer then
    refresh()
    local outfitViewer = unifiedInventoryWindow:getChildById('outfitViewer')
    if outfitViewer then
      outfitViewer:setCreature(LocalPlayer)
    end
  end
end

function terminate()
  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange
  })
  disconnect(g_game, { 
    onGameStart = refresh,
    onClientVersionChange = function(version)
      -- Also enable when client version changes (when connecting to server)
      if not g_game.getFeature(GameExtendedOpcode) then
        g_game.enableFeature(GameExtendedOpcode)
      end
    end,
    onGameEnd = clearBackpack
  })
  disconnect(Container, {
    onOpen = onContainerOpen,
    onUpdateItem = onContainerUpdateItem,
    onSizeChange = onContainerChangeSize
  })
  
  g_keyboard.unbindKeyDown('Ctrl+U')
  
  if unifiedInventoryWindow then
    unifiedInventoryWindow:destroy()
  end
  
  if unifiedInventoryButton then
    unifiedInventoryButton:destroy()
  end
  
  virtualBackpack = {}
end

function createEquipmentSlots()
  if not inventoryPanel then 
    return 
  end
  
  -- Create slots using the exact same styles and positions as the standard inventory
  -- Based on 40-inventory.otui layout
  
  -- Use standard inventory layout with anchors, but adjust shield position
  local slotSize = 34
  
  -- Head slot (slot1) - center top
  local headSlot = g_ui.createWidget('HeadSlot', inventoryPanel)
  headSlot:setId('slot1')
  headSlot:resize(slotSize, slotSize)
  headSlot:addAnchor(AnchorTop, 'parent', AnchorTop)
  headSlot:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  headSlot:setMarginTop(3)
  headSlot:setVisible(true)
  headSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Body slot (slot4) - below head
  local bodySlot = g_ui.createWidget('BodySlot', inventoryPanel)
  bodySlot:setId('slot4')
  bodySlot:resize(slotSize, slotSize)
  bodySlot:addAnchor(AnchorTop, 'slot1', AnchorBottom)
  bodySlot:addAnchor(AnchorHorizontalCenter, 'slot1', AnchorHorizontalCenter)
  bodySlot:setMarginTop(3)
  bodySlot:setVisible(true)
  bodySlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Leg slot (slot7) - below body
  local legSlot = g_ui.createWidget('LegSlot', inventoryPanel)
  legSlot:setId('slot7')
  legSlot:resize(slotSize, slotSize)
  legSlot:addAnchor(AnchorTop, 'slot4', AnchorBottom)
  legSlot:addAnchor(AnchorHorizontalCenter, 'slot4', AnchorHorizontalCenter)
  legSlot:setMarginTop(3)
  legSlot:setVisible(true)
  legSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Feet slot (slot8) - below leg
  local feetSlot = g_ui.createWidget('FeetSlot', inventoryPanel)
  feetSlot:setId('slot8')
  feetSlot:resize(slotSize, slotSize)
  feetSlot:addAnchor(AnchorTop, 'slot7', AnchorBottom)
  feetSlot:addAnchor(AnchorHorizontalCenter, 'slot7', AnchorHorizontalCenter)
  feetSlot:setMarginTop(3)
  feetSlot:setVisible(true)
  feetSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Back slot (slot3) - right of head
  local backSlot = g_ui.createWidget('BackSlot', inventoryPanel)
  backSlot:setId('slot3')
  backSlot:resize(slotSize, slotSize)
  backSlot:addAnchor(AnchorTop, 'slot1', AnchorTop)
  backSlot:addAnchor(AnchorLeft, 'slot1', AnchorRight)
  backSlot:setMarginTop(13)
  backSlot:setMarginLeft(5)
  backSlot:setVisible(true)
  backSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Neck slot (slot2) - left of head
  local neckSlot = g_ui.createWidget('NeckSlot', inventoryPanel)
  neckSlot:setId('slot2')
  neckSlot:resize(slotSize, slotSize)
  neckSlot:addAnchor(AnchorTop, 'slot1', AnchorTop)
  neckSlot:addAnchor(AnchorRight, 'slot1', AnchorLeft)
  neckSlot:setMarginTop(13)
  neckSlot:setMarginRight(5)
  neckSlot:setVisible(true)
  neckSlot:setPhantom(false)
  neckSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Left slot (slot6/shield) - below neck, aligned with slot2 (neck) in left column
  local leftSlot = g_ui.createWidget('LeftSlot', inventoryPanel)
  leftSlot:setId('slot6')
  leftSlot:resize(slotSize, slotSize)
  -- Position it below slot2 (neck) and align with slot2 horizontally
  leftSlot:addAnchor(AnchorTop, 'slot2', AnchorBottom)
  leftSlot:addAnchor(AnchorLeft, 'slot2', AnchorLeft)  -- Align with slot2
  leftSlot:setMarginTop(3)
  leftSlot:setVisible(true)
  leftSlot:setPhantom(false)
  leftSlot:raise()  -- Bring to front to avoid being covered
  leftSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Right slot (slot5) - below back, aligned with slot3 (back) in right column
  local rightSlot = g_ui.createWidget('RightSlot', inventoryPanel)
  rightSlot:setId('slot5')
  rightSlot:resize(slotSize, slotSize)
  rightSlot:addAnchor(AnchorTop, 'slot3', AnchorBottom)
  rightSlot:addAnchor(AnchorLeft, 'slot3', AnchorLeft)  -- Align with slot3
  rightSlot:setMarginTop(3)
  rightSlot:setVisible(true)
  rightSlot:setPhantom(false)
  rightSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Finger slot (slot9) - below left/shield, aligned with slot6 in left column
  local fingerSlot = g_ui.createWidget('FingerSlot', inventoryPanel)
  fingerSlot:setId('slot9')
  fingerSlot:resize(slotSize, slotSize)
  fingerSlot:addAnchor(AnchorTop, 'slot6', AnchorBottom)
  fingerSlot:addAnchor(AnchorLeft, 'slot6', AnchorLeft)  -- Align with slot6
  fingerSlot:setMarginTop(3)
  fingerSlot:setVisible(true)
  fingerSlot:setPhantom(false)
  fingerSlot:raise()  -- Bring to front to avoid being covered
  fingerSlot:setImageSource('/images/landcore/inventoryicon')
  
  -- Ammo slot (slot10) - below right, aligned with slot5 in right column
  local ammoSlot = g_ui.createWidget('AmmoSlot', inventoryPanel)
  ammoSlot:setId('slot10')
  ammoSlot:resize(slotSize, slotSize)
  ammoSlot:addAnchor(AnchorTop, 'slot5', AnchorBottom)
  ammoSlot:addAnchor(AnchorLeft, 'slot5', AnchorLeft)  -- Align with slot5
  ammoSlot:setMarginTop(3)
  ammoSlot:setVisible(true)
  ammoSlot:setPhantom(false)
  ammoSlot:setImageSource('/images/landcore/inventoryicon')
  
end

function initializeBackpackSlots()
  if not backpackPanel then
    return
  end
  
  -- Initialize backpack area with anchored grid positions
  local slotIndex = 0
  local cellSize = 34
  local cellSpacing = 3  -- 3 pixels between slots
  
  local firstSlot = nil
  local previousSlotInRow = nil
  local firstSlotInRow = nil
  
  for row = 0, BACKPACK_ROWS - 1 do
    previousSlotInRow = nil
    firstSlotInRow = nil
    
    for col = 0, BACKPACK_COLUMNS - 1 do
      if slotIndex < TOTAL_BACKPACK_SLOTS then
        local itemWidget = g_ui.createWidget('Item', backpackPanel)
        if not itemWidget then
        else
          itemWidget:setId('backpackSlot' .. slotIndex)
          itemWidget:setItem(nil)
          itemWidget:setMargin(0)
          itemWidget:resize(cellSize, cellSize)
          itemWidget:setPhantom(false)
          itemWidget:setVisible(true)
          itemWidget:setVirtual(false)  -- Use real items from container
          -- Remove border/highlight effect
          itemWidget:setBorderWidth(0)
          if itemWidget.setBorderColor then
            itemWidget:setBorderColor('#00000000')  -- Transparent border
          end
          -- Set background image for slot
          itemWidget:setImageSource('/images/landcore/inventoryicon')
          
          -- First slot of the first row - anchor to top-left of panel
          if slotIndex == 0 then
            -- Add anchors to parent panel (backpackPanel)
            itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
            itemWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            -- Set margins to position at top-left (panel has 3px margin)
            itemWidget:setMarginTop(3)
            itemWidget:setMarginLeft(3)
            -- Disable clipping for slot 0 to ensure it's always visible
            if itemWidget.setClipping then
              itemWidget:setClipping(false)
            end
            firstSlot = itemWidget
            firstSlotInRow = itemWidget
            previousSlotInRow = itemWidget
          -- First slot of each row - anchor to left of panel and below previous row's first slot
          elseif col == 0 then
            if row > 0 then
              local prevRowFirstSlotId = 'backpackSlot' .. (slotIndex - BACKPACK_COLUMNS)
              itemWidget:addAnchor(AnchorTop, prevRowFirstSlotId, AnchorBottom)
              itemWidget:setMarginTop(cellSpacing)
            end
            itemWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            itemWidget:setMarginLeft(3)  -- Match margin of first slot
            firstSlotInRow = itemWidget
            previousSlotInRow = itemWidget
          -- Other slots in row - anchor to right of previous slot
          else
            local prevSlotId = 'backpackSlot' .. (slotIndex - 1)
            itemWidget:addAnchor(AnchorTop, prevSlotId, AnchorTop)
            itemWidget:addAnchor(AnchorLeft, prevSlotId, AnchorRight)
            itemWidget:setMarginLeft(cellSpacing)
            previousSlotInRow = itemWidget
          end
          
          virtualBackpack[slotIndex] = nil
          
          -- Setup drag & drop handlers
          setupBackpackSlotHandlers(itemWidget, slotIndex)
          
          slotIndex = slotIndex + 1
        end
      end
    end
  end
  
  
  -- Ensure slot 0 is on top after all slots are created
  if backpackPanel then
    local slot0Widget = backpackPanel:getChildById('backpackSlot0')
    if slot0Widget then
      -- Move to end of children list by removing and re-adding (ensures it's rendered last/on top)
      local parent = slot0Widget:getParent()
      if parent then
        -- Store slot 0 properties
        local item = slot0Widget:getItem()
        local handlers = slot0Widget.onDrop  -- Store handlers reference
        
        -- Remove from parent and re-add at end
        parent:removeChild(slot0Widget)
        parent:addChild(slot0Widget)
        
        -- Restore item if it existed
        if item then
          slot0Widget:setItem(item)
        end
        
        slot0Widget:raise()
        slot0Widget:setVisible(true)
        slot0Widget:setPhantom(false)
      else
        slot0Widget:raise()
        slot0Widget:setVisible(true)
        slot0Widget:setPhantom(false)
      end
    end
  end
  
end


function setupBackpackSlotHandlers(widget, slotIndex)
  -- Override canAcceptDrop to always accept items (for virtual slots)
  -- Note: UIItem's canAcceptDrop checks if selectable, but we override it
  widget.canAcceptDrop = function(self, droppedWidget, mousePos)
    if not droppedWidget then
      return false
    end
    -- Accept if it's an item widget with currentDragThing (standard OTClient way) or item property
    if (droppedWidget.currentDragThing and droppedWidget.currentDragThing:isItem()) or droppedWidget.item then
      return true
    end
    return false
  end
  
  -- Handle right-click to switch equipment
  -- Store original handlers to call them if needed
  local originalOnMousePress = widget.onMousePress
  local originalOnMouseRelease = widget.onMouseRelease
  
  -- Override onMousePress to intercept right-click BEFORE default processing
  widget.onMousePress = function(self, mousePos, mouseButton)
    -- Button 2 is right button in OTClient
    if mouseButton == 2 or mouseButton == MouseButtonRight then
      -- Just prevent default processing, we'll handle it on release
      return true
    end
    
    -- Call original handler if it exists
    if originalOnMousePress then
      return originalOnMousePress(self, mousePos, mouseButton)
    end
    return false
  end
  
  -- Also override onMouseRelease as fallback
  widget.onMouseRelease = function(self, mousePos, mouseButton)
    -- Button 2 is right button in OTClient
    if mouseButton == 2 or mouseButton == MouseButtonRight then
      -- Get item from widget or from virtual backpack
      local item = widget:getItem()
      if not item then
        item = virtualBackpack[slotIndex]
      end
      
      if item and item:isItem() then
        switchEquipment(item)
        -- Return true to prevent default processing
        return true
      else
      end
    end
    
    -- Call original handler if it exists
    if originalOnMouseRelease then
      return originalOnMouseRelease(self, mousePos, mouseButton)
    end
    return false
  end
  
  -- Handle item drop on backpack slot
  widget.onDrop = function(self, droppedWidget, mousePos, forced)
    if not droppedWidget then
      return false
    end
    
    -- Get item from currentDragThing (standard OTClient way) or item property
    local item = nil
    if droppedWidget.currentDragThing and droppedWidget.currentDragThing:isItem() then
      item = droppedWidget.currentDragThing
    elseif droppedWidget.item then
      item = droppedWidget.item
    end
    
    if not item then
      return false
    end
    
    local currentItem = virtualBackpack[slotIndex]
    
    -- Find where the dropped item came from (if it's already in backpack)
    local sourceSlot = findItemInBackpack(item)
    
    -- If slot is empty, accept the item
    if not currentItem then
      -- Check if item is being moved within the virtual inventory container
      if sourceSlot and sourceSlot ~= slotIndex then
        -- Item is being moved from one slot to another within virtual inventory
        local virtualInventoryContainer = g_game.getContainer(14)
        if not virtualInventoryContainer then
          for i = 0, 15 do
            local testContainer = g_game.getContainer(i)
            if testContainer and testContainer:getCapacity() == 121 then
              virtualInventoryContainer = testContainer
              break
            end
          end
        end
        
        if virtualInventoryContainer then
          -- Get the item from the container at source slot
          local sourceItemInContainer = virtualInventoryContainer:getItem(sourceSlot)
          if sourceItemInContainer then
            -- Move item within the same container to the new slot
            local virtualPos = {x = 0xFFFF, y = 0x4E, z = 0}
            g_game.move(sourceItemInContainer, virtualPos, slotIndex)
            -- Items will be updated via onContainerUpdateItem (like physical backpack)
            return true
          end
        end
        
        -- Fallback: remove from source slot and let server sync handle it
        setBackpackItem(sourceSlot, nil)
        return true
      else
        -- Item came from outside virtual backpack
        -- Try to move the item to server's virtual inventory container
        local player = g_game.getLocalPlayer()
        if player then
          -- Get virtual inventory container (container ID 14 or find by capacity 121)
          local virtualInventoryContainer = g_game.getContainer(14)
          if not virtualInventoryContainer then
            -- Try to find by capacity
            for i = 0, 15 do
              local testContainer = g_game.getContainer(i)
              if testContainer and testContainer:getCapacity() == 121 then
                virtualInventoryContainer = testContainer
                break
              end
            end
          end
          
          if virtualInventoryContainer then
            -- Container is open, move item directly
            local itemPos = item:getPosition()
            
            -- Create a position for the virtual inventory container
            -- Use a special position that represents the virtual inventory (container ID 0xE = 14)
            -- 0x4E = 0x40 | 0xE (bitwise OR: 64 | 14 = 78)
            local virtualPos = {x = 0xFFFF, y = 0x4E, z = 0}
            
            if itemPos and itemPos.x ~= 65535 then  -- Valid position (not from inventory slot)
              -- Item from ground or other container, move to virtual inventory
              -- Use the target slot index directly
              if item:getCount() > 1 then
                modules.game_interface.moveStackableItem(item, virtualPos)
              else
                g_game.move(item, virtualPos, slotIndex)
              end
              -- Items will be updated via onContainerUpdateItem (like physical backpack)
            else
              -- Item is from inventory slot (equipment), move to virtual inventory
              -- Use the target slot index directly
              g_game.move(item, virtualPos, slotIndex)
              -- Items will be updated via onContainerUpdateItem (like physical backpack)
            end
          else
            -- Container not open yet, request it and queue the move
            openVirtualInventoryFromServer()
            table.insert(pendingMoves, {
              item = item,
              containerId = 14,  -- Container ID for virtual inventory
              slotIndex = slotIndex,
              isEquipped = (item:getPosition().x == 65535)
            })
          end
        end
        
        -- Check if we're trying to move the item to real backpack
        local itemPos = item:getPosition()
        local isMovingToBackpack = false
        
        if player then
          local backpack = player:getInventoryItem(InventorySlotBack)
          if backpack and backpack:isContainer() then
            -- If item is from inventory slot (x = 65535) or from valid position, we're moving it
            if (itemPos and itemPos.x == 65535) or (itemPos and itemPos.x ~= 65535) then
              local backpackContainer = g_game.getContainer(backpack:getId())
              if backpackContainer or not backpackContainer then  -- We're trying to move it
                isMovingToBackpack = true
                -- Don't add virtual copy yet - wait for sync
                return true
              end
            end
          end
        end
        
        -- Don't create virtual copy - wait for server sync to use real item from container
        -- Items will be updated via onContainerUpdateItem (like physical backpack)
        return true
      end
    end
    
    -- If slot has item, swap items in container
    if currentItem then
      if sourceSlot and sourceSlot ~= slotIndex then
        -- Swap items in virtual inventory container
        local virtualInventoryContainer = g_game.getContainer(14)
        if not virtualInventoryContainer then
          for i = 0, 15 do
            local testContainer = g_game.getContainer(i)
            if testContainer and testContainer:getCapacity() == 121 then
              virtualInventoryContainer = testContainer
              break
            end
          end
        end
        
        if virtualInventoryContainer then
          -- Get items from container
          local currentItemInContainer = virtualInventoryContainer:getItem(slotIndex)
          local sourceItemInContainer = virtualInventoryContainer:getItem(sourceSlot)
          
          if currentItemInContainer and sourceItemInContainer then
            -- Swap items in container
            local virtualPos = {x = 0xFFFF, y = 0x4E, z = 0}
            g_game.move(currentItemInContainer, virtualPos, sourceSlot)
            -- Move second item with minimal delay, then sync
            scheduleEvent(function()
              g_game.move(sourceItemInContainer, virtualPos, slotIndex)
              -- Sync after a short delay to allow server to process both moves
              scheduleEvent(function()
                -- Items will be updated via onContainerUpdateItem (like physical backpack)
              end, 100)
            end, 50)
            return true
          end
        end
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

-- Open virtual inventory container from server
function openVirtualInventoryFromServer()
  if not g_game.isOnline() then
    return
  end
  
  -- Try to enable ExtendedOpcode if not enabled
  if not g_game.getFeature(GameExtendedOpcode) then
    g_game.enableFeature(GameExtendedOpcode)
    -- Check again after enabling
    if not g_game.getFeature(GameExtendedOpcode) then
      return
    end
  end
  
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end
  
  -- Request server to open virtual inventory via extended opcode
  protocolGame:sendExtendedOpcode(0x01, "openVirtualInventory")
  
  -- Check if container opens after a delay
  scheduleEvent(function()
    -- Try to get container by ID 14 (0xE) or find by capacity
    local container = g_game.getContainer(14)  -- Container ID used by server
    if not container then
      -- Try to find by capacity (121 slots is unique to virtual inventory)
      for i = 0, 15 do
        local testContainer = g_game.getContainer(i)
        if testContainer and testContainer:getCapacity() == 121 then
          container = testContainer
          break
        end
      end
    end
    if container then
      refreshVirtualInventoryItems(container)
    end
  end, 500)
end

function isVisible()
  return unifiedInventoryWindow and unifiedInventoryWindow:isVisible()
end

function toggle()
  -- Request server to open virtual inventory
  openVirtualInventoryFromServer()
  
  if not unifiedInventoryButton then
    return
  end
  
  if not unifiedInventoryWindow then
    return
  end
  
  if unifiedInventoryButton:isOn() then
    -- Remove shader when closing
    local backgroundImage = unifiedInventoryWindow:getChildById('backgroundImage')
    if backgroundImage then
      if backgroundImage.setImageShader then
        backgroundImage:setImageShader("")
      elseif backgroundImage.setBackgroundShader then
        backgroundImage:setBackgroundShader("")
      end
    end
    unifiedInventoryWindow:hide()
    unifiedInventoryButton:setOn(false)
  else
    if unifiedInventoryWindow then
      -- Ensure window is anchored to center (in case it was moved), 60 pixels down
      local rootPanel = modules.game_interface.getRootPanel()
      if rootPanel then
        unifiedInventoryWindow:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
        unifiedInventoryWindow:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
        unifiedInventoryWindow:setMarginTop(60)
      end
      
      -- Start fade in animation (like minimap)
      unifiedInventoryWindow:setOpacity(0)
      unifiedInventoryWindow:setVisible(true)
      unifiedInventoryWindow:show()
      unifiedInventoryWindow:raise()
      unifiedInventoryWindow:focus()
      
      -- Apply shader to backgroundImage (on top of the background image)
      scheduleEvent(function()
        local backgroundImage = unifiedInventoryWindow:getChildById('backgroundImage')
        if backgroundImage then
          -- Apply shader to the image itself (using ui_blood shader optimized for UI widgets)
          if backgroundImage.setImageShader then
            backgroundImage:setImageShader("ui_blood")
          -- Fallback to background shader if image shader doesn't exist
          elseif backgroundImage.setBackgroundShader then
            backgroundImage:setBackgroundShader("ui_blood")
            if backgroundImage.setBackgroundColor then
              backgroundImage:setBackgroundColor("#000000")
            end
          end
        end
      end, 10)
      
      -- Fade in animation
      local fadeDuration = 300  -- 300ms fade duration
      local startTime = g_clock.millis()
      local startOpacity = 0
      local targetOpacity = 1.0
      local steps = 30
      local stepDuration = fadeDuration / steps
      
      -- Easing function for smooth animation (ease-in-out)
      local function easeInOut(t)
        return t * t * (3.0 - 2.0 * t)
      end
      
      local function animate()
        if not unifiedInventoryWindow or not unifiedInventoryWindow:isVisible() then
          return  -- Stop if window was closed
        end
        
        local elapsed = g_clock.millis() - startTime
        local progress = math.min(elapsed / fadeDuration, 1.0)
        
        -- Apply easing for smooth animation
        local easedProgress = easeInOut(progress)
        
        -- Interpolate opacity with easing
        local currentOpacity = startOpacity + (targetOpacity - startOpacity) * easedProgress
        unifiedInventoryWindow:setOpacity(currentOpacity)
        
        if progress < 1.0 then
          scheduleEvent(animate, stepDuration)
        else
          -- Ensure full opacity at the end
          unifiedInventoryWindow:setOpacity(1.0)
        end
      end
      
      scheduleEvent(animate, stepDuration)
      
      -- Force update slot 0 visibility when opening window
      scheduleEvent(function()
        if backpackPanel then
          local slot0Widget = backpackPanel:getChildById('backpackSlot0')
          if slot0Widget then
            slot0Widget:setVisible(true)
            slot0Widget:setPhantom(false)
            slot0Widget:raise()
            local item = virtualBackpack[0]
            if item then
              slot0Widget:setItem(item)
            end
          end
        end
      end, 100)
      
      -- Update outfit viewer when opening window
      local outfitViewer = unifiedInventoryWindow:recursiveGetChildById('outfitViewer')
      if outfitViewer then
        local player = g_game.getLocalPlayer()
        if g_game.isOnline() and player then
          outfitViewer:setCreature(player)
        end
      end
      
      -- Request virtual inventory from server and sync when opening
      openVirtualInventoryFromServer()
      scheduleEvent(function()
        -- Try to sync from virtual inventory container first, fallback to real backpack
        local virtualInventoryContainer = g_game.getContainer(14)  -- Container ID for virtual inventory
        if virtualInventoryContainer then
          refreshVirtualInventoryItems(virtualInventoryContainer)
        else
          scheduleEvent(syncBackpackFromContainer, 200)
        end
      end, 300)
      
    end
    unifiedInventoryButton:setOn(true)
    refresh()
  end
end

function onMiniWindowClose()
  -- Remove shader when closing
  if unifiedInventoryWindow then
    local backgroundImage = unifiedInventoryWindow:getChildById('backgroundImage')
    if backgroundImage then
      if backgroundImage.setImageShader then
        backgroundImage:setImageShader("")
      elseif backgroundImage.setBackgroundShader then
        backgroundImage:setBackgroundShader("")
      end
    end
  end
  
  if unifiedInventoryButton then
    unifiedInventoryButton:setOn(false)
  end
end

function refresh()
  if not g_game.isOnline() then
    return
  end
  
  if not inventoryPanel then
    return
  end
  
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end
  
  -- Update outfit viewer
  if unifiedInventoryWindow then
    local outfitViewer = unifiedInventoryWindow:recursiveGetChildById('outfitViewer')
    if outfitViewer then
      outfitViewer:setCreature(player)
    end
  end

  -- Update bank gold display
  updateBankGoldDisplay()
  
  -- Refresh equipment slots
  for slot = InventorySlotFirst, InventorySlotLast do
    local item = player:getInventoryItem(slot)
    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if itemWidget then
      if item then
        -- Item is equipped, show it
        itemWidget:setItem(item)
        itemWidget:setVisible(true)
        itemWidget:setPhantom(false)
      else
        -- Slot is empty, item widget already has the slot image from OTUI
        itemWidget:setItem(nil)
        itemWidget:setVisible(true)  -- Make sure empty slots are visible too
        itemWidget:setPhantom(false)
      end
    else
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
    
    -- When an item is equipped, sync the virtual inventory container immediately
    -- This ensures that if the item came from the virtual inventory, it's removed from the display
    local virtualInventoryContainer = g_game.getContainer(14)
    if not virtualInventoryContainer then
      for j = 0, 15 do
        local testContainer = g_game.getContainer(j)
        if testContainer and testContainer:getCapacity() == 121 then
          virtualInventoryContainer = testContainer
          break
        end
      end
    end
    if virtualInventoryContainer then
      -- Use a small delay to allow server to process the equip action first
      scheduleEvent(function()
        refreshVirtualInventoryItems(virtualInventoryContainer)
      end, 50)
    end
  else
    -- Slot is empty, item widget already has the slot image from OTUI
    itemWidget:setItem(nil)
  end
end

function clearBackpack()
  -- Check if panels exist
  if not backpackPanel then
    return
  end
  
  -- Clear all virtual backpack slots
  for i = 0, TOTAL_BACKPACK_SLOTS - 1 do
    local widget = nil
    if backpackPanel then
      widget = backpackPanel:getChildById('backpackSlot' .. i)
    end
    
    if widget then
      widget:setItem(nil)
      widget:setVisible(true)  -- Keep slot visible even when empty
      widget:setPhantom(false)
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
  if not backpackPanel then
    return false
  end
  
  local widget = backpackPanel:getChildById('backpackSlot' .. slot)
  
  if widget then
    if item then
      widget:setItem(item)
      widget:setVisible(true)
      widget:setPhantom(false)
      -- Special check for slot 0 to ensure it's visible
      if slot == 0 then
        widget:raise()  -- Bring to front
        widget:setVisible(true)
        widget:setPhantom(false)
        
        -- Force immediate update with a small delay to ensure rendering
        scheduleEvent(function()
          if widget and widget:getParent() then
            widget:raise()
            widget:setVisible(true)
            widget:setPhantom(false)
            -- Re-set the item to force a refresh
            widget:setItem(item)
            
          end
        end, 10)  -- Very short delay to ensure widget is ready
      else
        -- Only log non-slot-0 items if there's an issue
      end
    else
      widget:setItem(nil)
      widget:setVisible(true)  -- Keep slot visible even when empty
      widget:setPhantom(false)
      
      -- Special check for slot 0 to ensure it's updated when cleared
      if slot == 0 then
        widget:raise()  -- Bring to front
        widget:setVisible(true)
        widget:setPhantom(false)
        
        -- Force immediate update with a small delay to ensure rendering
        scheduleEvent(function()
          if widget and widget:getParent() then
            widget:raise()
            widget:setVisible(true)
            widget:setPhantom(false)
            -- Ensure item is cleared
            widget:setItem(nil)
            
          end
        end, 10)  -- Very short delay to ensure widget is ready
      end
    end
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

-- Sync virtual backpack with player's real backpack container
function syncBackpackFromContainer()
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end
  
  local backpack = player:getInventoryItem(InventorySlotBack)
  if not backpack or not backpack:isContainer() then
    return
  end
  
  local container = g_game.getContainer(backpack:getId())
  if not container then
    return
  end
  
  -- Clear virtual backpack first
  clearBackpack()
  
  -- Copy items from real backpack to virtual backpack
  local slotIndex = 0
  for i = 0, container:getCapacity() - 1 do
    if slotIndex >= TOTAL_BACKPACK_SLOTS then
      break
    end
    
    local item = container:getItem(i)
    if item then
      setBackpackItem(slotIndex, item)
      slotIndex = slotIndex + 1
    end
  end
  
end

-- Sync virtual backpack with server's virtual inventory container
-- Uses the same simple approach as syncBackpackFromContainer (physical backpack)
-- Handle container open event
function onContainerOpen(container, previousContainer)
  if not container then
    return
  end
  
  local containerId = container:getId()
  
  -- Check if this is the virtual inventory container from server
  -- Container ID 14 (0xE) is used for virtual inventory, or check by capacity (121 slots)
  if containerId == 14 or container:getCapacity() == 121 then
    -- Ensure slots are created (like physical backpack does)
    if not backpackPanel then
      return
    end
    
    -- Fix slots using the same method as physical backpack
    -- In physical backpack, slots are created/updated when container opens
    for slot = 0, container:getCapacity() - 1 do
      if slot >= TOTAL_BACKPACK_SLOTS then break end
      local itemWidget = backpackPanel:getChildById('backpackSlot' .. slot)
      if itemWidget then
        -- For slot 0, use anchors instead of position (to keep it fixed in top-left)
        if slot == 0 then
          -- Don't set position for slot 0, use anchors instead
          itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
          itemWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
          itemWidget:setMarginTop(3)
          itemWidget:setMarginLeft(3)
        else
          -- For other slots, use container's slot position (like physical backpack)
          local slotPos = container:getSlotPosition(slot)
          if slotPos then
            itemWidget.position = slotPos
          end
        end
        
        -- Ensure slot is visible and properly set
        itemWidget:setVisible(true)
        itemWidget:setPhantom(false)
        itemWidget:setVirtual(false)
        -- Remove border/highlight effect
        itemWidget:setBorderWidth(0)
        if itemWidget.setBorderColor then
          itemWidget:setBorderColor('#00000000')  -- Transparent border
        end
        
        if slot == 0 then
          itemWidget:raise()
        end
      end
    end
    
    -- Process any pending moves for virtual inventory
    for i = #pendingMoves, 1, -1 do
      local move = pendingMoves[i]
      if move and move.containerId == 14 then
        local item = move.item
        if item then
          -- Move item to virtual inventory container
          -- 0x4E = 0x40 | 0xE (bitwise OR: 64 | 14 = 78) - Container ID 0xE (14)
          local virtualPos = {x = 0xFFFF, y = 0x4E, z = 0}
          if item:getCount() > 1 then
            modules.game_interface.moveStackableItem(item, virtualPos)
          else
            g_game.move(item, virtualPos, move.slotIndex)
          end
        end
        table.remove(pendingMoves, i)
      end
    end
    
    -- Hide the container window if our unified inventory is open (we show it in our window instead)
    if unifiedInventoryWindow and unifiedInventoryWindow:isVisible() then
      local containerWindow = modules.game_interface.getContainerPanel():getChildById('container' .. container:getId())
      if containerWindow then
        containerWindow:hide()
      end
    end
    
    -- Refresh items using the same method as physical backpack
    refreshVirtualInventoryItems(container)
    
    return
  end
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end
  
  local backpack = player:getInventoryItem(InventorySlotBack)
  if backpack and backpack:isContainer() and container:getId() == backpack:getId() then
    
    -- Process any pending moves for virtual inventory
    for i = #pendingMoves, 1, -1 do
      local move = pendingMoves[i]
      if move and move.containerId == 14 then
        local item = move.item
        if item then
          -- Move item to virtual inventory container
          -- 0x4E = 0x40 | 0xE (bitwise OR: 64 | 14 = 78) - Container ID 0xE (14)
          local virtualPos = {x = 0xFFFF, y = 0x4E, z = 0}
          if item:getCount() > 1 then
            modules.game_interface.moveStackableItem(item, virtualPos)
          else
            g_game.move(item, virtualPos, move.slotIndex)
          end
        end
        table.remove(pendingMoves, i)
      elseif move and move.backpackId == container:getId() then
        local item = move.item
        if item then
          -- Move item to backpack
          if item:getCount() > 1 then
            modules.game_interface.moveStackableItem(item, backpack:getPosition())
          else
            g_game.move(item, backpack:getPosition(), 1)
          end
        end
        table.remove(pendingMoves, i)
      end
    end
    
    -- Player's backpack was opened, sync virtual backpack
    scheduleEvent(syncBackpackFromContainer, 200)
    
    -- Hide the backpack window if our unified inventory is open (we show it in our window instead)
    if unifiedInventoryWindow and unifiedInventoryWindow:isVisible() then
      scheduleEvent(function()
              local containerWindow = modules.game_interface.getContainerPanel():getChildById('container' .. container:getId())
              if containerWindow then
                containerWindow:hide()
              end
      end, 50)
    end
  end
end

-- Handle container item update event
-- EXACT copy from physical backpack containers.lua
function onContainerUpdateItem(container, slot, item, oldItem)
  local containerId = container:getId()
  
  -- Check if this is the virtual inventory container (ID 14 or capacity 121)
  if containerId == 14 or container:getCapacity() == 121 then
    if not backpackPanel then return end
    local itemWidget = backpackPanel:getChildById('backpackSlot' .. slot)
    if itemWidget then
      itemWidget:setItem(item)
      virtualBackpack[slot] = item
      -- Remove border/highlight effect
      itemWidget:setBorderWidth(0)
      if itemWidget.setBorderColor then
        itemWidget:setBorderColor('#00000000')  -- Transparent border
      end
    end
    return
  end
  
  -- Check if this is the player's real backpack
  local player = g_game.getLocalPlayer()
  if player then
    local backpack = player:getInventoryItem(InventorySlotBack)
    if backpack and backpack:isContainer() and containerId == backpack:getId() then
      -- Player's backpack was updated, sync virtual backpack
      scheduleEvent(syncBackpackFromContainer, 100)
    end
  end
end

-- Handle container size change event
-- EXACT copy from physical backpack containers.lua
function onContainerChangeSize(container, size)
  local containerId = container:getId()
  
  -- Check if this is the virtual inventory container (ID 14 or capacity 121)
  if containerId == 14 or container:getCapacity() == 121 then
    if not backpackPanel then return end
    refreshVirtualInventoryItems(container)
    return
  end
end

-- Refresh all virtual inventory items
-- EXACT copy from physical backpack refreshContainerItems, adapted for virtual inventory
function refreshVirtualInventoryItems(container)
  if not backpackPanel then return end
  
  for slot = 0, container:getCapacity() - 1 do
    if slot >= TOTAL_BACKPACK_SLOTS then break end
    local itemWidget = backpackPanel:getChildById('backpackSlot' .. slot)
    if itemWidget then
      local item = container:getItem(slot)
      itemWidget:setItem(item)
      virtualBackpack[slot] = item
      -- Remove border/highlight effect
      itemWidget:setBorderWidth(0)
      if itemWidget.setBorderColor then
        itemWidget:setBorderColor('#00000000')  -- Transparent border
      end
    end
  end
end

-- Switch equipment: right-click on item in virtual inventory to swap with equipped item
function switchEquipment(item)
  if not item or not item:isItem() then
    return
  end

  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  -- Get virtual inventory container to find which slot the item is in
  local virtualInventoryContainer = g_game.getContainer(14)
  if not virtualInventoryContainer then
    for i = 0, 15 do
      local testContainer = g_game.getContainer(i)
      if testContainer and testContainer:getCapacity() == 121 then
        virtualInventoryContainer = testContainer
        break
      end
    end
  end

  if not virtualInventoryContainer then
    return
  end

  -- Find the slot where this item is in the virtual inventory
  local itemSlot = nil
  for i = 0, virtualInventoryContainer:getCapacity() - 1 do
    local containerItem = virtualInventoryContainer:getItem(i)
    if containerItem and containerItem:getId() == item:getId() then
      itemSlot = i
      break
    end
  end

  if not itemSlot then
    return
  end

  -- Use extended opcode to request server to equip the item
  -- Format: "equipItem:<slotIndex>"
  local containerId = virtualInventoryContainer:getId()
  local slotIndex = itemSlot
  g_game.getProtocolGame():sendExtendedOpcode(0x02, "equipItem:" .. slotIndex)
end

function onResourceBalance(type, balance)
  if type == 0 then -- bank gold
    bankGold = balance
    updateBankGoldDisplay()
  end
end

function updateBankGoldDisplay()
  if not bankGoldLabel or not unifiedInventoryWindow then
    return
  end

  local formattedGold = comma_value(bankGold)
  bankGoldLabel:setText("Bank: " .. formattedGold .. " gold")
end


