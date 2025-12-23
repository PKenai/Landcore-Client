-- Spellbar
-- Sistema de barra de skills baseada em itens equipados
-- Configuração recebida do servidor via ExtendedOpcode JSON
--
-- FORMATO JSON ESPERADO DO SERVIDOR:
-- {
--   "action": "updateItemSkills",
--   "data": {
--     "1000": {  // ID do item (pode ser número ou string numérica)
--       "s1": "exura",
--       "s2": "exura gran",
--       "s3": "exura vita"
--     },
--     "Wood Sword": {  // OU por nome do item (string)
--       "s1": "exura",
--       "s2": "exura gran",
--       "s3": "exura vita"
--     }
--   }
-- }
--
-- NOTA: O servidor pode enviar por ID (número/string numérica) ou por nome (string).
-- O sistema tenta encontrar por ID primeiro, depois por nome.
--
-- Opcode para comunicação com servidor
local SPELLBAR_EXTENDED_OPCODE = 202

-- Variáveis privadas
local spellbarWindow
local gameRootPanel

-- Dados recebidos do servidor (não editável pelo player)
-- Formato: serverItemSkills[itemId] = { s1 = "exura", s2 = "exura gran", ... }
-- ou serverItemSkills[itemName] = { s1 = "exura", s2 = "exura gran", ... }
-- O servidor pode enviar por ID (número) ou por nome (string)
local serverItemSkills = {}

-- Configuração dos slots da barra
local slotOrder = { 's1', 's2', 's3', 's4', 's5', 's6' }

local slots = {
  s1 = { widgetId = 'slot1', buttonId = 'slot1Button', iconId = 'slot1Icon', key = '1' },
  s2 = { widgetId = 'slot2', buttonId = 'slot2Button', iconId = 'slot2Icon', key = '2' },
  s3 = { widgetId = 'slot3', buttonId = 'slot3Button', iconId = 'slot3Icon', key = '3' },
  s4 = { widgetId = 'slot4', buttonId = 'slot4Button', iconId = 'slot4Icon', key = 'R' },
  s5 = { widgetId = 'slot5', buttonId = 'slot5Button', iconId = 'slot5Icon', key = 'T' },
  s6 = { widgetId = 'slot6', buttonId = 'slot6Button', iconId = 'slot6Icon', key = 'Y' }
}

local currentSpells = {} -- slotName ("s1") -> string da spell

local DEFAULT_ICON = '/modules/game_tspellbar/imgs/vazio.png'
local SKILL_ICON_BASE = '/modules/game_tspellbar/imgs/skills/'

-- Handler para ExtendedOpcode JSON do servidor
-- Definido cedo para garantir que exista quando o módulo registra o callback
function onSpellbarExtendedJSONOpcode(protocol, code, json_data)
  if code ~= SPELLBAR_EXTENDED_OPCODE then
    return
  end

  local action = json_data['action']
  local data = json_data['data']

  if action == 'updateItemSkills' and data then
    updateItemSkills(data)
  elseif action == 'clearItemSkills' then
    -- Limpa todas as skills (útil quando o servidor quer resetar)
    serverItemSkills = {}
    rebuildSpellsFromEquipment()
  end
end

-- Funções auxiliares ---------------------------------------------------------

local function isChatEnabled()
  if not modules.game_chat or not modules.game_chat.isChatEnabled then
    return false
  end
  return modules.game_chat.isChatEnabled()
end

local function getSlotIconWidget(slotName)
  local info = slots[slotName]
  if not info or not spellbarWindow then
    return nil
  end
  if not info.iconWidget then
    local slotWidget = spellbarWindow:recursiveGetChildById(info.widgetId)
    if not slotWidget then return nil end
    info.iconWidget = slotWidget:getChildById(info.iconId)
  end
  return info.iconWidget
end

local function getSlotButtonWidget(slotName)
  local info = slots[slotName]
  if not info or not spellbarWindow then
    return nil
  end
  if not info.buttonWidget then
    local slotWidget = spellbarWindow:recursiveGetChildById(info.widgetId)
    if not slotWidget then return nil end
    info.buttonWidget = slotWidget:getChildById(info.buttonId)
  end
  return info.buttonWidget
end

local function resetSpellbarIcons()
  for _, slotName in ipairs(slotOrder) do
    currentSpells[slotName] = nil
    local icon = getSlotIconWidget(slotName)
    if icon then
      icon:setImageSource(DEFAULT_ICON)
    end
  end
end

local function updateIconsFromCurrentSpells()
  for _, slotName in ipairs(slotOrder) do
    local spellName = currentSpells[slotName]
    local icon = getSlotIconWidget(slotName)
    if icon then
      if spellName and spellName ~= '' then
        local path = SKILL_ICON_BASE .. spellName .. '.png'
        icon:setImageSource(path)
      else
        icon:setImageSource(DEFAULT_ICON)
      end
    end
  end
end

local function rebuildSpellsFromEquipment()
  resetSpellbarIcons()

  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  -- Debug: verifica se há dados do servidor
  local hasServerData = not table.empty(serverItemSkills)

  -- Varre TODOS os slots de equipamento (HEAD até AMMO) e aplica as skills definidas pelo servidor
  for invSlot = InventorySlotFirst, InventorySlotLast do
    local item = player:getInventoryItem(invSlot)
    if item then
      -- Usa getId() (clientId), que é o mesmo ID que estamos usando no servidor em SPELLBAR_ITEMS
      local itemId = item:getId()
      local itemName = item:getName()
      local cfg = nil
      
      -- Debug: mostra item encontrado
      -- (logs removidos)
      
      -- Tenta encontrar por ID primeiro
      cfg = serverItemSkills[itemId]
      
      -- Se não encontrou por ID numérico, tenta por string numérica
      if not cfg then
        cfg = serverItemSkills[tostring(itemId)]
      end
      
      if cfg then
        for slotName, spellName in pairs(cfg) do
          if table.contains(slotOrder, slotName) and type(spellName) == 'string' and spellName ~= '' then
            currentSpells[slotName] = spellName
          end
        end
      end
    end
  end

  updateIconsFromCurrentSpells()
end

local function executeSkill(slotName)
  local spellName = currentSpells[slotName]
  if not spellName or spellName == '' then
    return
  end

  -- Só funciona com o chat desativado
  if isChatEnabled() then
    return
  end

  g_game.talk(spellName)
end

local function setupButtonsCallbacks()
  for _, slotName in ipairs(slotOrder) do
    local button = getSlotButtonWidget(slotName)
    if button then
      button.onClick = function()
        executeSkill(slotName)
      end
    end
  end
end

local function bindKeys()
  if not gameRootPanel then
    gameRootPanel = modules.game_interface.getRootPanel()
  end

  for _, slotName in ipairs(slotOrder) do
    local info = slots[slotName]
    if info and info.key then
      g_keyboard.bindKeyDown(info.key, function()
        executeSkill(slotName)
      end, gameRootPanel)
    end
  end
end

local function unbindKeys()
  if not gameRootPanel then
    gameRootPanel = modules.game_interface.getRootPanel()
  end

  for _, slotName in ipairs(slotOrder) do
    local info = slots[slotName]
    if info and info.key then
      g_keyboard.unbindKeyDown(info.key, gameRootPanel)
    end
  end
end

-- Callbacks de eventos -------------------------------------------------------

local function onInventoryChange(player, slot, item, oldItem)
  -- Sempre que qualquer slot mudar, recalculamos a barra inteira
  rebuildSpellsFromEquipment()
end

-- Funções públicas -----------------------------------------------------------

function init()
  gameRootPanel = modules.game_interface.getRootPanel()

  -- Registrar handler para receber dados do servidor via ExtendedOpcode (sempre, como o módulo de shop)
  ProtocolGame.registerExtendedJSONOpcode(SPELLBAR_EXTENDED_OPCODE, onSpellbarExtendedJSONOpcode)

  -- Conectar eventos do jogo
  connect(g_game, {
    onGameStart = show,
    onGameEnd = hide
  })

  -- Conectar eventos de inventário do player
  connect(LocalPlayer, {
    onInventoryChange = onInventoryChange
  })

  bindKeys()

  -- Carregar interface se já estiver no jogo
  if g_game.isOnline() then
    show()
  end
end

function terminate()
  -- Desregistrar handler do ExtendedOpcode
  ProtocolGame.unregisterExtendedJSONOpcode(SPELLBAR_EXTENDED_OPCODE)

  -- Desconectar eventos
  disconnect(g_game, {
    onGameStart = show,
    onGameEnd = hide
  })

  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange
  })

  unbindKeys()

  -- Destruir janela se existir
  if spellbarWindow then
    spellbarWindow:destroy()
    spellbarWindow = nil
  end
end

function show()
  if not spellbarWindow then
    spellbarWindow = g_ui.loadUI('spellbar', modules.game_interface.getRootPanel())
    setupButtonsCallbacks()
    rebuildSpellsFromEquipment()
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

-- Função pública para receber dados do servidor
-- Pode ser chamada diretamente ou via ExtendedOpcode handler
-- data: tabela no formato { [serverId] = { s1 = "exura", s2 = "exura gran", ... }, ... }
function updateItemSkills(data)
  if not data or type(data) ~= 'table' then
    g_logger.warning('spellbar: updateItemSkills recebeu dados inválidos')
    return
  end

  -- Limpa dados antigos e atualiza com novos dados do servidor
  serverItemSkills = {}
  
  -- Processa os dados recebidos
  for itemKey, skills in pairs(data) do
    if type(skills) == 'table' then
      -- Mantém a chave original (pode ser número ou string numérica)
      -- O sistema de busca em rebuildSpellsFromEquipment vai tentar número e string
      local key = itemKey
      
      -- Se for string numérica, também armazena como número para busca rápida
      if type(itemKey) == 'string' then
        local numKey = tonumber(itemKey)
        if numKey then
          -- Armazena tanto como string quanto como número para compatibilidade
          key = numKey
        end
      end
      
      -- Valida e armazena as skills
      local validSkills = {}
      for slotName, spellName in pairs(skills) do
        if table.contains(slotOrder, slotName) and type(spellName) == 'string' and spellName ~= '' then
          validSkills[slotName] = spellName
        end
      end
      
      if not table.empty(validSkills) then
        -- Armazena pela chave normalizada (serverId numérico)
        serverItemSkills[key] = validSkills
        
        -- Se a chave original era string numérica, também armazena como string para compatibilidade
        if type(itemKey) == 'string' and tonumber(itemKey) then
          serverItemSkills[itemKey] = validSkills
        end
      end
    end
  end

  -- Reconstrói a barra com os novos dados
  rebuildSpellsFromEquipment()
end

