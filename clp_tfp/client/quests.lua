-- clp_tfp · quests/ (Client) — Aufgaben-Übersicht (F5-Menü / /aufgaben)

TFP = TFP or {}

function TFP.OpenQuests()
    local list = lib.callback.await('clp_tfp:getQuests', false) or {}
    local opts = {}
    for _, q in ipairs(list) do
        local pct = math.min(100, math.floor((q.cur / math.max(1, q.target)) * 100))
        opts[#opts + 1] = {
            title = q.label,
            description = ('%s  —  %d / %d'):format(q.desc, q.cur, q.target),
            icon = pct >= 100 and 'fa-solid fa-circle-check' or 'fa-solid fa-list-check',
            progress = pct,
            colorScheme = 'lime',
            disabled = true,
        }
    end
    if #opts == 0 then opts[#opts + 1] = { title = 'Keine Aufgaben verfügbar', disabled = true } end
    lib.registerContext({ id = 'tfp_quests', title = '📋 Aufgaben', options = opts })
    lib.showContext('tfp_quests')
end

RegisterCommand('aufgaben', TFP.OpenQuests, false)
