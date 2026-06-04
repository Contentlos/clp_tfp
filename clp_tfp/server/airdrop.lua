-- clp_tfp · loot/ · Airdrops (Server): Timer, Abwurf, autoritativer Loot (first come)

local current = nil -- { id, x, y, z, looted }
local nextId = 0

-- kq_airdrop bevorzugen (Flugzeug + Fallschirm-Visuals), wenn die Resource läuft
local function tryKqDrop(p)
    if Config.Airdrop.useKqAirdrop == false then return false end
    if GetResourceState('kq_airdrop') ~= 'started' then return false end
    local ok = pcall(function() exports.kq_airdrop:StartDropAt(vector3(p.x, p.y, p.z)) end)
    if ok and TFP_Loot then TFP_Loot(('Airdrop (kq) @ %.0f, %.0f — Flugzeug im Anflug.'):format(p.x, p.y)) end
    return ok
end

local function startDrop()
    if not Config.Airdrop.enabled then return end
    local p = Config.Airdrop.points[math.random(#Config.Airdrop.points)]
    if tryKqDrop(p) then return end  -- kq_airdrop übernimmt (eigenes Loot via kq_lootareas)
    -- Fallback: eingebauter Airdrop
    nextId = nextId + 1
    current = { id = nextId, x = p.x, y = p.y, z = p.z, looted = false }
    TriggerClientEvent('clp_tfp:airdropIncoming', -1, current.id, p.x, p.y, p.z, Config.Airdrop.warnSeconds)
    if TFP_Loot then TFP_Loot(('Airdrop #%d fällt @ %.0f, %.0f — wer zuerst kommt…'):format(current.id, p.x, p.y)) end
end

CreateThread(function()
    while true do
        Wait(Config.Airdrop.intervalMs or 1800000)
        startDrop()
    end
end)

-- neue/joinende Clients: aktiven Drop nachreichen
RegisterNetEvent('clp_tfp:requestAirdrop', function()
    if current and not current.looted then
        TriggerClientEvent('clp_tfp:airdropLanded', source, current.id, current.x, current.y, current.z)
    end
end)

RegisterNetEvent('clp_tfp:airdropLoot', function(id)
    local src = source
    if not current or current.id ~= id or current.looted then return end
    local pc = GetEntityCoords(GetPlayerPed(src))
    if #(pc - vector3(current.x, current.y, current.z)) > 6.0 then return end -- grober Anti-Cheat
    current.looted = true
    TFP_RollGive(src, Config.Airdrop.loot)
    TriggerClientEvent('clp_tfp:airdropLooted', -1, id)
end)

-- Admin-Panel: Airdrop auslösen
RegisterNetEvent('clp_tfp:adminAirdrop', function()
    if TFP_IsAdmin(source) then startDrop() end
end)

-- Admin/Debug: sofort einen Drop auslösen
RegisterCommand('tfpairdrop', function(src)
    if src == 0 or IsPlayerAceAllowed(src, 'airdrop.admin') then startDrop() end
end, true)
