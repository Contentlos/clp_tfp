-- clp_tfp · admin/ (Client) — NUI-Panel (ox_lib) für Admins: Wipe, Tools, Teleport

local function teleport(c)
    DoScreenFadeOut(400); Wait(500)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z + 1.0, false, false, false)
    Wait(300); DoScreenFadeIn(600)
end

local function confirmWipe(scope, text)
    local r = lib.alertDialog({ header = 'Wipe bestätigen', content = text .. '\n\n**Unumkehrbar!**', centered = true, cancel = true })
    if r == 'confirm' then TriggerServerEvent('clp_tfp:adminWipe', scope) end
end

local function openWipe()
    lib.registerContext({ id = 'tfp_wipe', title = 'Wipe — VORSICHT', menu = 'tfp_admin', options = {
        { title = 'Map-Wipe', icon = 'fa-solid fa-house-chimney-crack', description = 'Löscht ALLE Bauten/Basen',
          onSelect = function() confirmWipe('map', 'Alle Bauten/Basen löschen?') end },
        { title = 'Blueprint-Wipe', icon = 'fa-solid fa-scroll', description = 'Setzt erforschte Rezepte zurück',
          onSelect = function() confirmWipe('blueprints', 'Alle erforschten Blueprints zurücksetzen?') end },
        { title = 'VOLL-WIPE', icon = 'fa-solid fa-triangle-exclamation', description = 'Bauten + Blueprints + Spieler-Reset',
          onSelect = function() confirmWipe('full', 'ALLES wipen? Bauten, Blueprints UND Spieler-Fortschritt (Starter-Kit + verstreutes Spawnen neu)') end },
    } })
    lib.showContext('tfp_wipe')
end

local function openTeleport()
    local opts = {}
    if Config.World and Config.World.safezone then
        opts[#opts + 1] = { title = 'Safezone / Strandlager', icon = 'fa-solid fa-umbrella-beach',
            onSelect = function() teleport(Config.World.safezone.center) end }
    end
    for _, camp in ipairs(Config.Camps.list) do
        opts[#opts + 1] = { title = camp.name, icon = 'fa-solid fa-skull', onSelect = function() teleport(camp.center) end }
    end
    lib.registerContext({ id = 'tfp_tp', title = 'Teleport', menu = 'tfp_admin', options = opts })
    lib.showContext('tfp_tp')
end

local function openStat()
    local input = lib.inputDialog('Survival-Stat setzen', {
        { type = 'select', label = 'Stat', required = true, options = {
            { value = 'hunger', label = 'Hunger' }, { value = 'thirst', label = 'Durst' },
            { value = 'stamina', label = 'Stamina' }, { value = 'temperature', label = 'Temperatur' },
            { value = 'wetness', label = 'Nässe' }, { value = 'sickness', label = 'Krankheit' },
        } },
        { type = 'slider', label = 'Wert (%)', min = 0, max = 100, default = 100 },
    })
    if input and input[1] then
        TriggerEvent('esx_status:set', input[1], math.floor((input[2] or 0) / 100 * 1000000))
    end
end

local function fmtAgo(s)
    s = math.floor(s or 0)
    if s < 3600 then return ('vor %d Min'):format(math.floor(s / 60)) end
    return ('vor %.1f h'):format(s / 3600)
end

local function openDeaths()
    local deaths = lib.callback.await('clp_tfp:getRecentDeaths', false) or {}
    local opts = {}
    for _, d in ipairs(deaths) do
        opts[#opts + 1] = {
            title = d.name or '?',
            description = ('%s · %.0f, %.0f, %.0f'):format(fmtAgo(d.ago), d.x, d.y, d.z),
            icon = 'fa-solid fa-skull',
            onSelect = function() teleport({ x = d.x, y = d.y, z = d.z }) end,
        }
    end
    if #opts == 0 then opts[#opts + 1] = { title = 'Keine Tode in den letzten Stunden', disabled = true } end
    lib.registerContext({ id = 'tfp_deaths', menu = 'tfp_admin',
        title = ('☠️ Letzte Tode (%dh)'):format((Config.Threat and Config.Threat.deathLogHours) or 12), options = opts })
    lib.showContext('tfp_deaths')
end

local function openAdmin()
    lib.registerContext({ id = 'tfp_admin', title = '🛠️ TFP Admin', options = {
        { title = 'Wipe…', icon = 'fa-solid fa-broom', arrow = true, onSelect = openWipe },
        { title = 'Airdrop auslösen', icon = 'fa-solid fa-parachute-box', onSelect = function() TriggerServerEvent('clp_tfp:adminAirdrop') end },
        { title = 'Wrack-Event auslösen', icon = 'fa-solid fa-anchor', onSelect = function() TriggerServerEvent('clp_tfp:adminWreck') end },
        { title = 'Gegner-Welle spawnen (Test)', icon = 'fa-solid fa-skull', onSelect = function() TriggerEvent('clp_tfp:spawnWave') end },
        { title = 'Voll heilen', icon = 'fa-solid fa-heart', onSelect = function()
            local p = PlayerPedId(); SetEntityHealth(p, GetEntityMaxHealth(p)); ClearPedBloodDamage(p); ClearPedWetness(p)
        end },
        { title = 'Selbst wiederbeleben (/tfprevive)', icon = 'fa-solid fa-heart-pulse', onSelect = function()
            if TFP.SelfRevive then TFP.SelfRevive() end
        end },
        { title = 'Survival auffüllen', icon = 'fa-solid fa-bottle-water', onSelect = function()
            for _, n in ipairs({ 'hunger', 'thirst', 'stamina', 'temperature' }) do TriggerEvent('esx_status:set', n, 1000000) end
            TriggerEvent('esx_status:set', 'wetness', 0)
            TriggerEvent('esx_status:set', 'sickness', 0)
        end },
        { title = 'Survival-Stat setzen…', icon = 'fa-solid fa-sliders', onSelect = openStat },
        { title = 'Teleport…', icon = 'fa-solid fa-location-dot', arrow = true, onSelect = openTeleport },
        { title = ('Letzte Tode (%dh)'):format((Config.Threat and Config.Threat.deathLogHours) or 12),
          icon = 'fa-solid fa-skull-crossbones', arrow = true, onSelect = openDeaths },
        { title = 'Punkt-Editor (Koords setzen)', icon = 'fa-solid fa-map-location-dot', arrow = true,
          onSelect = function() if TFP.OpenEditor then TFP.OpenEditor() end end },
        { title = 'Item geben', icon = 'fa-solid fa-gift', onSelect = function()
            local i = lib.inputDialog('Item geben', {
                { type = 'input', label = 'Item-Name', required = true },
                { type = 'number', label = 'Menge', default = 1, min = 1, max = 1000 },
            })
            if i and i[1] then TriggerServerEvent('clp_tfp:adminGive', i[1], math.floor(i[2] or 1)) end
        end },
        { title = 'Verletzungen heilen', icon = 'fa-solid fa-kit-medical', onSelect = function()
            local p = PlayerPedId()
            SetEntityHealth(p, GetEntityMaxHealth(p)); ClearPedBloodDamage(p); ClearPedWetness(p)
            if TFP.StopBleed then TFP.StopBleed() end
            if TFP.HealFracture then TFP.HealFracture() end
        end },
        { title = 'Bau-Modus (gratis/unbegrenzt/überall)', icon = 'fa-solid fa-trowel-bricks', onSelect = function()
            TFP._adminBuild = not TFP._adminBuild
            TriggerServerEvent('clp_tfp:setAdminBuild', TFP._adminBuild)
            if TFP.OpenBuild and TFP._adminBuild then TFP.OpenBuild() end -- direkt Bau-Menü öffnen
        end },
        { title = 'Godmode an/aus', icon = 'fa-solid fa-shield-halved', onSelect = function()
            TFP._god = not TFP._god
            SetEntityInvincible(PlayerPedId(), TFP._god)
            SetPlayerInvincible(PlayerId(), TFP._god)
            lib.notify({ title = 'TFP Admin', description = 'Godmode: ' .. tostring(TFP._god), type = 'inform' })
        end },
        { title = 'Zu Markierung teleportieren', icon = 'fa-solid fa-map-pin', onSelect = function()
            local wp = GetFirstBlipInfoId(8)
            if not DoesBlipExist(wp) then lib.notify({ description = 'Keine Karten-Markierung gesetzt.', type = 'error' }); return end
            local c = GetBlipInfoIdCoord(wp)
            DoScreenFadeOut(300); Wait(400)
            local ped = PlayerPedId()
            SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
            for h = 0, 1000, 25 do
                local f, z = GetGroundZFor_3dCoord(c.x, c.y, h + 0.0, false)
                if f then SetEntityCoords(ped, c.x, c.y, z + 1.0, false, false, false, false); break end
                Wait(0)
            end
            Wait(300); DoScreenFadeIn(500)
        end },
        { title = 'Fahrzeug spawnen', icon = 'fa-solid fa-car', onSelect = function()
            local i = lib.inputDialog('Fahrzeug spawnen', { { type = 'input', label = 'Modell', default = 'dinghy', required = true } })
            if not i or not i[1] then return end
            local model = joaat(i[1])
            if not IsModelValid(model) then lib.notify({ description = 'Ungültiges Modell.', type = 'error' }); return end
            if lib.requestModel(model, 5000) then
                local ped = PlayerPedId()
                local f = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.5, 0.0)
                local veh = CreateVehicle(model, f.x, f.y, GetEntityCoords(ped).z, GetEntityHeading(ped), true, false)
                SetModelAsNoLongerNeeded(model)
                SetVehicleOnGroundProperly(veh)
                SetVehicleHasBeenOwnedByPlayer(veh, true)
            end
        end },
    } })
    lib.showContext('tfp_admin')
end

RegisterNetEvent('clp_tfp:openAdmin', function() openAdmin() end)

function TFP.OpenAdmin()
    if lib.callback.await('clp_tfp:isAdmin', false) then
        openAdmin()
    else
        lib.notify({ title = 'TFP Admin', description = 'Keine Berechtigung (tfp.admin / Admin-Gruppe).', type = 'error' })
    end
end

RegisterCommand('tfpadmin', function() TFP.OpenAdmin() end, false)
