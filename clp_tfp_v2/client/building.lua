-- clp_tfp · client/building — Freeform-Builder, Statik-Vorschau, Raid-Erkennung, Raid-Log
local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}
local builds = {}        -- [id] = { entity, baseHeading, cat, tier }
local buildByEntity = {} -- [entity] = id
local INTEG = Config.Building.integrity or { enabled = false }

local function hasLocalSupport(px, py, pz, selfEnt)
    local r2 = (INTEG.supportRadius or 3.2) ^ 2
    local drop, lat = INTEG.supportDrop or 3.4, INTEG.lateralTol or 1.2
    for _, e in pairs(builds) do
        if e.entity ~= selfEnt and DoesEntityExist(e.entity) then
            local bc = GetEntityCoords(e.entity); local dz = pz - bc.z
            if dz <= drop and dz >= -lat then
                local dx, dy = px - bc.x, py - bc.y
                if (dx * dx + dy * dy) <= r2 then return true end
            end
        end
    end
    return false
end

local function rotToDir(rot) local z, x = math.rad(rot.z), math.rad(rot.x); local n = math.abs(math.cos(x)); return vector3(-math.sin(z) * n, math.cos(z) * n, math.sin(x)) end
local function costText(entry) local t = {}; for _, c in ipairs(entry.cost) do t[#t + 1] = ('%s ×%d'):format(c.item, c.count) end return table.concat(t, ', ') end
local function snapTo(v, g) return math.floor(v / g + 0.5) * g end

local function placementMode(buildId, entry)
    local model = joaat(entry.model)
    if not IsModelValid(model) or not lib.requestModel(model, 5000) then
        lib.notify({ description = 'Modell nicht verfügbar (evtl. bzzz_blocks nicht gestartet).', type = 'error' }); return
    end
    local ghost = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetEntityCollision(ghost, false, false); FreezeEntityPosition(ghost, true)
    local minDim = GetModelDimensions(model); local baseOff = -((minDim and minDim.z) or 0.0)
    SetModelAsNoLongerNeeded(model)
    local rot, hOff, snap, done = 0.0, 0.0, false, false
    local maxD, step, grid = Config.Building.maxPlaceDistance, Config.Building.rotateStep or 45.0, Config.Building.snapGrid or 2.5
    local sz = Config.World and Config.World.safezone
    lib.showTextUI('[E] Platzieren • [Mausrad] Drehen • [↑/↓] Höhe • [ALT] Raster • [Rücktaste] Abbrechen' .. (INTEG.enabled and '\nStatik: erhöhte Teile brauchen Halt (rot = kein Halt)' or ''))
    while not done do
        Wait(0)
        local ped = PlayerPedId(); local cam = GetGameplayCamCoord(); local dir = rotToDir(GetGameplayCamRot(2))
        local dest = cam + dir * maxD
        local handle = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 1 + 16, ped, 4)
        local _, hit, hitCoords = GetShapeTestResult(handle)
        local pos
        if hit == 1 then pos = hitCoords else
            local fwd = cam + dir * (maxD * 0.7); local fg, gz = GetGroundZFor_3dCoord(fwd.x, fwd.y, fwd.z + 5.0, false)
            pos = vector3(fwd.x, fwd.y, fg and gz or fwd.z)
        end
        local px, py, pz, hdg = pos.x, pos.y, pos.z + baseOff + hOff, rot
        if snap then px, py = snapTo(px, grid), snapTo(py, grid); hdg = snapTo(rot, 90.0) % 360.0 end
        SetEntityCoordsNoOffset(ghost, px, py, pz, false, false, false); SetEntityHeading(ghost, hdg)

        local valid, reason = true, nil
        local pc = GetEntityCoords(ped); local gpos = vector3(px, py, pz)
        if #(gpos - pc) > (maxD + 2.0) then valid = false; reason = 'Zu weit weg.' end
        if sz and sz.center and #(gpos - sz.center) < (Config.Building.noBuildRadius or 50.0) then valid = false; reason = 'Zu nah an der Safezone.' end
        local fg, gz = GetGroundZFor_3dCoord(px, py, pz + 4.0, false)
        local grounded = (not fg) or (pz - gz) <= (INTEG.groundTolerance or 1.4)
        if valid and INTEG.enabled and not grounded and not TFP._adminBuild and not hasLocalSupport(px, py, pz, ghost) then
            valid = false; reason = 'Kein Halt — Stütze darunter nötig.'
        end
        SetEntityAlpha(ghost, valid and 170 or 70, false)

        DisableControlAction(0, 24, true)
        if IsDisabledControlJustPressed(0, 241) then rot = rot + step end
        if IsDisabledControlJustPressed(0, 242) then rot = rot - step end
        if IsControlPressed(0, 172) then hOff = hOff + 0.04 end
        if IsControlPressed(0, 173) then hOff = hOff - 0.04 end
        if IsControlJustPressed(0, 19) then snap = not snap end
        if IsControlJustPressed(0, 38) then
            if valid then TriggerServerEvent('clp_tfp:placeBuild', buildId, vec3(px, py, pz), hdg, grounded); done = true
            else lib.notify({ description = reason or 'Platzierung ungültig.', type = 'error' }) end
        elseif IsControlJustPressed(0, 194) then done = true end
    end
    lib.hideTextUI()
    if DoesEntityExist(ghost) then DeleteObject(ghost) end
end

local function openCategory(menuName)
    local options = {}
    for id, entry in pairs(Config.Building.catalog) do
        if entry.menu == menuName then
            options[#options + 1] = { title = entry.label, description = 'Kosten: ' .. costText(entry), onSelect = function() placementMode(id, entry) end }
        end
    end
    lib.registerContext({ id = 'tfp_build_cat', title = menuName, menu = 'tfp_build', options = options })
    lib.showContext('tfp_build_cat')
end
local function openBuildMenu()
    local options = {}
    for _, cat in ipairs(Config.Building.categories) do options[#options + 1] = { title = cat, arrow = true, onSelect = function() openCategory(cat) end } end
    lib.registerContext({ id = 'tfp_build', title = 'Bauen', options = options })
    lib.showContext('tfp_build')
end
exports('openBuildMenu', function() openBuildMenu(); return false end)
function TFP.OpenBuild() openBuildMenu() end

-- ─── Bauten spawnen + Interaktionen ──────────────────────────────────────────
local function doorHeading(base, open) return base + (open and 90.0 or 0.0) end

local function spawnBuild(b)
    if builds[b.id] then return end
    local model = joaat(b.model)
    if not IsModelValid(model) or not lib.requestModel(model, 5000) then return end
    local obj = CreateObject(model, b.x, b.y, b.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    local baseHeading = b.heading or 0.0
    SetEntityHeading(obj, (b.cat == 'door') and doorHeading(baseHeading, b.doorOpen) or baseHeading)
    FreezeEntityPosition(obj, true)
    builds[b.id] = { entity = obj, baseHeading = baseHeading, cat = b.cat, tier = b.tier or 'wood' }
    buildByEntity[obj] = b.id

    local opts = {}
    local function add(o) opts[#opts + 1] = o end

    if b.cat == 'storage' then
        add({ name = 'tfp_open_' .. b.id, icon = 'fa-solid fa-box-open', label = 'Öffnen', distance = 2.5, onSelect = function()
            if lib.callback.await('clp_tfp:canAccessBuild', false, b.id) then exports.ox_inventory:openInventory('stash', 'tfp_build_' .. b.id)
            else lib.notify({ description = 'Gehört dir/deinem Stamm nicht.', type = 'error' }) end
        end })
    elseif b.cat == 'door' then
        add({ name = 'tfp_door_' .. b.id, icon = 'fa-solid fa-door-open', label = 'Tür öffnen/schließen', distance = 2.5, onSelect = function() TriggerServerEvent('clp_tfp:toggleDoor', b.id) end })
        add({ name = 'tfp_code_' .. b.id, icon = 'fa-solid fa-lock', label = 'Codeschloss setzen/ändern', distance = 2.5, onSelect = function()
            local inp = lib.inputDialog('Codeschloss', { { type = 'input', label = 'Code (leer = entfernen)', max = 8 } })
            if inp then TriggerServerEvent('clp_tfp:setBuildCode', b.id, inp[1] or '') end
        end })
    elseif b.cat == 'station_campfire' then
        add({ name = 'tfp_boil_' .. b.id, icon = 'fa-solid fa-mug-hot', label = 'Wasser abkochen', distance = 2.5, onSelect = function()
            if lib.progressBar({ duration = 4000, label = 'Wasser abkochen…', canCancel = true, disable = { move = true, combat = true } }) then TriggerServerEvent('clp_tfp:boilWater') end
        end })
        add({ name = 'tfp_craftc_' .. b.id, icon = 'fa-solid fa-hammer', label = 'Handwerk (Lagerfeuer)', distance = 2.5, onSelect = function() TriggerEvent('clp_tfp:openStation', 'campfire') end })
    elseif b.cat == 'station_workbench' then
        add({ name = 'tfp_craftw_' .. b.id, icon = 'fa-solid fa-screwdriver-wrench', label = 'Werkbank — Handwerk', distance = 2.5, onSelect = function() TriggerEvent('clp_tfp:openStation', 'workbench') end })
    elseif b.cat == 'station_forge' then
        add({ name = 'tfp_craftf_' .. b.id, icon = 'fa-solid fa-fire', label = 'Schmelzofen — Metall', distance = 2.5, onSelect = function() TriggerEvent('clp_tfp:openStation', 'forge') end })
    elseif b.cat == 'bed' then
        add({ name = 'tfp_bed_' .. b.id, icon = 'fa-solid fa-bed', label = 'Als Spawnpunkt setzen', distance = 2.5, onSelect = function() TriggerServerEvent('clp_tfp:setBedSpawn', b.id) end })
        add({ name = 'tfp_sleep_' .. b.id, icon = 'fa-solid fa-moon', label = 'Schlafen (erholt + Zeit vor)', distance = 2.5, onSelect = function() if TFP.Sleep then TFP.Sleep() end end })
    elseif b.cat == 'cupboard' then
        add({ name = 'tfp_cup_' .. b.id, icon = 'fa-solid fa-box', label = 'Material einlagern (Upkeep)', distance = 2.5, onSelect = function()
            local up = Config.Building.upkeep or {}; local o = {}
            for _, it in ipairs(up.items or {}) do o[#o + 1] = { value = it, label = it } end
            local input = lib.inputDialog('Versorgungs-Kern füttern', { { type = 'select', label = 'Material', options = o, required = true }, { type = 'number', label = 'Menge', default = 5, min = 1, max = 100 } })
            if input and input[1] then TriggerServerEvent('clp_tfp:cupboardUpkeep', b.id, input[1], input[2] or 1) end
        end })
    end

    if b.cat == 'structure' or b.cat == 'door' or b.cat == 'storage' or b.cat == 'cupboard' then
        local tlabel = (((Config.Building.tiers or {})[b.tier or 'wood']) or {}).label or b.tier
        add({ name = 'tfp_upg_' .. b.id, icon = 'fa-solid fa-arrow-up-from-bracket', label = 'Verstärken  (jetzt: ' .. tostring(tlabel) .. ')', distance = 2.5, onSelect = function() TriggerServerEvent('clp_tfp:upgradeBuild', b.id) end })
    end
    add({ name = 'tfp_rem_' .. b.id, icon = 'fa-solid fa-hammer', label = 'Abreißen', distance = 2.5, onSelect = function() TriggerServerEvent('clp_tfp:removeBuild', b.id) end })
    add({ name = 'tfp_ref_' .. b.id, icon = 'fa-solid fa-clock-rotate-left', label = 'Auffrischen', distance = 2.5, onSelect = function() TriggerServerEvent('clp_tfp:refreshBuild', b.id) end })
    exports.ox_target:addLocalEntity(obj, opts)
end

RegisterNetEvent('clp_tfp:spawnBuild', function(b) spawnBuild(b) end)
RegisterNetEvent('clp_tfp:syncBuilds', function(list) for _, b in ipairs(list) do spawnBuild(b) end end)
RegisterNetEvent('clp_tfp:despawnBuild', function(id)
    local e = builds[id]
    if e then if DoesEntityExist(e.entity) then exports.ox_target:removeLocalEntity(e.entity); DeleteObject(e.entity) end buildByEntity[e.entity] = nil end
    builds[id] = nil
end)
RegisterNetEvent('clp_tfp:wipeAllBuilds', function()
    for id, e in pairs(builds) do if e and DoesEntityExist(e.entity) then exports.ox_target:removeLocalEntity(e.entity); DeleteObject(e.entity) end builds[id] = nil end
end)
RegisterNetEvent('clp_tfp:setDoorState', function(id, open) local e = builds[id]; if e and DoesEntityExist(e.entity) then SetEntityHeading(e.entity, doorHeading(e.baseHeading, open)) end end)

CreateThread(function() while not ESX.PlayerLoaded do Wait(250) end TriggerServerEvent('clp_tfp:requestBuilds') end)

-- ─── Fallen ──────────────────────────────────────────────────────────────────
CreateThread(function()
    local tc = Config.Trap or {}
    while true do
        Wait(tc.intervalMs or 1500)
        local trapCoords = {}
        for _, e in pairs(builds) do if e.cat == 'trap' and DoesEntityExist(e.entity) then trapCoords[#trapCoords + 1] = GetEntityCoords(e.entity) end end
        if #trapCoords > 0 then
            local ped = PlayerPedId(); local pc = GetEntityCoords(ped)
            for _, t in ipairs(trapCoords) do if not IsEntityDead(ped) and #(pc - t) < (tc.radius or 2.2) then ApplyDamageToPed(ped, tc.damage or 25, false) end end
            for _, p in ipairs(GetGamePool('CPed')) do
                if p ~= ped and DoesEntityExist(p) and not IsPedAPlayer(p) and not IsEntityDead(p) then
                    local epc = GetEntityCoords(p)
                    for _, t in ipairs(trapCoords) do if #(epc - t) < (tc.radius or 2.2) then ApplyDamageToPed(p, tc.damage or 25, false); break end end
                end
            end
        end
    end
end)

-- ─── Raid: Treffer auf Bauten erkennen ──────────────────────────────────────
local RAID = (Config.Building.raid or {})
local RDMG = RAID.damage or {}
local function weaponDamage(weapon)
    if weapon == `WEAPON_STICKYBOMB` or weapon == `WEAPON_GRENADE` or weapon == `WEAPON_RPG` or weapon == `WEAPON_PIPEBOMB` or weapon == `WEAPON_PROXMINE` or weapon == `WEAPON_MOLOTOV` then return RDMG.explosive or 600 end
    if weapon == `WEAPON_HATCHET` or weapon == `WEAPON_BATTLEAXE` or weapon == `WEAPON_HAMMER` or weapon == `WEAPON_CROWBAR` or weapon == `WEAPON_STONE_HATCHET` or weapon == `WEAPON_WRENCH` then return RDMG.hatchet or 25 end
    if weapon == `WEAPON_PUMPSHOTGUN` or weapon == `WEAPON_SAWNOFFSHOTGUN` or weapon == `WEAPON_ASSAULTSHOTGUN` or weapon == `WEAPON_HEAVYSHOTGUN` or weapon == `WEAPON_PUMPSHOTGUN_MK2` then return RDMG.shotgun or 14 end
    if weapon == `WEAPON_SNIPERRIFLE` or weapon == `WEAPON_HEAVYSNIPER` or weapon == `WEAPON_MARKSMANRIFLE` or weapon == `WEAPON_HEAVYSNIPER_MK2` then return RDMG.sniper or 40 end
    if weapon == `WEAPON_ASSAULTRIFLE` or weapon == `WEAPON_CARBINERIFLE` or weapon == `WEAPON_SPECIALCARBINE` or weapon == `WEAPON_BULLPUPRIFLE` or weapon == `WEAPON_ADVANCEDRIFLE` or weapon == `WEAPON_ASSAULTRIFLE_MK2` then return RDMG.rifle or 9 end
    if weapon == `WEAPON_MICROSMG` or weapon == `WEAPON_SMG` or weapon == `WEAPON_ASSAULTSMG` or weapon == `WEAPON_COMBATPDW` or weapon == `WEAPON_MACHINEPISTOL` then return RDMG.smg or 5 end
    if weapon == `WEAPON_PISTOL` or weapon == `WEAPON_COMBATPISTOL` or weapon == `WEAPON_PISTOL50` or weapon == `WEAPON_APPISTOL` or weapon == `WEAPON_HEAVYPISTOL` or weapon == `WEAPON_SNSPISTOL` then return RDMG.pistol or 4 end
    return RDMG.melee or 8
end
CreateThread(function()
    local lastImpact = vector3(0.0, 0.0, 0.0)
    while true do
        Wait(120)
        if RAID.enabled then
            local ped = PlayerPedId()
            local hit, coords = GetPedLastWeaponImpactCoord(ped)
            if hit and #(coords - lastImpact) > 0.05 then
                lastImpact = coords
                for id, e in pairs(builds) do
                    if DoesEntityExist(e.entity) and #(coords - GetEntityCoords(e.entity)) < 2.4 then
                        TriggerServerEvent('clp_tfp:damageBuild', id, weaponDamage(GetSelectedPedWeapon(ped))); break
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('clp_tfp:doorNeedsCode', function(id)
    local inp = lib.inputDialog('Verschlossene Tür', { { type = 'input', label = 'Code eingeben', max = 8, required = true } })
    if inp and inp[1] then TriggerServerEvent('clp_tfp:toggleDoor', id, inp[1]) end
end)

local function smokeFx(x, y, z, scale, wood)
    RequestNamedPtfxAsset('core'); local t = GetGameTimer()
    while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() - t < 800 do Wait(0) end
    if HasNamedPtfxAssetLoaded('core') then
        if wood then UseParticleFxAssetNextCall('core'); StartParticleFxNonLoopedAtCoord('ent_dst_wood_chunks', x, y, z, 0.0, 0.0, 0.0, 2.2, false, false, false) end
        UseParticleFxAssetNextCall('core'); StartParticleFxNonLoopedAtCoord('ent_amb_smoke_foundry', x, y, z + 0.5, 0.0, 0.0, 0.0, scale, false, false, false)
    end
end
RegisterNetEvent('clp_tfp:buildDestroyed', function(id, x, y, z) if #(GetEntityCoords(PlayerPedId()) - vector3(x, y, z)) <= 60.0 then smokeFx(x, y, z, 1.4, false) end end)
RegisterNetEvent('clp_tfp:buildCollapsed', function(id, x, y, z)
    if #(GetEntityCoords(PlayerPedId()) - vector3(x, y, z)) > 90.0 then return end
    smokeFx(x, y, z, 1.8, true)
    if TFP.Sfx and Config.Sounds and Config.Sounds.collapse then TFP.Sfx('collapse', vector3(x, y, z), 0.85) end
    lib.notify({ title = 'Statik', description = 'In der Nähe ist eine ungestützte Konstruktion eingestürzt!', type = 'warning' })
end)

-- ─── Raid-Protokoll ──────────────────────────────────────────────────────────
local function agoText(s) if s < 3600 then return math.max(1, math.floor(s / 60)) .. ' Min her' elseif s < 86400 then return math.floor(s / 3600) .. ' Std her' end return math.floor(s / 86400) .. ' Tg her' end
function TFP.OpenRaidLog()
    local rows = lib.callback.await('clp_tfp:getRaidLog', false) or {}
    local opts = {}
    if #rows == 0 then opts[1] = { title = 'Keine Vorfälle', description = 'Deine Basis wurde (noch) nicht geraidet.', icon = 'shield-halved', disabled = true }
    else
        for _, r in ipairs(rows) do
            local entry = Config.Building.catalog[r.build]
            opts[#opts + 1] = { title = ('%s zerstört'):format((entry and entry.label) or r.build), description = ('von %s · %s'):format(r.attacker_name or '?', agoText(r.ago or 0)),
                icon = 'fa-solid fa-house-crack', metadata = { { label = 'Angreifer', value = r.attacker_name or '?' }, { label = 'Position', value = ('%d, %d, %d'):format(r.x, r.y, r.z) } } }
        end
    end
    lib.registerContext({ id = 'tfp_raidlog', title = '🛡️ Raid-Protokoll', options = opts })
    lib.showContext('tfp_raidlog')
end
RegisterCommand('raidlog', function() TFP.OpenRaidLog() end, false)
