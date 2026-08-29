-- ====================================================================
-- Ak47 Time & Weather Sync - Server-Side Custom Events & Hooks
-- ====================================================================

local function GetInitiator(src)
    return src == 0 and 'Server' or (GetPlayerName(src) or ('ID: ' .. tostring(src)))
end

AddEventHandler('ak47_timesync:server:onTimeChanged', function(source, hours, mins, transitionSpeed)
    SendDiscordLog('Clock Time Changed', string.format('**Changed by:** %s\n**New Time:** %02d:%02d\n**Speed:** %ds', GetInitiator(source), hours, mins, transitionSpeed), 0x3B82F6)
end)

AddEventHandler('ak47_timesync:server:onWeatherChanged', function(source, weatherType, transitionDuration)
    SendDiscordLog('Weather Changed', string.format('**Changed by:** %s\n**Weather:** %s\n**Duration:** %ds', GetInitiator(source), weatherType, transitionDuration), 0x10B981)
end)

AddEventHandler('ak47_timesync:server:onBlackoutChanged', function(source, state)
    SendDiscordLog('Blackout ' .. (state and 'Enabled' or 'Disabled'), string.format('**Changed by:** %s\n**State:** %s', GetInitiator(source), state and 'ON' or 'OFF'), state and 0xEF4444 or 0x6B7280)
end)

AddEventHandler('ak47_timesync:server:onFreezeChanged', function(source, freezeType, state)
    SendDiscordLog(string.format('Freeze %s %s', freezeType:gsub('^%l', string.upper), state and 'Enabled' or 'Disabled'), string.format('**Changed by:** %s\n**State:** %s', GetInitiator(source), state and 'Frozen' or 'Unfrozen'), 0xF59E0B)
end)
