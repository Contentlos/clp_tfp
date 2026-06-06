-- clp_tfp · client/radio — Funkgerät über pma-voice

exports('useRadio', function()
    local input = lib.inputDialog('Funkgerät', {
        { type = 'number', label = 'Kanal (0 = aus)', min = 0, max = Config.Radio.maxChannel or 99, default = 0 },
    })
    if not input then return false end
    local ch = math.floor(input[1] or 0)
    if ch <= 0 then
        pcall(function() exports['pma-voice']:setVoiceProperty('radioEnabled', false) end)
        pcall(function() exports['pma-voice']:setRadioChannel(0) end)
        lib.notify({ title = 'Funk', description = 'Funk ausgeschaltet.', type = 'inform' })
    else
        pcall(function() exports['pma-voice']:setVoiceProperty('radioEnabled', true) end)
        pcall(function() exports['pma-voice']:setRadioChannel(ch) end)
        lib.notify({ title = 'Funk', description = ('Kanal %d aktiv — Sprechtaste (pma-voice) halten.'):format(ch), type = 'success' })
    end
    return false
end)
