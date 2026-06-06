-- clp_tfp · client/spawn — verstreutes Erst-Spawnen, Respawn, Schlafsack, Home-Blip
local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

RegisterNetEvent('clp_tfp:firstSpawn', function(p)
    DoScreenFadeOut(500); Wait(600)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, p.x, p.y, p.z, false, false, false)
    SetEntityHeading(ped, p.w or 0.0)
    Wait(300); DoScreenFadeIn(1200)
    lib.notify({ title = 'Gestrandet', description = 'Du erwachst an einem fremden Strand…', type = 'inform' })
    Wait(1500)
    lib.alertDialog({
        header = '☠️  Gestrandet auf Cayo Perico', centered = true, size = 'md',
        content = [[
Das Boot ist weg. Niemand weiß, dass du hier bist. Die Insel will dich nicht.

**So überlebst du:**
- **Sammeln:** Bäume/Felsen/Büsche anvisieren (ox_target-Auge). Bäume brauchen eine **Axt** (notfalls Steinaxt craften).
- **Menü:** **F5** — Handwerk, Bauen, Aktivitäten, Stamm.
- **Essen & Trinken:** Items benutzen. Rohes Fleisch/dreckiges Wasser am **Feuer** zubereiten.
- **Wärme & Nässe:** Nachts & im Regen kühlst du aus → krank. Mach **Feuer**, trockne dich.
- **Verletzung:** Blutung → **Verband**, Bruch → **Schiene**.
- **Respawn:** Leg einen **Schlafsack** aus.

_`/tfphelp` zeigt jederzeit die Steuerung._]],
    })
end)

-- Respawn (Schlafsack > Strand) — von threat/ (Phase 3) nach endgültigem Tod genutzt
function TFP.Respawn()
    local coords = lib.callback.await('clp_tfp:getRespawn', false)
    DoScreenFadeOut(500); Wait(600)
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.h or 0.0, true, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.h or 0.0)
    ClearPedBloodDamage(ped); ClearPedWetness(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    TriggerEvent('esx_basicneeds:resetStatus')
    if TFP.ResetSurvival then TFP.ResetSurvival() end
    Wait(400); DoScreenFadeIn(900)
end

-- Schlafsack auslegen (ox_inventory client.export — Item 'sleeping_bag')
exports('placeSleepingBag', function()
    local ped = PlayerPedId()
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
    local found, gz = GetGroundZFor_3dCoord(fwd.x, fwd.y, fwd.z + 1.0, false)
    local coords = vec3(fwd.x, fwd.y, found and gz or fwd.z)
    if lib.progressBar({ duration = 3000, label = 'Schlafsack auslegen…', canCancel = true,
            disable = { move = true, car = true, combat = true }, anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' } }) then
        TriggerServerEvent('clp_tfp:placeSleepingBag', coords, GetEntityHeading(ped))
    end
    return false
end)

RegisterNetEvent('clp_tfp:spawnSleepingBag', function(coords, heading)
    local model = joaat(Config.Spawn.sleepingBagModel)
    if lib.requestModel(model, 5000) then
        local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(model)
        if heading then SetEntityHeading(obj, heading) end
        PlaceObjectOnGroundProperly(obj); FreezeEntityPosition(obj, true)
    end
end)

-- Home-Blip
local homeBlip
local function setHomeBlip(c)
    if homeBlip then RemoveBlip(homeBlip) end
    homeBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(homeBlip, 1); SetBlipColour(homeBlip, 3); SetBlipScale(homeBlip, 0.85); SetBlipAsShortRange(homeBlip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Schlafplatz'); EndTextCommandSetBlipName(homeBlip)
end
RegisterNetEvent('clp_tfp:setHome', function(c) setHomeBlip(c) end)
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    local h = lib.callback.await('clp_tfp:getHome', false)
    if h then setHomeBlip(h) end
end)

if Config.Debug then
    RegisterCommand('tfpaddspawn', function()
        local ped = PlayerPedId(); local c = GetEntityCoords(ped)
        local s = ('vec4(%.1f, %.1f, %.1f, %.1f),'):format(c.x, c.y, c.z, GetEntityHeading(ped))
        lib.setClipboard(s); lib.notify({ description = 'Spawnpunkt kopiert:\n' .. s })
    end, false)
end
