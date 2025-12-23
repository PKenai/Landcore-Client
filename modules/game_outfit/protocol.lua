-- chunkname: @/modules/game_outfit/protocol.lua

local Opcodes = {
	Paperdoll = {
		Purchase = 51,
		Update = 52,
		Color = 53
	}
}

local protocolGame

local function onGameStart()
	protocolGame = g_game.getProtocolGame()
end

local function onGameEnd()
	protocolGame = nil
end

function sendPaperdollPurchase(slotName, itemId)
	if protocolGame then
		local data = {
			slotName = slotName,
			itemId = itemId
		}
		local buffer = json.encode(data)
		protocolGame:sendExtendedOpcode(Opcodes.Paperdoll.Purchase, buffer)
	end
end

function requestPaperdollData()
	if protocolGame then
		protocolGame:sendExtendedOpcode(Opcodes.Paperdoll.Update, "")
	end
end

function sendPaperdollColor(slotName, colorId)
	if protocolGame then
		local data = {
			slotName = slotName,
			colorId = colorId
		}
		local buffer = json.encode(data)
		protocolGame:sendExtendedOpcode(Opcodes.Paperdoll.Color, buffer)
	end
end

local function parsePaperdollUpdate(protocol, opcode, buffer)
	local ok, data = pcall(function() return json.decode(buffer) end)
	if ok and data then
		signalcall(PlayerCustom.onPaperdoll, data)
	end
end

local function parseOpen(outfit, outfits, creatureMount, mountList)
	local player = g_game.getLocalPlayer()
	local data = {
		outfit = table.copy(outfit),
		name = player:getName()
	}

	requestPaperdollData()

	signalcall(PlayerCustom.onOpen, data, outfits)
end


function initProtocol()
	ProtocolGame.registerExtendedOpcode(Opcodes.Paperdoll.Update, parsePaperdollUpdate)

	connect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
		onOpenOutfitWindow = parseOpen
	})

	if g_game.isOnline() then
		onGameStart()
	end
end

function terminateProtocol()
	ProtocolGame.unregisterExtendedOpcode(Opcodes.Paperdoll.Update)

	disconnect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
		onOpenOutfitWindow = parseOpen
	})
end
