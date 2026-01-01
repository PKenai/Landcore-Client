-- private variables
local background

-- public functions
function init()
  background = g_ui.displayUI('background')
  background:lower()

  -- Log para verificar se o background foi carregado
  print("[BACKGROUND] Background widget loaded: " .. (background and "YES" or "NO"))

  -- Verificar se o shader está sendo aplicado
  if background then
    print("[BACKGROUND] Attempting to apply ui_life_simple shader...")

    -- Tentar aplicar o shader
    local shaderApplied = false
    if background.setImageShader then
      background:setImageShader("ui_life_simple")
      print("[BACKGROUND] Applied ui_life_simple via setImageShader")
      shaderApplied = true
    elseif background.setBackgroundShader then
      background:setBackgroundShader("ui_life_simple")
      print("[BACKGROUND] Applied ui_life_simple via setBackgroundShader")
      if background.setBackgroundColor then
        background:setBackgroundColor("#000000")
        print("[BACKGROUND] Set background color to black")
      end
      shaderApplied = true
    end

    if not shaderApplied then
      print("[BACKGROUND] WARNING: Could not apply shader - no shader methods available")
    end

    -- Verificar se o shader foi realmente aplicado
    scheduleEvent(function()
      if background then
        local currentImageShader = "N/A"
        local currentBgShader = "N/A"

        if background.getImageShader then
          currentImageShader = background:getImageShader() or "N/A"
        end

        if background.getBackgroundShader then
          currentBgShader = background:getBackgroundShader() or "N/A"
        end

        print("[BACKGROUND] Current image shader: " .. currentImageShader)
        print("[BACKGROUND] Current background shader: " .. currentBgShader)
        print("[BACKGROUND] Widget visible: " .. (background:isVisible() and "YES" or "NO"))
      end
    end, 1000) -- Verificar após 1 segundo
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