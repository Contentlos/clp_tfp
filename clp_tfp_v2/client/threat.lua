-- clp_tfp · client/threat — Downed-Zustand, endgültiger Tod, Wiederbeleben
local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}

local cfg = Config.Threat.downed or {}
local downedPlayers = {}

local function realDeath()
    TFP.downed = false
    TriggerServerEvent('clp_tfp:setDowned', false)
    if TFP.SetDowned then TFP.SetDowned(true, 0, 'dead') end
    if Config.Threat.dropInventoryOnDeath then TriggerServerEvent('clp_tfp:died'); Wait(600) else TriggerServerEvent('clp_tfp:died') end
    Wait(900)
    if TFP.SetDowned then TFP.SetDowned(false) end
    AnimpostfxStop('DeathFailOut')
    if TFP.Respawn then TFP.Respawn() end
end

local function enterDowned()
    TFP.downed = true
    local ped = PlayerPedId(); local c = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
    ClearPedTasksImmediately(ped); SetEntityHealth(ped, 150)
    TriggerServerEvent('clp_tfp:setDowned', true)
    AnimpostfxPlay('DeathFailOut')
    local total = cfg.bleedoutSeconds or 120
    local deadline = GetGameTimer() + (total * 1000)
    local lastShown = -1
    if TFP.SetDowned then TFP.SetDowned(true, total, 'downed') end
    CreateThread(function()
        while TFP.downed and GetGameTimer() < deadline do
            Wait(0)
            local p = PlayerPedId()
            if not IsPedRagdoll(p) then SetPedToRagdoll(p, 4000, 4000, 0, false, false, false) end
            DisableControlAction(0, 24, true); DisableControlAction(0, 25, true); DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true); DisableControlAction(0, 23, true)
            local left = math.max(0, math.ceil((deadline - GetGameTimer()) / 1000))
            if left ~= lastShown then lastShown = left; if TFP.SetDowned then TFP.SetDowned(true, left, 'downed') end end
            if IsControlJustPressed(0, 73) then break end
        end
        if TFP.downed then realDeath() end
    end)
end

CreateThread(function()
    while true do
        Wait(300)
        local ped = PlayerPedId()
        if ESX.PlayerLoaded and not TFP.downed and (IsEntityDead(ped) or IsPedFatallyInjured(ped)) then
            if cfg.enabled then enterDowned() else realDeath() end
        end
    end
end)

RegisterNetEvent('clp_tfp:revived', function()
    if not TFP.downed then return end
    TFP.downed = false
    TriggerServerEvent('clp_tfp:setDowned', false)
    AnimpostfxStop('DeathFailOut')
    if TFP.SetDowned then TFP.SetDowned(false) end
    local ped = PlayerPedId(); ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, math.floor(GetEntityMaxHealth(ped) * 0.5))
    if TFP.ResetSurvival then TFP.ResetSurvival() end
    lib.notify({ title = 'Gerettet', description = 'Du wurdest wiederbelebt.', type = 'success' })
end)

RegisterNetEvent('clp_tfp:playerDowned', function(serverId, state) downedPlayers[serverId] = state or nil end)

CreateThread(function()
    local ok, err = pcall(function()
        exports.ox_target:addGlobalPlayer({ {
            name = 'tfp_revive', icon = 'fa-solid fa-suitcase-medical', label = 'Wiederbeleben', distance = 2.0,
            canInteract = function(entity) return downedPlayers[GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))] == true end,
            onSelect = function(data)
                local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                if (exports.ox_inventory:Search('count', cfg.reviveItem) or 0) < 1 then lib.notify({ description = 'Du brauchst ein Erste-Hilfe-Set.', type = 'error' }); return end
                if lib.progressBar({ duration = (cfg.reviveSeconds or 6) * 1000, label = 'Wiederbeleben…', canCancel = true,
                        disable = { move = true, car = true, combat = true }, anim = { dict = 'mini@cpr@char_a@cpr_str', clip = 'cpr_pumpchest' } }) then
                    TriggerServerEvent('clp_tfp:revive', sid)
                end
            end,
        } })
    end)
    if not ok and TFP_Warn then TFP_Warn('Revive-Target nicht verfügbar: ' .. tostring(err)) end
end)
