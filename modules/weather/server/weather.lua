-- ====================================================================
-- Ak47 Time & Weather Sync - Server Weather & Dynamic Cycles
-- ====================================================================

CreateThread(function()
    while true do
        local intervalMin = math.max(1, tonumber(SyncState.newWeatherTimer) or 10)
        Wait(intervalMin * 60 * 1000)
        if SyncState.dynamicCycle and not SyncState.freezeWeather then
            Ak47TimeSync.Server.NextWeatherStage(0)
        end
    end
end)

RegisterNetEvent('ak47_timesync:server:setWeather', function(weatherType, transitionDuration, forcedInstant)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then
        if src > 0 and Lib47 and Lib47.Notify then Lib47.Notify(src, _U('no_permission'), 'error') end
        return
    end

    local ok = Ak47TimeSync.Server.SetWeather(src, weatherType, transitionDuration, forcedInstant)
    if ok and src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('weather_updated', weatherType, tonumber(transitionDuration) or 10), 'success')
    end
end)

RegisterNetEvent('ak47_timesync:server:setBlackout', function(state)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    local isBlackout = Ak47TimeSync.Server.SetBlackout(src, state)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('blackout_toggled', isBlackout and _U('enabled') or _U('disabled')), 'info')
    end
end)

RegisterNetEvent('ak47_timesync:server:toggleFreezeWeather', function(state)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    local isFrozen = Ak47TimeSync.Server.SetFreezeWeather(src, state)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('freeze_weather_toggled', isFrozen and _U('enabled') or _U('disabled')), 'info')
    end
end)

RegisterNetEvent('ak47_timesync:server:setDynamicCycle', function(state)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    local isDynamic = Ak47TimeSync.Server.SetDynamicWeather(src, state)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('dynamic_weather_toggled', isDynamic and _U('enabled') or _U('disabled')), 'info')
    end
end)

RegisterNetEvent('ak47_timesync:server:setSnowTracks', function(state)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    local isSnow = Ak47TimeSync.Server.SetSnowTracks(src, state)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('snow_tracks_toggled', isSnow and _U('enabled') or _U('disabled')), 'info')
    end
end)

RegisterNetEvent('ak47_timesync:server:setWind', function(speed, direction)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    SyncState.windSpeed = tonumber(speed) or 0.0
    SyncState.windDirection = tonumber(direction) or 0.0
    TriggerClientEvent('ak47_timesync:client:setWind', -1, { speed = SyncState.windSpeed, direction = SyncState.windDirection })
    if SyncState.SaveSettings then SyncState.SaveSettings() end
end)

