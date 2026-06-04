-- clp_tfp · survival · HUD-Bridge (NUI)
-- Schickt die aktuellen Stat-Werte an die NUI. Sichtbarkeit pro Stat regelt app.js.
TFP = TFP or {}

function TFP.UpdateHud(data)
    SendNUIMessage({ action = 'update', data = data })
end

-- Wetter/Zeit/Temperatur-Widget (von weather/ gespeist)
function TFP.UpdateEnv(weatherLabel, hour, minute, tempC)
    SendNUIMessage({
        action = 'env',
        weather = weatherLabel,
        time = string.format('%02d:%02d', hour, minute),
        temp = tempC,
    })
end

-- Death/Downed-Screen (Vollbild-Overlay)
function TFP.SetDowned(show, seconds, mode)
    SendNUIMessage({ action = 'downed', show = show and true or false, seconds = seconds or 0, mode = mode or 'downed' })
end

-- Realismus-Vignetten (rot = niedrige HP, blau = Kälte), Intensität 0..1
function TFP.UpdateFx(red, blue)
    SendNUIMessage({ action = 'fx', red = red or 0.0, blue = blue or 0.0 })
end

local function hideHud()
    SendNUIMessage({ action = 'display', show = false })
end

AddEventHandler('esx:onPlayerDeath', hideHud)
AddEventHandler('esx:onPlayerLogout', hideHud)

-- HUD beim Resource-Stop sauber ausblenden (Dev-Reloads)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then hideHud() end
end)
