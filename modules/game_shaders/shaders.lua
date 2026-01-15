function init()
  -- add manually your shaders from /data/shaders

  -- ui shaders
  g_shaders.createShader("ui_life_simple", "/shaders/ui_life_simple_vertex", "/shaders/ui_life_simple_fragment")
  g_shaders.createShader("ui_blood", "/shaders/ui_blood_vertex", "/shaders/ui_blood_fragment")

  -- map shaders
  g_shaders.createShader("map_default", "/shaders/map_default_vertex", "/shaders/map_default_fragment")  

  g_shaders.createShader("map_rainbow", "/shaders/map_rainbow_vertex", "/shaders/map_rainbow_fragment")
  g_shaders.addTexture("map_rainbow", "/images/shaders/rainbow.png")

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader

  -- outfit shaders
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit_default_vertex", "/shaders/outfit_default_fragment")

  -- shadow shader
  g_shaders.createOutfitShader("simple_soft_shadow", "/shaders/outfit_default_vertex", "/shaders/simple_soft_shadow_fragment")

  g_shaders.createOutfitShader("Shader #25", "/shaders/outfit_rainbow_vertex", "/shaders/outfit_rainbow_fragment")
  g_shaders.addTexture("Shader #25", "/images/shaders/rainbow.png")

  -- you can use creature:setOutfitShader("outfit_rainbow") to set shader
  g_shaders.createOutfitShader("Shader #1", "/shaders/outfit_rainbow_vertex", "/shaders/energizer_yellow")
  g_shaders.createOutfitShader("Shader #2", "/shaders/outfit_rainbow_vertex", "/shaders/energizer_white")
  g_shaders.createOutfitShader("Shader #3", "/shaders/rainbow_vertex", "/shaders/energizer_red")
  g_shaders.createOutfitShader("Shader #4", "/shaders/outfit_rainbow_vertex", "/shaders/energizer_orange")
  g_shaders.createOutfitShader("Shader #5", "/shaders/outfit_rainbow_vertex", "/shaders/energizer_blue")
  g_shaders.createOutfitShader("Shader #6", "/shaders/outfit_rainbow_vertex", "/shaders/energizer_pink")
  
  g_shaders.createOutfitShader("Shader #7", "/shaders/outfit_rainbow_vertex", "/shaders/bloohs_green")
  g_shaders.createOutfitShader("Shader #8", "/shaders/outfit_rainbow_vertex", "/shaders/bloohs_red")
  g_shaders.createOutfitShader("Shader #9", "/shaders/outfit_rainbow_vertex", "/shaders/bloohs_white")
  g_shaders.createOutfitShader("Shader #10", "/shaders/outfit_rainbow_vertex", "/shaders/bloohs_yellow")
  
  g_shaders.createOutfitShader("Shader #11", "/shaders/outfit_rainbow_vertex", "/shaders/dortmond_green")
  g_shaders.createOutfitShader("Shader #12", "/shaders/outfit_rainbow_vertex", "/shaders/dortmond_red")
  g_shaders.createOutfitShader("Shader #13", "/shaders/outfit_rainbow_vertex", "/shaders/dortmond_white")
  g_shaders.createOutfitShader("Shader #14", "/shaders/outfit_rainbow_vertex", "/shaders/dortmond_yellow")
  g_shaders.createOutfitShader("Shader #15", "/shaders/outfit_rainbow_vertex", "/shaders/dortmond_blue")
  
  g_shaders.createOutfitShader("Shader #16", "/shaders/outfit_rainbow_vertex", "/shaders/blue_lumni")  
  g_shaders.createOutfitShader("Shader #17", "/shaders/outfit_rainbow_vertex", "/shaders/green_lumni")
  g_shaders.createOutfitShader("Shader #18", "/shaders/outfit_rainbow_vertex", "/shaders/red_lumni")
  g_shaders.createOutfitShader("Shader #19", "/shaders/outfit_rainbow_vertex", "/shaders/yellow_lumni")
	
  g_shaders.createOutfitShader("Shader #20", "/shaders/outfit_rainbow_vertex", "/shaders/yellow_ozeus")
  g_shaders.createOutfitShader("Shader #21", "/shaders/outfit_rainbow_vertex", "/shaders/blue_ozeus")
  g_shaders.createOutfitShader("Shader #22", "/shaders/outfit_rainbow_vertex", "/shaders/green_ozeus")
  g_shaders.createOutfitShader("Shader #23", "/shaders/outfit_rainbow_vertex", "/shaders/red_ozeus")
  g_shaders.createOutfitShader("Shader #24", "/shaders/outfit_rainbow_vertex", "/shaders/white_ozeus")
end

function terminate()
end


