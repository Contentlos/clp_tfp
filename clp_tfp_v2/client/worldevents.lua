-- clp_tfp · client/worldevents — Blip + Beutekisten + Wachen/Rudel je Event
-- Modelliert auf dem bewährten Wrack-Spawn (IsModelValid + requestModel + Cleanup).

local ESX = exports['es_extended']:getSharedObject()
local WE = Config.WorldEvents or { enabled = false }
local cur = nil  -- { id, key, coords, blip, crateEnts = {}, guards = {} }
local evRel

CreateThread(function()
    evRel = AddRelationshipGroup('TFP_EVENT_HOSTILE')
    SetRelationshipBetweenGroups(5, evRel, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, evRel)
end)

local function defOf(key) for _, e in ipairs(WE.events) do if e.key == key then return e end end end
local function snap(x, y, z) local f, gz = GetGroundZFor_3dCoord(x, y, z + 25.0, false); return f and gz or z end

local function cleanup()
    if not cur then return end
    if cur.blip and DoesBlipExist(cur.blip) then RemoveBlip(cur.blip) end
    for _, c in pairs(cur.crateEnts or {}) do
        if c and DoesEntityExist(c) then exports.ox_target:removeLocalEntity(c); DeleteEntity(c) end
    end
    for _, g in ipairs(cur.guards or {}) do if DoesEntityExist(g) then DeleteEntity(g) end end
    cur = nil
end

local function spawnGuards(coords, g)
    local models = (Config.Camps and Config.Camps.guardModels) or { 'g_m_y_armgoon_02' }
    for _ = 1, (g.count or 4) do
        local m = joaat(models[math.random(#models)])
        if IsModelValid(m) and lib.requestModel(m, 3000) then
            local ang = math.random() * math.pi * 2.0
            local r = 5.0 + math.random() * 12.0
            local x, y = coords.x + math.cos(ang) * r, coords.y + math.sin(ang) * r
            local ped = CreatePed(4, m, x, y, snap(x, y, coords.z), math.random(0, 359) + 0.0, false, false)
            SetModelAsNoLongerNeeded(m)
            SetEntityAsMissionEntity(ped, true, true)
            SetPedRelationshipGroupHash(ped, evRel)
            SetPedAccuracy(ped, g.accuracy or 26)
            SetPedCombatAttributes(ped, 46, true)
            SetPedFleeAttributes(ped, 0, false)
            if g.weapon then GiveWeaponToPed(ped, joaat(g.weapon), 250, false, true) end
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
            cur.guards[#cur.guards + 1] = ped
        end
    end
end

local function addCrate(coords, idx)
    local m = joaat('prop_box_ammo07a')
    if not (IsModelValid(m) and lib.requestModel(m, 5000)) then return end
    local ang = math.random() * math.pi * 2.0
    local r = 1.5 + math.random() * 3.0
    local x, y = coords.x + math.cos(ang) * r, coords.y + math.sin(ang) * r
    local o = CreateObject(m, x, y, snap(x, y, coords.z), false, false, false)
    SetModelAsNoLongerNeeded(m)
    PlaceObjectOnGroundProperly(o)
    FreezeEntityPosition(o, true)
    cur.crateEnts[idx] = o
    local id = cur.id
    exports.ox_target:addLocalEntity(o, { {
        name = 'tfp_we_' .. id .. '_' .. idx, icon = 'fa-solid fa-box-open', label = 'Durchsuchen', distance = 2.5,
        onSelect = function()
            if lib.progressBar({ duration = (Config.Loot.searchTime or 3000) + 1000, label = 'Durchsuchen…',
                    canCancel = true, disable = { move = true, combat = true }, anim = Config.Loot.searchAnim }) then
                TriggerServerEvent('clp_tfp:worldEventLoot', id, idx)
            end
        end,
    } })
end

RegisterNetEvent('clp_tfp:worldEventStart', function(id, key, coords, crateState)
    if cur and cur.id == id then return end
    cleanup()
    local e = defOf(key); if not e then return end
    coords = vector3(coords.x, coords.y, coords.z)
    cur = { id = id, key = key, coords = coords, crateEnts = {}, guards = {} }

    if not e.noBlip and e.blip then
        local b = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(b, e.blip.sprite or 161); SetBlipColour(b, e.blip.color or 5); SetBlipScale(b, e.blip.scale or 1.0)
        SetBlipAsShortRange(b, false)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(e.label or 'Ereignis'); EndTextCommandSetBlipName(b)
        cur.blip = b
    end

    -- Kannibalen-Rudel: spawnt, sobald ein Spieler nah genug ist (nutzt predators-Welle)
    if e.pack then
        CreateThread(function()
            local tries = 0
            while cur and cur.id == id and tries < 90 do
                if #(GetEntityCoords(PlayerPedId()) - coords) < 130.0 and not IsPedDeadOrDying(PlayerPedId(), true) then
                    TriggerEvent('clp_tfp:spawnWave')
                    break
                end
                tries = tries + 1; Wait(2000)
            end
        end)
        return
    end

    for i = 1, #(e.crates or {}) do
        if not (crateState and crateState[i]) then addCrate(coords, i) end
    end
    if e.guards then spawnGuards(coords, e.guards) end
end)

RegisterNetEvent('clp_tfp:worldEventCrateLooted', function(id, idx)
    if not cur or cur.id ~= id then return end
    local c = cur.crateEnts[idx]
    if c and DoesEntityExist(c) then exports.ox_target:removeLocalEntity(c); DeleteEntity(c) end
    cur.crateEnts[idx] = nil
end)

RegisterNetEvent('clp_tfp:worldEventEnd', function(id) if cur and cur.id == id then cleanup() end end)

AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then cleanup() end end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(300) end
    if WE.enabled then TriggerServerEvent('clp_tfp:requestWorldEvent') end
end)
