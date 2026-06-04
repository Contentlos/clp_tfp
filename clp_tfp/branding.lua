-- clp_tfp · branding/ — gebrandete Konsolen-Ausgabe + Start-Logo (Client & Server)
-- FiveM-Farbcodes: ^1 rot ^2 grün ^3 gelb ^4 blau ^5 cyan ^6 pink ^7 weiß ^8 orange ^9 grau/rot

-- ── Themed Log-Helfer (überall nutzbar) ──────────────────────────────────────
function TFP_Log(msg)   print(('^2[TFP]^7 %s'):format(tostring(msg))) end          -- info
function TFP_OK(msg)    print(('^2[TFP ✔]^7 %s'):format(tostring(msg))) end          -- erfolg
function TFP_Warn(msg)  print(('^3[TFP ▲]^7 %s'):format(tostring(msg))) end          -- warnung
function TFP_Err(msg)   print(('^1[TFP ✖]^7 %s'):format(tostring(msg))) end          -- fehler
function TFP_Hunt(msg)  print(('^8[TFP 🩸]^7 %s'):format(tostring(msg))) end          -- jagd/combat
function TFP_Loot(msg)  print(('^5[TFP ▣]^7 %s'):format(tostring(msg))) end          -- loot/event
function TFP_Build(msg) print(('^6[TFP ⌂]^7 %s'):format(tostring(msg))) end          -- bauen

-- ── Start-Banner (einmalig je Seite) ─────────────────────────────────────────
local TAGLINES = {
    'Die Insel will dich nicht. Bleib trotzdem.',
    'Tag 1. Niemand weiß, dass du hier bist.',
    'Hunger, Kälte, Kannibalen — willkommen daheim.',
    "Vertrau niemandem, der nachts \"Hilfe\" ruft.",
    'Verbluten ist auch eine Art zu gehen.',
    'Das Boot ist weg. Der Wahnsinn nicht.',
    'Iss das Fleisch roh und finde es heraus.',
}

do
    local side = IsDuplicityVersion() and 'SERVER' or 'CLIENT'
    math.randomseed((GetGameTimer and GetGameTimer() or os.time()) + #side)
    local tag = TAGLINES[math.random(#TAGLINES)]

    print('^2 ')
    print("^2   .vvv.        ^3 _____ _____ ____ ")
    print("^2  vv^3@@@^2vv       ^3|_   _|  ___|  _ \\    ^7THE FOREST PERICO")
    print("^2   ^3`\\^2|^3/`^2 v       ^3  | | | |_  | |_) |   ^7Hardcore Insel-Survival")
    print("^8    |||  ^2v        ^3  | | |  _| |  __/    ^7auf Cayo Perico")
    print("^8 ~~~|||~~~~~~~~   ^3  |_| |_|   |_|       ^8» geladen [" .. side .. ']')
    print('^7   „' .. tag .. '"')
    print('^2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^7')
end
