-- clp_tfp · server/weather — autoritatives Wetter + Zeit, an alle Clients gesynct

local gameMinTotal = (Config.Weather.startHour or 8) * 60.0 -- 0..1440 Spielminuten
local weather = 'CLEAR'
local holdUntil = 0

local function pickWeather()
    local total = 0
    for _, t in ipairs(Config.Weather.types) do total = total + t.weight end
    local r = math.random() * total
    for _, t in ipairs(Config.Weather.types) do
        r = r - t.weight
        if r <= 0 then return t.w end
    end
    return 'CLEAR'
end

local function broadcast(target)
    local h = math.floor(gameMinTotal / 60) % 24
    local m = math.floor(gameMinTotal % 60)
    TriggerClientEvent('clp_tfp:weatherSync', target or -1, h, m, weather)
end

CreateThread(function()
    if not Config.Weather.enabled then return end
    weather = pickWeather()
    holdUntil = GetGameTimer() + math.random(Config.Weather.holdMinSec, Config.Weather.holdMaxSec) * 1000
    local tickSec = 2
    local gainPerTick = (1440.0 / (Config.Weather.minutesPerDay * 60.0)) * tickSec -- Spielminuten pro Tick
    while true do
        Wait(tickSec * 1000)
        gameMinTotal = (gameMinTotal + gainPerTick) % 1440.0
        if GetGameTimer() >= holdUntil then
            weather = pickWeather()
            holdUntil = GetGameTimer() + math.random(Config.Weather.holdMinSec, Config.Weather.holdMaxSec) * 1000
        end
        broadcast(-1)
    end
end)

RegisterNetEvent('clp_tfp:requestWeather', function() broadcast(source) end)
