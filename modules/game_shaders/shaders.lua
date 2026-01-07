local GameOutfitShaders = 106

function init()
  -- add manually your shaders from /data/shaders

  -- map shaders
  g_shaders.createShader("map_default", "/shaders/map_default_vertex", "/shaders/map_default_fragment")  

  g_shaders.createShader("map_rainbow", "/shaders/map_rainbow_vertex", "/shaders/map_rainbow_fragment")
  g_shaders.addTexture("map_rainbow", "/images/shaders/rainbow.png")

  g_shaders.createShader("map_blood", "/shaders/map_blood_vertex", "/shaders/map_blood_fragment")

  -- UI shaders (for widgets and windows)
  g_shaders.createShader("ui_blood", "/shaders/ui_blood_vertex", "/shaders/ui_blood_fragment")
  g_shaders.createShader("ui_life_simple", "/shaders/ui_life_simple_vertex", "/shaders/ui_life_simple_fragment")

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader
  -- use modules.game_interface.gameMapPanel:setShader("map_blood") to set blood shader
  -- use widget:setImageShader("ui_blood") or widget:setBackgroundShader("ui_blood") for UI widgets

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader
  -- use modules.game_interface.gameMapPanel:setShader("map_blood") to set blood shader
  -- use widget:setImageShader("ui_blood") or widget:setBackgroundShader("ui_blood") for UI widgets

  -- outfit shaders
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit_default_vertex", "/shaders/outfit_default_fragment")
  -- shadow shader usado na Creature::draw (sombra inclinada)
  g_shaders.createOutfitShader("simple_soft_shadow", "/shaders/outfit_default_vertex", "/shaders/simple_soft_shadow_fragment")

  g_shaders.createOutfitShader("outfit_rainbow", "/shaders/outfit_rainbow_vertex", "/shaders/outfit_rainbow_fragment")
  g_shaders.addTexture("outfit_rainbow", "/images/shaders/rainbow.png")

  g_shaders.createOutfitShader("outfit_golden", "/shaders/outfit_golden_vertex", "/shaders/outfit_golden_fragment")
  g_shaders.addTexture("outfit_golden", "/images/shaders/stone.png")

  g_shaders.createOutfitShader("frostknock1novice_shader", "/shaders/outfit_frostknock1novice_shader_vertex", "/shaders/outfit_frostknock1novice_shader_fragment")
  g_shaders.addTexture("frostknock1novice_shader", "/images/shaders/stone.png")

  g_shaders.createOutfitShader("stoneskin1novice_shader", "/shaders/outfit_stoneskin1novice_shader_vertex", "/shaders/outfit_stoneskin1novice_shader_fragment")

  -- you can use creature:setOutfitShader("outfit_rainbow") to set shader
  -- you can use creature:setOutfitShader("outfit_golden") to set golden shader
  -- you can use creature:setOutfitShader("frostknock1novice_shader") to set blue frost shader

  -- Register handler for server extended opcode
  connect(g_game, {
    onGameStart = function()
      if ProtocolGame then
        ProtocolGame.registerExtendedOpcode(GameOutfitShaders, function(protocol, opcode, buffer)
          local player = g_game.getLocalPlayer()
          if player then
            if buffer == "" then
              -- Remove shader
              player:setOutfitShader("")
            else
              -- Apply shader
              player:setOutfitShader(buffer)
            end
          end
        end)
      end
    end,
    onGameEnd = function()
      if ProtocolGame then
        ProtocolGame.unregisterExtendedOpcode(GameOutfitShaders)
      end
    end
  })

  -- Register on game start if already online
  if g_game.isOnline() then
    if ProtocolGame then
      ProtocolGame.registerExtendedOpcode(GameOutfitShaders, function(protocol, opcode, buffer)
        local player = g_game.getLocalPlayer()
        if player then
          if buffer == "" then
            -- Remove shader
            player:setOutfitShader("")
          else
            -- Apply shader
            player:setOutfitShader(buffer)
          end
        end
      end)
    end
  end

end

function terminate()
end


