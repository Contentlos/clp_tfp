-- clp_tfp · client/escape — mehrstufige Festland-Flucht-Quest
-- Funkturm → Treibstoff → Boot → Strandwache durchbrechen → ablegen.

local ESX = exports['es_extended']:getSharedObject()
local step = 1
local zoneId
local blip

-- ── Strandwache (Showdown am letzten Schritt) ───────────────────────────────
local guardRel
local guards = {}
CreateThread(function()
    guardRel = AddRelationshipGroup('TFP_ESCAPE_GUARD')
    SetRelationshipBetweenGroups(5, guardRel, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, guardRel)
end)

local function aliveGuards()
    local n = 0
    for i = #guards, 1, -1 do
        local p = guards[i]
        if DoesEntityExist(p) and not IsEntityDead(p) then n = n + 1
        else if DoesEntityExist(p) then SetPedAsNoLongerNeeded(p) end; table.remove(guards, i) end
    end
    return n
end

local function clearGuards()
    for _, p in ipairs(guards) do if DoesEntityExist(p) then DeleteEntity(p) end end
    guards = {}
end

local function spawnGuards(s)
    if #guards > 0 then return end
    local g = s.guards
    local models = g.models or (Config.Camps and Config.Camps.guardModels) or { 'g_m_y_armgoon_02' }
    for _ = 1, (g.count or 5) do
        local model = joaat(models[math.random(#models)])
        if IsModelValid(model) and lib.requestModel(model, 3000) then
            local ang = math.random() * math.pi * 2.0
            local r = 6.0 + math.random() * 14.0
            local x, y = s.coords.x + math.cos(ang) * r, s.coords.y + math.sin(ang) * r
            local found, gz = GetGroundZFor_3dCoord(x, y, s.coords.z + 30.0, false)
            local ped = CreatePed(4, model, x, y, found and gz or s.coords.z, math.random(0, 359) + 0.0, false, false)
            SetModelAsNoLongerNeeded(model)
            SetEntityAsMissionEntity(ped, true, true)
            SetPedRelationshipGroupHash(ped, guardRel)
            SetPedAccuracy(ped, g.accuracy or 25)
            SetPedCombatAttributes(ped, 46, true)
            SetPedFleeAttributes(ped, 0, false)
            if g.weapon then GiveWeaponToPed(ped, joaat(g.weapon), 250, false, true) end
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
            guards[#guards + 1] = ped
        end
    end
    lib.notify({ title = 'Flucht', description = 'Die Strandwache greift an — kämpf dich durch!', type = 'error' })
end

local function stepData(id)
    for _, st in ipairs(Config.Escape.steps) do if st.id == id then return st end end
    return nil
end

-- ── Ziel-Tracker (HUD) ──────────────────────────────────────────────────────
local objVisible = true

local function buildNeeds(s)
    local needs = {}
    for _, n in ipairs(s.need or {}) do
        local def = exports.ox_inventory:Items(n.item)
        local have = exports.ox_inventory:Search('count', n.item) or 0
        needs[#needs + 1] = { item = n.item, label = (def and def.label) or n.item, have = have, need = n.count }
    end
    return needs
end

local function pushObjective()
    if not TFP.UpdateObjective then return end
    local s = (Config.Escape.enabled and objVisible) and stepData(step) or nil
    if not s then TFP.UpdateObjective({ active = false }); return end
    TFP.UpdateObjective({
        active = true, step = step, total = #Config.Escape.steps,
        label = s.label, story = s.story, hint = s.hint, needs = buildNeeds(s),
    })
end

local function refresh()
    if zoneId then exports.ox_target:removeZone(zoneId); zoneId = nil end
    if blip then RemoveBlip(blip); blip = nil end
    clearGuards()

    local s = stepData(step)
    if not s then return end -- Quest abgeschlossen

    blip = AddBlipForCoord(s.coords.x, s.coords.y, s.coords.z)
    SetBlipSprite(blip, Config.Escape.blipSprite or 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.9)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Flucht: ' .. s.label)
    EndTextCommandSetBlipName(blip)

    zoneId = exports.ox_target:addSphereZone({
        coords = s.coords, radius = 2.5, debug = Config.Debug,
        options = {
            { name = 'tfp_escape_' .. s.id, icon = 'fa-solid fa-person-walking-arrow-right', label = s.label,
              onSelect = function()
                  if s.guards and aliveGuards() > 0 then
                      lib.notify({ title = 'Flucht', description = 'Erst die Strandwache ausschalten!', type = 'error' }); return
                  end
                  TriggerServerEvent('clp_tfp:escapeStep', s.id)
              end },
        },
    })
    pushObjective()
end

-- Wachen spawnen, sobald man dem bewachten Schritt nahe kommt
CreateThread(function()
    while true do
        Wait(2000)
        local s = stepData(step)
        if s and s.guards and ESX.PlayerLoaded then
            local d = #(GetEntityCoords(PlayerPedId()) - s.coords)
            if d <= (s.guards.radius or 50.0) then
                if #guards == 0 then spawnGuards(s) end
            elseif d > (s.guards.radius or 50.0) + 60.0 then
                clearGuards() -- weit weg -> zurücksetzen (greift beim nächsten Anlauf neu)
            end
        end
    end
end)

local introShown = false
RegisterNetEvent('clp_tfp:escapeState', function(s)
    local advanced = s > step
    step = s
    refresh()
    -- einmalige Story-Einleitung beim ersten Laden
    if not introShown and Config.Escape.intro then
        introShown = true
        lib.notify({ title = 'Gestrandet', description = Config.Escape.intro, type = 'inform', duration = 11000 })
    end
    -- Story-Beat beim Vorankommen
    local sd = stepData(step)
    if advanced and sd and sd.story then
        lib.notify({ title = '◢ Flucht', description = sd.story, type = 'inform', duration = 8000 })
    end
end)

RegisterNetEvent('clp_tfp:escapeDone', function(coords, msg)
    clearGuards()
    DoScreenFadeOut(800); Wait(1000)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    Wait(500); DoScreenFadeIn(1200)
    lib.notify({ title = 'Flucht', description = msg or 'Du hast die Insel verlassen…', type = 'success' })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearGuards() end
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    if Config.Escape.enabled then TriggerServerEvent('clp_tfp:escapeRequest') end
end)

-- Live-Material-Zähler im Ziel-Tracker aktuell halten
CreateThread(function()
    while true do
        Wait(3000)
        if ESX.PlayerLoaded and Config.Escape.enabled then pushObjective() end
    end
end)

-- Ziel-Anzeige ein-/ausblenden
RegisterCommand('ziel', function()
    objVisible = not objVisible
    pushObjective()
    lib.notify({ description = objVisible and 'Ziel-Anzeige eingeblendet.' or 'Ziel-Anzeige ausgeblendet.', type = 'inform' })
end, false)
lib.addKeybind({ name = 'tfp_ziel', description = 'Flucht-Ziel ein/aus', defaultKey = 'K', onPressed = function()
    objVisible = not objVisible; pushObjective()
end })
TFP = TFP or {}
TFP.ToggleObjective = function() objVisible = not objVisible; pushObjective() end
