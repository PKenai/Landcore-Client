local soundOpcode = 135

local soundOpcode = 135

function init()
    connect(g_game, { onGameStart = onGameStart })
end

function terminate()
    disconnect(g_game, { onGameStart = onGameStart })
end

function onGameStart()
    ProtocolGame.registerExtendedOpcode(soundOpcode, onExtendedOpcode)
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