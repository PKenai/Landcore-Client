-- Player Ranks Module
-- Displays rank icons next to player names based on their level

local playerRanks = {}
local rankTextures = {}

-- Rank configuration based on level ranges
local RANK_CONFIG = {
    {minLevel = 0, maxLevel = 24, texture = '/images/landcore/rank/RankNormal.png'},
    {minLevel = 25, maxLevel = 49, texture = '/images/landcore/rank/RankBronze.png'},
    {minLevel = 50, maxLevel = 74, texture = '/images/landcore/rank/RankSilver.png'},
    {minLevel = 75, maxLevel = 99, texture = '/images/landcore/rank/RankGold.png'},
    {minLevel = 100, maxLevel = 150, texture = '/images/landcore/rank/RankDiamond.png'}
}

function init()
    -- Register extended opcode for receiving player rank updates
    ProtocolGame.registerExtendedOpcode(150, onPlayerRankUpdate)

    -- Connect to creature events
    connect(Creature, {
        onAppear = onCreatureAppear,
        onDisappear = onCreatureDisappear
    })

    -- Connect to game events
    connect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })

    -- Load rank textures
    loadRankTextures()

    -- For testing purposes, set some sample ranks
    setupTestRanks()

    -- Request initial player ranks from server
    requestPlayerRanks()
end

function terminate()
    disconnect(Creature, {
        onAppear = onCreatureAppear,
        onDisappear = onCreatureDisappear
    })

    disconnect(g_game, {
        onGameStart = onGameStart,
        onGameEnd = onGameEnd
    })

    playerRanks = {}
    rankTextures = {}
end

function loadRankTextures()
    for _, config in ipairs(RANK_CONFIG) do
        rankTextures[config.texture] = g_textures.getTexture(config.texture)
    end
end

function setupTestRanks()
    -- Test ranks for demonstration (remove this in production)
    -- These would normally come from the server
    playerRanks[12345] = 15   -- Normal rank (0-24)
    playerRanks[12346] = 35   -- Bronze rank (25-49)
    playerRanks[12347] = 65   -- Silver rank (50-74)
    playerRanks[12348] = 85   -- Gold rank (75-99)
    playerRanks[12349] = 120  -- Diamond rank (100-150)
end

function getRankTextureForLevel(level)
    for _, config in ipairs(RANK_CONFIG) do
        if level >= config.minLevel and level <= config.maxLevel then
            return rankTextures[config.texture]
        end
    end
    return nil
end

function setPlayerRank(creatureId, level)
    playerRanks[creatureId] = level
end

function getPlayerRank(creatureId)
    return playerRanks[creatureId]
end

function removePlayerRank(creatureId)
    playerRanks[creatureId] = nil
end

function onCreatureAppear(creature)
    if creature:isPlayer() then
        -- Request rank for this player if we don't have it
        if not getPlayerRank(creature:getId()) then
            requestPlayerRank(creature:getId())
        end
    end
end

function onCreatureDisappear(creature)
    if creature:isPlayer() then
        removePlayerRank(creature:getId())
    end
end

function onGameStart()
    playerRanks = {}
    requestPlayerRanks()
end

function onGameEnd()
    playerRanks = {}
end

function requestPlayerRanks()
    -- Send extended opcode to request all player ranks
    local protocol = g_game.getProtocolGame()
    if protocol then
        local msg = OutputMessage.create()
        msg:addU8(150) -- Extended opcode
        msg:addString("REQUEST_ALL_RANKS")
        protocol:send(msg)
    end
end

function requestPlayerRank(creatureId)
    -- Send extended opcode to request rank for specific player
    local protocol = g_game.getProtocolGame()
    if protocol then
        local msg = OutputMessage.create()
        msg:addU8(150) -- Extended opcode
        msg:addString("REQUEST_RANK")
        msg:addU32(creatureId)
        protocol:send(msg)
    end
end

function onPlayerRankUpdate(protocol, opcode, data)
    if type(data) == 'table' then
        if data.action == "UPDATE_RANK" then
            setPlayerRank(data.creatureId, data.level)
        elseif data.action == "UPDATE_MULTIPLE_RANKS" then
            for _, rankData in ipairs(data.ranks) do
                setPlayerRank(rankData.creatureId, rankData.level)
            end
        end
    end
end

-- Export functions for use by other modules or C++ code
PlayerRanks = {
    getRankTextureForLevel = getRankTextureForLevel,
    getPlayerRank = getPlayerRank,
    setPlayerRank = setPlayerRank
}

-- Debug function to test rank display
function testRankDisplay()
    print("Player Ranks Module Loaded Successfully!")
    print("Available ranks:")
    for creatureId, level in pairs(playerRanks) do
        print(string.format("Creature ID %d: Level %d", creatureId, level))
    end
end

-- Call test function after init
g_clock.scheduleEvent(function()
    testRankDisplay()
end, 1000)
