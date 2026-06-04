-- clp_tfp · tribe/ (Client) : Menü, Verwaltung (Rang/Kick), geteilte Truhe, Einladungen, Blips

local ESX = exports['es_extended']:getSharedObject()
local openTribeMenu  -- forward declaration

local function nearestPlayerServerId()
    local me = PlayerPedId()
    local mc = GetEntityCoords(me)
    local closest, dist = nil, 5.0
    for _, p in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(p)
        if ped ~= me and DoesEntityExist(ped) then
            local d = #(GetEntityCoords(ped) - mc)
            if d < dist then dist = d; closest = GetPlayerServerId(p) end
        end
    end
    return closest
end

local function rankLabel(rank)
    if rank == 'leader' then return '👑 Anführer' end
    if rank == 'officer' then return '🎖️ Offizier' end
    return 'Mitglied'
end

-- Aktionen an einem einzelnen Mitglied (Beförderung/Herabstufung/Kick)
local function openMemberActions(tribe, mem)
    local iAmLeader  = tribe.myRank == 'leader'
    local iAmOfficer = tribe.myRank == 'officer'
    local opts = {}

    if iAmLeader and mem.rank == 'member' then
        opts[#opts + 1] = { title = 'Zum Offizier befördern', icon = 'fa-solid fa-arrow-up',
            onSelect = function() TriggerServerEvent('clp_tfp:tribePromote', mem.identifier); SetTimeout(300, openTribeMenu) end }
    end
    if iAmLeader and mem.rank == 'officer' then
        opts[#opts + 1] = { title = 'Zum Mitglied herabstufen', icon = 'fa-solid fa-arrow-down',
            onSelect = function() TriggerServerEvent('clp_tfp:tribeDemote', mem.identifier); SetTimeout(300, openTribeMenu) end }
    end
    local canKick = (iAmLeader and mem.rank ~= 'leader') or (iAmOfficer and mem.rank == 'member')
    if canKick then
        opts[#opts + 1] = { title = 'Aus Stamm entfernen', icon = 'fa-solid fa-user-xmark', iconColor = 'red',
            onSelect = function()
                local c = lib.alertDialog({ header = 'Entfernen', content = ('**%s** wirklich entfernen?'):format(mem.name), centered = true, cancel = true })
                if c == 'confirm' then TriggerServerEvent('clp_tfp:tribeKick', mem.identifier); SetTimeout(300, openTribeMenu) end
            end }
    end
    if #opts == 0 then opts[#opts + 1] = { title = 'Keine Aktionen verfügbar', disabled = true } end

    lib.registerContext({ id = 'tfp_tribe_mem', title = ('%s · %s'):format(mem.name, rankLabel(mem.rank)), menu = 'tfp_tribe_members', options = opts })
    lib.showContext('tfp_tribe_mem')
end

local function openMembers(tribe)
    local opts = {}
    for _, mem in ipairs(tribe.members) do
        opts[#opts + 1] = {
            title = mem.name, description = 'Rang: ' .. rankLabel(mem.rank),
            icon = mem.rank == 'leader' and 'fa-solid fa-crown' or (mem.rank == 'officer' and 'fa-solid fa-shield-halved' or 'fa-solid fa-user'),
            arrow = true,
            onSelect = function() openMemberActions(tribe, mem) end,
        }
    end
    lib.registerContext({ id = 'tfp_tribe_members', title = 'Mitglieder (' .. #tribe.members .. ')', menu = 'tfp_tribe', options = opts })
    lib.showContext('tfp_tribe_members')
end

openTribeMenu = function()
    local tribe = lib.callback.await('clp_tfp:getMyTribe', false)
    local options = {}

    if not tribe then
        options[#options + 1] = { title = 'Stamm gründen', icon = 'fa-solid fa-plus', onSelect = function()
            local input = lib.inputDialog('Stamm gründen', { { type = 'input', label = 'Name', required = true, max = 48 } })
            if input and input[1] then TriggerServerEvent('clp_tfp:tribeCreate', input[1]) end
        end }
    else
        options[#options + 1] = { title = '🏕️ ' .. tribe.name, description = 'Dein Rang: ' .. rankLabel(tribe.myRank), disabled = true }
        options[#options + 1] = { title = 'Mitglieder verwalten', icon = 'fa-solid fa-users', description = #tribe.members .. ' / ' .. (Config.Tribe.maxMembers or 10),
            arrow = true, onSelect = function() openMembers(tribe) end }
        options[#options + 1] = { title = 'Gemeinsame Truhe', icon = 'fa-solid fa-box-archive', onSelect = function()
            local id = lib.callback.await('clp_tfp:getTribeStash', false)
            if id then exports.ox_inventory:openInventory('stash', id)
            else lib.notify({ description = 'Kein Stamm-Stash verfügbar.', type = 'error' }) end
        end }
        if tribe.myRank == 'leader' or tribe.myRank == 'officer' then
            options[#options + 1] = { title = 'Nächsten Spieler einladen', icon = 'fa-solid fa-user-plus', onSelect = function()
                local t = nearestPlayerServerId()
                if t then TriggerServerEvent('clp_tfp:tribeInvite', t)
                else lib.notify({ description = 'Kein Spieler in der Nähe (max. 5 m).', type = 'error' }) end
            end }
        end
        local leaveLabel = tribe.myRank == 'leader' and 'Stamm auflösen' or 'Stamm verlassen'
        options[#options + 1] = { title = leaveLabel, icon = 'fa-solid fa-door-open', onSelect = function()
            local c = lib.alertDialog({ header = leaveLabel, content = 'Sicher?', centered = true, cancel = true })
            if c == 'confirm' then TriggerServerEvent('clp_tfp:tribeLeave') end
        end }
    end

    lib.registerContext({ id = 'tfp_tribe', title = 'Stamm', options = options })
    lib.showContext('tfp_tribe')
end

RegisterCommand('tribe', openTribeMenu, false)
function TFP.OpenTribe() openTribeMenu() end

RegisterNetEvent('clp_tfp:tribeInvited', function(name)
    local res = lib.alertDialog({
        header = 'Stamm-Einladung',
        content = 'Du wurdest zu **' .. name .. '** eingeladen. Beitreten?',
        centered = true, cancel = true,
    })
    if res == 'confirm' then TriggerServerEvent('clp_tfp:tribeAccept') end
end)

RegisterNetEvent('clp_tfp:tribeKicked', function()
    pcall(function() lib.hideContext(true) end)
end)

-- ─── Stamm-Blips ─────────────────────────────────────────────────────────────
local blips = {}
CreateThread(function()
    while true do
        local positions = lib.callback.await('clp_tfp:getTribePositions', false) or {}
        local seen = {}
        for _, p in ipairs(positions) do
            seen[p.id] = true
            if not blips[p.id] then
                local b = AddBlipForCoord(p.x, p.y, p.z)
                SetBlipSprite(b, Config.Tribe.blipSprite or 1)
                SetBlipColour(b, Config.Tribe.blipColor or 2)
                SetBlipScale(b, 0.8)
                SetBlipAsShortRange(b, false)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(p.name or 'Stamm')
                EndTextCommandSetBlipName(b)
                blips[p.id] = b
            else
                SetBlipCoords(blips[p.id], p.x, p.y, p.z)
            end
        end
        for id, b in pairs(blips) do
            if not seen[id] then RemoveBlip(b); blips[id] = nil end
        end
        Wait(3000)
    end
end)
