-- clp_tfp · atmosphere/ (Client) : Lore-Fundstücke + optionaler Insel-Ambient (xsound)

local A = Config.Atmosphere or {}

-- ─── Lore-Notizen: anvisieren & lesen ────────────────────────────────────────
CreateThread(function()
    local noteModel = A.noteProp and joaat(A.noteProp)
    local haveModel = noteModel and IsModelValid(noteModel) and lib.requestModel(noteModel, 5000)
    for i, note in ipairs(A.notes or {}) do
        if haveModel then
            local obj = CreateObject(noteModel, note.coords.x, note.coords.y, note.coords.z, false, false, false)
            PlaceObjectOnGroundProperly(obj)
            SetEntityHeading(obj, math.random(0, 359) + 0.0)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
        end
        exports.ox_target:addSphereZone({
            coords = note.coords,
            radius = 1.2,
            debug = Config.Debug,
            options = {
                {
                    name = 'tfp_note_' .. i,
                    icon = 'fa-solid fa-scroll',
                    label = 'Notiz lesen',
                    distance = 1.8,
                    onSelect = function()
                        lib.alertDialog({ header = '📜 ' .. (note.title or 'Notiz'), content = note.text or '…', centered = true, size = 'md' })
                    end,
                },
            },
        })
    end
    if haveModel then SetModelAsNoLongerNeeded(noteModel) end
end)

-- ─── Optionaler Insel-Ambient über xsound (AUS by default; URL in Config setzen) ──
if A.ambient and A.ambient.enabled and A.ambient.url and A.ambient.url ~= '' then
    CreateThread(function()
        local playing = false
        local center = Config.World and Config.World.islandCenter
        local radius = (Config.World and Config.World.islandRadius) or 2000.0
        while true do
            Wait(4000)
            local onIsland = center and (#(GetEntityCoords(PlayerPedId()) - center) <= radius)
            if onIsland and not playing then
                pcall(function() exports.xsound:PlayUrl('tfp_ambient', A.ambient.url, A.ambient.volume or 0.25, true) end)
                playing = true
            elseif not onIsland and playing then
                pcall(function() exports.xsound:Destroy('tfp_ambient') end)
                playing = false
            end
        end
    end)

    AddEventHandler('onResourceStop', function(res)
        if res == GetCurrentResourceName() then pcall(function() exports.xsound:Destroy('tfp_ambient') end) end
    end)
end
