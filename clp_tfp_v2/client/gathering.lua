-- clp_tfp · client/gathering — Ressourcen an Welt-Props (ox_target addModel; §2.5)
TFP = TFP or {}

local function hasTool(tool)
    if not tool then return true end
    return (exports.ox_inventory:Search('count', tool) or 0) > 0
end
local function startEmote(name) if not name then return false end ExecuteCommand('e ' .. name); return true end
local function stopEmote() ExecuteCommand('e c') end

local function gather(nodeType)
    local node = Config.Gathering.nodes[nodeType]; if not node then return end
    if not hasTool(node.tool) then
        local tl = (node.tool == 'WEAPON_HATCHET') and 'eine Axt' or 'das passende Werkzeug'
        lib.notify({ title = 'Sammeln', description = ('Du brauchst dafür %s im Inventar.'):format(tl), type = 'error' }); return
    end
    local emoting = startEmote(node.emote)
    local fxing = true
    CreateThread(function() while fxing do if TFP.GatherFx then TFP.GatherFx(nodeType) end Wait(700) end end)
    local ok = lib.progressBar({ duration = node.usetime, label = node.label, canCancel = true,
        disable = { move = true, car = true, combat = true }, anim = (not emoting) and node.anim or nil })
    fxing = false
    if emoting then stopEmote() end
    if ok then TriggerServerEvent('clp_tfp:gather', nodeType) end
end

CreateThread(function()
    for nodeType, node in pairs(Config.Gathering.nodes) do
        local nt = nodeType
        local ok, err = pcall(function()
            exports.ox_target:addModel(node.models, { {
                name = 'tfp_gather_' .. nt, icon = node.icon or 'fa-solid fa-hand', label = node.label,
                distance = node.distance or 2.5, onSelect = function() gather(nt) end,
            } })
        end)
        if not ok and TFP_Warn then TFP_Warn(('Sammel-Target "%s" übersprungen: %s'):format(nt, tostring(err))) end
    end
end)

-- Debug: Modell anvisieren → Hash kopieren (für unerkannte Bäume)
do
    local function rotToDir(rot) local z, x = math.rad(rot.z), math.rad(rot.x); local n = math.abs(math.cos(x)); return vector3(-math.sin(z) * n, math.cos(z) * n, math.sin(x)) end
    RegisterCommand('tfpmodel', function()
        local cam = GetGameplayCamCoord(); local dir = rotToDir(GetGameplayCamRot(2)); local dest = cam + dir * 12.0
        local h = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
        local _, hit, _, _, entity = GetShapeTestResult(h)
        if hit ~= 1 or not entity or entity == 0 then lib.notify({ description = 'Kein Objekt anvisiert.', type = 'error' }); return end
        local model = GetEntityModel(entity)
        lib.setClipboard(tostring(model))
        lib.notify({ description = ('Modell-Hash: %s (kopiert)'):format(model), type = 'inform' })
    end, false)
end
