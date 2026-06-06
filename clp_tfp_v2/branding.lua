-- clp_tfp · branding/ (shared) — Themen-Logger + Start-Banner
-- Ersetzt rohe [clp_tfp]-Prints. Auf Client UND Server verfügbar.

local TAG = '^2[TFP]^7 '

local function out(prefix, msg) print(prefix .. tostring(msg) .. '^7') end

function TFP_Log(msg)  out(TAG, msg) end
function TFP_OK(msg)   out('^2[TFP ✓]^7 ', msg) end
function TFP_Warn(msg) out('^3[TFP ⚠]^7 ', msg) end
function TFP_Err(msg)  out('^1[TFP ✖]^7 ', msg) end
-- Modul-spezifische Logger (von Modulen genutzt)
function TFP_Build(msg) out('^5[TFP ⌂]^7 ', msg) end
function TFP_Loot(msg)  out('^5[TFP ☼]^7 ', msg) end
function TFP_Hunt(msg)  out('^5[TFP ⚔]^7 ', msg) end

-- ── Start-Banner ─────────────────────────────────────────────────────────────
local side = IsDuplicityVersion() and 'SERVER' or 'CLIENT'
CreateThread(function()
    Wait(50)
    print('^2 ')
    print('^2   .vvv.         ^3 _____ _____ ____ ')
    print('^2  vv^3@@@^2vv       ^3|_   _|  ___|  _ \\    ^7THE FOREST PERICO')
    print('^2   ^3`\\^2|^3/`^2 v       ^3  | | | |_  | |_) |   ^7Hardcore Insel-Survival')
    print('^8    |||  ^2v        ^3  | | |  _| |  __/    ^7auf Cayo Perico')
    print(('^8 ~~~|||~~~~~~~~   ^3  |_| |_|   |_|       ^8» Neuaufbau v2 [%s]'):format(side))
    print('^2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^7')
    TFP_OK('Fundament geladen.')
end)
