-- clp_tfp · gathering/ : Ressourcen an Welt-Props sammeln (ox_target)

local function hasTool(tool)
    if not tool then return true end
    -- Besitz im Inventar reicht (Axt muss NICHT gezogen sein)
    return (exports.ox_inventory:Search('count', tool) or 0) > 0
end

-- rpemotes-reborn-Emote starten/stoppen (resource-name-unabhängig via /e Befehl)
local function startEmote(name)
    if not name then return false end
    ExecuteCommand('e ' .. name)
    return true
end
local function stopEmote()
    ExecuteCommand('e c')
end

local function gather(nodeType)
    local node = Config.Gathering.nodes[nodeType]
    if not node then return end
    if not hasTool(node.tool) then
        local toolLabel = (node.tool == 'WEAPON_HATCHET') and 'eine Axt' or 'das passende Werkzeug'
        lib.notify({ title = 'Sammeln', description = ('Du brauchst dafür %s im Inventar.'):format(toolLabel), type = 'error' })
        return
    end
    local emoting = startEmote(node.emote)
    -- Partikel-/Sound-Juice während des Sammelns (Holzspäne, Steinstaub …)
    local fxing = true
    CreateThread(function()
        while fxing do
            if TFP.GatherFx then TFP.GatherFx(nodeType) end
            Wait(700)
        end
    end)
    local ok = lib.progressBar({
        duration = node.usetime, label = node.label, canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = (not emoting) and node.anim or nil,  -- Emote liefert die Animation, sonst Fallback-Anim
    })
    fxing = false
    if emoting then stopEmote() end
    if ok then
        TriggerServerEvent('clp_tfp:gather', nodeType)
    end
end

CreateThread(function()
    for nodeType, node in pairs(Config.Gathering.nodes) do
        local nt = nodeType
        -- addModel statt addGlobalObject: ox_target prüft das Modell intern (kein eigenes
        -- GetEntityModel → kein Native-Crash bei Map-Objekten). Funktioniert auch an Map-Props.
        local ok, err = pcall(function()
            exports.ox_target:addModel(node.models, {
                {
                    name = 'tfp_gather_' .. nt,
                    icon = node.icon or 'fa-solid fa-hand',
                    label = node.label,
                    distance = node.distance or 2.5,
                    onSelect = function() gather(nt) end,
                },
            })
        end)
        if not ok and TFP_Warn then TFP_Warn(('Sammel-Target "%s" übersprungen: %s'):format(nt, tostring(err))) end
    end
end)

-- ─── Debug: Modell von dem, worauf man zielt, ermitteln ──────────────────────
-- Immer verfügbar: anvisieren + /tfpmodel → Hash wird in die Zwischenablage gelegt.
-- Bleibt ein Baum unerkannt, hiermit den Hash holen und in Config.Gathering.nodes.tree.models eintragen.
do
    local function rotToDir(rot)
        local z = math.rad(rot.z)
        local x = math.rad(rot.x)
        local num = math.abs(math.cos(x))
        return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
    end

    RegisterCommand('tfpmodel', function()
        local cam = GetGameplayCamCoord()
        local dir = rotToDir(GetGameplayCamRot(2))
        local dest = cam + dir * 12.0
        local h = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
        local _, hit, _, _, entity = GetShapeTestResult(h)
        if hit ~= 1 or not entity or entity == 0 then
            lib.notify({ description = 'Kein Objekt anvisiert (evtl. Map-Mesh — nicht targetbar).', type = 'error' })
            print('^3[tfpmodel]^7 kein Entity getroffen (hit=' .. tostring(hit) .. ')')
            return
        end
        local model = GetEntityModel(entity)
        -- gegen konfigurierte Modelle prüfen
        for nodeType, node in pairs(Config.Gathering.nodes) do
            for _, m in ipairs(node.models) do
                if joaat(m) == model then
                    lib.notify({ description = ('Bereits konfiguriert als %s: %s'):format(nodeType, m), type = 'success' })
                    print(('^2[tfpmodel]^7 %s -> %s (hash %s)'):format(nodeType, m, model))
                    return
                end
            end
        end
        local info = ('Unkonfiguriert. Hash: %s  (Typ %d)'):format(model, GetEntityType(entity))
        lib.notify({ description = info, type = 'inform' })
        lib.setClipboard(tostring(model))
        print('^3[tfpmodel]^7 ' .. info .. ' — Hash in Zwischenablage. In Config.Gathering.<node>.models als Zahl eintragen.')
    end, false)
end
