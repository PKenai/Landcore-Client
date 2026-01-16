timerPanel = nil
timerLabel = nil
currentTimer = nil
timerEvent = nil

function init()
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onDeath = onDeath,
    onLogout = onLogout
  })
end

function startSlideUpAnimation()
  -- Painel já está na posição final
  timerPanel:setOpacity(1.0)
  timerPanel:setVisible(true)

  -- Pega a referência da imagem
  local timerImage = timerPanel:getChildById('timerImage')
  if not timerImage then
    -- Fallback: apenas mostrar o timer sem animação
    updateTimer()
    return
  end

  -- Configura imagem e texto iniciais (invisíveis)
  local imageHeight = 78
  timerImage:setHeight(0)
  timerLabel:setOpacity(0)  -- Texto começa invisível

  -- Animação de revelação (cortando a imagem e revelando o texto)
  local animationDuration = 1200  -- ms (tempo dramático)
  local animationSteps = 48       -- Mais steps para máxima suavidade
  local stepDuration = animationDuration / animationSteps
  local heightStep = imageHeight / animationSteps
  local opacityStep = 1.0 / animationSteps  -- Opacidade do texto

  local currentStep = 0

  local function animateStep()
    currentStep = currentStep + 1
    local currentHeight = heightStep * currentStep
    local currentOpacity = opacityStep * currentStep

    -- Anima a altura da imagem
    timerImage:setHeight(math.min(imageHeight, currentHeight))

    -- Anima a opacidade do texto (ligeiramente atrasada para efeito)
    if currentStep > 6 then  -- Texto aparece um pouco depois da imagem
      local textOpacity = opacityStep * (currentStep - 6)
      timerLabel:setOpacity(math.min(1.0, textOpacity))
    end

    if currentStep < animationSteps then
      scheduleEvent(animateStep, stepDuration)
    else
      -- Animação completa
      timerImage:setHeight(imageHeight)
      timerLabel:setOpacity(1.0)  -- Texto totalmente visível
      updateTimer()  -- Inicia a contagem do timer após a revelação
    end
  end

  -- Inicia animação de revelação
  animateStep()
end

function terminate()
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onDeath = onDeath,
    onLogout = onLogout
  })

  stopTimer()
  if timerPanel then
    timerPanel:destroy()
    timerPanel = nil
  end
end

function online()
  -- Carrega a UI apenas quando o jogo estiver online
  if not timerPanel then
    local parentPanel = modules.game_interface.getRootPanel() or rootWidget
    if parentPanel then
      timerPanel = g_ui.loadUI('timer', parentPanel)
      if timerPanel then
        timerLabel = timerPanel:getChildById('timerLabel')
        if timerLabel then
          timerLabel:setText("00:00")
        end
      end
    end
  end

  -- Timer é reiniciado quando conecta
  stopTimer()
end

function offline()
  -- Remove timer quando desconecta
  stopTimer()
end

function onDeath()
  -- Remove timer quando morre
  stopTimer()
end

function onLogout()
  -- Remove timer quando faz logout
  stopTimer()
end

function startTimer(seconds)
  if not timerPanel or not timerLabel or seconds <= 0 then
    return
  end

  stopTimer()

  currentTimer = {
    totalSeconds = seconds,
    remainingSeconds = seconds,
    startTime = g_clock.millis()
  }

  -- Inicia animação de revelação (efeito pôr do sol)
  startSlideUpAnimation()
end

function updateTimer()
  if not currentTimer or not timerPanel or not timerLabel then
    stopTimer()
    return
  end

  -- Calcula tempo restante baseado no tempo real decorrido
  local elapsed = (g_clock.millis() - currentTimer.startTime) / 1000
  currentTimer.remainingSeconds = math.max(0, currentTimer.totalSeconds - elapsed)

  if currentTimer.remainingSeconds <= 0 then
    -- Timer acabou
    stopTimer()
    return
  end

  -- Formata o tempo em MM:SS
  local minutes = math.floor(currentTimer.remainingSeconds / 60)
  local seconds = math.floor(currentTimer.remainingSeconds % 60)
  local timeString = string.format("%02d:%02d", minutes, seconds)

  -- Atualiza o texto do timer
  timerLabel:setText(timeString)

  -- FADE OUT nos últimos 5 segundos
  if currentTimer.remainingSeconds <= 5 then
    local opacity = currentTimer.remainingSeconds / 5.0
    timerPanel:setOpacity(opacity)
  else
    -- Garante opacidade total quando não está no fade out
    timerPanel:setOpacity(1.0)
  end

  -- Continua atualizando a cada segundo
  timerEvent = scheduleEvent(function()
    updateTimer()
  end, 1000)
end

function stopTimer()
  if timerEvent then
    removeEvent(timerEvent)
    timerEvent = nil
  end

  if timerPanel then
    timerPanel:setOpacity(1.0)  -- Reseta opacidade para próxima vez
    timerPanel:setVisible(false)
  end

  currentTimer = nil
end

function isTimerActive()
  return currentTimer ~= nil and timerPanel and timerPanel:isVisible()
end

function getRemainingTime()
  if not currentTimer then
    return 0
  end

  local elapsed = (g_clock.millis() - currentTimer.startTime) / 1000
  return math.max(0, currentTimer.totalSeconds - elapsed)
end