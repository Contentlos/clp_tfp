-- clp_tfp · client/weather — wendet Wetter+Zeit an, speist HUD-Widget (Wetter/Zeit/Temp)

local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

local cur = { hour = 8, minute = 0, weather = 'CLEAR' }

local LABELS = {
    EXTRASUNNY = 'Sonnig', CLEAR = 'Klar', CLOUDS = 'Bewölkt', OVERCAST = 'Bedeckt',
    FOGGY = 'Neblig', RAIN = 'Regen', THUNDER = 'Gewitter', CLEARING = 'Aufklarend',
    NEUTRAL = 'Klar', SMOG = 'Smog', SNOW = 'Schnee', BLIZZARD = 'Schneesturm',
}

RegisterNetEvent('clp_tfp:weatherSync', function(h, m, w)
    cur.hour, cur.minute = h, m
    if w ~= cur.weather then
        cur.weather = w
        SetWeatherTypeOverTime(w, (Config.Weather.transitionSec or 25) + 0.0)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if Config.Weather.enabled then
            if Config.Weather.syncTime then NetworkOverrideClockTime(cur.hour, cur.minute, 0) end
            local tempPct = (TFP.State and TFP.State.temperature) or 70
            local tempC = math.floor(-5 + tempPct / 100 * 43 + 0.5)
            if TFP.UpdateEnv then
                TFP.UpdateEnv(LABELS[cur.weather] or cur.weather, cur.hour, cur.minute, tempC)
            end
        end
    end
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    TriggerServerEvent('clp_tfp:requestWeather')
end)
