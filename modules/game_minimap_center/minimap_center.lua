-- CONFIGURAÇÃO DE POSIÇÃO DA MOLDURA
-- Você pode ajustar esses valores para posicionar a moldura
-- offsetX e offsetY: deslocamento em pixels da moldura em relação ao minimap
-- Use valores negativos para mover para esquerda/cima, positivos para direita/baixo
FRAME_OFFSET_X = -20  -- Deslocamento horizontal (pixels)
FRAME_OFFSET_Y = -40  -- Deslocamento vertical (pixels)
FRAME_SIZE_OFFSET_WIDTH = 35   -- Ajuste de largura (pixels) - positivo aumenta, negativo diminui
FRAME_SIZE_OFFSET_HEIGHT = 60  -- Ajuste de altura (pixels) - positivo aumenta, negativo diminui

minimapCenterWindow = nil
minimapWidget = nil
minimapFrame = nil
opacityTimer = nil
fadeAnimationTimer = nil
currentOpacity = 0.4
targetOpacity = 0.4

-- Tamanhos do minimapa
NORMAL_WINDOW_SIZE = {width = 300, height = 300}
NORMAL_MINIMAP_SIZE = {width = 250, height = 250}
SMALL_WINDOW_SIZE = {width = 150, height = 150}  -- Tamanho reduzido
SMALL_MINIMAP_SIZE = {width = 195, height = 195}  -- Tamanho reduzido (140 + 10% = 154)
currentWindowSize = {width = 300, height = 300}
currentMinimapSize = {width = 250, height = 250}
targetWindowSize = {width = 300, height = 300}
targetMinimapSize = {width = 250, height = 250}

function init()
  -- Desabilitar o minimapa antigo
  disableOldMinimap()
  
  -- Os estilos de data/styles já são carregados globalmente pelo módulo client_styles
  -- Apenas importar o estilo do próprio módulo
  g_ui.importStyle('minimap_center')
  
  -- Carregar a UI do módulo usando createWidget no painel do jogo
  local gameRootPanel = modules.game_interface.getRootPanel()
  if not gameRootPanel then
    gameRootPanel = rootWidget
  end
  minimapCenterWindow = g_ui.createWidget('MinimapCenterWindow', gameRootPanel)
  if not minimapCenterWindow then
    return
  end
  
  -- Garantir que o widget está visível e acima de outros elementos
  minimapCenterWindow:setVisible(true)
  minimapCenterWindow:setEnabled(true)
  minimapCenterWindow:raise()
  minimapCenterWindow:setPhantom(false)
  
  -- Remover anchors que possam estar fixando a posição
  minimapCenterWindow:breakAnchors()
  
  minimapWidget = minimapCenterWindow:recursiveGetChildById('minimap')
  if not minimapWidget then
    return
  end
  
  -- Aplicar transparência de 40% no minimap
  minimapWidget:setOpacity(0.4)
  currentOpacity = 0.4
  targetOpacity = 0.4
  
  -- Inicializar tamanhos
  currentWindowSize = {width = NORMAL_WINDOW_SIZE.width, height = NORMAL_WINDOW_SIZE.height}
  currentMinimapSize = {width = NORMAL_MINIMAP_SIZE.width, height = NORMAL_MINIMAP_SIZE.height}
  targetWindowSize = {width = NORMAL_WINDOW_SIZE.width, height = NORMAL_WINDOW_SIZE.height}
  targetMinimapSize = {width = NORMAL_MINIMAP_SIZE.width, height = NORMAL_MINIMAP_SIZE.height}
  
  -- Remover todos os botões do minimap
  local resetWidget = minimapWidget:recursiveGetChildById('resetWidget')
  if resetWidget then
    resetWidget:destroy()
  end
  
  local zoomInWidget = minimapWidget:recursiveGetChildById('zoomInWidget')
  if zoomInWidget then
    zoomInWidget:destroy()
  end
  
  local zoomOutWidget = minimapWidget:recursiveGetChildById('zoomOutWidget')
  if zoomOutWidget then
    zoomOutWidget:destroy()
  end
  
  local floorUpWidget = minimapWidget:recursiveGetChildById('floorUpWidget')
  if floorUpWidget then
    floorUpWidget:destroy()
  end
  
  local floorDownWidget = minimapWidget:recursiveGetChildById('floorDownWidget')
  if floorDownWidget then
    floorDownWidget:destroy()
  end
  
  -- Adicionar eventos de mouse para controlar opacidade
  minimapWidget.onHoverChange = function(widget, hovered)
    if hovered then
      setFullOpacity()
    else
      scheduleOpacityFade()
    end
  end
  
  -- Criar a moldura como widget separado no rootWidget
  minimapFrame = g_ui.createWidget('UIWidget', rootWidget)
  minimapFrame:setId('minimapFrame')
  minimapFrame:setImageSource('/images/landcore/moldura_minimap')
  minimapFrame:setFocusable(false)
  minimapFrame:setPhantom(true)
  minimapFrame:setVisible(false)  -- Inicialmente invisível até o jogo iniciar
  minimapFrame:setOpacity(0.4)  -- 40% de transparência
  
  -- Adicionar eventos de mouse na moldura também
  minimapFrame.onHoverChange = function(widget, hovered)
    if hovered then
      setFullOpacity()
    else
      scheduleOpacityFade()
    end
  end
  
  -- Posicionar a janela no canto inferior direito após ser renderizada
  scheduleEvent(function()
    centerWindow()
  end, 50)
  
  -- Atualizar moldura após um delay maior para garantir que tudo está renderizado
  scheduleEvent(function()
    updateFramePosition()
  end, 150)
  
  -- Atualizar posição da moldura quando a janela mover ou redimensionar
  connect(minimapCenterWindow, {
    onGeometryChange = function()
      updateFramePosition()
    end
  })
  
  -- Também atualizar quando a janela do jogo redimensionar
  connect(g_app, {
    onWindowResize = function()
      centerWindow()
      scheduleEvent(function()
        updateFramePosition()
      end, 50)
    end
  })
  
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })
  
  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })
  
  if g_game.isOnline() then
    online()
  end
end

function terminate()
  -- Cancelar timers se existirem
  if opacityTimer then
    removeEvent(opacityTimer)
    opacityTimer = nil
  end
  if fadeAnimationTimer then
    removeEvent(fadeAnimationTimer)
    fadeAnimationTimer = nil
  end
  
  if g_game.isOnline() then
    saveMap()
  end
  
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })
  
  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })
  
  if minimapWidget then
    minimapWidget.onHoverChange = nil
  end
  
  if minimapFrame then
    minimapFrame.onHoverChange = nil
    minimapFrame:destroy()
    minimapFrame = nil
  end
  
  if minimapCenterWindow then
    minimapCenterWindow:destroy()
    minimapCenterWindow = nil
  end
  
  minimapWidget = nil
end

function centerWindow()
  if not minimapCenterWindow then 
    return 
  end
  
  local windowWidth = minimapCenterWindow:getWidth()
  local windowHeight = minimapCenterWindow:getHeight()
  local screenWidth = g_window.getWidth()
  local screenHeight = g_window.getHeight()
  
  -- Posicionar no canto inferior direito com pequena margem
  local margin = 10
  local x = screenWidth - windowWidth - margin
  local y = screenHeight - windowHeight - margin
  
  -- Remover quaisquer anchors que possam estar impedindo o movimento
  minimapCenterWindow:breakAnchors()
  
  -- Posicionar a janela
  minimapCenterWindow:setX(x)
  minimapCenterWindow:setY(y)
  
  -- Verificar se moveu e atualizar moldura
  scheduleEvent(function()
    local actualX = minimapCenterWindow:getX()
    local actualY = minimapCenterWindow:getY()
    
    if actualX ~= x or actualY ~= y then
      -- Tentar novamente
      minimapCenterWindow:setX(x)
      minimapCenterWindow:setY(y)
    end
    
    -- Atualizar posição da moldura
    updateFramePosition()
  end, 10)
end

function updateFramePosition()
  if not minimapFrame or not minimapWidget or not minimapCenterWindow then
    return
  end
  
  -- Verificar se os widgets estão visíveis
  if not minimapCenterWindow:isVisible() then
    return
  end
  
  -- Obter a posição da janela
  local windowX = minimapCenterWindow:getX()
  local windowY = minimapCenterWindow:getY()
  
  -- Calcular a posição do minimap relativa à janela
  local windowWidth = minimapCenterWindow:getWidth()
  local windowHeight = minimapCenterWindow:getHeight()
  local minimapWidth = minimapWidget:getWidth()
  local minimapHeight = minimapWidget:getHeight()
  
  -- Calcular posição relativa do minimap (centrado na janela)
  local minimapRelativeX = (windowWidth - minimapWidth) / 2
  local minimapRelativeY = (windowHeight - minimapHeight) / 2
  
  -- Posição global do minimap
  local minimapX = windowX + minimapRelativeX
  local minimapY = windowY + minimapRelativeY
  
  -- Aplicar os offsets configurados
  local frameX = minimapX + FRAME_OFFSET_X
  local frameY = minimapY + FRAME_OFFSET_Y
  local frameWidth = minimapWidth + FRAME_SIZE_OFFSET_WIDTH
  local frameHeight = minimapHeight + FRAME_SIZE_OFFSET_HEIGHT
  
  -- Posicionar a moldura sobre o minimap
  minimapFrame:setX(frameX)
  minimapFrame:setY(frameY)
  minimapFrame:setWidth(frameWidth)
  minimapFrame:setHeight(frameHeight)
  minimapFrame:raise()  -- Garantir que fique acima de outros elementos
end

function online()
  -- Garantir que a janela está visível quando o jogo iniciar
  if minimapCenterWindow then
    minimapCenterWindow:setVisible(true)
    minimapCenterWindow:raise()
    
    -- Reposicionar após o jogo iniciar
    scheduleEvent(function()
      centerWindow()
    end, 100)
  end
  
  -- Tornar a moldura visível quando o jogo iniciar
  if minimapFrame then
    minimapFrame:setVisible(true)
    minimapFrame:raise()
    
    -- Atualizar posição da moldura após um pequeno delay
    scheduleEvent(function()
      updateFramePosition()
    end, 150)
  end
  
  -- Reconectar eventos caso tenham sido desconectados
  if not minimapWidget then
    minimapWidget = minimapCenterWindow:recursiveGetChildById('minimap')
    if minimapWidget then
      -- Reconfigurar opacidade e eventos
      minimapWidget:setOpacity(currentOpacity)
      minimapWidget.onHoverChange = function(widget, hovered)
        if hovered then
          setFullOpacity()
        else
          scheduleOpacityFade()
        end
      end
      
      -- Remover botões novamente caso tenham sido recriados
      local resetWidget = minimapWidget:recursiveGetChildById('resetWidget')
      if resetWidget then resetWidget:destroy() end
      local zoomInWidget = minimapWidget:recursiveGetChildById('zoomInWidget')
      if zoomInWidget then zoomInWidget:destroy() end
      local zoomOutWidget = minimapWidget:recursiveGetChildById('zoomOutWidget')
      if zoomOutWidget then zoomOutWidget:destroy() end
      local floorUpWidget = minimapWidget:recursiveGetChildById('floorUpWidget')
      if floorUpWidget then floorUpWidget:destroy() end
      local floorDownWidget = minimapWidget:recursiveGetChildById('floorDownWidget')
      if floorDownWidget then floorDownWidget:destroy() end
    end
  end
  
  loadMap()
  updateCameraPosition()
end

function offline()
  saveMap()
  
  -- Esconder o minimapa e a moldura quando sair do jogo
  if minimapCenterWindow then
    minimapCenterWindow:setVisible(false)
  end
  
  if minimapFrame then
    minimapFrame:setVisible(false)
  end
end

function loadMap()
  if not minimapWidget then 
    return 
  end
  
  local clientVersion = g_game.getClientVersion()
  
  g_minimap.clean()
  
  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
  
  local loaded = false
  if g_resources.fileExists(dataMinimapFile) then
    loaded = g_minimap.loadOtmm(dataMinimapFile)
  end
  if not loaded and g_resources.fileExists(versionedMinimapFile) then
    loaded = g_minimap.loadOtmm(versionedMinimapFile)
  end
  if not loaded and g_resources.fileExists(minimapFile) then
    loaded = g_minimap.loadOtmm(minimapFile)
  end
  
  if minimapWidget then
    minimapWidget:load()
  end
end

function saveMap()
  if not minimapWidget then 
    return 
  end
  
  local clientVersion = g_game.getClientVersion()
  local minimapFile = '/minimap' .. clientVersion .. '.otmm'
  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function updateCameraPosition()
  if not minimapWidget then return end
  
  local player = g_game.getLocalPlayer()
  if not player then return end
  
  local pos = player:getPosition()
  if not pos then return end
  
  if not minimapWidget:isDragging() then
    minimapWidget:setCameraPosition(player:getPosition())
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function setFullOpacity()
  -- Cancelar timers se existirem
  if opacityTimer then
    removeEvent(opacityTimer)
    opacityTimer = nil
  end
  if fadeAnimationTimer then
    removeEvent(fadeAnimationTimer)
    fadeAnimationTimer = nil
  end
  
  -- Iniciar fade para 100% de opacidade e tamanho normal
  targetOpacity = 1.0
  targetWindowSize = {width = NORMAL_WINDOW_SIZE.width, height = NORMAL_WINDOW_SIZE.height}
  targetMinimapSize = {width = NORMAL_MINIMAP_SIZE.width, height = NORMAL_MINIMAP_SIZE.height}
  startFadeAnimation()
end

function setFadedOpacity()
  -- Iniciar fade para 40% de opacidade e tamanho reduzido
  targetOpacity = 0.4
  targetWindowSize = {width = SMALL_WINDOW_SIZE.width, height = SMALL_WINDOW_SIZE.height}
  targetMinimapSize = {width = SMALL_MINIMAP_SIZE.width, height = SMALL_MINIMAP_SIZE.height}
  startFadeAnimation()
end

-- Função de easing para animação mais suave (ease-in-out)
local function easeInOut(t)
  return t * t * (3.0 - 2.0 * t)
end

function startFadeAnimation()
  -- Cancelar animação anterior se existir
  if fadeAnimationTimer then
    removeEvent(fadeAnimationTimer)
  end
  
  local startOpacity = currentOpacity
  local startWindowSize = {width = currentWindowSize.width, height = currentWindowSize.height}
  local startMinimapSize = {width = currentMinimapSize.width, height = currentMinimapSize.height}
  local fadeDuration = 1000  -- 1 segundo
  local startTime = g_clock.millis()
  local steps = 60  -- Mais steps para animação mais suave
  local stepDuration = fadeDuration / steps
  
  local function animate()
    local elapsed = g_clock.millis() - startTime
    local progress = math.min(elapsed / fadeDuration, 1.0)
    
    -- Aplicar easing para animação mais suave
    local easedProgress = easeInOut(progress)
    
    -- Interpolação com easing para opacidade
    currentOpacity = startOpacity + (targetOpacity - startOpacity) * easedProgress
    
    -- Interpolação com easing para tamanhos
    currentWindowSize.width = startWindowSize.width + (targetWindowSize.width - startWindowSize.width) * easedProgress
    currentWindowSize.height = startWindowSize.height + (targetWindowSize.height - startWindowSize.height) * easedProgress
    currentMinimapSize.width = startMinimapSize.width + (targetMinimapSize.width - startMinimapSize.width) * easedProgress
    currentMinimapSize.height = startMinimapSize.height + (targetMinimapSize.height - startMinimapSize.height) * easedProgress
    
    -- Aplicar opacidade nos widgets
    if minimapWidget then
      minimapWidget:setOpacity(currentOpacity)
    end
    if minimapFrame then
      minimapFrame:setOpacity(currentOpacity)
    end
    
    -- Aplicar tamanhos nos widgets
    if minimapCenterWindow then
      minimapCenterWindow:setWidth(math.floor(currentWindowSize.width))
      minimapCenterWindow:setHeight(math.floor(currentWindowSize.height))
    end
    if minimapWidget then
      minimapWidget:setWidth(math.floor(currentMinimapSize.width))
      minimapWidget:setHeight(math.floor(currentMinimapSize.height))
    end
    
    -- Atualizar posição da moldura após mudança de tamanho
    updateFramePosition()
    
    -- Reposicionar no canto após mudança de tamanho
    if minimapCenterWindow then
      local screenWidth = g_window.getWidth()
      local screenHeight = g_window.getHeight()
      local margin = 10
      local x = screenWidth - math.floor(currentWindowSize.width) - margin
      local y = screenHeight - math.floor(currentWindowSize.height) - margin
      minimapCenterWindow:setX(x)
      minimapCenterWindow:setY(y)
    end
    
    if progress < 1.0 then
      fadeAnimationTimer = scheduleEvent(animate, stepDuration)
    else
      currentOpacity = targetOpacity
      currentWindowSize = {width = targetWindowSize.width, height = targetWindowSize.height}
      currentMinimapSize = {width = targetMinimapSize.width, height = targetMinimapSize.height}
      fadeAnimationTimer = nil
    end
  end
  
  -- Iniciar animação
  animate()
end

function scheduleOpacityFade()
  -- Cancelar timer anterior se existir
  if opacityTimer then
    removeEvent(opacityTimer)
  end
  
  -- Agendar fade para 40% após 5 segundos
  opacityTimer = scheduleEvent(function()
    setFadedOpacity()
    opacityTimer = nil
  end, 5000)
end

function disableOldMinimap()
  -- Aguardar o módulo game_minimap ser carregado
  scheduleEvent(function()
    if modules.game_minimap then
      -- Esconder e desabilitar a janela do minimapa antigo
      if modules.game_minimap.minimapWindow then
        modules.game_minimap.minimapWindow:setVisible(false)
        modules.game_minimap.minimapWindow:setEnabled(false)
        modules.game_minimap.minimapWindow:setPhantom(true)
        modules.game_minimap.minimapWindow:close()
      end
      
      -- Esconder e desabilitar o botão do minimapa antigo
      if modules.game_minimap.minimapButton then
        modules.game_minimap.minimapButton:setVisible(false)
        modules.game_minimap.minimapButton:setEnabled(false)
        modules.game_minimap.minimapButton:setOn(false)
      end
      
      -- Desabilitar o widget do minimapa antigo
      if modules.game_minimap.minimapWidget then
        modules.game_minimap.minimapWidget:setVisible(false)
        modules.game_minimap.minimapWidget:setEnabled(false)
        modules.game_minimap.minimapWidget:setPhantom(true)
      end
      
      -- Sobrescrever a função toggle para não fazer nada
      if modules.game_minimap.toggle then
        local originalToggle = modules.game_minimap.toggle
        modules.game_minimap.toggle = function()
          -- Não fazer nada, mantém a referência mas desabilita a funcionalidade
        end
      end
    else
      -- Tentar novamente se o módulo ainda não foi carregado
      scheduleEvent(disableOldMinimap, 200)
    end
  end, 100)
end
