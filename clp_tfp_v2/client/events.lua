-- clp_tfp · client/events — Wrack-Event (Prop + Loot-Kiste + Blip) + Unterwasser-Tauch-Spots

local wreckProps = {}  -- id -> { wreck, crate, blip }

local function spawnWreckClient(id, coords, propName)
    if wreckProps[id] then return end
    local entry = {}

    local m = joaat(propName)
    if IsModelValid(m) and lib.requestModel(m, 5000) then
        local o = CreateObject(m, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(m)
        PlaceObjectOnGroundProperly(o)
        FreezeEntityPosition(o, true)
        entry.wreck = o
    end

    local cm = joaat(Config.WreckEvent.crateProp)
    if IsModelValid(cm) and lib.requestModel(cm, 5000) then
        local c = CreateObject(cm, coords.x + 1.5, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(cm)
        PlaceObjectOnGroundProperly(c)
        FreezeEntityPosition(c, true)
        entry.crate = c
        exports.ox_target:addLocalEntity(c, {
            {
                name = 'tfp_wreckloot_' .. id,
                icon = 'fa-solid fa-anchor',
                label = 'Wrack durchsuchen',
                distance = 2.5,
                onSelect = function()
                    if lib.progressBar({ duration = Config.Loot.searchTime or 3000, label = 'Durchsuchen…',
                            canCancel = true, disable = { move = true, combat = true }, anim = Config.Loot.searchAnim }) then
                        TriggerServerEvent('clp_tfp:wreckLoot', id)
                    end
                end,
            },
        })
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.WreckEvent.blipSprite or 455)
    SetBlipColour(blip, Config.WreckEvent.blipColor or 5)
    SetBlipScale(blip, 0.9)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Wrack'); EndTextCommandSetBlipName(blip)
    entry.blip = blip

    wreckProps[id] = entry
    lib.notify({ title = 'Wrack gesichtet', description = 'Ein Wrack wurde an der Küste entdeckt (Karte).', type = 'inform' })
end

local function despawnWreckClient(id)
    local e = wreckProps[id]; if not e then return end
    if e.crate and DoesEntityExist(e.crate) then exports.ox_target:removeLocalEntity(e.crate); DeleteEntity(e.crate) end
    if e.wreck and DoesEntityExist(e.wreck) then DeleteEntity(e.wreck) end
    if e.blip and DoesBlipExist(e.blip) then RemoveBlip(e.blip) end
    wreckProps[id] = nil
end

RegisterNetEvent('clp_tfp:wreckSpawn', function(id, coords, propName) spawnWreckClient(id, coords, propName) end)
RegisterNetEvent('clp_tfp:wreckDespawn', function(id) despawnWreckClient(id) end)

AddEventHandler('esx:playerLoaded', function() TriggerServerEvent('clp_tfp:requestWreck') end)
CreateThread(function()
    local ESX = exports['es_extended']:getSharedObject()
    while not ESX.PlayerLoaded do Wait(300) end
    TriggerServerEvent('clp_tfp:requestWreck')
end)

-- ── Unterwasser-Tauch-Spots (statisch) ───────────────────────────────────────
if Config.Wrecks and Config.Wrecks.enabled then
    local diveLooted = {}
    CreateThread(function()
        local cm = joaat(Config.Wrecks.crateProp)
        if not IsModelValid(cm) or not lib.requestModel(cm, 8000) then return end
        for i, spot in ipairs(Config.Wrecks.spots) do
            local c = CreateObject(cm, spot.x, spot.y, spot.z, false, false, false)
            FreezeEntityPosition(c, true)
            exports.ox_target:addLocalEntity(c, {
                {
                    name = 'tfp_dive_' .. i,
                    icon = 'fa-solid fa-anchor',
                    label = 'Wrack durchsuchen (tauchen)',
                    distance = 2.5,
                    onSelect = function()
                        local now = GetGameTimer()
                        if diveLooted[i] and now - diveLooted[i] < (Config.Wrecks.reLootCooldownMs or 900000) then
                            lib.notify({ description = 'Dieses Wrack ist vorerst leer.', type = 'inform' }); return
                        end
                        if lib.progressBar({ duration = (Config.Loot.searchTime or 3000) + 2000, label = 'Durchsuchen…',
                                canCancel = true, disable = { move = true, combat = true } }) then
                            diveLooted[i] = now
                            TriggerServerEvent('clp_tfp:loot', Config.Wrecks.loot, vector3(spot.x, spot.y, spot.z))
                        end
                    end,
                },
            })
        end
        SetModelAsNoLongerNeeded(cm)
    end)
end
