-- clp_tfp · survival · spawn/
-- Verstreutes Erst-Spawnen, Respawn-Funktion (von threat/ genutzt), Schlafsack.
-- Tod-/Downed-Logik liegt in threat/.

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

-- ─── Erstes Spawnen: verstreut an den Strand ─────────────────────────────────
RegisterNetEvent('clp_tfp:firstSpawn', function(p)
    DoScreenFadeOut(500)
    Wait(600)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, p.x, p.y, p.z, false, false, false)
    SetEntityHeading(ped, p.w or 0.0)
    Wait(300)
    DoScreenFadeIn(1200)
    lib.notify({ title = 'Gestrandet', description = 'Du erwachst an einem fremden Strand…', type = 'inform' })

    -- ── Onboarding: Lore + Steuerung (einmalig beim ersten Spawn) ──
    Wait(1500)
    lib.alertDialog({
        header = '☠️  Gestrandet auf Cayo Perico',
        content = [[
Das Boot ist weg. Niemand weiß, dass du hier bist. Die Insel will dich nicht.

**So überlebst du:**
- **Sammeln:** Visiere Bäume/Felsen/Büsche an (ox_target-Auge) und sammle Holz, Stein, Fasern. Eine **Axt** brauchst du für Bäume — fehlt sie, bau dir eine **Steinaxt** (Stein + Faser).
- **Handwerk & Bauen:** Öffne das Menü mit **F5** (oder `/survival`): Handwerk, Bauen, Stamm, Admin.
- **Essen & Trinken:** Items im Inventar benutzen. **Rohes Fleisch/Fisch** macht oft krank — am **Lagerfeuer braten**! Dreckiges Wasser → abkochen.
- **Wärme & Nässe:** Nachts & im Regen kühlst du aus → krank. Mach **Feuer**, trockne, näh dir **Fellkleidung** (aus Tierfell).
- **Verletzung:** Blutung → **Verband**, Knochenbruch → **Schiene**, Krankheit → **Medizin/Antibiotika**.
- **Respawn:** Leg einen **Schlafsack** aus — dort wachst du nach dem Tod wieder auf.

**Gefahren:** Wildtiere, **Haie** im Wasser, das Kartell in den Lagern — und nachts kommen die **Kannibalen**. Bleib wachsam.

_Tipp: `/tfphelp` zeigt jederzeit die komplette Steuerung._]],
        centered = true,
        size = 'md',
    })
end)

-- ─── Respawn (Schlafsack > Strand) — von threat/ nach endgültigem Tod ────────
function TFP.Respawn()
    local coords = lib.callback.await('clp_tfp:getRespawn', false)
    DoScreenFadeOut(500)
    Wait(600)
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.h or 0.0, true, false)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.h or 0.0)
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    TriggerEvent('esx_basicneeds:resetStatus')
    if TFP.ResetSurvival then TFP.ResetSurvival() end  -- Verletzungen/Krankheit zurücksetzen (keine Todesschleife)
    Wait(400)
    DoScreenFadeIn(900)
end

-- ─── Schlafsack platzieren (ox_inventory client.export) ──────────────────────
exports('placeSleepingBag', function()
    local ped = PlayerPedId()
    local fwd = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
    local found, gz = GetGroundZFor_3dCoord(fwd.x, fwd.y, fwd.z + 1.0, false)
    local coords = vec3(fwd.x, fwd.y, found and gz or fwd.z)
    if lib.progressBar({
        duration = 3000, label = 'Schlafsack auslegen…', canCancel = true,
        useWhileDead = false, disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base' },
    }) then
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
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        exports.ox_target:addLocalEntity(obj, {
            { name = 'tfp_bag_sleep', icon = 'fa-solid fa-moon', label = 'Schlafen (erholt + Zeit vor)', distance = 2.0,
              onSelect = function() if TFP.Sleep then TFP.Sleep() end end },
        })
    end
end)

-- ─── Home-Blip (Schlafplatz) ─────────────────────────────────────────────────
local homeBlip
local function setHomeBlip(c)
    if homeBlip then RemoveBlip(homeBlip) end
    homeBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(homeBlip, 1)
    SetBlipColour(homeBlip, 3)
    SetBlipScale(homeBlip, 0.85)
    SetBlipAsShortRange(homeBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Schlafplatz')
    EndTextCommandSetBlipName(homeBlip)
end

RegisterNetEvent('clp_tfp:setHome', function(c) setHomeBlip(c) end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    local h = lib.callback.await('clp_tfp:getHome', false)
    if h then setHomeBlip(h) end
end)

-- ─── Universeller Koord-Kopierer (immer verfügbar) ───────────────────────────
-- Kopiert die aktuelle Position als vec3 — zum Setzen aller Platzhalter-Koords
-- (Notizen, Wrack-/Tauch-Punkte, Zonen) direkt in der config.lua.
RegisterCommand('tfppos', function()
    local c = GetEntityCoords(PlayerPedId())
    local s = ('vec3(%.1f, %.1f, %.1f),'):format(c.x, c.y, c.z)
    lib.setClipboard(s)
    print('^2[clp_tfp]^7 ' .. s)
    lib.notify({ title = 'Position kopiert', description = s, type = 'success' })
end, false)

-- ─── Debug ───────────────────────────────────────────────────────────────────
if Config.Debug then
    RegisterCommand('tfpaddspawn', function()
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        local s = ('vec4(%.1f, %.1f, %.1f, %.1f),'):format(c.x, c.y, c.z, h)
        print('^2[clp_tfp spawn]^7 ' .. s)
        lib.setClipboard(s)
        lib.notify({ description = 'Spawnpunkt kopiert:\n' .. s })
    end, false)

    RegisterCommand('tfprespawn', function() TFP.Respawn() end, false)
end
