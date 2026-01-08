local NotificationOpcode = 36
local panelNotification
local _G = modules._G

-- Função para parsear dados serializados (fallback)
function parseSerializedData(buffer)
	local parts = {}
	for part in string.gmatch(buffer, "([^@]+)") do
		table.insert(parts, part)
	end

	if #parts < 4 then return nil end

	local data = {
		message = parts[1] or "Mensagem padrão",
		timer = tonumber(parts[2]) or 3
	}

	-- Parse do ícone
	local iconPart = parts[3] or "none"
	if iconPart ~= "none" then
		local iconType, iconValue = string.match(iconPart, "([^|]+)|(.+)")
		if iconType == "image" then
			data.image = iconValue
		elseif iconType == "item" then
			data.itemId = tonumber(iconValue)
		elseif iconType == "outfit" then
			data.outfit = tonumber(iconValue)
		end
	end

	-- Parse do botão
	local buttonPart = parts[4] or "none"
	if buttonPart ~= "none" then
		local buttonType, buttonValue = string.match(buttonPart, "([^|]+)|(.+)")
		if buttonType and buttonValue then
			data.notification = {
				type = buttonType,
				value = buttonValue
			}
		end
	end

	return data
end

local notifyCreateIcon = {
	item = function(widget, value)
		if (not widget or not value) then return; end

		local w = g_ui.createWidget("ItemNotify", widget)
		if (not w) then return; end

		local itemWidget = w:getChildById("item")
		if (not itemWidget) then return; end
		
		itemWidget:setItemId(value)
	end,

	outfit = function(widget, value)
		if (not widget or not value) then return; end

		local w = g_ui.createWidget("OutfitNotify", widget)
		if (not w) then return; end

		local creature = w:getChildById("creature")
		if (not creature) then return; end

		creature:setOutfit(value)
	end,

	image = function(widget, value)
		if (not widget or not value) then return; end

		local w = g_ui.createWidget("ImageNotify", widget)
		if (not w) then return; end

		local image = w:getChildById("image")
		if (not image) then return; end

		if string.match(value, "^https?://") and (string.match(value, "%.apng$") or string.match(value, "%.png$")) then
			HTTP.downloadImage(value, function(filePath, error)
				if (error or not filePath or filePath == "") then
					image:setImageSource("/images/icons/logo")
					return;
				end
				image:setImageSource(filePath)
			end)
		else
			image:setImageSource(value)
		end
	end,
}

function init()
	g_ui.importStyle("notification")

	ProtocolGame.registerExtendedOpcode(NotificationOpcode, function(protocol, opcode, buffer)
		if (not buffer) then return; end

		local data = nil
		local ok, jsonData = pcall(function()
			return json.decode(buffer)
		end)

		if ok and jsonData then
			data = jsonData
		else
			data = parseSerializedData(buffer)
		end

		if data then
			createNotify(data)
		end
	end)

	initPanel()
end

function initPanel()
	local rootPanel = nil

	if modules.game_interface and modules.game_interface.getRootPanel then
		rootPanel = modules.game_interface.getRootPanel()
	elseif g_ui.getRootWidget then
		rootPanel = g_ui.getRootWidget()
	end

	if rootPanel then
		panelNotification = g_ui.createWidget("PanelNotification", rootPanel)
	end
end

function terminate()
	ProtocolGame.unregisterExtendedOpcode(NotificationOpcode)
	if panelNotification then
		panelNotification:destroy()
		panelNotification = nil
	end
end

function createNotify(param)
	if (not param or not panelNotification) then
		return;
	end
	local notify = g_ui.createWidget("NotifyPanel", panelNotification)
	if (not notify) then
		return;
	end
	notify:hide()

	setIcon(notify, param)

	local function showNotify()
		if (not notify) then
			return;
		end
		notify:show()
		setMessage(notify, param.message)
		setCooldown(notify, param.timer)
		setResize(notify, param)
		setButton(notify, param)
		notify.onDoubleClick = function(self)
			hideNotify(notify)
		end
	end

	local isUrlImage = param.image
		and string.match(param.image, "^https?://")
		and (string.match(param.image, "%.apng$") or string.match(param.image, "%.png$"))
	if isUrlImage then
		scheduleEvent(function()
			showNotify()
		end, 800) -- 0,8 schedule for http get image
	else
		showNotify()
	end
end

function destroyNotify(notify)
	if (not notify) then
		return;
	end
	g_effects.fadeOut(notify)
	scheduleEvent(function()
		if notify then
			notify:destroy()
		end
	end, 350)
end

function hideNotify(notify)
	if (not notify) then
		return;
	end
	g_effects.fadeOut(notify)
	scheduleEvent(function()
		if notify then
			notify:hide()
		end
	end, 350)
end

function setMessage(notify, message)
	if (not notify or not message) then
		return;
	end
	local label = notify:getChildById("message")
	if (not label) then
		return;
	end
	label:setText(message)
	label:setVisible(true)
end

function setCooldown(notify, timer, updateInterval)
	if (not notify or not timer) then
		return;
	end
	local progressBar = notify:getChildById("progress")
	if timer == "infinite" then
		if progressBar then
			progressBar:setPercent(100)
		end
		return;
	end
	if (not progressBar or timer <= 0) then
		return;
	end

	updateInterval = updateInterval or 100 -- avoid lag
	local totalSteps = math.floor((timer * 1000) / updateInterval)
	if (totalSteps <= 0) then
		return;
	end
	local step = 100 / totalSteps

	for i = 1, totalSteps do
		scheduleEvent(function()
			if (not progressBar) then
				return;
			end
			local newValue = math.max(0, 100 - (step * i))
			progressBar:setPercent(newValue)
			if i >= totalSteps then
				destroyNotify(notify)
			end
		end, updateInterval * i)
	end
end

function setIcon(notify, icon)
	if (not notify or not icon) then
		return;
	end
	local widget = notify:getChildById("icon")
	if (not widget) then
		return;
	end

	local iconType = icon.image and "image" or icon.itemId and "item" or icon.outfit and "outfit"
	local value = icon.image or icon.itemId or icon.outfit
	if not iconType or not value then
		iconType = "image"
		value = "/images/icons/logo"
	end

	widget:setVisible(true)
	local msg = notify:getChildById("message")
	if msg then
		msg:setVisible(true)
	end

	if notifyCreateIcon[iconType] then
		notifyCreateIcon[iconType](widget, value)
	end
end

function setButton(notify, param)
	if (not notify or not param or not param.notification) then
		return
	end
	local actionButton = notify:getChildById("actionButton")
	local message = notify:getChildById("message")
	if (not actionButton or not message) then
		return;
	end

	actionButton:setVisible(true)
	actionButton:setText("")
	actionButton:fill(message)

	actionButton.onClick = function()
		local n = param.notification
		if (not n) then
			return;
		end

		if n.type == "say" and n.value then
			if g_game then
				g_game.talk(n.value)
			end
		elseif n.type == "opcode" and n.value then
			if ProtocolGame and n.value.opcode and n.value.data then
				ProtocolGame.sendExtendedOpcode(n.value.opcode, n.value.data)
			end
		elseif n.type == "variable" and n.value then
			if _G and n.value.name then
				_G[n.value.name] = n.value.data
			end
		elseif n.type == "callback" and n.value then
			if type(n.value) == "function" then
				n.value(notify)
			elseif type(n.value) == "string" and _G[n.value] then
				_G[n.value](notify)
			end
		end

		hideNotify(notify)
	end
end

function setResize(notify, param)
	if (not notify) then
		return;
	end
	local message = notify:getChildById("message")
	if (not message) then
		return;
	end

	local height = notify:getPaddingTop()
		+ notify:getPaddingBottom()
		+ notify:getPaddingLeft()
		+ notify:getPaddingRight()
		+ message:getTextSize().height
		+ 27
	if param and param.notification then
		height = height + 20
	end
	notify:setHeight(height)
end
