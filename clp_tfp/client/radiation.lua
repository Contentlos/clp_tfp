-- clp_tfp · radiation/ (Client) — verstrahlte Festland-Zone (Phase 5)
-- Ohne Schutzanzug: Schaden + grüner Screen-FX. Geigerzähler warnt in der Nähe.
-- High-Tier-Loot-Kisten in der Zone.

local ESX = exports['es_extended']:getSharedObject()
local crates = {}
local inZone, fxOn = false, false
local lastGeiger = 0

local function hasItem(name)
    return (exports.ox_inventory:Search('count', name) or 0) > 0
end

local function spawnCrates()
    if #crates > 0 then return end
    local z = Config.Radiation.zone
    local model = joaat(Config.Radiation.crateModel)
    if not lib.requestModel(model, 4000) then return end
    for _ = 1, (Config.Radiation.hotzones or 3) do
        local ang = math.random() * math.pi * 2.0
        local r = math.random() * z.radius
        local x, y = z.center.x + math.cos(ang) * r, z.center.y + math.sin(ang) * r
        local found, gz = GetGroundZFor_3dCoord(x, y, z.center.z + 30.0, false)
        local obj = CreateObject(model, x, y, found and gz or z.center.z, false, false, false)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        crates[#crates + 1] = obj
        exports.ox_target:addLocalEntity(obj, {
            { name = 'tfp_rad_' .. obj, icon = 'fa-solid fa-radiation', label = 'Plündern', distance = 2.0,
              onSelect = function()
                  if lib.progressBar({ duration = 3000, label = 'Plündern…', canCancel = true,
                          disable = { move = true, combat = true }, anim = { dict = 'amb@prop_human_bum_bin@base', clip = 'base' } }) then
                      TriggerServerEvent('clp_tfp:radLoot')
                  end
              end },
        })
    end
    SetModelAsNoLongerNeeded(model)
end

local function clearCrates()
    for _, c in ipairs(crates) do
        if DoesEntityExist(c) then exports.ox_target:removeLocalEntity(c); DeleteObject(c) end
    end
    crates = {}
end

local function setFx(on)
    if on == fxOn then return end
    fxOn = on
    if on then AnimpostfxPlay(Config.Radiation.fx) else AnimpostfxStop(Config.Radiation.fx) end
end

CreateThread(function()
    if not Config.Radiation.enabled then return end
    while true do
        local z = Config.Radiation.zone
        local ped = PlayerPedId()
        local d = #(GetEntityCoords(ped) - z.center)
        if d <= z.radius then
            if not inZone then inZone = true; spawnCrates() end
            if not hasItem(Config.Radiation.hazmatItem) then
                setFx(true)
                if not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - (Config.Radiation.damagePerTick or 4)))
                end
            else
                setFx(false)
            end
        else
            if inZone then inZone = false; clearCrates(); setFx(false) end
            if hasItem(Config.Radiation.geigerItem) and d <= z.radius + 200.0 then
                local now = GetGameTimer()
                if now - lastGeiger > 5000 then
                    lastGeiger = now
                    lib.notify({ description = '☢️ Geigerzähler: Strahlung in der Nähe!', type = 'warning' })
                    PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
                end
            end
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearCrates(); setFx(false) end
end)
