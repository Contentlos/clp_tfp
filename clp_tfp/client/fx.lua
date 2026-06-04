-- clp_tfp · fx/ — Partikel-FX + Sound (xsound) für SOTF-Juice
local ESX = exports['es_extended']:getSharedObject()
TFP = TFP or {}
local FX  = Config.FX or {}
local SND = Config.Sounds or {}

-- ─── PTFX-Asset-Cache + Burst ────────────────────────────────────────────────
local loaded = {}
local function ptfx(dict)
    if loaded[dict] then return true end
    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        local t = GetGameTimer()
        while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() - t < 1500 do Wait(0) end
    end
    loaded[dict] = HasNamedPtfxAssetLoaded(dict)
    return loaded[dict]
end
local function burst(dict, name, c, scale)
    if not ptfx(dict) then return end
    UseParticleFxAssetNextCall(dict)
    StartParticleFxNonLoopedAtCoord(name, c.x, c.y, c.z, 0.0, 0.0, 0.0, scale or 1.0, false, false, false)
end

-- ─── xsound: positionierter One-Shot (nur wenn URL konfiguriert) ─────────────
local sfxN = 0
function TFP.Sfx(key, c, vol)
    local url = SND[key]
    if not url or url == '' then return end
    sfxN = sfxN + 1
    local id = 'tfp_sfx_' .. sfxN
    pcall(function()
        if c then exports.xsound:PlayUrlPos(id, url, vol or 0.4, c) else exports.xsound:PlayUrl(id, url, vol or 0.4) end
    end)
    SetTimeout(5000, function() pcall(function() exports.xsound:Destroy(id) end) end)
end

-- ─── Sammel-FX (Holzspäne / Steinstaub / Pflanzen) ───────────────────────────
local GATHER = {
    tree  = { dict = 'core', name = 'ent_dst_gen_gobstop', sfx = 'chop' },
    rock  = { dict = 'core', name = 'ent_dst_concrete',    sfx = 'mine' },
    scrap = { dict = 'core', name = 'ent_dst_concrete',    sfx = 'mine' },
    bush  = { dict = 'core', name = 'ent_dst_gen_gobstop', sfx = 'gather' },
    berry = { dict = 'core', name = 'ent_dst_gen_gobstop', sfx = 'gather' },
}
function TFP.GatherFx(nodeType)
    if not (FX.enabled and FX.gather) then return end
    local g = GATHER[nodeType] or GATHER.tree
    local c = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.9, 0.15)
    burst(g.dict, g.name, c, 0.55)
    if g.sfx then TFP.Sfx(g.sfx, c) end
end

-- ─── Lagerfeuer: warmes Licht + Glut + optional Knistern (nur in der Nähe) ───
if FX.enabled and FX.campfireLight then
    local fireModels = {}
    for _, m in ipairs({ Config.CampfireModel, 'prop_beach_fire', 'bzzz_blocks_fireplace_1a' }) do
        if m then fireModels[#fireModels + 1] = joaat(m) end
    end
    CreateThread(function()
        local firePlaying = false
        while true do
            local wait = 800
            if ESX.PlayerLoaded then
                local pc = GetEntityCoords(PlayerPedId())
                local fc
                for _, m in ipairs(fireModels) do
                    local obj = GetClosestObjectOfType(pc.x, pc.y, pc.z, FX.campfireRange or 14.0, m, false, false, false)
                    if obj ~= 0 then fc = GetEntityCoords(obj); break end
                end
                if fc then
                    wait = 0
                    DrawLightWithRange(fc.x, fc.y, fc.z + 0.4, 255, 130, 45, 6.5, 2.2)
                    if math.random(140) <= 1 then burst('core', 'ent_amb_smoke_foundry', vector3(fc.x, fc.y, fc.z + 0.3), 0.25) end
                    if (SND.fire or '') ~= '' and not firePlaying then
                        firePlaying = true
                        pcall(function()
                            exports.xsound:PlayUrlPos('tfp_fire', SND.fire, SND.fireVolume or 0.35, fc)
                            exports.xsound:Distance('tfp_fire', 12.0)
                            exports.xsound:setSoundLoop('tfp_fire', true)
                        end)
                    end
                elseif firePlaying then
                    firePlaying = false
                    pcall(function() exports.xsound:Destroy('tfp_fire') end)
                end
            end
            Wait(wait)
        end
    end)
end

-- ─── Wasser-Eintauchen: Sound (GTA macht den Spritzer selbst) ────────────────
if FX.enabled and FX.waterSplash then
    CreateThread(function()
        local wasIn = false
        while true do
            Wait(350)
            if ESX.PlayerLoaded then
                local ped = PlayerPedId()
                local inw = IsEntityInWater(ped)
                if inw and not wasIn then TFP.Sfx('splash', GetEntityCoords(ped), 0.5) end
                wasIn = inw
            end
        end
    end)
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then pcall(function() exports.xsound:Destroy('tfp_fire') end) end
end)
