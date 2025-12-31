-- Definição das zonas com suas imagens correspondentes
local areas = {
	{from = {x = 92, y = 114, z = 7}, to = {x = 98, y = 120, z = 7}, priority = 1, name = 'Cidade principal', image = 'BLACK'},

	}
local area = nil
local currentImage = nil
local intervalo = 1
local duracao = 5
local retorno = 0
local eventAnimation = nil
local check = true
function isInRange(pos, fromPos, toPos)
    return
        pos.x>=fromPos.x and
        pos.y>=fromPos.y and
        pos.z>=fromPos.z and
        pos.x<=toPos.x and
        pos.y<=toPos.y and
        pos.z<=toPos.z
end

-- Função helper para adicionar novas zonas facilmente
-- Uso: addZone(fromX, fromY, fromZ, toX, toY, toZ, priority, name, imageName)
function addZone(fromX, fromY, fromZ, toX, toY, toZ, priority, name, imageName)
    table.insert(areas, {
        from = {x = fromX, y = fromY, z = fromZ},
        to = {x = toX, y = toY, z = toZ},
        priority = priority,
        name = name,
        image = imageName
    })
end

function init()
	placa = g_ui.displayUI('cityInfo', modules.game_interface.getRootPanel())
	placa:setVisible(false)
	
	connect(g_game, { onGameStart = updatePosition})
	connect(g_game, { onGameStart = AdjustSize})
	
	connect(LocalPlayer, {
		onPositionChange = updatePosition
	})
end
function AdjustSize()
	local top = (g_window.getHeight()/2) - 100  -- Ajustado para o novo tamanho 386x122
	placa:setMarginTop(-top)
end

function terminate()
	placa:destroy()
end

function updatePosition()
	local player = g_game.getLocalPlayer()
	if not player then
		return 
	end
	local pos = player:getPosition()
	if not pos then return end
	check = false
	local prioridade = nil
	for i = 1, #areas do
		if isInRange(pos, areas[i].from, areas[i].to) then
			if prioridade == nil then
				prioridade = areas[i].priority
				Table = areas[i]
			end
			
			if areas[i].priority > prioridade then
				Table = areas[i]
				prioridade = areas[i].priority
			end
			check = true
		end
	end
	if check == true then
		if Table.name == area and Table.image == currentImage then
			return false
		else
			reset()
			area = Table.name
			currentImage = Table.image
			retorno = 1
			-- Define a imagem baseada na zona
			local imagePath = 'img/' .. currentImage
			placa:setImageSource(imagePath)
			placa:setOpacity(0)  -- Começa invisível para evitar o flash
			placa:setVisible(true)
			eventAnimation = cycleEvent(function() showPlaca(retorno) end, 200)
			check = true
		end
	else
		reset()	
	end
end

function reset()
	area = nil
	currentImage = nil
	removeEvent(eventAnimation)
	removeEvent(placa.fadeEvent)
	if placa:isVisible() then
		g_effects.fadeOut(placa, 1100)
		retorno = 0
	else
		placa:setVisible(false)
	end
end
function showPlaca()
	if retorno == 1 then
		g_effects.fadeIn(placa, 1100)
		retorno = 2  -- Mantém visível, não agenda fade out automático
		removeEvent(eventAnimation)
		return
	elseif retorno == 2 then
		g_effects.fadeOut(placa, 1100)
		retorno = 0
		removeEvent(eventAnimation)
	end
end
