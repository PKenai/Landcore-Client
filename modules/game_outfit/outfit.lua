PlayerCustom = {}

local protocol = runinsandbox("protocol")
local window, outfitsPanel, mountPanel, customizationPanel
local hairPanel, helmetPanel, armorPanel, shirtPanel, pantsPanel, bootsPanel, leftHandPanel, rightHandPanel
local PlayerCustomize = {}
local pendingMounts
local pendingPaperdoll

local colorModeGroup = nil
local colorBoxGroup = nil
local currentColorMode = "head"
local paperdollColorGroups = {}
local currentPaperdollSlot = ""

-- CRITICAL: Separate storage for paperdoll colors to prevent loss from server updates
local savedPaperdollColors = {}
local function hasGamePlayerMounts()
  return g_game.getFeature and g_game.getFeature(GamePlayerMounts)
end

local function parseOutfits(list)
  if not outfitsPanel or not outfitsPanel.list then 
    return 
  end
  for i, value in ipairs(list) do
    local button = g_ui.createWidget("PanelCustomOutfit", outfitsPanel.list)
    local cleanOutfit = table.copy(PlayerCustomize.outfit)
    cleanOutfit.type = value[1]
    cleanOutfit.mount = 0
    cleanOutfit.hair = 0
    cleanOutfit.helmet = 0
    cleanOutfit.armor = 0
    cleanOutfit.shirt = 0
    cleanOutfit.pants = 0
    cleanOutfit.boots = 0
    cleanOutfit.gloves = 0
    cleanOutfit.belt = 0
    cleanOutfit.necklace = 0
    cleanOutfit.ringLeft = 0
    cleanOutfit.ringRight = 0
    cleanOutfit.leftHand = 0
    cleanOutfit.rightHand = 0
    cleanOutfit.backpack = 0
    cleanOutfit.cloak = 0
    button:setId(cleanOutfit.type)
    button:setTooltip(value[2])
    button.outfit:setOutfit(cleanOutfit)
  end
  local panelButton = outfitsPanel.list[PlayerCustomize.outfit.type]
  if panelButton then
    panelButton:focus()
    onOutfitSelect(panelButton)
  end
  outfitsPanel.scroll:setVisible(#list > 15)
end

local function parseMounts(mounts)
  if not mountPanel or not mountPanel.list then return end
  
  mountPanel.list:destroyChildren()
  
  local nonePanel = g_ui.createWidget('PanelCustomMount', mountPanel.list)
  nonePanel.mount:setOutfit({type = 0})
  nonePanel:setId(0)
  nonePanel:setTooltip("Sem Mount")
  
  for i, mountData in ipairs(mounts) do
    local panel = g_ui.createWidget('PanelCustomMount', mountPanel.list)
    
    local mountId = mountData[1]
    local mountName = mountData[2]
    
    panel.mount:setOutfit({type = mountId})
    panel:setId(mountId)
    panel:setTooltip(mountName or "Mount " .. mountId)
  end
  
  local currentMountId = PlayerCustomize.outfit.mount or 0
  local selectedPanel = mountPanel.list[currentMountId]
  if selectedPanel then
    selectedPanel:focus()
    onMountSelect(selectedPanel)
  end
  
  mountPanel.scroll:setVisible(#mounts > 6)
end

local function onTabChange(tabBar, tab)
  local selectedTabId = tab.tabPanel:getId()
  
  if selectedTabId == "outfitsPanel" then
    local panelButton = outfitsPanel.list:getFocusedChild()
    outfitsPanel.list:ensureChildVisible(panelButton)
    onOutfitSelect(panelButton)
  elseif selectedTabId == "mountPanel" then
    updatePreview()
  elseif selectedTabId == "customizationPanel" then
    updateCustomizationInterface()
  elseif selectedTabId == "hairPanel" then
    currentPaperdollSlot = "hair"
    initPaperdollColors("hair", hairPanel)
  elseif selectedTabId == "helmetPanel" then
    currentPaperdollSlot = "helmet"
    initPaperdollColors("helmet", helmetPanel)
  elseif selectedTabId == "armorPanel" then
    currentPaperdollSlot = "armor"
    initPaperdollColors("armor", armorPanel)
  elseif selectedTabId == "shirtPanel" then
    currentPaperdollSlot = "shirt"
    initPaperdollColors("shirt", shirtPanel)
  elseif selectedTabId == "pantsPanel" then
    currentPaperdollSlot = "pants"
    initPaperdollColors("pants", pantsPanel)
  elseif selectedTabId == "bootsPanel" then
    currentPaperdollSlot = "boots"
    initPaperdollColors("boots", bootsPanel)
  elseif selectedTabId == "leftHandPanel" then
    currentPaperdollSlot = "leftHand"
    initPaperdollColors("leftHand", leftHandPanel)
  elseif selectedTabId == "rightHandPanel" then
    currentPaperdollSlot = "rightHand"
    initPaperdollColors("rightHand", rightHandPanel)
  end
  updatePreview()
end

local function onMounts(mounts)
  if not mountPanel then
    pendingMounts = mounts
    return
  end
  parseMounts(mounts)
end

local function parsePaperdollItems(slotName, items, panel)
  if not panel or not panel.list then return end
  
  panel.list:destroyChildren()
  
  -- Get the correct widget type for each panel
  local widgetType = "PanelCustom" .. slotName:gsub("^%l", string.upper)
  
  -- Convert table to array for iteration (handle string keys)
  local itemArray = {}
  for itemId, item in pairs(items) do
    -- Ensure id is numeric for proper handling
    item.id = tonumber(itemId) or tonumber(item.id) or 0
    table.insert(itemArray, item)
  end
  
  -- Sort by id for consistent ordering
  table.sort(itemArray, function(a, b) return a.id < b.id end)
  
  for _, item in ipairs(itemArray) do
    local button = g_ui.createWidget(widgetType, panel.list)
    if button then 
      button:setId(item.looktype)
      
      -- Set tooltip with price if not unlocked
      local tooltipText = item.name
      if not item.unlocked and item.price then
        tooltipText = item.name .. " (" .. item.price .. " gold coins)"
      end
      button:setTooltip(tooltipText)
      
      -- Set the outfit/looktype if the item has one
      if item.looktype and item.looktype > 0 and button.outfit then
        local cleanOutfit = table.copy(PlayerCustomize.outfit)
        cleanOutfit.type = item.looktype
        cleanOutfit.mount = 0
        cleanOutfit.hair = 0
        cleanOutfit.helmet = 0
        cleanOutfit.armor = 0
        cleanOutfit.shirt = 0
        cleanOutfit.pants = 0
        cleanOutfit.boots = 0
        cleanOutfit.gloves = 0
        cleanOutfit.belt = 0
        cleanOutfit.necklace = 0
        cleanOutfit.ringLeft = 0
        cleanOutfit.ringRight = 0
        cleanOutfit.leftHand = 0
        cleanOutfit.rightHand = 0
        cleanOutfit.backpack = 0
        cleanOutfit.cloak = 0
        
        -- Set only the specific paperdoll for this slot with saved color
        cleanOutfit[slotName] = item.looktype
        local savedColor = PlayerCustomize.paperdollParts and PlayerCustomize.paperdollParts[slotName .. "Color"] or 20
        cleanOutfit[slotName .. "Color"] = savedColor
        
        button.outfit:setOutfit(cleanOutfit)
      end
      
      if not item.unlocked then
        button:setOpacity(0.6)
      end
      
      -- Check if this item is currently selected
      local currentItem = 0
      if PlayerCustomize.paperdollParts and PlayerCustomize.paperdollParts[slotName] then
        currentItem = PlayerCustomize.paperdollParts[slotName]
      elseif PlayerCustomize.outfit and PlayerCustomize.outfit[slotName] then
        currentItem = PlayerCustomize.outfit[slotName]
      end
      
      if currentItem > 0 and currentItem == item.looktype then
        button:focus()
        button:setChecked(true)
      end
      
      button.itemData = item
      button.slotName = slotName
      
      button.onClick = function() onPaperdollItemSelect(button) end
    else
      print("ERROR: Failed to create " .. widgetType .. " widget for " .. slotName)
    end
  end
  
  panel.scroll:setVisible(#itemArray > 15)
end

local function onPaperdoll(paperdollData)
  if not hairPanel or not helmetPanel then
    pendingPaperdoll = paperdollData
    return
  end
  
  -- Se é uma atualização de item individual
  if paperdollData.action == "update" and paperdollData.slotName and paperdollData.itemId then
    local slotData = PlayerCustomize.paperdollData and PlayerCustomize.paperdollData[paperdollData.slotName]
    if slotData and slotData[tostring(paperdollData.itemId)] then
      slotData[tostring(paperdollData.itemId)].unlocked = paperdollData.unlocked or true
      
      -- Refresh the current panel with correct panel mapping
      local panelMapping = {
        hair = hairPanel,
        helmet = helmetPanel,
        armor = armorPanel,
        shirt = shirtPanel,
        pants = pantsPanel,
        boots = bootsPanel,
        leftHand = leftHandPanel,
        rightHand = rightHandPanel
      }
      
      local panel = panelMapping[paperdollData.slotName]
      if panel then
        parsePaperdollItems(paperdollData.slotName, slotData, panel)
        -- Reapply colors after updating the panel
        scheduleEvent(function()
          updatePaperdollColorSelection(paperdollData.slotName, panel)
        end, 50)
      end
    end
    return
  end
  
  -- Se são dados completos do paperdoll
  if paperdollData then
    local slotNames = {}
    for slotName, _ in pairs(paperdollData) do
      if slotName ~= "savedColors" then
        table.insert(slotNames, slotName)
      end
    end
    
    -- Apply server saved colors if received
    if paperdollData.savedColors then
      if not PlayerCustomize.paperdollParts then
        PlayerCustomize.paperdollParts = {}
      end
      
      -- Apply all server colors to paperdollParts
      for colorKey, colorValue in pairs(paperdollData.savedColors) do
        PlayerCustomize.paperdollParts[colorKey] = colorValue
        -- Also save to local storage to maintain compatibility
        savedPaperdollColors[colorKey] = colorValue
      end
      
      -- Remove savedColors from paperdollData before processing slots
      paperdollData.savedColors = nil
    end
    
    PlayerCustomize.paperdollData = paperdollData
    
    -- Refresh all panels with correct panel mapping
    local panelMapping = {
      hair = hairPanel,
      helmet = helmetPanel,
      armor = armorPanel,
      shirt = shirtPanel,
      pants = pantsPanel,
      boots = bootsPanel,
      leftHand = leftHandPanel,
      rightHand = rightHandPanel
    }
    
    for slotName, items in pairs(paperdollData) do
      local panel = panelMapping[slotName]
      if items and panel then
        parsePaperdollItems(slotName, items, panel)
        
        -- Only reapply colors if the panel has color groups initialized
        scheduleEvent(function()
          if paperdollColorGroups[slotName] then
            updatePaperdollColorSelection(slotName, panel)
          end
        end, 50)
      end
    end
  end
end

local function parsePaperdollHair(hairData)
  if not hairPanel or not hairPanel.list then return end
  
  hairPanel.list:destroyChildren()
  
  local noneButton = g_ui.createWidget("PanelCustomHair", hairPanel.list)
  noneButton:setId(0)
  noneButton:setTooltip("No Hair")
  
  -- Check if no hair is selected
  local currentHair = 0
  if PlayerCustomize.paperdollParts and PlayerCustomize.paperdollParts.hair then
    currentHair = PlayerCustomize.paperdollParts.hair
  elseif PlayerCustomize.outfit and PlayerCustomize.outfit.hair then
    currentHair = PlayerCustomize.outfit.hair
  end
  
  if currentHair == 0 then
    noneButton:focus()
    noneButton:setChecked(true)
  end
  
  noneButton.itemData = {id = 0, name = "No Hair", looktype = 0, unlocked = true, price = 0}
  noneButton.slotName = "hair"
  noneButton.onClick = function() 
    if PlayerCustomize.paperdollParts then
      PlayerCustomize.paperdollParts.hair = 0
    end
    updatePreview()
  end
  
  for _, item in ipairs(hairData) do
    local button = g_ui.createWidget("PanelCustomHair", hairPanel.list)
    local cleanOutfit = table.copy(PlayerCustomize.outfit)
    cleanOutfit.type = item.looktype
    cleanOutfit.mount = 0
    cleanOutfit.hair = 0
    cleanOutfit.helmet = 0
    cleanOutfit.armor = 0
    cleanOutfit.shirt = 0
    cleanOutfit.pants = 0
    cleanOutfit.boots = 0
    cleanOutfit.gloves = 0
    cleanOutfit.belt = 0
    cleanOutfit.necklace = 0
    cleanOutfit.ringLeft = 0
    cleanOutfit.ringRight = 0
    cleanOutfit.leftHand = 0
    cleanOutfit.rightHand = 0
    cleanOutfit.backpack = 0
    cleanOutfit.cloak = 0
    button:setId(item.looktype)
    
    -- Set tooltip with price if not unlocked
    local tooltipText = item.name
    if not item.unlocked and item.price then
      tooltipText = item.name .. " (" .. item.price .. " gold coins)"
    end
    button:setTooltip(tooltipText)
    
    -- Apply saved color for this specific hair item
    cleanOutfit.hair = item.looktype
    local savedColor = PlayerCustomize.paperdollParts and PlayerCustomize.paperdollParts["hairColor"] or 20
    cleanOutfit.hairColor = savedColor
    
    button.outfit:setOutfit(cleanOutfit)
    
    if not item.unlocked then
      button:setOpacity(0.6)
    end
    
    -- Check if this hair item is currently selected
    local currentHair = 0
    if PlayerCustomize.paperdollParts and PlayerCustomize.paperdollParts.hair then
      currentHair = PlayerCustomize.paperdollParts.hair
    elseif PlayerCustomize.outfit and PlayerCustomize.outfit.hair then
      currentHair = PlayerCustomize.outfit.hair
    end
    
    if currentHair > 0 and currentHair == item.looktype then
      button:focus()
      button:setChecked(true)
    end
    
    button.itemData = item
    button.slotName = "hair"
    
    button.onClick = function() onPaperdollItemSelect(button) end
  end
  
  hairPanel.scroll:setVisible(#hairData > 15)
end

local function parsePaperdollData(paperdollData)
  if not paperdollData or not paperdollData[1] then
    return
  end
  
  local slotMappings = {
    [1] = {slot = "hair", panel = hairPanel},
    [2] = {slot = "helmet", panel = helmetPanel},
    [3] = {slot = "armor", panel = armorPanel},
    [4] = {slot = "shirt", panel = shirtPanel},
    [5] = {slot = "pants", panel = pantsPanel},
    [6] = {slot = "boots", panel = bootsPanel},
    [7] = {slot = "leftHand", panel = leftHandPanel},
    [8] = {slot = "rightHand", panel = rightHandPanel}
  }
  
  for slotIndex, slotData in ipairs(paperdollData) do
    local mapping = slotMappings[slotIndex]
    if mapping and mapping.panel then
      local clientData = {}
      for i, itemData in ipairs(slotData) do
        local looktype, name, unlocked, price, gender = unpack(itemData)
        table.insert(clientData, {
          id = i,
          name = name,
          looktype = looktype,
          unlocked = unlocked,
          price = price,
          gender = gender
        })
      end
      
      parsePaperdollItems(mapping.slot, clientData, mapping.panel)
    end
  end
  
  -- Initialize paperdoll button selection after loading data
  scheduleEvent(function()
    updatePaperdollButtonsSelection()
  end, 100)
end

local function onOpen(playerData, outfits, mounts, healthBars, manaBars, wings, auras, shaders, paperdollData)

  if type(playerData) == "table" and playerData.type then
    local currentOutfit = playerData
    local outfitList = outfits
    local mountList = mounts
    
    playerData = {
      outfit = currentOutfit,
      name = g_game.getCharacterName() or "Player"
    }
    outfits = outfitList
    mounts = mountList
  end
  
  if window and not window:isHidden() then
    
    if paperdollData and paperdollData[1] and hairPanel then
      parsePaperdollData(paperdollData)
    end
    
    if hasGamePlayerMounts() and mounts and #mounts > 0 then
      parseMounts(mounts)
    end
    return
  end
  window = g_ui.displayUI("outfitwindow")
  window:onVisibilityChange(true)
  window.mainTabBar:setContentWidget(window.mainTabContent)
  outfitsPanel     = g_ui.loadUI("ui/outfitsPanel")
  
  window.mainTabBar:addTab(tr("Outfit"), outfitsPanel)
  
  if hasGamePlayerMounts() then
    mountPanel = g_ui.loadUI("ui/mountPanel")
    window.mainTabBar:addTab(tr("Mount"), mountPanel)
  end
  
  -- Removed paperdollPanel
  
  hairPanel = g_ui.loadUI("ui/hairPanel") 
  window.mainTabBar:addTab(tr("Hair"), hairPanel)
  
  helmetPanel = g_ui.loadUI("ui/helmetPanel")
  window.mainTabBar:addTab(tr("Helmet"), helmetPanel)
  
  armorPanel = g_ui.loadUI("ui/armorPanel")
  window.mainTabBar:addTab(tr("Armor"), armorPanel)
  
  shirtPanel = g_ui.loadUI("ui/shirtPanel")
  window.mainTabBar:addTab(tr("Shirt"), shirtPanel)
  
  pantsPanel = g_ui.loadUI("ui/pantsPanel")
  window.mainTabBar:addTab(tr("Pants"), pantsPanel)
  
  bootsPanel = g_ui.loadUI("ui/bootsPanel")
  window.mainTabBar:addTab(tr("Boots"), bootsPanel)
  
  leftHandPanel = g_ui.loadUI("ui/leftHandPanel")
  window.mainTabBar:addTab(tr("Left Hand"), leftHandPanel)
  
  rightHandPanel = g_ui.loadUI("ui/rightHandPanel")
  window.mainTabBar:addTab(tr("Right Hand"), rightHandPanel)
  
  customizationPanel = g_ui.loadUI("ui/customizationPanel")
  window.mainTabBar:addTab(tr("Customization"), customizationPanel)
  
  window.mainTabBar.onTabChange = onTabChange
  
  local previousPaperdollParts = PlayerCustomize.paperdollParts
  
  PlayerCustomize = playerData
  
  if previousPaperdollParts then
    PlayerCustomize.paperdollParts = previousPaperdollParts
  else
    if PlayerCustomize.outfit and PlayerCustomize.outfit.hair and PlayerCustomize.outfit.hair > 0 then
      PlayerCustomize.paperdollParts = {
        hair = PlayerCustomize.outfit.hair
      }
    end
  end
  
  if PlayerCustomize.outfit then
    PlayerCustomize.outfit.head = PlayerCustomize.outfit.head or 20
    PlayerCustomize.outfit.body = PlayerCustomize.outfit.body or 30
    PlayerCustomize.outfit.legs = PlayerCustomize.outfit.legs or 40
    PlayerCustomize.outfit.feet = PlayerCustomize.outfit.feet or 50
    PlayerCustomize.outfit.addons = PlayerCustomize.outfit.addons or 0
  end
  
  if window.previewPanel and window.previewPanel.outfit then
    window.previewPanel.outfit:setAnimate(false)
    window.previewPanel.outfit:setCenter(true)
    window.previewPanel.outfit:setDirection(2)
    
    if PlayerCustomize.outfit then
      window.previewPanel.outfit:setOutfit(PlayerCustomize.outfit)
    end
  end
  
  parseOutfits(outfits)
  
  if paperdollData and paperdollData[1] and hairPanel then
    parsePaperdollData(paperdollData)
  end
  
  if hasGamePlayerMounts() and mounts and #mounts > 0 then
    parseMounts(mounts)
  end
  
  if pendingMounts then
    parseMounts(pendingMounts)
    pendingMounts = nil
  end
  if pendingPaperdoll then
    parsePaperdollData(pendingPaperdoll)
    pendingPaperdoll = nil
  end
  
  initCustomization()
  
  updatePreview()
end

function initPaperdollColors(slotName, panel)
  if not panel or not panel.colorsSection then 
    return 
  end
  
  if paperdollColorGroups[slotName] then
    paperdollColorGroups[slotName]:destroy()
  end
  
  paperdollColorGroups[slotName] = UIRadioGroup.create()
  
  if panel.colorsSection.colorGridPanel then
    panel.colorsSection.colorGridPanel:destroyChildren()
    
    for j = 0, 6 do
      for i = 0, 18 do
        local colorBox = g_ui.createWidget('ColorBox', panel.colorsSection.colorGridPanel)
        local outfitColor = getOutfitColor(j * 19 + i)
        colorBox:setImageColor(outfitColor)
        colorBox:setId('colorBox' .. j * 19 + i)
        colorBox.colorId = j * 19 + i
        colorBox.slotName = slotName
        
        paperdollColorGroups[slotName]:addWidget(colorBox)
      end
    end
    
    paperdollColorGroups[slotName].onSelectionChange = function(widget, selectedWidget)
      onPaperdollColorChange(selectedWidget)
    end
    
    -- Update the selection to show saved color
    updatePaperdollColorSelection(slotName, panel)
  end
end

function updatePaperdollColorSelection(slotName, panel)
  if not panel or not paperdollColorGroups[slotName] then 
    return 
  end
  
  -- Try separate storage first, then fallback to paperdollParts
  local savedColor = savedPaperdollColors[slotName .. "Color"] or 
                     (PlayerCustomize.paperdollParts and PlayerCustomize.paperdollParts[slotName .. "Color"])
  
  if savedColor then
    local colorBox = panel.colorsSection.colorGridPanel:getChildById('colorBox' .. savedColor)
    if colorBox then
      paperdollColorGroups[slotName]:selectWidget(colorBox)
      
      -- Also restore to paperdollParts if it was lost
      if not PlayerCustomize.paperdollParts then
        PlayerCustomize.paperdollParts = {}
      end
      PlayerCustomize.paperdollParts[slotName .. "Color"] = savedColor
      
      if PlayerCustomize.outfit then
        PlayerCustomize.outfit[slotName .. "Color"] = savedColor
      end
    end
  end
end

function onPaperdollColorChange(selectedWidget)
  if not selectedWidget or not selectedWidget.slotName then 
    return 
  end
  
  local colorId = selectedWidget.colorId
  local slotName = selectedWidget.slotName
  
  if not PlayerCustomize.paperdollParts then
    PlayerCustomize.paperdollParts = {}
  end
  
  -- Save to both locations
  PlayerCustomize.paperdollParts[slotName .. "Color"] = colorId
  savedPaperdollColors[slotName .. "Color"] = colorId
  
  if PlayerCustomize.outfit then
    PlayerCustomize.outfit[slotName .. "Color"] = colorId
  end
  
  -- Send color to server for permanent storage
  sendPaperdollColor(slotName, colorId)
  
  -- Update all buttons in the current panel to show the new color
  local currentPanel = nil
  if slotName == "hair" then
    currentPanel = hairPanel
  elseif slotName == "helmet" then
    currentPanel = helmetPanel
  elseif slotName == "armor" then
    currentPanel = armorPanel
  elseif slotName == "shirt" then
    currentPanel = shirtPanel
  elseif slotName == "pants" then
    currentPanel = pantsPanel
  elseif slotName == "boots" then
    currentPanel = bootsPanel
  elseif slotName == "leftHand" then
    currentPanel = leftHandPanel
  elseif slotName == "rightHand" then
    currentPanel = rightHandPanel
  end
  
  if currentPanel and currentPanel.list then
    for _, child in ipairs(currentPanel.list:getChildren()) do
      if child.outfit and child.itemData and child.itemData.looktype then
        local childOutfit = child.outfit:getOutfit()
        if childOutfit[slotName] and childOutfit[slotName] > 0 then
          childOutfit[slotName .. "Color"] = colorId
          child.outfit:setOutfit(childOutfit)
        end
      end
    end
  end
  
  updatePreview()
end

-- Funções do sistema de customização
function initCustomization()
  if not customizationPanel then return end
  
  colorModeGroup = UIRadioGroup.create()
  colorModeGroup:addWidget(customizationPanel.colorsSection.colorModePanel.headButton)
  colorModeGroup:addWidget(customizationPanel.colorsSection.colorModePanel.primaryButton)
  colorModeGroup:addWidget(customizationPanel.colorsSection.colorModePanel.secondaryButton)
  colorModeGroup:addWidget(customizationPanel.colorsSection.colorModePanel.detailButton)
  colorModeGroup.onSelectionChange = onColorModeChange
  colorModeGroup:selectWidget(customizationPanel.colorsSection.colorModePanel.headButton)
  
  colorBoxGroup = UIRadioGroup.create()
  for j = 0, 6 do
    for i = 0, 18 do
      local colorBox = g_ui.createWidget('ColorBox', customizationPanel.colorsSection.colorGridPanel)
      local outfitColor = getOutfitColor(j * 19 + i)
      colorBox:setImageColor(outfitColor)
      colorBox:setId('colorBox' .. j * 19 + i)
      colorBox.colorId = j * 19 + i
      
      if PlayerCustomize.outfit and colorBox.colorId == PlayerCustomize.outfit.head then
        colorBox:setChecked(true)
      end
      
      colorBoxGroup:addWidget(colorBox)
    end
  end
  
  colorBoxGroup.onSelectionChange = onColorCheckChange
  
  customizationPanel.addonsSection.addonsContent.addon1Panel.addon1Check.onCheckChange = onAddon1Change
  customizationPanel.addonsSection.addonsContent.addon2Panel.addon2Check.onCheckChange = onAddon2Change
  
  updateCustomizationInterface()
end

function onColorModeChange(widget, selectedWidget)
  if not selectedWidget then return end
  
  currentColorMode = selectedWidget:getId():gsub("Button", ""):lower()
  updateColorSelection()
end

function onColorCheckChange(widget, selectedWidget)
  local colorId = selectedWidget.colorId
  local colorMode = colorModeGroup:getSelectedWidget():getId():gsub("Button", ""):lower()
  
  if not PlayerCustomize.outfit then return end
  
  if colorMode == "head" then
    PlayerCustomize.outfit.head = colorId
  elseif colorMode == "primary" then
    PlayerCustomize.outfit.body = colorId
  elseif colorMode == "secondary" then
    PlayerCustomize.outfit.legs = colorId
  elseif colorMode == "detail" then
    PlayerCustomize.outfit.feet = colorId
  end
  
  updatePreview()
  updateOutfitButtons()
end

function onAddon1Change(widget, checked)
  if not PlayerCustomize.outfit then return end
  
  local currentAddons = PlayerCustomize.outfit.addons or 0
  
  if checked then
    if currentAddons == 0 then
      PlayerCustomize.outfit.addons = 1
    elseif currentAddons == 2 then
      PlayerCustomize.outfit.addons = 3
    end
  else
    if currentAddons == 1 then
      PlayerCustomize.outfit.addons = 0
    elseif currentAddons == 3 then
      PlayerCustomize.outfit.addons = 2
    end
  end
  
  updatePreview()
  updateOutfitButtons()
end

function onAddon2Change(widget, checked)
  if not PlayerCustomize.outfit then return end
  
  local currentAddons = PlayerCustomize.outfit.addons or 0
  
  if checked then
    if currentAddons == 0 then
      PlayerCustomize.outfit.addons = 2
    elseif currentAddons == 1 then
      PlayerCustomize.outfit.addons = 3
    end
  else
    if currentAddons == 2 then
      PlayerCustomize.outfit.addons = 0
    elseif currentAddons == 3 then
      PlayerCustomize.outfit.addons = 1
    end
  end
  
  updatePreview()
  updateOutfitButtons()
end

function updateColorSelection()
  if not PlayerCustomize.outfit or not colorBoxGroup then return end
  
  local colorId = 0
  local colorMode = colorModeGroup:getSelectedWidget():getId():gsub("Button", ""):lower()
  
  if colorMode == "head" then
    colorId = PlayerCustomize.outfit.head or 20
  elseif colorMode == "primary" then
    colorId = PlayerCustomize.outfit.body or 30
  elseif colorMode == "secondary" then
    colorId = PlayerCustomize.outfit.legs or 40
  elseif colorMode == "detail" then
    colorId = PlayerCustomize.outfit.feet or 50
  end
  
  local colorBox = customizationPanel.colorsSection.colorGridPanel:getChildById('colorBox' .. colorId)
  if colorBox then
    colorBoxGroup:selectWidget(colorBox)
  end
end

function updateCustomizationInterface()
  if not customizationPanel or not PlayerCustomize.outfit then return end
  
  local addons = PlayerCustomize.outfit.addons or 0
  local hasAddon1 = addons == 1 or addons == 3
  local hasAddon2 = addons == 2 or addons == 3
  
  customizationPanel.addonsSection.addonsContent.addon1Panel.addon1Check:setChecked(hasAddon1)
  customizationPanel.addonsSection.addonsContent.addon2Panel.addon2Check:setChecked(hasAddon2)
  
  updateColorSelection()
end

function updateOutfitButtons()
  if outfitsPanel and outfitsPanel.list and PlayerCustomize.outfit then
    for _, button in ipairs(outfitsPanel.list:getChildren()) do
      if button.outfit then
        local currentOutfit = button.outfit:getOutfit()
        currentOutfit.head = PlayerCustomize.outfit.head
        currentOutfit.body = PlayerCustomize.outfit.body
        currentOutfit.legs = PlayerCustomize.outfit.legs
        currentOutfit.feet = PlayerCustomize.outfit.feet
        currentOutfit.addons = PlayerCustomize.outfit.addons
        currentOutfit.mount = 0
        currentOutfit.hair = 0
        currentOutfit.helmet = 0
        currentOutfit.armor = 0
        currentOutfit.shirt = 0
        currentOutfit.pants = 0
        currentOutfit.boots = 0
        currentOutfit.gloves = 0
        currentOutfit.belt = 0
        currentOutfit.necklace = 0
        currentOutfit.ringLeft = 0
        currentOutfit.ringRight = 0
        currentOutfit.leftHand = 0
        currentOutfit.rightHand = 0
        currentOutfit.backpack = 0
        currentOutfit.cloak = 0
        button.outfit:setOutfit(currentOutfit)
      end
    end
  end
end

function destroyCustomization()
  if colorModeGroup then
    colorModeGroup:destroy()
    colorModeGroup = nil
  end
  if colorBoxGroup then
    colorBoxGroup:destroy()
    colorBoxGroup = nil
  end
  
  for slotName, colorGroup in pairs(paperdollColorGroups) do
    if colorGroup then
      colorGroup:destroy()
    end
  end
  paperdollColorGroups = {}
end

function init()
  protocol.initProtocol()
  connect(g_game, {
    onGameEnd = destroy,
    onOpenOutfitWindow = onOpen
  })
  connect(PlayerCustom, {
    onOpen = onOpen,
    onMounts = onMounts,
    onPaperdoll = onPaperdoll
  })
end

function terminate()
  protocol.terminateProtocol()
  disconnect(g_game, {
    onGameEnd = destroy,
    onOpenOutfitWindow = onOpen
  })
  disconnect(PlayerCustom, {
    onOpen = onOpen,
    onMounts = onMounts,
    onPaperdoll = onPaperdoll
  })
  destroy()
end

function destroy()
  if window then
    destroyCustomization()
    window:destroy()
    window = nil
    outfitsPanel, mountPanel, customizationPanel = nil, nil, nil
    hairPanel, helmetPanel, armorPanel, shirtPanel, pantsPanel, bootsPanel, leftHandPanel, rightHandPanel = nil, nil, nil, nil, nil, nil, nil, nil
    PlayerCustomize = {}
    pendingMounts, pendingPaperdoll = nil, nil
  end
end

function onOutfitSelect(panelButton)
  if not panelButton or not panelButton.outfit then 
    return 
  end
  
  local selectedOutfit = panelButton.outfit:getOutfit()
  
  local currentMount = PlayerCustomize.outfit and PlayerCustomize.outfit.mount or 0
  
  -- Preserve paperdoll parts and colors
  local currentPaperdolls = {}
  local currentPaperdollParts = {}
  if PlayerCustomize.outfit then
    currentPaperdolls.hair = PlayerCustomize.outfit.hair
    currentPaperdolls.helmet = PlayerCustomize.outfit.helmet
    currentPaperdolls.armor = PlayerCustomize.outfit.armor
    currentPaperdolls.shirt = PlayerCustomize.outfit.shirt
    currentPaperdolls.pants = PlayerCustomize.outfit.pants
    currentPaperdolls.boots = PlayerCustomize.outfit.boots
    currentPaperdolls.rightHand = PlayerCustomize.outfit.rightHand
    currentPaperdolls.leftHand = PlayerCustomize.outfit.leftHand
    currentPaperdolls.necklace = PlayerCustomize.outfit.necklace
    currentPaperdolls.ringLeft = PlayerCustomize.outfit.ringLeft
    currentPaperdolls.ringRight = PlayerCustomize.outfit.ringRight
    currentPaperdolls.backpack = PlayerCustomize.outfit.backpack
    currentPaperdolls.cloak = PlayerCustomize.outfit.cloak
    currentPaperdolls.gloves = PlayerCustomize.outfit.gloves
    currentPaperdolls.belt = PlayerCustomize.outfit.belt
    
    currentPaperdolls.hairColor = PlayerCustomize.outfit.hairColor
    currentPaperdolls.helmetColor = PlayerCustomize.outfit.helmetColor
    currentPaperdolls.armorColor = PlayerCustomize.outfit.armorColor
    currentPaperdolls.shirtColor = PlayerCustomize.outfit.shirtColor
    currentPaperdolls.pantsColor = PlayerCustomize.outfit.pantsColor
    currentPaperdolls.bootsColor = PlayerCustomize.outfit.bootsColor
    currentPaperdolls.rightHandColor = PlayerCustomize.outfit.rightHandColor
    currentPaperdolls.leftHandColor = PlayerCustomize.outfit.leftHandColor
  end
  
  -- Preserve paperdollParts
  if PlayerCustomize.paperdollParts then
    for key, value in pairs(PlayerCustomize.paperdollParts) do
      currentPaperdollParts[key] = value
    end
  end
  
  PlayerCustomize.outfit = selectedOutfit
  PlayerCustomize.outfit.mount = currentMount
  
  -- Restore paperdollParts
  if next(currentPaperdollParts) then
    PlayerCustomize.paperdollParts = currentPaperdollParts
  end
  
  -- Apply preserved paperdolls to new outfit
  if currentPaperdolls.hair then PlayerCustomize.outfit.hair = currentPaperdolls.hair end
  if currentPaperdolls.helmet then PlayerCustomize.outfit.helmet = currentPaperdolls.helmet end
  if currentPaperdolls.armor then PlayerCustomize.outfit.armor = currentPaperdolls.armor end
  if currentPaperdolls.shirt then PlayerCustomize.outfit.shirt = currentPaperdolls.shirt end
  if currentPaperdolls.pants then PlayerCustomize.outfit.pants = currentPaperdolls.pants end
  if currentPaperdolls.boots then PlayerCustomize.outfit.boots = currentPaperdolls.boots end
  if currentPaperdolls.rightHand then PlayerCustomize.outfit.rightHand = currentPaperdolls.rightHand end
  if currentPaperdolls.leftHand then PlayerCustomize.outfit.leftHand = currentPaperdolls.leftHand end
  if currentPaperdolls.necklace then PlayerCustomize.outfit.necklace = currentPaperdolls.necklace end
  if currentPaperdolls.ringLeft then PlayerCustomize.outfit.ringLeft = currentPaperdolls.ringLeft end
  if currentPaperdolls.ringRight then PlayerCustomize.outfit.ringRight = currentPaperdolls.ringRight end
  if currentPaperdolls.backpack then PlayerCustomize.outfit.backpack = currentPaperdolls.backpack end
  if currentPaperdolls.cloak then PlayerCustomize.outfit.cloak = currentPaperdolls.cloak end
  if currentPaperdolls.gloves then PlayerCustomize.outfit.gloves = currentPaperdolls.gloves end
  if currentPaperdolls.belt then PlayerCustomize.outfit.belt = currentPaperdolls.belt end
  
  -- Apply preserved colors
  if currentPaperdolls.hairColor then PlayerCustomize.outfit.hairColor = currentPaperdolls.hairColor end
  if currentPaperdolls.helmetColor then PlayerCustomize.outfit.helmetColor = currentPaperdolls.helmetColor end
  if currentPaperdolls.armorColor then PlayerCustomize.outfit.armorColor = currentPaperdolls.armorColor end
  if currentPaperdolls.shirtColor then PlayerCustomize.outfit.shirtColor = currentPaperdolls.shirtColor end
  if currentPaperdolls.pantsColor then PlayerCustomize.outfit.pantsColor = currentPaperdolls.pantsColor end
  if currentPaperdolls.bootsColor then PlayerCustomize.outfit.bootsColor = currentPaperdolls.bootsColor end
  if currentPaperdolls.rightHandColor then PlayerCustomize.outfit.rightHandColor = currentPaperdolls.rightHandColor end
  if currentPaperdolls.leftHandColor then PlayerCustomize.outfit.leftHandColor = currentPaperdolls.leftHandColor end
  
  updateCustomizationInterface()
  
  -- Update visual selection of paperdoll buttons
  updatePaperdollButtonsSelection()
  
  updatePreview()
end

function updatePaperdollButtonsSelection()
  if not PlayerCustomize.paperdollParts then
    return
  end
  
  -- Define slot mapping to panels
  local slotPanels = {
    hair = hairPanel,
    helmet = helmetPanel,
    armor = armorPanel,
    shirt = shirtPanel,
    pants = pantsPanel,
    boots = bootsPanel,
    leftHand = leftHandPanel,
    rightHand = rightHandPanel
  }
  
  -- Update each slot's button selection
  for slotName, panel in pairs(slotPanels) do
    if panel and panel.list and PlayerCustomize.paperdollParts[slotName] then
      local selectedLooktype = PlayerCustomize.paperdollParts[slotName]
      
      -- Clear all selections first
      for _, child in ipairs(panel.list:getChildren()) do
        child:setChecked(false)
      end
      
      -- Find and select the correct button
      for _, child in ipairs(panel.list:getChildren()) do
        if child.itemData and child.itemData.looktype == selectedLooktype then
          child:focus()
          child:setChecked(true)
          break
        end
      end
    end
  end
end

function onMountSelect(panelButton)
  if not panelButton or not panelButton.mount then 
    return 
  end
  
  local mountOutfit = panelButton.mount:getOutfit()
  local mountId = mountOutfit.type
  
  if not PlayerCustomize.outfit then
    PlayerCustomize.outfit = {
      type = 136,
      head = 20,
      body = 30,
      legs = 40,
      feet = 50,
      addons = 0
    }
  end
  
  PlayerCustomize.outfit.mount = mountId
  
  updatePreview()
end

function updatePreview()
  if not window or not window.previewPanel then return end
  
  if PlayerCustomize.name then
    window.previewPanel.name:setText(PlayerCustomize.name)
  end
  if PlayerCustomize.outfit then
    local direction = window.previewPanel.outfit:getDirection()
    local previewOutfit = table.copy(PlayerCustomize.outfit)
    
    window.previewPanel.outfit:setOutfit(previewOutfit)
    
    window.previewPanel.outfit:setCenter(true)
    
    if direction then
      window.previewPanel.outfit:setDirection(direction)
    else
      window.previewPanel.outfit:setDirection(2)
    end
  end
end

function confirmChoose()
  if PlayerCustomize.outfit then
    if hasGamePlayerMounts() and PlayerCustomize.outfit.mount then
      local player = g_game.getLocalPlayer()
      if player then
        local currentlyMounted = player:isMounted()
        local shouldBeMounted = PlayerCustomize.outfit.mount > 0
        
        if not currentlyMounted and shouldBeMounted then
          player:mount()
        elseif currentlyMounted and not shouldBeMounted then
          player:dismount()
        end
      end
    end
    
    local success3, err3 = pcall(function()
      g_game.changeOutfit(PlayerCustomize.outfit)
    end)
  end
  destroy()
end

-- Paperdoll purchase function
function purchasePaperdollItem(slotName, itemId)
  if g_game.isOnline() then
    sendPaperdollPurchase(slotName, itemId)
  end
end

function cancelPaperdollPurchase()
  if purchaseWindow then
    purchaseWindow:destroy()
    purchaseWindow = nil
  end
end

-- Paperdoll item selection function
function onPaperdollItemSelect(button)
  if not button or not button.itemData then
    return
  end
  
  local itemData = button.itemData
  local slotName = button.slotName
  
  if not itemData.unlocked then
    local text = tr("Do you want to purchase %s for %d gold coins?", itemData.name, itemData.price)
    
    local purchaseDialog
    purchaseDialog = displayGeneralBox(tr("Purchase Paperdoll Item"), text, {
      { text = tr("Yes"), callback = function() 
        purchasePaperdollItem(slotName, itemData.id)
        scheduleEvent(function()
          if purchaseDialog then
            purchaseDialog:destroy()
            purchaseDialog = nil
          end
        end, 10)
      end },
      { text = tr("No"), callback = function() 
        scheduleEvent(function()
          if purchaseDialog then
            purchaseDialog:destroy()
            purchaseDialog = nil
          end
        end, 10)
      end }
    }, function() 
      scheduleEvent(function()
        if purchaseDialog then
          purchaseDialog:destroy()
          purchaseDialog = nil
        end
      end, 10)
    end)
    return
  end
  
  if itemData.unlocked then
    if not PlayerCustomize.paperdollParts then
      PlayerCustomize.paperdollParts = {}
    end
    
    -- Clear all buttons in current panel
    local currentPanel = nil
    if slotName == "hair" then
      currentPanel = hairPanel
    elseif slotName == "helmet" then
      currentPanel = helmetPanel
    elseif slotName == "armor" then
      currentPanel = armorPanel
    elseif slotName == "shirt" then
      currentPanel = shirtPanel
    elseif slotName == "pants" then
      currentPanel = pantsPanel
    elseif slotName == "boots" then
      currentPanel = bootsPanel
    elseif slotName == "leftHand" then
      currentPanel = leftHandPanel
    elseif slotName == "rightHand" then
      currentPanel = rightHandPanel
    end
    
    if currentPanel and currentPanel.list then
      for _, child in ipairs(currentPanel.list:getChildren()) do
        child:setChecked(false)
      end
    end
    
    button:focus()
    button:setChecked(true)
    
    PlayerCustomize.paperdollParts[slotName] = itemData.looktype or 0
    
    if PlayerCustomize.outfit then
      PlayerCustomize.outfit[slotName] = itemData.looktype or 0
      
      -- Apply color if already saved in paperdollParts or savedPaperdollColors
      local savedColor = PlayerCustomize.paperdollParts[slotName .. "Color"] or 
                         savedPaperdollColors[slotName .. "Color"] or 20
      
      PlayerCustomize.outfit[slotName .. "Color"] = savedColor
      PlayerCustomize.paperdollParts[slotName .. "Color"] = savedColor
      savedPaperdollColors[slotName .. "Color"] = savedColor
    end
    
    -- Update color selection in the current panel
    if currentPanel and currentPaperdollSlot == slotName then
      updatePaperdollColorSelection(slotName, currentPanel)
    end
    
    updatePreview()
  end
end
