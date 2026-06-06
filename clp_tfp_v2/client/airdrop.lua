-- clp_tfp · client/airdrop — zeitgesteuerte High-Tier-Abwürfe (Blip, Kiste, Loot)

local ESX = exports['es_extended']:getSharedObject()
local crates = {} -- [id] = entity
local blips = {}  -- [id] = blip

local function makeBlip(id, x, y, z, colour, name)
    if blips[id] then RemoveBlip(blips[id]) end
    local b = AddBlipForCoord(x, y, z)
    SetBlipSprite(b, 568)
    SetBlipColour(b, colour)
    SetBlipScale(b, 1.0)
    SetBlipFlashes(b, true)
    SetBlipAsShortRange(b, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(b)
    blips[id] = b
end

local function landDrop(id, x, y, z)
    if crates[id] then return end
    local found, gz = GetGroundZFor_3dCoord(x, y, z, false)
    local zz = found and gz or z
    local model = joaat(Config.Airdrop.model)
    if lib.requestModel(model, 5000) then
        local obj = CreateObject(model, x, y, zz, false, false, false)
        SetModelAsNoLongerNeeded(model)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        crates[id] = obj
        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'tfp_airdrop_' .. id, icon = 'fa-solid fa-parachute-box', label = 'Airdrop plündern', distance = 2.5,
                onSelect = function()
                    if lib.progressBar({ duration = 3000, label = 'Airdrop plündern…', canCancel = true,
                            disable = { move = true, combat = true }, anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' } }) then
                        TriggerServerEvent('clp_tfp:airdropLoot', id)
                    end
                end,
            },
        })
    end
    makeBlip(id, x, y, zz, 1, 'Airdrop')
end

RegisterNetEvent('clp_tfp:airdropIncoming', function(id, x, y, z, warn)
    lib.notify({ title = 'Airdrop', description = 'Ein Versorgungsabwurf ist eingehend!', type = 'inform' })
    makeBlip(id, x, y, z, 5, 'Airdrop (eingehend)')
    SetTimeout((warn or 30) * 1000, function() landDrop(id, x, y, z) end)
end)

RegisterNetEvent('clp_tfp:airdropLanded', function(id, x, y, z) landDrop(id, x, y, z) end)

RegisterNetEvent('clp_tfp:airdropLooted', function(id)
    if crates[id] and DoesEntityExist(crates[id]) then
        exports.ox_target:removeLocalEntity(crates[id])
        DeleteObject(crates[id])
    end
    crates[id] = nil
    if blips[id] then RemoveBlip(blips[id]); blips[id] = nil end
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    TriggerServerEvent('clp_tfp:requestAirdrop')
end)
