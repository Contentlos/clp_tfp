-- clp_tfp · predators/ (Client) : Hai (Wasser) · Berglöwe (Land) · Kannibalen (Nacht)
-- client-lokal wie ai/, populationsgedeckelt; ausschlachtbar wie Wild/NPC.

local ESX = exports['es_extended']:getSharedObject()
local PC = Config.Predators
local predRel
local sharks, lions, cannibals = {}, {}, {}

CreateThread(function()
    predRel = AddRelationshipGroup(PC.relationshipGroup)
    SetRelationshipBetweenGroups(5, predRel, `PLAYER`) -- 5 = Hass
    SetRelationshipBetweenGroups(5, `PLAYER`, predRel)
end)

local function isNight()
    local h = GetClockHours()
    local c = PC.cannibals
    if c.nightFrom <= c.nightTo then
        return h >= c.nightFrom and h < c.nightTo
    end
    return h >= c.nightFrom or h < c.nightTo
end

local function inSafezone(coords)
    local sz = Config.World and Config.World.safezone
    return sz and sz.center and #(coords - sz.center) < (sz.radius + (sz.predatorBuffer or 25.0))
end

local function groundSpawn(pc, minD, maxD)
    local ang = math.random() * math.pi * 2.0
    local r = minD + math.random() * (maxD - minD)
    local x, y = pc.x + math.cos(ang) * r, pc.y + math.sin(ang) * r
    local found, gz = GetGroundZFor_3dCoord(x, y, pc.z + 30.0, false)
    return vector3(x, y, found and gz or pc.z), found
end

local function waterSpawn(pc, minD, maxD)
    local ang = math.random() * math.pi * 2.0
    local r = minD + math.random() * (maxD - minD)
    return vector3(pc.x + math.cos(ang) * r, pc.y + math.sin(ang) * r, pc.z - 1.0)
end

local function harvestTarget(ped, htype)
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'tfp_predharvest_' .. ped,
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
end

local function spawnPredator(models, coords, opts)
    local model = joaat(models[math.random(#models)])
    if not IsModelValid(model) or not lib.requestModel(model, 3000) then return nil end
    local ped = CreatePed(opts.npc and 4 or 28, model, coords.x, coords.y, coords.z, math.random(0, 359) + 0.0, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, predRel)
    SetPedAccuracy(ped, opts.accuracy or 25)
    SetPedCombatAttributes(ped, 46, true) -- always fight
    SetPedFleeAttributes(ped, 0, false)
    if opts.weapon then GiveWeaponToPed(ped, joaat(opts.weapon), 250, false, true) end
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
    harvestTarget(ped, opts.harvest or 'animal')
    return ped
end

local function prune(list, pc, maxDist)
    for i = #list, 1, -1 do
        local h = list[i]
        if not DoesEntityExist(h) or #(GetEntityCoords(h) - pc) > maxDist then
            if DoesEntityExist(h) then DeleteEntity(h) end
            table.remove(list, i)
        end
    end
end

local function inDangerZone(pc)
    for _, zone in ipairs(Config.AI.zones or {}) do
        if #(pc - zone.center) <= zone.radius then return true end
    end
    return false
end

-- ── Lärm: Schießen/Sprinten lockt Kannibalen (auch tagsüber) — „Lärm & Gefahr" ──
local noise = 0
CreateThread(function()
    while true do
        Wait(500)
        if ESX.PlayerLoaded then
            local ped = PlayerPedId()
            if IsPedShooting(ped) then noise = math.min(120, noise + 25)
            elseif IsPedSprinting(ped) then noise = math.min(120, noise + 3)
            else noise = math.max(0, noise - 2) end
        end
    end
end)

-- sofortige Kannibalen-Welle (Admin/Test) — TriggerEvent('clp_tfp:spawnWave')
local function spawnCannibalWave(n)
    local cb = PC.cannibals
    local pc = GetEntityCoords(PlayerPedId())
    for _ = 1, (n or cb.max or 3) do
        if #cannibals >= (cb.max or 3) then break end
        local sc, ok = groundSpawn(pc, cb.spawnMin or 40.0, cb.spawnMax or 90.0)
        if ok then
            local w = cb.weapons and cb.weapons[math.random(#cb.weapons)]
            local p = spawnPredator(cb.models, sc, { npc = true, accuracy = cb.accuracy, weapon = w, harvest = cb.harvest or 'npc' })
            if p then cannibals[#cannibals + 1] = p end
        end
    end
    lib.notify({ title = 'Gefahr', description = 'Kannibalen nähern sich…', type = 'error' })
end
AddEventHandler('clp_tfp:spawnWave', function() spawnCannibalWave() end)

CreateThread(function()
    while true do
        Wait(PC.checkIntervalMs or 3000)
        if ESX.PlayerLoaded then
            local ped = PlayerPedId()
            if not IsPedDeadOrDying(ped, true) then
                local pc = GetEntityCoords(ped)
                prune(sharks, pc, PC.despawnDistance)
                prune(lions, pc, PC.despawnDistance)
                prune(cannibals, pc, PC.despawnDistance)

                -- Verfolger, die in die Safezone gelaufen sind, sofort entfernen
                if inSafezone(pc) then
                    for _, list in ipairs({ sharks, lions, cannibals }) do
                        for i = #list, 1, -1 do
                            local h = list[i]
                            if DoesEntityExist(h) and inSafezone(GetEntityCoords(h)) then
                                DeleteEntity(h); table.remove(list, i)
                            end
                        end
                    end
                end

                -- SAFEZONE = SAFEZONE: keinerlei Raubtier-/Kannibalen-Spawns in/nahe der Safezone
                if not inSafezone(pc) then
                    -- Hai: nur wenn der Spieler schwimmt
                    local sh = PC.shark
                    if sh.enabled and #sharks < sh.max and IsPedSwimming(ped) and math.random(100) <= sh.chance then
                        local sc = waterSpawn(pc, sh.spawnMin, sh.spawnMax)
                        if not inSafezone(sc) then
                            local p = spawnPredator(sh.models, sc, { accuracy = sh.accuracy, harvest = 'animal' })
                            if p then sharks[#sharks + 1] = p end
                        end
                    end

                    -- Berglöwe: an Land, nur in Gefahrenzonen (standardmäßig deaktiviert)
                    local ln = PC.land
                    if ln.enabled and #lions < ln.max and not IsPedSwimming(ped) and inDangerZone(pc) and math.random(100) <= ln.chance then
                        local sc, ok = groundSpawn(pc, ln.spawnMin, ln.spawnMax)
                        if ok and not inSafezone(sc) then
                            local p = spawnPredator(ln.models, sc, { accuracy = ln.accuracy, harvest = 'animal' })
                            if p then lions[#lions + 1] = p end
                        end
                    end

                    -- Kannibalen: nachts ODER bei Lärm (Schüsse/Sprinten) — auch tagsüber
                    local cb = PC.cannibals
                    local lured = noise >= (cb.noiseThreshold or 60)
                    if cb.enabled and #cannibals < cb.max and not IsPedSwimming(ped)
                       and (isNight() or lured) and math.random(100) <= (lured and 90 or cb.chance) then
                        local sc, ok = groundSpawn(pc, cb.spawnMin, cb.spawnMax)
                        if ok and not inSafezone(sc) then
                            local w = cb.weapons and cb.weapons[math.random(#cb.weapons)]
                            local p = spawnPredator(cb.models, sc, { npc = true, accuracy = cb.accuracy, weapon = w, harvest = cb.harvest or 'npc' })
                            if p then cannibals[#cannibals + 1] = p; if lured then noise = 0 end end
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, list in ipairs({ sharks, lions, cannibals }) do
        for _, h in ipairs(list) do if DoesEntityExist(h) then DeleteEntity(h) end end
    end
end)
