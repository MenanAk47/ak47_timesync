-- ====================================================================
-- Ak47 Time & Weather Sync - Chat Commands & Administration
-- ====================================================================

RegisterCommand('weather', function(source, args)
    if not Ak47TimeSync.Server.HasPermission(source) then
        if source > 0 and Lib47 and Lib47.Notify then Lib47.Notify(source, _U('no_permission'), 'error') end
        return
    end
    if args[1] then
        local ok = Ak47TimeSync.Server.SetWeather(source, args[1], Config.DefaultWeatherTransitionSpeed or 10, false)
        if not ok and source > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(source, 'Invalid weather condition.', 'error')
        end
    end
end, false)

RegisterCommand('timesync', function(source, args)
    if not Ak47TimeSync.Server.HasPermission(source) then
        if source > 0 and Lib47 and Lib47.Notify then Lib47.Notify(source, _U('no_permission'), 'error') end
        return
    end
    TriggerClientEvent('ak47_timesync:client:openAdminMenu', source, Ak47TimeSync.Server.GetFullState())
end, false)

RegisterCommand('time', function(source, args)
    if not Ak47TimeSync.Server.HasPermission(source) then
        if source > 0 and Lib47 and Lib47.Notify then Lib47.Notify(source, _U('no_permission'), 'error') end
        return
    end
    if args[1] == nil or args[1] == '' then
        TriggerClientEvent('ak47_timesync:client:openAdminMenu', source, Ak47TimeSync.Server.GetFullState())
        return
    end
    local h, m = tonumber(args[1]) or 12, tonumber(args[2]) or 0
    Ak47TimeSync.Server.SetTime(source, h, m, 0, Config.DefaultTimeTransitionSpeed or 5, false)
end, false)

RegisterCommand('freezetime', function(source)
    if not Ak47TimeSync.Server.HasPermission(source) then return end
    local isFrozen = Ak47TimeSync.Server.SetFreezeTime(source)
    if source > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(source, _U('freeze_time_toggled', isFrozen and _U('enabled') or _U('disabled')), 'info')
    end
end, false)

RegisterCommand('freezeweather', function(source)
    if not Ak47TimeSync.Server.HasPermission(source) then return end
    local isFrozen = Ak47TimeSync.Server.SetFreezeWeather(source)
    if source > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(source, _U('freeze_weather_toggled', isFrozen and _U('enabled') or _U('disabled')), 'info')
    end
end, false)

RegisterCommand('blackout', function(source)
    if not Ak47TimeSync.Server.HasPermission(source) then return end
    local isBlackout = Ak47TimeSync.Server.SetBlackout(source)
    if source > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(source, _U('blackout_toggled', isBlackout and _U('enabled') or _U('disabled')), 'info')
    end
end, false)

local quickTimes = {
    morning = { 9, 0 },
    noon = { 12, 0 },
    evening = { 18, 30 },
    night = { 0, 0 },
}

for cmd, t in pairs(quickTimes) do
    RegisterCommand(cmd, function(source)
        if Ak47TimeSync.Server.HasPermission(source) then
            Ak47TimeSync.Server.SetTime(source, t[1], t[2], 0, 5, false)
        end
    end, false)
end
