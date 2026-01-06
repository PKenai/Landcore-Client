-- Fishing Module
-- Minigame reworked: balance a buoy against a leftward force

-- Configuration
local FISHING_OPCODE = 103

-- Visual layout (assets live in mods/game_fishing/imagens)
local BAR_WIDTH = 400
local BAR_HEIGHT = 30
local BUOY_WIDTH = 28
local BUOY_HEIGHT = 24

-- Gameplay tuning
local UPDATE_INTERVAL = 50 -- ms between physics ticks
local CANCEL_THRESHOLD = 0.10 -- 10% from each edge
local CENTER_TOLERANCE = 0.50 -- ±10% around center counts as control
local SUCCESS_HOLD_MS = 7000 -- need 7s centered to succeed

-- Forces (normalized 0..1 across the bar)
local FORCE_BASE_MIN = 0.003
local FORCE_BASE_MAX = 0.008
local FORCE_JITTER = 0.002
local PLAYER_IMPULSE = 0.035 -- push right per space tap

-- Module variables
local fishingWindow = nil
local buoyWidget = nil
local barWidget = nil
local statusLabel = nil
local timerLabel = nil
local fishingActive = false
local debugMode = true

-- Physics state
local buoyPosition = 0.5 -- normalized (0 = far left, 1 = far right)
local centerTimer = 0 -- ms spent near center
local spacePressCount = 0
local baseForce = 0
local pendingBaseForce = nil

-- Debug log function
function debugLog(message)
  if debugMode and message then
    g_logger.debug("[Fishing] " .. message)
    print("[Fishing] " .. message)
  end
end

-- Initialize the module
function init()
  connect(g_game, {
    onGameStart = create,
    onGameEnd = destroy,
    onKeyDown = handleKeyDown
  })

  ProtocolGame.registerExtendedOpcode(FISHING_OPCODE, onExtendedOpcode)
  connect(g_game, { onTextMessage = handleTextMessage })

  if g_game.isOnline() then
    create()
  end

  debugLog("Fishing module initialized")
end

-- Handler for text messages (avoid unhandled warnings)
function handleTextMessage(mode, text)
  if string.find(text, "fish") then
    debugLog("Captured fishing text message: " .. text)
    return true
  end
  return false
end

-- Clean up when module unloads
function terminate()
  disconnect(g_game, {
    onGameStart = create,
    onGameEnd = destroy,
    onKeyDown = handleKeyDown,
    onTextMessage = handleTextMessage
  })

  ProtocolGame.unregisterExtendedOpcode(FISHING_OPCODE)
  destroy()
  debugLog("Fishing module terminated")
end

-- Create placeholder state
function create()
  debugLog("Game started, waiting for fishing window request")
end

-- Clean up interface
function destroy()
  fishingActive = false
  if fishingWindow then
    fishingWindow:destroy()
    fishingWindow = nil
    buoyWidget = nil
    barWidget = nil
    statusLabel = nil
    timerLabel = nil
    debugLog("Fishing window destroyed")
  end
end

-- Handle messages from server
function onExtendedOpcode(protocol, opcode, buffer)
  if opcode ~= FISHING_OPCODE then
    return
  end

  local ok, data = pcall(function() return json.decode(buffer) end)
  if not ok then
    g_logger.error("Fishing JSON error: " .. tostring(data))
    return
  end

  debugLog("Received message: " .. buffer)

  if data.action == "result" then
    showFishingResult(data.success, data.message)
  elseif data.action == "open" then
    pendingBaseForce = data.baseForce
    openFishingWindow()
  end
end

-- Create and show the fishing window
function openFishingWindow()
  if fishingWindow then
    fishingWindow:show()
    fishingWindow:raise()
    fishingWindow:focus()
    g_keyboard.bindKeyDown('Space', onSpacePress)
    startFishing()
    debugLog("Reusing fishing window and restarting minigame")
    return
  end

  debugLog("Creating fishing window (frameless)")

  -- Use a frameless UIWidget to avoid the gray client window chrome.
  fishingWindow = g_ui.createWidget('UIWidget', modules.game_interface.getRootPanel())
  if not fishingWindow then
    g_logger.error("Failed to create fishing window")
    return
  end

  fishingWindow:setId('fishingWindow')
  fishingWindow:setSize({width = 520, height = 240})
  fishingWindow:setDraggable(true)
  fishingWindow:setFocusable(true)
  fishingWindow:setImageColor('#00000000') -- transparent background

  -- Bar image
  barWidget = g_ui.createWidget('UIWidget', fishingWindow)
  barWidget:setId('barWidget')
  barWidget:setImageSource('/mods/game_fishing/imagens/Barra.png')
  barWidget:setSize({width = BAR_WIDTH, height = BAR_HEIGHT})
  barWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
  barWidget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
  barWidget:setMarginTop(10)

  -- Buoy image
  buoyWidget = g_ui.createWidget('UIWidget', fishingWindow)
  buoyWidget:setId('buoyWidget')
  buoyWidget:setImageSource('/mods/game_fishing/imagens/boia.png')
  buoyWidget:setSize({width = BUOY_WIDTH, height = BUOY_HEIGHT})

  -- Status labels (kept minimal)
  -- Hidden labels (kept for state updates but not shown)
  statusLabel = g_ui.createWidget('Label', fishingWindow)
  statusLabel:setId('statusLabel')
  statusLabel:setVisible(false)

  timerLabel = g_ui.createWidget('Label', fishingWindow)
  timerLabel:setId('timerLabel')
  timerLabel:setVisible(false)

  local resultLabel = g_ui.createWidget('Label', fishingWindow)
  resultLabel:setId('resultLabel')
  resultLabel:setVisible(false)

  -- Close button with minimal footprint
  local closeButton = g_ui.createWidget('Button', fishingWindow)
  closeButton:setId('closeButton')
  closeButton:setText('X')
  closeButton:setWidth(22)
  closeButton:addAnchor(AnchorTop, 'parent', AnchorTop)
  closeButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  closeButton:setMarginTop(4)
  closeButton:setMarginRight(4)
  closeButton.onClick = function() hide() end

  -- Center on screen
  local parent = fishingWindow:getParent()
  if parent then
    fishingWindow:setPosition({
      x = (parent:getWidth() - fishingWindow:getWidth()) / 2,
      y = ((parent:getHeight() - fishingWindow:getHeight()) / 2) + 130
    })
  end

  g_keyboard.bindKeyDown('Space', onSpacePress)
  startFishing()
  debugLog("Fishing widget created and minigame started")
end

-- Function for when spacebar is pressed
function onSpacePress()
  if not fishingActive or not fishingWindow or not fishingWindow:isVisible() then
    debugLog("Spacebar pressed but fishing not active")
    return false
  end

  spacePressCount = spacePressCount + 1
  buoyPosition = buoyPosition + PLAYER_IMPULSE
  if buoyPosition > 1 then buoyPosition = 1 end
  updateBuoyWidget()
  debugLog("Space pressed, count=" .. spacePressCount .. ", pos=" .. string.format('%.3f', buoyPosition))
  return true
end

-- Start the fishing minigame
function startFishing()
  buoyPosition = 0.5
  centerTimer = 0
  spacePressCount = 0
  if pendingBaseForce then
    baseForce = pendingBaseForce
    pendingBaseForce = nil
  else
    baseForce = FORCE_BASE_MIN
    debugLog("No server baseForce provided; fallback to minimum (client should not set force).")
  end
  fishingActive = true
  updateBuoyWidget()
  updateStatus(0)
  scheduleEvent(function() updateBuoy() end, UPDATE_INTERVAL)
  debugLog("Started fishing minigame, baseForce=" .. tostring(baseForce))
end

-- Stop the fishing minigame
function stopFishing()
  fishingActive = false
  debugLog("Stopped fishing minigame")
end

-- Update buoy physics / position
function updateBuoy()
  if not fishingActive or not fishingWindow then
    debugLog("Update buoy canceled - fishing not active")
    return
  end

  local jitter = (math.random() * 2 - 1) * FORCE_JITTER
  local drift = baseForce + jitter
  buoyPosition = buoyPosition - drift

  if buoyPosition < 0 then buoyPosition = 0 end
  if buoyPosition > 1 then buoyPosition = 1 end

  updateBuoyWidget()

  if buoyPosition <= CANCEL_THRESHOLD or buoyPosition >= (1 - CANCEL_THRESHOLD) then
    failFishing("A boia foi puxada para longe!")
    return
  end

  if isCentered() then
    centerTimer = centerTimer + UPDATE_INTERVAL
    if centerTimer >= SUCCESS_HOLD_MS then
      completeFishing(true)
      return
    end
  else
    centerTimer = 0
  end

  updateStatus(centerTimer)

  if fishingActive then
    scheduleEvent(function() updateBuoy() end, UPDATE_INTERVAL)
  end
end

function isCentered()
  local center = 0.5
  return math.abs(buoyPosition - center) <= CENTER_TOLERANCE
end

function completeFishing(success)
  fishingActive = false
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(FISHING_OPCODE, json.encode({
      action = "fish",
      success = success,
      presses = spacePressCount,
      force = baseForce
    }))
    debugLog("Sent fishing result to server. success=" .. tostring(success) .. ", presses=" .. spacePressCount)
  end
  -- Always hide to ensure the next session starts clean.
  hide()
end

function failFishing(message)
  local resultLabel = fishingWindow and fishingWindow:getChildById('resultLabel')
  if resultLabel then
    resultLabel:setText(message or "A boia foi puxada para longe!")
    resultLabel:setColor('#FF0000')
  end
  completeFishing(false)
end

function updateBuoyWidget()
  if not fishingWindow or not barWidget or not buoyWidget then return end
  local barPos = barWidget:getPosition()
  local x = barPos.x + (buoyPosition * (BAR_WIDTH - BUOY_WIDTH))
  local y = barPos.y + ((BAR_HEIGHT - BUOY_HEIGHT) / 2)
  buoyWidget:setPosition({x = x, y = y})
end

function updateStatus(currentCenterTime)
  if statusLabel then
    statusLabel:setText(string.format("Força base: %.3f | Toques: %d", baseForce, spacePressCount))
  end
  if timerLabel then
    timerLabel:setText(string.format("Tempo centrado: %.1fs / %.1fs", currentCenterTime / 1000, SUCCESS_HOLD_MS / 1000))
  end
end

-- Show the result of fishing
function showFishingResult(success, message)
  if not fishingWindow then
    debugLog("Cannot show result, fishing window does not exist")
    return
  end

  debugLog("Showing fishing result: " .. tostring(success) .. ", " .. message)

  local resultLabel = fishingWindow:getChildById('resultLabel')
  if resultLabel then
    resultLabel:setText(message)
    if success then
      resultLabel:setColor('#00FF00')
    else
      resultLabel:setColor('#FF0000')
    end
  end

  -- Already hidden in completeFishing; if window still visible, let it remain hidden.
end

-- Function to hide the window
function hide()
  if fishingWindow then
    g_keyboard.unbindKeyDown('Space')
    fishingWindow:hide()
    stopFishing()
    debugLog("Fishing window hidden")
  end
end

-- Handle keypresses
function handleKeyDown(self, keyCode, keyChar, keyboardModifiers)
  if not fishingActive or not fishingWindow or not fishingWindow:isVisible() then
    return false
  end

  if keyCode == 32 then
    debugLog("Spacebar keypress detected in handleKeyDown")
    return onSpacePress()
  end

  return false
end

