local defaultOptions = {
  layout = DEFAULT_LAYOUT, -- set in init.lua
  vsync = true,
  showFps = true,
  showPing = true,
  showOnlinePlayers = true,
  showPlayerShadows = true,
  fullscreen = false,
  classicView = false,--not g_app.isMobile(),
  cacheMap = g_app.isMobile(),
  classicControl = not g_app.isMobile(),
  smartWalk = true,
  showStatusMessagesInConsole = true,
  showEventMessagesInConsole = true,
  showInfoMessagesInConsole = true,
  showTimestampsInConsole = true,
  showPrivateMessagesInConsole = true,
  showPrivateMessagesOnScreen = true,
  rightPanels = 4,
  leftPanels = 0,
  containerPanel = 8,
  backgroundFrameRate = 60,
  enableAudio = true,
  enableMusicSound = true,
  musicSoundVolume = 50,
  enableLights = true,
  floorFading = 500,
  crosshair = 0,
  ambientLight = 36,
  effectOpacity = 100,
  optimizationLevel = 1,
  displayNames = true,
  displayCreatureShadows = true,
  displayHealthOnTop = false,
  highlightThingsUnderCursor = false,
  displayText = true,
  enableSpeechBalloon = true,
  dontStretchShrink = false,
  turnDelay = 30,
  hotkeyDelay = 30,
  animatedTextScale = 0,
  wsadWalking = false,
  walkFirstStepDelay = 200,
  walkTurnDelay = 100,
  walkStairsDelay = 50,
  walkTeleportDelay = 200,
  walkCtrlTurnDelay = 150,
  
  actionbar1 = true,
  actionbar2 = true,
}

local optionsWindow
--local optionsButton
optionsTabBar = nil
local options = {}
local extraOptions = {}
local generalPanel
local interfacePanel
local consolePanel
local graphicsPanel
local soundPanel
local othersPanel
extrasPanel = nil
local audioButton

function init()
  for k,v in pairs(defaultOptions) do
    g_settings.setDefault(k, v)
    options[k] = v
  end
  for _, v in ipairs(g_extras.getAll()) do
	  extraOptions[v] = g_extras.get(v)
    g_settings.setDefault("extras_" .. v, extraOptions[v])
  end


  optionsWindow = g_ui.displayUI('options')
  optionsWindow:hide()

  optionsTabBar = optionsWindow:getChildById('optionsTabBar')
  optionsTabBar:setContentWidget(optionsWindow:getChildById('optionsTabContent'))

  g_keyboard.bindKeyDown('Ctrl+Shift+F', function() toggleOption('fullscreen') end)

  generalPanel = g_ui.loadUI('game')
  optionsTabBar:addTab(tr('Game'), generalPanel, '/modules/client_options/settings/iconpanel')
  
  interfacePanel = g_ui.loadUI('interface')
  optionsTabBar:addTab(tr('Interface'), interfacePanel, '/modules/client_options/settings/iconpanel')  

  consolePanel = g_ui.loadUI('console')
  optionsTabBar:addTab(tr('Console'), consolePanel, '/modules/client_options/settings/iconpanel')

  graphicsPanel = g_ui.loadUI('graphics')
  optionsTabBar:addTab(tr('Graphics'), graphicsPanel, '/modules/client_options/settings/iconpanel')

  audioPanel = g_ui.loadUI('audio')
  optionsTabBar:addTab(tr('Audio'), audioPanel, '/modules/client_options/settings/iconpanel')

  othersPanel = g_ui.loadUI('others')
  optionsTabBar:addTab(tr('Others'), othersPanel, '/modules/client_options/settings/iconpanel')

  extrasPanel = g_ui.createWidget('OptionPanel')
  for _, v in ipairs(g_extras.getAll()) do
    local extrasButton = g_ui.createWidget('OptionCheckBox')
    extrasButton:setId(v)
    extrasButton:setText(g_extras.getDescription(v))
    extrasPanel:addChild(extrasButton)
  end
  --[[if not g_game.getFeature(GameNoDebug) and not g_app.isMobile() then
    optionsTabBar:addTab(tr('Extras'), extrasPanel, '/images/optionstab/extras')
  end]]--

  --optionsButton = modules.client_topmenu.addLeftButton('optionsButton', tr('Options'), '/images/topbuttons/options', toggle)
  audioButton = modules.client_topmenu.addLeftButton('audioButton', tr('Audio'), '/images/topbuttons/audio', function() toggleOption('enableAudio') end)
  audioButton:hide()
  if g_app.isMobile() then
    audioButton:hide()
  end
  
  addEvent(function() setup() end)
  
  connect(g_game, { onGameStart = online,
                     onGameEnd = offline })                    
end

function terminate()
  disconnect(g_game, { onGameStart = online,
                     onGameEnd = offline })  

  g_keyboard.unbindKeyDown('Ctrl+Shift+F')
  optionsWindow:destroy()
  --optionsButton:destroy()
  audioButton:destroy()
end

function setup()
  -- load options
  for k,v in pairs(defaultOptions) do
    if type(v) == 'boolean' then
      setOption(k, g_settings.getBoolean(k), true)
    elseif type(v) == 'number' then
      setOption(k, g_settings.getNumber(k), true)
    elseif type(v) == 'string' then
      setOption(k, g_settings.getString(k), true)
    end
  end
  
  for _, v in ipairs(g_extras.getAll()) do
    g_extras.set(v, g_settings.getBoolean("extras_" .. v))
    local widget = extrasPanel:recursiveGetChildById(v)
    if widget then
      widget:setChecked(g_extras.get(v))
    end
  end  
  
  if g_game.isOnline() then
    online()
  end  
end

function toggle()
  if optionsWindow:isVisible() then
    hide()
  else
    show()
  end
end

function show()
  optionsWindow:show()
  optionsWindow:raise()
  optionsWindow:focus()
  modules.game_chat.manageButton('settingsButton', true)
end

function hide()
  optionsWindow:hide()
  modules.game_chat.manageButton('settingsButton', false)
end

function toggleDisplays()
  if options['displayNames'] and options['displayHealth'] and options['displayMana'] then
    setOption('displayNames', false)
  elseif options['displayHealth'] then
    setOption('displayHealth', true)
    setOption('displayMana', true)
  else
    if not options['displayNames'] and not options['displayHealth'] then
      setOption('displayNames', true)
    else
      setOption('displayHealth', true)
      setOption('displayMana', true)
    end
  end
end

function toggleOption(key) 
  setOption(key, not getOption(key))
end

function setOption(key, value, force)
  if extraOptions[key] ~= nil then
    g_extras.set(key, value)
    g_settings.set("extras_" .. key, value)
    if key == "debugProxy" and modules.game_proxy then
      if value then
        modules.game_proxy.show()
      else
        modules.game_proxy.hide()      
      end
    end
    return
  end
  
  if modules.game_interface == nil then
    return
  end
   
  if not force and options[key] == value then return end
  local gameMapPanel = modules.game_interface.getMapPanel()

  if key == 'vsync' then
    g_window.setVerticalSync(value)
  elseif key == 'showFps' then
    if g_game.isOnline() then
      modules.client_topmenu.setFpsVisible(value)
      if modules.game_stats and modules.game_stats.ui.fps then
        modules.game_stats.ui.fps:setVisible(value)
      end
  end
  elseif key == 'showPing' then
    modules.client_topmenu.setPingVisible(value)
    if modules.game_stats and modules.game_stats.ui.ping then
      modules.game_stats.ui.ping:setVisible(value)
    end
  elseif key == 'showOnlinePlayers' then
    modules.client_topmenu.setOnlinePlayersVisible(value)
    if modules.game_stats and modules.game_stats.ui.onlinePlayers then
      modules.game_stats.ui.onlinePlayers:setVisible(value)
    end
  elseif key == 'showPlayerShadows' then
    gameMapPanel:setDrawCreatureShadows(value)
  elseif key == 'fullscreen' then
    g_window.setFullscreen(value)
  elseif key == 'enableAudio' then
    if g_sounds ~= nil then
      g_sounds.setAudioEnabled(value)
    end
    if value then
      audioButton:setIcon('/images/topbuttons/audio')
    else
      audioButton:setIcon('/images/topbuttons/audio_mute')
    end
  elseif key == 'enableMusicSound' then
    if g_sounds ~= nil then
      g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
    end
  elseif key == 'musicSoundVolume' then
    if g_sounds ~= nil then
      g_sounds.getChannel(SoundChannels.Music):setGain(value/100)
    end
    audioPanel:getChildById('musicSoundVolumeBG'):getChildById('musicSoundVolumeLabelBG'):setText(tr('%d', value))
	local valueScroll = ((value*200)/100)
	audioPanel:getChildById('musicSoundVolumeBG'):getChildById('musicSoundVolume'):getChildById('activeScroll'):setWidth(valueScroll)
  elseif key == 'backgroundFrameRate' then
    local text, v = value, value
    if value <= 0 or value >= 201 then text = 'max' v = 0 end
    graphicsPanel:getChildById('backgroundFrameRateBG'):getChildById('backgroundFrameRateLabelBG'):setText(tr('%s', text))
	local valueScroll = ((value*200)/201)
	graphicsPanel:getChildById('backgroundFrameRateBG'):getChildById('backgroundFrameRate'):getChildById('activeScroll'):setWidth(valueScroll)
    g_app.setMaxFps(v)
  elseif key == 'enableLights' then
    gameMapPanel:setDrawLights(value and options['ambientLight'] < 100)
    graphicsPanel:getChildById('ambientLightBG'):getChildById('ambientLight'):setEnabled(value)
  elseif key == 'floorFading' then
    gameMapPanel:setFloorFading(value)
    interfacePanel:getChildById('floorFadingBG'):getChildById('floorFadingLabelBG'):setText(tr('%s ms', value))
	local valueScroll = ((value*200)/2000)
	interfacePanel:getChildById('floorFadingBG'):getChildById('floorFading'):getChildById('activeScroll'):setWidth(valueScroll)
  elseif key == 'crosshair' then
    if value == 1 then
      gameMapPanel:setCrosshair("")    
    elseif value == 2 then
      gameMapPanel:setCrosshair("/images/crosshair/default.png")        
    elseif value == 3 then
      gameMapPanel:setCrosshair("/images/crosshair/full.png")    
    end
  elseif key == 'ambientLight' then
    graphicsPanel:getChildById('ambientLightBG'):getChildById('ambientLightLabelBG'):setText(tr('%s%%', value))
    gameMapPanel:setMinimumAmbientLight(value/100)
    gameMapPanel:setDrawLights(options['enableLights'] and value < 100)
	local valueScroll = ((value*200)/100)
	graphicsPanel:getChildById('ambientLightBG'):getChildById('ambientLight'):getChildById('activeScroll'):setWidth(valueScroll)
  elseif key == 'effectOpacity' then
    graphicsPanel:getChildById('effectOpacityBG'):getChildById('effectOpacityLabelBG'):setText(tr('%s%%', value))
	local valueScroll = ((value*200)/100)
	graphicsPanel:getChildById('effectOpacityBG'):getChildById('effectOpacity'):getChildById('activeScroll'):setWidth(valueScroll)
  elseif key == 'optimizationLevel' then
    g_adaptiveRenderer.setLevel(value - 2)
  elseif key == 'displayNames' then
    gameMapPanel:setDrawNames(value)
  elseif key == 'displayCreatureShadows' then
    gameMapPanel:setDrawCreatureShadows(value)
  elseif key == 'displayHealthOnTop' then
    gameMapPanel:setDrawHealthBarsOnTop(value)
  elseif key == 'displayText' then
    gameMapPanel:setDrawTexts(value)
  elseif key == 'enableSpeechBalloon' then
    -- This will be handled in the creature drawing logic
  elseif key == 'dontStretchShrink' then
    addEvent(function()
      modules.game_interface.updateStretchShrink()
    end)
  elseif key == 'dash' then
    if value then
      g_game.setMaxPreWalkingSteps(2)
    else 
      g_game.setMaxPreWalkingSteps(1)    
    end
  elseif key == 'wsadWalking' then
    if modules.game_chat then
      modules.game_chat.toggleChatByOptions(value)
    end
  elseif key == 'autoTargetDirection' then
    -- Envia a opção para o servidor via extended opcode
    if g_game.isOnline() then
      local protocolGame = g_game.getProtocolGame()
      if protocolGame then
        local opcode = 2 -- OPCODE_AUTO_TARGET_DIRECTION
        local buffer = value and '1' or '0'
        protocolGame:sendExtendedOpcode(opcode, buffer)
      end
    end
  elseif key == 'nearestAutoTarget' then
    -- Se ativar nearestAutoTarget, desativa autoRetarget (mutuamente exclusivo)
    if value and options['autoRetarget'] then
      setOption('autoRetarget', false, true)
    end
    -- Envia a opção para o servidor via extended opcode
    if g_game.isOnline() then
      local protocolGame = g_game.getProtocolGame()
      if protocolGame then
        local opcode = 3 -- OPCODE_NEAREST_AUTO_TARGET
        local buffer = value and '1' or '0'
        protocolGame:sendExtendedOpcode(opcode, buffer)
      end
    end
  elseif key == 'autoRetarget' then
    -- Se ativar autoRetarget, desativa nearestAutoTarget (mutuamente exclusivo)
    if value and options['nearestAutoTarget'] then
      setOption('nearestAutoTarget', false, true)
    end
  end

  -- change value for keybind updates
  for _,panel in pairs(optionsTabBar:getTabsPanel()) do
    local widget = panel:recursiveGetChildById(key)
    if widget then
      if widget:getStyle().__class == 'UICheckBox' then
        widget:setChecked(value)
      elseif widget:getStyle().__class == 'UIScrollBar' then
        widget:setValue(value)
      elseif widget:getStyle().__class == 'UIComboBox' then
        if type(value) == "string" then
          widget:setCurrentOption(value, true)
          break
        end
        if value == nil or value < 1 then 
          value = 1
        end
        if widget.currentIndex ~= value then
          widget:setCurrentIndex(value, true)
        end
      end      
      break
    end
  end
  
  g_settings.set(key, value)
  options[key] = value
  
if key == 'classicView' or key == 'rightPanels' or key == 'leftPanels' or key == 'cacheMap' then
    modules.game_interface.refreshViewMode()    
  elseif key:find("actionbar") then
    modules.game_actionbar.show()
  end
  end

function getOption(key)
  return options[key]
end

function addTab(name, panel, icon)
  optionsTabBar:addTab(name, panel, icon)
end

function addButton(name, func, icon)
  optionsTabBar:addButton(name, func, icon)
end

-- hide/show

function online()
  setLightOptionsVisibility(not g_game.getFeature(GameForceLight))
  audioButton:show()
  -- Envia as opções para o servidor ao logar
  addEvent(function()
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
      if options['autoTargetDirection'] ~= nil then
        local opcode = 2 -- OPCODE_AUTO_TARGET_DIRECTION
        local buffer = options['autoTargetDirection'] and '1' or '0'
        protocolGame:sendExtendedOpcode(opcode, buffer)
      end
      if options['nearestAutoTarget'] ~= nil then
        local opcode = 3 -- OPCODE_NEAREST_AUTO_TARGET
        local buffer = options['nearestAutoTarget'] and '1' or '0'
        protocolGame:sendExtendedOpcode(opcode, buffer)
      end
    end
  end)
end

function offline()
  setLightOptionsVisibility(true)
  audioButton:hide()
end

-- classic view

-- graphics
function setLightOptionsVisibility(value)
  graphicsPanel:getChildById('enableLights'):setEnabled(value)
  graphicsPanel:getChildById('ambientLightBG'):getChildById('ambientLightLabelBG'):setEnabled(value)
  graphicsPanel:getChildById('ambientLightBG'):getChildById('ambientLight'):setEnabled(value)  
  interfacePanel:getChildById('floorFadingBG'):getChildById('floorFading'):setEnabled(value)
  interfacePanel:getChildById('floorFadingLabel'):setEnabled(value)
  interfacePanel:getChildById('floorFadingLabel2'):setEnabled(value)  
end
