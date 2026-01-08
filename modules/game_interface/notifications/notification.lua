local NotificationOpcode = 36

function init()
	print("NOTIFICATION MODULE: Successfully loaded!")
	print("NOTIFICATION MODULE: Registering opcode " .. NotificationOpcode)

	ProtocolGame.registerExtendedOpcode(NotificationOpcode, function(protocol, opcode, buffer)
		print("NOTIFICATION MODULE: Received notification data: " .. (buffer or "empty"))
	end)

	print("NOTIFICATION MODULE: Initialization complete!")
end

function terminate()
	ProtocolGame.unregisterExtendedOpcode(NotificationOpcode)
	print("NOTIFICATION MODULE: Terminated")
end