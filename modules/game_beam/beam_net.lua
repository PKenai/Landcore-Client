--[[
  Beam Network Handler
  Receives Beam Packets (Opcode 150) from server and renders them.
]]

local BEAM_OPCODE = 150

function init()
  ProtocolGame.registerExtendedOpcode(BEAM_OPCODE, onBeamOpcode)
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(BEAM_OPCODE)
end

function onBeamOpcode(protocol, opcode, buffer)
  if opcode ~= BEAM_OPCODE then return end

  local status, data = pcall(json.decode, buffer)
  if not status then
    perr("Beam: Failed to decode beam json: " .. tostring(data))
    return
  end

  if data.action == "create" then
    local beam = Beam.create()
    
    if data.thickness then beam:setThickness(data.thickness) end
    if data.duration then beam:setDuration(data.duration) end
    
    if data.color then 
      beam:setColor(data.color) 
    end
    
    if data.particleColor then 
      beam:setParticleColor(data.particleColor) 
    end
    
    -- Parse positions
    local fromPos = {x=data.from.x, y=data.from.y, z=data.from.z}
    local toPos = {x=data.to.x, y=data.to.y, z=data.to.z}
    
    -- Set Source
    if data.sourceCid then
      local creature = g_map.getCreatureById(data.sourceCid)
      if creature then 
        beam:setSourceCreature(creature) 
      else
        beam:setSourcePos(fromPos)
      end
    else
      beam:setSourcePos(fromPos)
    end

    -- Set Target
    if data.targetCid then
      local creature = g_map.getCreatureById(data.targetCid)
      if creature then 
        beam:setTargetCreature(creature) 
      else
        beam:setTargetPos(toPos)
      end
    else
      beam:setTargetPos(toPos)
    end
    
    -- Add to map
    g_map.addBeam(beam)
  elseif data.action == "remove" then
    if data.sourceCid then
      local creature = g_map.getCreatureById(data.sourceCid)
      if creature then
        -- Check if C++ method exists, otherwise use Lua fallback
        if g_map.removeBeamsBySource then
          g_map.removeBeamsBySource(creature)
        elseif _G.removeBeamsBySource then
          _G.removeBeamsBySource(creature)
        else
          -- Lua Fallback: iterate and remove beams from this source
          local beams = g_map.getBeams()
          for _, beam in ipairs(beams) do
            if beam:getSourceCreature() == creature then
              g_map.removeBeam(beam)
            end
          end
        end
      end
    end
  end
end
