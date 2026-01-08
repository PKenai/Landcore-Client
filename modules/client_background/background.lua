-- private variables
local background

-- public functions
function init()
  background = g_ui.displayUI('background')
  background:lower()

  -- Verificar se o shader está sendo aplicado
  if background then
    -- Tentar aplicar o shader
    local shaderApplied = false
    if background.setImageShader then
      background:setImageShader("ui_life_simple")
      shaderApplied = true
    elseif background.setBackgroundShader then
      background:setBackgroundShader("ui_life_simple")
      if background.setBackgroundColor then
        background:setBackgroundColor("#000000")
      end
      shaderApplied = true
    end

    if not shaderApplied then
      -- Shader could not be applied - no shader methods available
    end

    -- Shader application verification completed
  end

  connect(g_game, { onGameStart = hide })
  connect(g_game, { onGameEnd = show })
end

function terminate()
  disconnect(g_game, { onGameStart = hide })
  disconnect(g_game, { onGameEnd = show })

  background:destroy()

  Background = nil
end

function hide()
  background:hide()
end

function show()
  background:show()
end

function getBackground()
  return background
end