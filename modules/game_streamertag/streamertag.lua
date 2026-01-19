-- Constants
local HIGHLIGHT_SPEED = 0.005
local HIGHLIGHT_WIDTH = 2.0
local UPDATE_INTERVAL = 16
local ADM_HIGHLIGHT_OPCODE = 203

-- State
local activeCreatures = {}
local adms = {} -- Stores templates {color1, color2} indexed by name
local updateEvent = nil

if not json then
    print("WARNING: [game_streamertag] 'json' global not found. Attempting to load from modules...")
end

function init()
    
    if not json then
        print("ERROR: [game_streamertag] JSON library is missing! Opcode handling will fail.")
    end

    connect(Creature, {
        onAppear = onCreatureAppear,
        onDisappear = onCreatureDisappear
    })
    
    ProtocolGame.registerExtendedOpcode(ADM_HIGHLIGHT_OPCODE, onAdmHighlightOpcode)
    
    -- Check for existing creatures
    for _, creature in ipairs(g_creatures.getCreatures()) do
        onCreatureAppear(creature)
    end
    
    updateEvent = cycleEvent(updateNameHighlights, UPDATE_INTERVAL)
end

function terminate()
    disconnect(Creature, {
        onAppear = onCreatureAppear,
        onDisappear = onCreatureDisappear
    })
    
    ProtocolGame.unregisterExtendedOpcode(ADM_HIGHLIGHT_OPCODE)
    
    if updateEvent then
        removeEvent(updateEvent)
        updateEvent = nil
    end
    
    for cid, data in pairs(activeCreatures) do
        local creature = data.creature
        if creature then
            creature:clearNameHighlight()
        end
    end
    activeCreatures = {}
    adms = {}
end

function onAdmHighlightOpcode(protocol, opcode, buffer)
    local status, data = pcall(function() return json.decode(buffer) end)
    if not status or not data then 
        print("ERROR: [game_streamertag] Failed to decode JSON: " .. tostring(data))
        return 
    end
    
    if data.action == "update" then
        if data.color1 and data.color2 then
            adms[data.name] = {
                nameColor1 = data.color1,
                nameColor2 = data.color2
            }
        else
            adms[data.name] = nil
        end
        
        -- Refresh existing creatures
        for _, creature in ipairs(g_creatures.getCreatures()) do
            if creature:getName() == data.name then
                onCreatureAppear(creature)
            end
        end

        -- Also check local player
        local localPlayer = g_game.getLocalPlayer()
        if localPlayer and localPlayer:getName() == data.name then
            onCreatureAppear(localPlayer)
        end
    end
end

function onCreatureAppear(creature)
    if not creature then return end
    
    local name = creature:getName()
    
    -- Safe check for isPlayer method (Local player might not have it in some versions or it's named differently)
    if creature.isPlayer and not creature:isPlayer() then 
        return 
    end
    
    local template = adms[name]
    
    if template then
        -- Check if C++ method exists
        if not creature.setNameHighlight then
            print("ERROR: [game_streamertag] Creature:setNameHighlight does not exist! Did you compile?")
            return
        end

        activeCreatures[creature:getId()] = {
            creature = creature,
            template = template,
            startTime = g_clock.millis(),
            originalName = name
        }
    else
        -- Clear if no longer highlighted
        if activeCreatures[creature:getId()] then
            creature:clearNameHighlight()
            activeCreatures[creature:getId()] = nil
        end
    end
end

function onCreatureDisappear(creature)
    if not creature then return end
    activeCreatures[creature:getId()] = nil
end

function updateNameHighlights()
    local now = g_clock.millis()
    local count = 0
    for cid, data in pairs(activeCreatures) do
        count = count + 1
        local creature = data.creature
        if creature and not creature:isRemoved() and not creature:isDead() then
            local template = data.template
            if template.nameColor1 and template.nameColor2 then
                local name = data.originalName
                local nameLen = #name
                if nameLen > 0 then
                    local elapsed = now - data.startTime
                    local highlightPos = (elapsed * HIGHLIGHT_SPEED) % nameLen
                    
                    local color1 = tocolor(template.nameColor1)
                    local color2 = tocolor(template.nameColor2)
                    
                    creature:setNameHighlight(color1, color2, highlightPos, HIGHLIGHT_WIDTH)
                end
            end
        else
            activeCreatures[cid] = nil
        end
    end
    
    -- Optional: Debug update loop (too noisy for 16ms, maybe only if count > 0)
    -- if count > 0 then print(">>> [game_streamertag] Updating " .. count .. " highlights") end
end
