-- clp_tfp · client/ai — Ambient-Wildtiere (überall) + Aggro-Feinde (Gefahrenzonen)
-- Slice: client-lokal (nicht spielerübergreifend gesynct). Population gedeckelt.

local ESX = exports['es_extended']:getSharedObject()
local hostiles, wildlife = {}, {}
local relGroup

CreateThread(function()
    relGroup = AddRelationshipGroup(Config.AI.relationshipGroup)
    SetRelationshipBetweenGroups(5, relGroup, `PLAYER`) -- 5 = Hass
    SetRelationshipBetweenGroups(5, `PLAYER`, relGroup)
end)

local function inSafezone(coords)
    local sz = Config.World and Config.World.safezone
    return sz and sz.center and #(coords - sz.center) < (sz.radius + 15.0)
end

local function groundSpawn(pc, minD, maxD)
    local ang = math.random() * math.pi * 2.0
    local r = minD + math.random() * (maxD - minD)
    local x, y = pc.x + math.cos(ang) * r, pc.y + math.sin(ang) * r
    local found, gz = GetGroundZFor_3dCoord(x, y, pc.z + 30.0, false)
    return vector3(x, y, found and gz or pc.z), found
end

local function spawnPed(models, coords, hostile, weapon, accuracy, harvestType)
    local model = joaat(models[math.random(#models)])
    if not IsModelValid(model) or not lib.requestModel(model, 3000) then return nil end
    local pedType = (harvestType == 'npc') and 4 or 28
    local ped = CreatePed(pedType, model, coords.x, coords.y, coords.z, math.random(0, 359) + 0.0, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ped, true, true)
    if hostile then
        SetPedRelationshipGroupHash(ped, relGroup)
        SetPedAccuracy(ped, accuracy or 25)
        SetPedCombatAttributes(ped, 46, true) -- always fight
        SetPedFleeAttributes(ped, 0, false)
        if weapon then GiveWeaponToPed(ped, joaat(weapon), 250, false, true) end
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
    else
        TaskWanderStandard(ped, 10.0, 10)
    end

    -- ox_target: Ausnehmen (Tier) / Durchsuchen (NPC) — nur wenn tot
    local htype = harvestType or 'animal'
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'tfp_harvest_' .. ped,
            icon = (htype == 'npc') and 'fa-solid fa-hand' or 'fa-solid fa-drumstick-bite',
            label = (htype == 'npc') and 'Durchsuchen' or 'Ausnehmen',
            distance = 2.0,
            canInteract = function(e) return IsEntityDead(e) end,
            onSelect = function()
                if lib.progressBar({ duration = 4000, label = (htype == 'npc') and 'Durchsuchen…' or 'Ausnehmen…',
                        canCancel = true, disable = { move = true, combat = true }, anim = Config.Hunt.anim }) then
                    TriggerServerEvent('clp_tfp:harvest', htype)
                    if DoesEntityExist(ped) then DeleteEntity(ped) end
                end
            end,
        },
    })
    return ped
end

-- Carcasses bleiben erhalten (zum Ausnehmen), bis sie zu weit weg sind/geerntet wurden
local function prune(list, pc, maxDist)
    for i = #list, 1, -1 do
        local h = list[i]
        if not DoesEntityExist(h) or #(GetEntityCoords(h) - pc) > maxDist then
            if DoesEntityExist(h) then DeleteEntity(h) end
            table.remove(list, i)
        end
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        local pc = GetEntityCoords(PlayerPedId())
        prune(hostiles, pc, Config.AI.despawnDistance)
        local amb = Config.AI.ambient
        prune(wildlife, pc, ((amb and amb.maxDist) or 95.0) + 40.0)

        -- Aggro-Zonen (NICHT in der Safezone)
        if not inSafezone(pc) then
            for _, zone in ipairs(Config.AI.zones) do
                if #(pc - zone.center) <= zone.radius then
                    local need = math.min(zone.count, Config.AI.maxActive - #hostiles)
                    for _ = 1, math.max(0, need) do
                        local sc = groundSpawn(pc, 25.0, Config.AI.spawnDistance)
                        if not inSafezone(sc) then
                            local p = spawnPed(zone.models, sc, true, zone.weapon, zone.accuracy, zone.kind == 'npc' and 'npc' or 'animal')
                            if p then hostiles[#hostiles + 1] = p end
                        end
                    end
                    break
                end
            end
        end

        -- Ambient-Wildtiere (passiv, überall außer Safezone)
        if amb and amb.enabled and not inSafezone(pc) and #wildlife < amb.max then
            for _ = 1, (amb.max - #wildlife) do
                local sc, ok = groundSpawn(pc, amb.minDist or 30.0, amb.maxDist or 95.0)
                if ok and not inSafezone(sc) then
                    local p = spawnPed(amb.models, sc, false, nil, nil, 'animal')
                    if p then wildlife[#wildlife + 1] = p end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, h in ipairs(hostiles) do if DoesEntityExist(h) then DeleteEntity(h) end end
    for _, h in ipairs(wildlife) do if DoesEntityExist(h) then DeleteEntity(h) end end
end)
