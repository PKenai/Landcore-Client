-- Spellbar
-- Gerado pelo OTUI Editor em 23/12/2025 04:23

-- Variáveis privadas
local spellbarWindow

-- Funções públicas
function init()
  -- Conectar eventos do jogo
  connect(g_game, {
    onGameStart = show,
    onGameEnd = hide
  })

  -- Carregar interface se já estiver no jogo
  if g_game.isOnline() then
    show()
  end
end

function terminate()
  -- Desconectar eventos
  disconnect(g_game, {
    onGameStart = show,
    onGameEnd = hide
  })

  -- Destruir janela se existir
  if spellbarWindow then
    spellbarWindow:destroy()
    spellbarWindow = nil
  end
end

function show()
  if not spellbarWindow then
    spellbarWindow = g_ui.loadUI('spellbar', modules.game_interface.getRootPanel())
  end

  spellbarWindow:show()
  spellbarWindow:raise()
  spellbarWindow:focus()
end

function hide()
  if spellbarWindow then
    spellbarWindow:hide()
  end
end

function toggle()
  if spellbarWindow and spellbarWindow:isVisible() then
    hide()
  else
    show()
  end
end

-- Adicione suas funções personalizadas abaixo
