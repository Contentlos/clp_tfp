-- clp_tfp · camps/ (Client) — strukturierte NPC-Lager + Compound (POI)
-- Wachen patrouillieren und greifen bei Sicht an; Loot-Kisten zum Plündern.
-- Slice: client-lokal (nicht spielerübergreifend gesynct).

local ESX = exports['es_extended']:getSharedObject()
local relGroup
local active = {}       -- [index] = { guards = {}, crates = {} }
local lootedCrate = {}  -- [entity] = GameTimer

CreateThread(function()
    relGroup = AddRelationshipGroup(Config.AI.relationshipGroup)
    SetRelationshipBetweenGroups(5, relGroup, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, relGroup)
end)

-- statische Karten-Blips (immer sichtbar = bekannte Gefahr/Beute)
CreateThread(function()
    for _, camp in ipairs(Config.Camps.list) do
        if camp.blip then
            local b = AddBlipForCoord(camp.center.x, camp.center.y, camp.center.z)
            SetBlipSprite(b, camp.blip.sprite or 84)
            SetBlipColour(b, camp.blip.color or 1)
            SetBlipScale(b, 0.9)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(camp.blip.label or 'Lager')
            EndTextCommandSetBlipName(b)
        end
    end
end)

local function randPoint(camp, mul)
    local ang = math.random() * math.pi * 2.0
    local r = math.random() * (camp.radius * (mul or 1.0))
    local x, y = camp.center.x + math.cos(ang) * r, camp.center.y + math.sin(ang) * r
    local found, gz = GetGroundZFor_3dCoord(x, y, camp.center.z + 25.0, false)
    return x, y, (found and gz or camp.center.z)
end

local function spawnGuard(camp)
    local model = joaat(Config.Camps.guardModels[math.random(#Config.Camps.guardModels)])
    if not IsModelValid(model) or not lib.requestModel(model, 3000) then return nil end
    local x, y, z = randPoint(camp, 1.0)
    local ped = CreatePed(4, model, x, y, z, math.random(0, 359) + 0.0, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, relGroup)
    SetPedAccuracy(ped, camp.accuracy or 25)
    SetPedCombatAttributes(ped, 46, true)
    SetPedFleeAttributes(ped, 0, false)
    if camp.weapon then GiveWeaponToPed(ped, joaat(camp.weapon), 250, false, true) end
    TaskWanderInArea(ped, camp.center.x, camp.center.y, camp.center.z, camp.radius, 5.0, 10.0)
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'tfp_campnpc_' .. ped, icon = 'fa-solid fa-hand', label = 'Durchsuchen', distance = 2.0,
            canInteract = function(e) return IsEntityDead(e) end,
            onSelect = function()
                if lib.progressBar({ duration = 4000, label = 'Durchsuchen…', canCancel = true,
                        disable = { move = true, combat = true }, anim = Config.Hunt.anim }) then
                    TriggerServerEvent('clp_tfp:harvest', 'npc')
                    if DoesEntityExist(ped) then DeleteEntity(ped) end
                end
            end,
        },
    })
    return ped
end

local function spawnCrate(camp)
    local model = joaat(Config.Camps.crateModel)
    if not IsModelValid(model) or not lib.requestModel(model, 3000) then return nil end
    local x, y, z = randPoint(camp, 0.5)
    local obj = CreateObject(model, x, y, z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    local lootKey = camp.loot
    exports.ox_target:addLocalEntity(obj, {
        {
            name = 'tfp_camploot_' .. obj, icon = 'fa-solid fa-box-open', label = 'Plündern', distance = 2.0,
            onSelect = function()
                local now = GetGameTimer()
                if lootedCrate[obj] and now - lootedCrate[obj] < 600000 then
                    lib.notify({ description = 'Diese Kiste ist leer.', type = 'inform' }); return
                end
                if lib.progressBar({ duration = 3000, label = 'Plündern…', canCancel = true,
                        disable = { move = true, combat = true }, anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' } }) then
                    lootedCrate[obj] = now
                    TriggerServerEvent('clp_tfp:campLoot', lootKey)
                end
            end,
        },
    })
    return obj
end

local function activate(i, camp)
    if active[i] then return end
    local a = { guards = {}, crates = {} }
    for _ = 1, camp.guards do
        local g = spawnGuard(camp); if g then a.guards[#a.guards + 1] = g end
    end
    for _ = 1, (camp.crates or 0) do
        local c = spawnCrate(camp); if c then a.crates[#a.crates + 1] = c end
    end
    active[i] = a
end

local function deactivate(i)
    local a = active[i]; if not a then return end
    for _, g in ipairs(a.guards) do if DoesEntityExist(g) then DeleteEntity(g) end end
    for _, c in ipairs(a.crates) do
        if DoesEntityExist(c) then exports.ox_target:removeLocalEntity(c); DeleteObject(c) end
    end
    active[i] = nil
end

CreateThread(function()
    while true do
        Wait(3000)
        local pc = GetEntityCoords(PlayerPedId())
        for i, camp in ipairs(Config.Camps.list) do
            local d = #(pc - camp.center)
            if d <= Config.Camps.activationDistance then
                activate(i, camp)
            elseif d > Config.Camps.activationDistance + 60.0 then
                deactivate(i)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for i in pairs(active) do deactivate(i) end
end)
