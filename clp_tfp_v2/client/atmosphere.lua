-- clp_tfp · client/atmosphere — Lore-Fundstücke + optionaler Insel-Ambient (xsound)

local A = Config.Atmosphere or {}

TFP = TFP or {}
local foundLore = {}  -- ["index"] = true (gefundene Tagebuch-Seiten)

-- gefundene Seiten beim Laden vom Server holen
CreateThread(function()
    local ESX = exports['es_extended']:getSharedObject()
    while not ESX.PlayerLoaded do Wait(300) end
    local f = lib.callback.await('clp_tfp:getLore', false)
    if type(f) == 'table' then foundLore = f end
end)

RegisterNetEvent('clp_tfp:loreAck', function(id, found, total)
    foundLore[tostring(id)] = true
    lib.notify({ title = '📖 Tagebuch', description = ('Neue Seite gefunden (%d/%d).'):format(found, total), type = 'success' })
end)

-- Tagebuch-Menü: alle Seiten, gefundene lesbar, Rest gesperrt
function TFP.OpenJournal()
    local notes = A.notes or {}
    local fc = 0; for _ in pairs(foundLore) do fc = fc + 1 end
    local opts = { { title = ('📖 Tagebuch — %d / %d Seiten'):format(fc, #notes), disabled = true } }
    for i, note in ipairs(notes) do
        local have = foundLore[tostring(i)] == true
        opts[#opts + 1] = {
            title = have and ('📜 ' .. (note.title or ('Seite ' .. i))) or '🔒 ??? — noch nicht gefunden',
            description = have and 'Lesen' or 'Irgendwo auf der Insel…',
            disabled = not have,
            onSelect = have and function()
                lib.alertDialog({ header = '📜 ' .. (note.title or 'Notiz'), content = note.text or '…', centered = true, size = 'md' })
            end or nil,
        }
    end
    lib.registerContext({ id = 'tfp_journal', title = '📖 Tagebuch', options = opts })
    lib.showContext('tfp_journal')
end
RegisterCommand('tagebuch', function() TFP.OpenJournal() end, false)

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
                        if not foundLore[tostring(i)] then TriggerServerEvent('clp_tfp:loreFound', i) end
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
