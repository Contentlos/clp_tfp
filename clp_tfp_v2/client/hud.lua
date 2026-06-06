-- clp_tfp · client/hud — NUI-Bridge. (§2.3) HUD nach Spawn/Revive zuverlässig zeigen.
TFP = TFP or {}

function TFP.UpdateHud(data) SendNUIMessage({ action = 'update', data = data }) end
function TFP.UpdateEnv(weatherLabel, hour, minute, tempC)
    SendNUIMessage({ action = 'env', weather = weatherLabel, time = string.format('%02d:%02d', hour, minute), temp = tempC })
end
function TFP.SetDowned(show, seconds, mode)
    SendNUIMessage({ action = 'downed', show = show and true or false, seconds = seconds or 0, mode = mode or 'downed' })
end
function TFP.UpdateFx(red, blue) SendNUIMessage({ action = 'fx', red = red or 0.0, blue = blue or 0.0 }) end
function TFP.UpdateObjective(data) SendNUIMessage({ action = 'objective', data = data }) end

local function hideHud() SendNUIMessage({ action = 'display', show = false }) end
local function showHud() SendNUIMessage({ action = 'display', show = true }) end
TFP.ShowHud = showHud
TFP.HideHud = hideHud

AddEventHandler('esx:onPlayerDeath', hideHud)
AddEventHandler('esx:onPlayerLogout', hideHud)
AddEventHandler('esx:onPlayerSpawn', showHud)   -- nach (Wieder-)Spawn wieder zeigen
AddEventHandler('playerSpawned', showHud)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then hideHud() end end)
