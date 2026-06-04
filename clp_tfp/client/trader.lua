-- clp_tfp · trader/ (Client) — Schwarzmarkt-Händler (Barter, kein Geld)

local ESX = exports['es_extended']:getSharedObject()
local T = Config.Trader or {}

local function itemCount(name) return exports.ox_inventory:Search('count', name) or 0 end

local function offerText(o)
    local parts = {}
    for _, g in ipairs(o.give) do parts[#parts + 1] = ('%s ×%d (du: %d)'):format(g.item, g.count, itemCount(g.item)) end
    return 'Gibst: ' .. table.concat(parts, ', ')
end

local function canAfford(o)
    for _, g in ipairs(o.give) do if itemCount(g.item) < g.count then return false end end
    return true
end

local function openTrade()
    local opts = {}
    for i, o in ipairs(T.offers or {}) do
        opts[#opts + 1] = {
            title = o.label,
            description = offerText(o),
            disabled = not canAfford(o),
            icon = 'fa-solid fa-right-left',
            onSelect = function() TriggerServerEvent('clp_tfp:trade', i) end,
        }
    end
    if #opts == 0 then opts[#opts + 1] = { title = 'Keine Angebote', disabled = true } end
    lib.registerContext({ id = 'tfp_trader', title = '🕶️ Schwarzmarkt', options = opts })
    lib.showContext('tfp_trader')
end

CreateThread(function()
    if not T.enabled or not T.coords then return end
    while not ESX.PlayerLoaded do Wait(250) end

    local model = joaat(T.ped or 'mp_m_shopkeep_01')
    if IsModelValid(model) and lib.requestModel(model, 5000) then
        local c = T.coords
        local ped = CreatePed(4, model, c.x, c.y, c.z - 1.0, c.w or 0.0, false, false)
        SetModelAsNoLongerNeeded(model)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        exports.ox_target:addLocalEntity(ped, {
            { name = 'tfp_trader', icon = 'fa-solid fa-sack-dollar', label = 'Handeln (Schwarzmarkt)', distance = 2.5,
              onSelect = openTrade },
        })
    end

    if T.blip then
        local b = AddBlipForCoord(T.coords.x, T.coords.y, T.coords.z)
        SetBlipSprite(b, T.blip.sprite or 52)
        SetBlipColour(b, T.blip.color or 2)
        SetBlipScale(b, 0.85)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(T.blip.label or 'Schwarzmarkt')
        EndTextCommandSetBlipName(b)
    end
end)

-- nach erfolgreichem Tausch das Menü mit aktuellen Mengen neu aufbauen
RegisterNetEvent('clp_tfp:tradeOk', function() openTrade() end)
