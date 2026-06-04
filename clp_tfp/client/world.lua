-- clp_tfp · world/ : Cayo Perico aktivieren + Lore-Safezone

local ESX = exports['es_extended']:getSharedObject()

-- ─── Insel aktivieren (Island-Hopper lädt die Cayo-Map-Daten) ────────────────
CreateThread(function()
    if not Config.World.enableIsland then return end
    while not ESX.PlayerLoaded do Wait(500) end
    -- moderne Methode; je nach Game-Build verschieden — daher abgesichert
    pcall(function() SetIslandHopperEnabled(Config.World.islandName, true) end)
    if Config.Debug then
        print('^2[clp_tfp world]^7 Island-Hopper aktiviert: ' .. Config.World.islandName)
    end
end)

-- ─── Minimap auf die Heist-Island umschalten, wenn man dort ist ──────────────
CreateThread(function()
    if not Config.World.enableIsland then return end
    local onIsland = false
    while true do
        Wait(2000)
        local d = #(GetEntityCoords(PlayerPedId()) - Config.World.islandCenter)
        local should = d <= Config.World.islandRadius
        if should ~= onIsland then
            onIsland = should
            pcall(function() SetToggleMinimapHeistIsland(should) end)
        end
    end
end)

-- ─── Lore-Safezone (kampffrei) ───────────────────────────────────────────────
local sz = Config.World.safezone
if sz and sz.enabled then
    CreateThread(function()
        local rb = AddBlipForRadius(sz.center.x, sz.center.y, sz.center.z, sz.radius)
        SetBlipColour(rb, 2)
        SetBlipAlpha(rb, 80)
        local b = AddBlipForCoord(sz.center.x, sz.center.y, sz.center.z)
        SetBlipSprite(b, 312)
        SetBlipColour(b, 2)
        SetBlipScale(b, 0.9)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(sz.label or 'Sichere Zone')
        EndTextCommandSetBlipName(b)
    end)
    lib.zones.sphere({
        coords = sz.center,
        radius = sz.radius,
        debug = Config.Debug,
        onEnter = function()
            lib.notify({ title = 'Sichere Zone', description = (sz.label or 'Sichere Zone') .. ' — hier kannst du nicht kämpfen.', type = 'success' })
        end,
        onExit = function()
            lib.notify({ title = 'Sichere Zone', description = 'Du verlässt die sichere Zone.', type = 'inform' })
            if not TFP._god then
                SetEntityInvincible(PlayerPedId(), false)
                SetPlayerInvincible(PlayerId(), false)
            end
        end,
        inside = function()
            local player = PlayerId()
            local ped = PlayerPedId()
            -- SAFEZONE = SAFEZONE: unverwundbar (auch gegen Tiere/Kannibalen, die hereinlaufen)
            if not TFP._god then
                SetEntityInvincible(ped, true)
                SetPlayerInvincible(player, true)
            end
            DisablePlayerFiring(player, true)
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 140, true) -- Melee leicht
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true)
        end,
    })
end

-- ─── POI-Blips: Strahlenzone + Gefahrenzonen (mehr Orientierung auf der Karte) ─
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(500) end

    if Config.Radiation and Config.Radiation.enabled and Config.Radiation.zone then
        local z = Config.Radiation.zone
        local rb = AddBlipForRadius(z.center.x, z.center.y, z.center.z, z.radius)
        SetBlipColour(rb, 1); SetBlipAlpha(rb, 90)
        local b = AddBlipForCoord(z.center.x, z.center.y, z.center.z)
        SetBlipSprite(b, 310); SetBlipColour(b, 1); SetBlipScale(b, 0.9)
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
