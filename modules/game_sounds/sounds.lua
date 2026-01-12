local soundOpcode = 140

function init()
    connect(g_game, { onGameStart = onGameStart })
end

function terminate()
    disconnect(g_game, { onGameStart = onGameStart })
    -- Safely unregister extended opcode
    pcall(function()
        ProtocolGame.unregisterExtendedOpcode(soundOpcode)
    end)
end

function onGameStart()
    -- Safely register the opcode, checking if it's already registered
    if not pcall(function()
        ProtocolGame.registerExtendedOpcode(soundOpcode, onExtendedOpcode)
    end) then
        -- If registration failed (opcode already taken), try to unregister first then re-register
        pcall(function()
            ProtocolGame.unregisterExtendedOpcode(soundOpcode)
            ProtocolGame.registerExtendedOpcode(soundOpcode, onExtendedOpcode)
        end)
    end
end

function onExtendedOpcode(protocol, opcode, buffer)
    if not buffer or buffer == "" then
        return
    end

    if buffer == "Default" then
        if g_sounds then
            g_sounds.stopAll()
        end
    else
        if g_sounds then
            local soundPath = "/data/sounds/" .. buffer .. '.ogg'
            g_sounds.getChannel():play(soundPath, 0, 1.0)
        end
    end
end