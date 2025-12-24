EnterGame = { }

-- private variables
local loadBox
local enterGame
local enterGameButton
local clientBox
local protocolLogin
local server = nil
local versionsFound = false

local rememberPasswordBox
local fullscreenStatusLabel
local protos = {"740", "760", "772", "792", "800", "810", "854", "860", "870", "910", "961", "1000", "1077", "1090", "1096", "1098", "1099", "1100", "1200", "1220"}

local checkedByUpdater = {}
local waitingForHttpResults = 0

-- private functions
local function onProtocolError(protocol, message, errorCode)
  if errorCode then
    return EnterGame.onError(message)
  end
  return EnterGame.onLoginError(message)
end

local function onSessionKey(protocol, sessionKey)
  G.sessionKey = sessionKey
end

local function onCharacterList(protocol, characters, account, otui)
  if rememberPasswordBox:isChecked() then
    local account = g_crypt.encrypt(G.account)
    local password = g_crypt.encrypt(G.password)

    g_settings.set('account', account)
    g_settings.set('password', password)
  else
    EnterGame.clearAccountFields()
  end

  for _, characterInfo in pairs(characters) do
    if characterInfo.previewState and characterInfo.previewState ~= PreviewState.Default then
      characterInfo.worldName = characterInfo.worldName .. ', Preview'
    end
  end

  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
    
  CharacterList.create(characters, account, otui)
  CharacterList.show()

  g_settings.save()
end

local function onUpdateNeeded(protocol, signature)
  return EnterGame.onError(tr('Your client needs updating, try redownloading it.'))
end

local function onProxyList(protocol, proxies)
  for _, proxy in ipairs(proxies) do
    g_proxy.addProxy(proxy["host"], proxy["port"], proxy["priority"])
  end
end

local function parseFeatures(features)
  for feature_id, value in pairs(features) do
      if value == "1" or value == "true" or value == true then
        g_game.enableFeature(feature_id)
      else
        g_game.disableFeature(feature_id)
      end
  end  
end

local function validateThings(things)
  local incorrectThings = ""
  local missingFiles = false
  local versionForMissingFiles = 0
  if things ~= nil then
    local thingsNode = {}
    for thingtype, thingdata in pairs(things) do
      thingsNode[thingtype] = thingdata[1]
      if not g_resources.fileExists("/things/" .. thingdata[1]) then
        incorrectThings = incorrectThings .. "Missing file: " .. thingdata[1] .. "\n"
        missingFiles = true
        versionForMissingFiles = thingdata[1]:split("/")[1]
      else
        local localChecksum = g_resources.fileChecksum("/things/" .. thingdata[1]):lower()
        if localChecksum ~= thingdata[2]:lower() and #thingdata[2] > 1 then
          if g_resources.isLoadedFromArchive() then -- ignore checksum if it's test/debug version
            incorrectThings = incorrectThings .. "Invalid checksum of file: " .. thingdata[1] .. " (is " .. localChecksum .. ", should be " .. thingdata[2]:lower() .. ")\n"
          end
        end
      end
    end
    g_settings.setNode("things", thingsNode)
  else
    g_settings.setNode("things", {})
  end
  if missingFiles then
    incorrectThings = incorrectThings .. "\nYou should open data/things and create directory " .. versionForMissingFiles .. 
    ".\nIn this directory (data/things/" .. versionForMissingFiles .. ") you should put missing\nfiles (Tibia.dat and Tibia.spr/Tibia.cwm) " ..
    "from correct Tibia version."
  end
  return incorrectThings
end

local function onTibia12HTTPResult(session, playdata)
  local characters = {}
  local worlds = {}
  local account = {
    status = 0,
    subStatus = 0,
    premDays = 0
  }
  if session["status"] ~= "active" then
    account.status = 1
  end
  if session["ispremium"] then
    account.subStatus = 1 -- premium
  end
  if session["premiumuntil"] > g_clock.seconds() then
    account.subStatus = math.floor((session["premiumuntil"] - g_clock.seconds()) / 86400)
  end
    
  local things = {
    data = {G.clientVersion .. "/Tibia.dat", ""},
    sprites = {G.clientVersion .. "/Tibia.cwm", ""},
  }

  local incorrectThings = validateThings(things)
  if #incorrectThings > 0 then
    things = {
      data = {G.clientVersion .. "/Tibia.dat", ""},
      sprites = {G.clientVersion .. "/Tibia.spr", ""},
    }  
    incorrectThings = validateThings(things)
  end
  
  if #incorrectThings > 0 then
    g_logger.error(incorrectThings)
    if Updater and not checkedByUpdater[G.clientVersion] then
      checkedByUpdater[G.clientVersion] = true
      return Updater.check({
        version = G.clientVersion,
        host = G.host
      })
    else
      return EnterGame.onError(incorrectThings)
    end
  end
  
  onSessionKey(nil, session["sessionkey"])
  
  for _, world in pairs(playdata["worlds"]) do
    worlds[world.id] = {
      name = world.name,
      port = world.externalportunprotected or world.externalportprotected or world.externaladdress,
      address = world.externaladdressunprotected or world.externaladdressprotected or world.externalport
    }
  end
  
  for _, character in pairs(playdata["characters"]) do
    local world = worlds[character.worldid]
    if world then
      table.insert(characters, {
        name = character.name,
        worldName = world.name,
        worldIp = world.address,
        worldPort = world.port
      })
    end
  end
  
  -- proxies
  if g_proxy then
    g_proxy.clear()
    if playdata["proxies"] then
      for i, proxy in ipairs(playdata["proxies"]) do
        g_proxy.addProxy(proxy["host"], tonumber(proxy["port"]), tonumber(proxy["priority"]))
      end
    end
  end
  
  g_game.setCustomProtocolVersion(0)
  g_game.chooseRsa(G.host)
  g_game.setClientVersion(G.clientVersion)
  g_game.setProtocolVersion(g_game.getClientProtocolVersion(G.clientVersion))
  g_game.setCustomOs(-1) -- disable
  if not g_game.getFeature(GameExtendedOpcode) then
    g_game.setCustomOs(5) -- set os to windows if opcodes are disabled
  end
  
  onCharacterList(nil, characters, account, nil)  
end

local function onHTTPResult(data, err)
  if waitingForHttpResults == 0 then
    return
  end
  
  waitingForHttpResults = waitingForHttpResults - 1
  if err and waitingForHttpResults > 0 then
    return -- ignore, wait for other requests
  end

  if err then
    return EnterGame.onError(err)
  end
  waitingForHttpResults = 0 
  if data['error'] and data['error']:len() > 0 then
    return EnterGame.onLoginError(data['error'])
  elseif data['errorMessage'] and data['errorMessage']:len() > 0 then
    return EnterGame.onLoginError(data['errorMessage'])
  end
  
  if type(data["session"]) == "table" and type(data["playdata"]) == "table" then
    return onTibia12HTTPResult(data["session"], data["playdata"])
  end  
  
  local characters = data["characters"]
  local account = data["account"]
  local session = data["session"]
 
  local version = data["version"]
  local things = data["things"]
  local customProtocol = data["customProtocol"]

  local features = data["features"]
  local settings = data["settings"]
  local rsa = data["rsa"]
  local proxies = data["proxies"]

  local incorrectThings = validateThings(things)
  if #incorrectThings > 0 then
    g_logger.info(incorrectThings)
    return EnterGame.onError(incorrectThings)
  end
  
  -- custom protocol
  g_game.setCustomProtocolVersion(0)
  if customProtocol ~= nil then
    customProtocol = tonumber(customProtocol)
    if customProtocol ~= nil and customProtocol > 0 then
      g_game.setCustomProtocolVersion(customProtocol)
    end
  end
  
  -- force player settings
  if settings ~= nil then
    for option, value in pairs(settings) do
      modules.client_options.setOption(option, value, true)
    end
  end
    
  -- version
  G.clientVersion = version
  g_game.setClientVersion(version)
  g_game.setProtocolVersion(g_game.getClientProtocolVersion(version))  
  g_game.setCustomOs(-1) -- disable
  
  if rsa ~= nil then
    g_game.setRsa(rsa)
  end

  if features ~= nil then
    parseFeatures(features)
  end

  if session ~= nil and session:len() > 0 then
    onSessionKey(nil, session)
  end
  
  -- proxies
  if g_proxy then
    g_proxy.clear()
    if proxies then
      for i, proxy in ipairs(proxies) do
        g_proxy.addProxy(proxy["host"], tonumber(proxy["port"]), tonumber(proxy["priority"]))
      end
    end
  end
  
  onCharacterList(nil, characters, account, nil)  
end


-- public functions
function EnterGame.init()
  if USE_NEW_ENERGAME then return end
  enterGame = g_ui.displayUI('entergame')
  
  if not enterGame then
    g_logger.error("Failed to load entergame UI")
    return
  end
  
  -- Hide window initially - it will be shown with animation later
  enterGame:hide()
  
  -- Set background image to cover entire window, scaled proportionally with slight overflow
  local backgroundImage = enterGame:getChildById('backgroundImage')
  
  if not backgroundImage then
    return
  end
  
  -- Ensure parent window doesn't clip
  enterGame:setClipping(false)
  
  -- Ensure background is behind all other elements
  backgroundImage:lower()
  
  -- Store reference globally so EnterGame.show() can access it
  EnterGame.backgroundImage = backgroundImage
  
  -- Function to update background image size and position
  -- Store globally so EnterGame.show() can call it
  EnterGame.updateBackgroundImage = function()
    local windowWidth = enterGame:getWidth()
    local windowHeight = enterGame:getHeight()
    
    local bgTextureWidth = backgroundImage:getImageTextureWidth()
    local bgTextureHeight = backgroundImage:getImageTextureHeight()
    
    if windowWidth <= 0 or windowHeight <= 0 then
      return
    end
    
    if bgTextureWidth <= 0 or bgTextureHeight <= 0 then
      return
    end
    
    -- Disable clipping to allow overflow beyond window bounds
    backgroundImage:setClipping(false)
    enterGame:setClipping(false)  -- Also disable parent clipping
    
    -- Use original texture size for the image box
    local newWidth = bgTextureWidth  -- 492
    local newHeight = bgTextureHeight  -- 330
    
    -- Calculate offset to position image above and to the left of login button
    -- Image is larger than window, so calculate offset from window center
    local centerX = math.floor((windowWidth - newWidth) / 2)
    local centerY = math.floor((windowHeight - newHeight) / 2)
    
    -- Break anchors first
    backgroundImage:breakAnchors()
    
    -- Set image dimensions (this scales the texture)
    backgroundImage:setImageWidth(newWidth)
    backgroundImage:setImageHeight(newHeight)
    
    -- Set widget size to match image
    backgroundImage:setSize({width = newWidth, height = newHeight})
    
    -- Position widget at 0,0 to ensure entire image is visible
    backgroundImage:setX(0)
    backgroundImage:setY(0)
    
    -- Use image offset to position image above and to the left of login button
    -- Calculate offset: move left and up from center
    local imgOffsetX = centerX - 20  -- Move 20px more to the left from center
    local imgOffsetY = centerY - 30  -- Move 30px more up from center (above login button)
    
    backgroundImage:setImageOffset({x = imgOffsetX, y = imgOffsetY})
    
    -- Ensure it's behind other elements (especially login button)
    backgroundImage:lower()
    
    -- Ensure login button is in front (get it fresh)
    local loginButton = enterGame:getChildById('loginButton')
    if loginButton then
      loginButton:raise()
    end
    
    -- Force show
    backgroundImage:show()
    backgroundImage:setVisible(true)
  end
  
  -- Also create local reference for scheduling
  local updateBackgroundImage = EnterGame.updateBackgroundImage
  
  -- Update multiple times to ensure it works
  scheduleEvent(function()
    updateBackgroundImage()
    scheduleEvent(updateBackgroundImage, 100)
    scheduleEvent(updateBackgroundImage, 300)
  end, 10)
  
  rememberPasswordBox = enterGame:getChildById('rememberPasswordBox')
  local loginButton = enterGame:getChildById('loginButton')
  
  -- Login button state will be controlled via functions
  
  local account = g_crypt.decrypt(g_settings.get('account'))
  local password = g_crypt.decrypt(g_settings.get('password'))
  
  -- Set textbox background colors
  local accountNameTextEdit = enterGame:getChildById('accountNameTextEdit')
  local accountPasswordTextEdit = enterGame:getChildById('accountPasswordTextEdit')
  if accountNameTextEdit then
    accountNameTextEdit:setBackgroundColor('#493E38')
    accountNameTextEdit:setImageSource('')
  end
  if accountPasswordTextEdit then
    accountPasswordTextEdit:setBackgroundColor('#493E38')
    accountPasswordTextEdit:setImageSource('')
  end
  
  accountPasswordTextEdit:setText(password)
  accountNameTextEdit:setText(account)
  rememberPasswordBox:setChecked(#account > 0)
    
  g_keyboard.bindKeyDown('Ctrl+G', EnterGame.openWindow)
  
  -- Create fullscreen status label in bottom left corner
  local rootWidget = g_ui.getRootWidget()
  fullscreenStatusLabel = g_ui.createWidget('UILabel', rootWidget)
  fullscreenStatusLabel:setId('fullscreenStatusLabel')
  fullscreenStatusLabel:setText('Window OFF')
  fullscreenStatusLabel:setColor('#888888')
  fullscreenStatusLabel:setTextAlign(AlignLeft)
  fullscreenStatusLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  fullscreenStatusLabel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  fullscreenStatusLabel:setMarginLeft(5)
  fullscreenStatusLabel:setMarginBottom(5)
  fullscreenStatusLabel:setSize({width = 100, height = 20})
  
  -- Function to update fullscreen status label
  local function updateFullscreenStatus()
    if fullscreenStatusLabel then
      if g_window.isFullscreen() then
        fullscreenStatusLabel:setText('Window ON')
        fullscreenStatusLabel:setColor('#00ff00')
      else
        fullscreenStatusLabel:setText('Window OFF')
        fullscreenStatusLabel:setColor('#888888')
      end
    end
  end
  
  -- Toggle for auto-fullscreen on startup (Ctrl+F12) - shortcut to options
  g_keyboard.bindKeyDown('Ctrl+F12', function()
    if modules.client_options then
      local currentValue = modules.client_options.getOption('autoFullscreenOnStartup')
      modules.client_options.setOption('autoFullscreenOnStartup', not currentValue)
      if not currentValue then
        g_logger.info("Auto-fullscreen on startup: ENABLED")
      else
        g_logger.info("Auto-fullscreen on startup: DISABLED")
      end
    end
    updateFullscreenStatus()
  end)
  
  -- Update status on window resize/fullscreen change
  connect(g_window, { onResize = updateFullscreenStatus })

  if g_game.isOnline() then
    return EnterGame.hide()
  end

  -- Check if auto-fullscreen is enabled from options
  local autoFullscreen = false
  if modules.client_options then
    autoFullscreen = modules.client_options.getOption('autoFullscreenOnStartup')
  else
    -- Fallback to settings if options module not loaded yet
    autoFullscreen = g_settings.get('autoFullscreenOnStartup', false)
  end
  
  if autoFullscreen then
    g_window.setFullscreen(true)
  else
    g_window.setFullscreen(false)
  end
  
  -- Update status label after a brief delay to ensure fullscreen state is set
  scheduleEvent(function()
    updateFullscreenStatus()
  end, 200)

  -- Wait 1 second before showing login window with animation
  scheduleEvent(function()
    EnterGame.show()
  end, 1000)
end

function EnterGame.terminate()
  if not enterGame then return end
  g_keyboard.unbindKeyDown('Ctrl+G')
  g_keyboard.unbindKeyDown('Ctrl+F12')
  
  if fullscreenStatusLabel then
    fullscreenStatusLabel:destroy()
    fullscreenStatusLabel = nil
  end
  
  enterGame:destroy()
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  if protocolLogin then
    protocolLogin:cancelLogin()
    protocolLogin = nil
  end
  EnterGame = nil
end

function EnterGame.show()
  if not enterGame then return end
  
  -- Animation: slide from bottom (fade already happened during the 1 second wait)
  local screenHeight = g_window.getHeight()
  local windowHeight = enterGame:getHeight()
  local finalY = math.floor((screenHeight - windowHeight) / 2)  -- Center position
  local startY = screenHeight + 100  -- Start from bottom (off-screen)
  
  -- Hide window first, then configure position
  enterGame:hide()
  
  -- Temporarily remove center anchor and set initial position
  enterGame:breakAnchors()
  enterGame:setY(startY)
  enterGame:setX(math.floor((g_window.getWidth() - enterGame:getWidth()) / 2))  -- Center horizontally
  enterGame:setOpacity(1)
  
  -- Ensure background image is visible when window is shown
  local backgroundImage = EnterGame.backgroundImage or enterGame:getChildById('backgroundImage')
  if backgroundImage then
    -- Update the image when window becomes visible
    scheduleEvent(function()
      -- Re-run update function now that window is visible
      if EnterGame.updateBackgroundImage then
        EnterGame.updateBackgroundImage()
      end
      backgroundImage:show()
      backgroundImage:setVisible(true)
      backgroundImage:lower()
    end, 50)
  end
  
  -- Now show and start animation
  enterGame:show()
  enterGame:raise()
  enterGame:focus()
  
    -- Animate to final position with smooth easing
    local animationTime = 800  -- milliseconds (increased for smoother animation)
    local stepInterval = 16  -- ~60fps for maximum smoothness
    local steps = math.ceil(animationTime / stepInterval)
    local totalDistance = startY - finalY
    local currentStep = 0
    
    local function easeOutCubic(t)
      return 1 - math.pow(1 - t, 3)  -- Easing function for smooth deceleration
    end
    
    local function animateSlide()
      currentStep = currentStep + 1
      local progress = currentStep / steps
      
      -- Apply easing for smooth deceleration
      local easedProgress = easeOutCubic(progress)
      local currentY = startY - (totalDistance * easedProgress)
      
      if currentStep >= steps then
        enterGame:setY(finalY)  -- Ensure final position
        -- Restore center anchor
        enterGame:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
        enterGame:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
        enterGame:getChildById('accountNameTextEdit'):focus()
      else
        enterGame:setY(currentY)
        scheduleEvent(animateSlide, stepInterval)
      end
    end
    
    scheduleEvent(animateSlide, stepInterval)
end

function EnterGame.hide()
  if not enterGame then return end
  enterGame:hide()
end

function EnterGame.openWindow()
  if g_game.isOnline() then
    CharacterList.show()
  elseif not g_game.isLogging() and not CharacterList.isVisible() then
    EnterGame.show()
  end
end

function EnterGame.clearAccountFields()
  enterGame:getChildById('accountNameTextEdit'):clearText()
  enterGame:getChildById('accountPasswordTextEdit'):clearText()
  enterGame:getChildById('accountNameTextEdit'):focus()
  g_settings.remove('account')
  g_settings.remove('password')
end

function EnterGame.onServerChange()
  -- Not used anymore, IP and Version are fixed
end

function EnterGame.onLoginButtonHover(widget)
  -- Reset animation before changing image to ensure it starts from the beginning
  widget:resetImageAnimation()
  
  if widget:isHovered() then
    widget:setImageSource('/images/landcore/loginhover')
  else
    widget:setImageSource('/images/landcore/login')
  end
end

function EnterGame.onLoginButtonPress(widget)
  widget:setImageSource('/images/landcore/loginclick')
end

function EnterGame.onLoginButtonRelease(widget)
  widget:resetImageAnimation()
  
  if widget:isHovered() then
    widget:setImageSource('/images/landcore/loginhover')
  else
    widget:setImageSource('/images/landcore/login')
  end
end

function EnterGame.doLogin(account, password, token, host)
  if g_game.isOnline() then
    local errorBox = displayErrorBox(tr('Login Error'), tr('Cannot login while already in game.'))
    connect(errorBox, { onOk = EnterGame.show })
    return
  end
  
  G.account = account or enterGame:getChildById('accountNameTextEdit'):getText()
  G.password = password or enterGame:getChildById('accountPasswordTextEdit'):getText()
  G.authenticatorToken = token or ""
  G.stayLogged = true
  G.server = ""
  G.host = host or "127.0.0.1"
  G.clientVersion = 1098  
 
  if not rememberPasswordBox:isChecked() then
    g_settings.set('account', G.account)
    g_settings.set('password', G.password)  
  end
  g_settings.set('host', G.host)
  g_settings.set('server', G.server)
  g_settings.set('client-version', G.clientVersion)
  g_settings.save()

  local server_params = G.host:split(":")
  if G.host:lower():find("http") ~= nil then
    if #server_params >= 4 then
      G.host = server_params[1] .. ":" .. server_params[2] .. ":" .. server_params[3] 
      G.clientVersion = tonumber(server_params[4])
    elseif #server_params >= 3 then
      if tostring(tonumber(server_params[3])) == server_params[3] then
        G.host = server_params[1] .. ":" .. server_params[2] 
        G.clientVersion = tonumber(server_params[3])
      end
    end
    return EnterGame.doLoginHttp()      
  end
  
  local server_ip = server_params[1]
  local server_port = 7171
  if #server_params >= 2 then
    server_port = tonumber(server_params[2])
  end
  if #server_params >= 3 then
    G.clientVersion = tonumber(server_params[3])
  end
  if type(server_ip) ~= 'string' or server_ip:len() <= 3 or not server_port or not G.clientVersion then
    return EnterGame.onError("Invalid server, it should be in format IP:PORT or it should be http url to login script")  
  end
  
  local things = {
    data = {G.clientVersion .. "/Tibia.dat", ""},
    sprites = {G.clientVersion .. "/Tibia.cwm", ""},
  }
  
  local incorrectThings = validateThings(things)
  if #incorrectThings > 0 then
    things = {
      data = {G.clientVersion .. "/Tibia.dat", ""},
      sprites = {G.clientVersion .. "/Tibia.spr", ""},
    }  
    incorrectThings = validateThings(things)
  end
  if #incorrectThings > 0 then
    g_logger.error(incorrectThings)
    if Updater and not checkedByUpdater[G.clientVersion] then
      checkedByUpdater[G.clientVersion] = true
      return Updater.check({
        version = G.clientVersion,
        host = G.host
      })
    else
      return EnterGame.onError(incorrectThings)
    end
  end

  protocolLogin = ProtocolLogin.create()
  protocolLogin.onLoginError = onProtocolError
  protocolLogin.onSessionKey = onSessionKey
  protocolLogin.onCharacterList = onCharacterList
  protocolLogin.onUpdateNeeded = onUpdateNeeded
  protocolLogin.onProxyList = onProxyList

  EnterGame.hide()
  loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to login server...'))
  connect(loadBox, { onCancel = function(msgbox)
                                  loadBox = nil
                                  protocolLogin:cancelLogin()
                                  EnterGame.show()
                                end })

  if G.clientVersion == 1000 then -- some people don't understand that tibia 10 uses 1100 protocol
    G.clientVersion = 1100
  end
  -- if you have custom rsa or protocol edit it here
  g_game.setClientVersion(G.clientVersion)
  g_game.setProtocolVersion(g_game.getClientProtocolVersion(G.clientVersion))
  g_game.setCustomProtocolVersion(0)
  g_game.setCustomOs(-1) -- disable
  g_game.chooseRsa(G.host)
  if #server_params <= 3 and not g_game.getFeature(GameExtendedOpcode) then
    g_game.setCustomOs(2) -- set os to windows if opcodes are disabled
  end

  -- extra features from init.lua
  for i = 4, #server_params do
    g_game.enableFeature(tonumber(server_params[i]))
  end
  
  -- proxies
  if g_proxy then
    g_proxy.clear()
  end
  
  if modules.game_things.isLoaded() then
    g_logger.info("Connecting to: " .. server_ip .. ":" .. server_port)
    protocolLogin:login(server_ip, server_port, G.account, G.password, G.authenticatorToken, G.stayLogged)
  else
    loadBox:destroy()
    loadBox = nil
    EnterGame.show()
  end
end

function EnterGame.doLoginHttp()
  if G.host == nil or G.host:len() < 10 then
    return EnterGame.onError("Invalid server url: " .. G.host)    
  end

  loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to login server...'))
  connect(loadBox, { onCancel = function(msgbox)
                                  loadBox = nil
                                  EnterGame.show()
                                end })                                
                              
  local data = {
    type = "login",
    account = G.account,
    accountname = G.account,
    email = G.account,
    password = G.password,
    accountpassword = G.password,
    token = G.authenticatorToken,
    version = APP_VERSION,
    uid = G.UUID,
    stayloggedin = true
  }
  
  waitingForHttpResults = 1
  HTTP.postJSON(G.host, data, onHTTPResult)
  EnterGame.hide()
end

function EnterGame.onError(err)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  local errorBox = displayErrorBox(tr('Login Error'), err)
  errorBox.onOk = EnterGame.show
end

function EnterGame.onLoginError(err)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  local errorBox = displayErrorBox(tr('Login Error'), err)
  errorBox.onOk = EnterGame.show
  if err:lower():find("invalid") or err:lower():find("not correct") or err:lower():find("or password") then
    EnterGame.clearAccountFields()
  end
end
