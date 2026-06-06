-- clp_tfp · client/world — Cayo Perico aktivieren + Lore-Safezone (§2.9: unverwundbar)

local ESX = exports['es_extended']:getSharedObject()

-- ─── Insel aktivieren ────────────────────────────────────────────────────────
CreateThread(function()
    if not Config.World.enableIsland then return end
    while not ESX.PlayerLoaded do Wait(500) end
    pcall(function() SetIslandHopperEnabled(Config.World.islandName, true) end)
end)

-- Minimap auf die Heist-Island umschalten, wenn man dort ist
CreateThread(function()
    if not Config.World.enableIsland then return end
    local onIsland = false
    while true do
        Wait(2000)
        local should = #(GetEntityCoords(PlayerPedId()) - Config.World.islandCenter) <= Config.World.islandRadius
        if should ~= onIsland then onIsland = should; pcall(function() SetToggleMinimapHeistIsland(should) end) end
    end
end)

-- ─── Safezone (kampffrei + unverwundbar) ─────────────────────────────────────
local sz = Config.World.safezone
if sz and sz.enabled then
    CreateThread(function()
        local rb = AddBlipForRadius(sz.center.x, sz.center.y, sz.center.z, sz.radius)
        SetBlipColour(rb, 2); SetBlipAlpha(rb, 80)
        local b = AddBlipForCoord(sz.center.x, sz.center.y, sz.center.z)
        SetBlipSprite(b, 312); SetBlipColour(b, 2); SetBlipScale(b, 0.9); SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(sz.label or 'Sichere Zone'); EndTextCommandSetBlipName(b)
    end)
    lib.zones.sphere({
        coords = sz.center, radius = sz.radius, debug = Config.Debug,
        onEnter = function()
            lib.notify({ title = 'Sichere Zone', description = (sz.label or 'Sichere Zone') .. ' — hier kannst du nicht kämpfen.', type = 'success' })
        end,
        onExit = function()
            lib.notify({ title = 'Sichere Zone', description = 'Du verlässt die sichere Zone.', type = 'inform' })
            if not TFP._god then SetEntityInvincible(PlayerPedId(), false); SetPlayerInvincible(PlayerId(), false) end
        end,
        inside = function()
            local player, ped = PlayerId(), PlayerPedId()
            if not TFP._god then SetEntityInvincible(ped, true); SetPlayerInvincible(player, true) end
            DisablePlayerFiring(player, true)
            DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true); DisableControlAction(0, 141, true); DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true); DisableControlAction(0, 263, true); DisableControlAction(0, 264, true)
        end,
    })
end

-- ─── POI-Blips (Radiation/Gefahrenzonen — greift erst, wenn die Configs existieren) ──
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(500) end
    if Config.Radiation and Config.Radiation.enabled and Config.Radiation.zone then
        local z = Config.Radiation.zone
        local rb = AddBlipForRadius(z.center.x, z.center.y, z.center.z, z.radius); SetBlipColour(rb, 1); SetBlipAlpha(rb, 90)
        local b = AddBlipForCoord(z.center.x, z.center.y, z.center.z); SetBlipSprite(b, 310); SetBlipColour(b, 1); SetBlipScale(b, 0.9)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Verstrahlte Zone'); EndTextCommandSetBlipName(b)
    end
    for _, zone in ipairs((Config.AI and Config.AI.zones) or {}) do
        if zone.center then
            local b = AddBlipForCoord(zone.center.x, zone.center.y, zone.center.z)
            SetBlipSprite(b, 84); SetBlipColour(b, 1); SetBlipScale(b, 0.8); SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('Gefahrenzone'); EndTextCommandSetBlipName(b)
        end
    end
end)
