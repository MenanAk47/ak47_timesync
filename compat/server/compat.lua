-- ====================================================================
-- Ak47 Time & Weather Sync - Drop-In Compatibility Layer (Server)
-- Provides full 100% interoperability for cd_easytime, qb-weathersync, and vSync
-- Reusable adapter delegating to Ak47TimeSync.Server API
-- ====================================================================

-- ====================================================================
-- Sync Request Handlers
-- ====================================================================

for _, evt in ipairs({
    'cd_easytime:RequestSync',
    'cd_easytime:SyncMe',
    'vSync:requestSync',
    'qb-weathersync:server:RequestState',
    'qb-weathersync:server:RequestStateSync',
}) do
    RegisterNetEvent(evt, function()
        local src = source
        if src and src > 0 then
            SyncState.Broadcast(src, true)
        end
    end)
end

-- ====================================================================
-- cd_easytime Specific Server Handlers
-- ====================================================================

RegisterNetEvent('cd_easytime:SyncMe_basics', function(data)
    local src = source
    if not src or src <= 0 then return end
    if not data or type(data) ~= 'table' then
        TriggerClientEvent('cd_easytime:SyncWeather', src, { weather = Ak47TimeSync.Server.GetWeather(), instantweather = true })
        TriggerClientEvent('cd_easytime:SyncTime', src, { hours = SyncState.hours, mins = SyncState.mins, instanttime = true })
        return
    end
    if data.weather then
        TriggerClientEvent('cd_easytime:SyncWeather', src, { weather = Ak47TimeSync.Server.GetWeather(), instantweather = true })
    end
    if data.time then
        TriggerClientEvent('cd_easytime:SyncTime', src, { hours = SyncState.hours, mins = SyncState.mins, instanttime = true })
    end
end)

RegisterNetEvent('cd_easytime:ForceUpdate', function(data)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    if not data or type(data) ~= 'table' then return end

    if data.hours ~= nil or data.mins ~= nil then
        local h = tonumber(data.hours) or SyncState.hours or 12
        local m = tonumber(data.mins) or SyncState.mins or 0
        Ak47TimeSync.Server.SetTime(src, h, m, 0, data.instanttime and 0 or Config.DefaultTimeTransitionSpeed or 5, data.instanttime == true)
    end

    if data.weather and data.weather ~= '' then
        Ak47TimeSync.Server.SetWeather(src, data.weather, data.instantweather and 0 or Config.DefaultWeatherTransitionSpeed or 10, data.instantweather == true)
    end

    if data.dynamic ~= nil then
        Ak47TimeSync.Server.SetDynamicWeather(src, data.dynamic == true)
    end

    if data.blackout ~= nil then
        Ak47TimeSync.Server.SetBlackout(src, data.blackout == true)
    end

    if data.freeze ~= nil then
        Ak47TimeSync.Server.SetGlobalFreeze(src, data.freeze == true)
    end

    SyncState.Broadcast(-1, data.instanttime or data.instantweather)
end)

RegisterNetEvent('cd_easytime:SetNewGameTime', function(time)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    if time and type(time) == 'table' then
        local h = tonumber(time.hours) or SyncState.hours or 12
        local m = tonumber(time.mins) or SyncState.mins or 0
        Ak47TimeSync.Server.SetTime(src, h, m, 0, 1, false)
    end
end)

RegisterNetEvent('cd_easytime:ToggleInstantChange', function(action, boolean)
    -- Instant change toggle acknowledged
end)

RegisterNetEvent('cd_easytime:SaveSettings', function()
    -- Compatibility settings save acknowledged
end)

RegisterNetEvent('cd_easytime:StartTsunamiCountdown', function(boolean)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    TriggerClientEvent('cd_easytime:StartTsunamiCountdown', -1, boolean == true)
end)

RegisterNetEvent('cd_easytime:OpenUI', function(_source)
    local src = _source or source
    if Ak47TimeSync.Server.HasPermission(src) then
        TriggerClientEvent('ak47_timesync:client:openAdminMenu', src, Ak47TimeSync.Server.GetFullState())
    end
end)

RegisterNetEvent('cd_easytime:SetWeather', function(w, instant)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetWeather(source, w, instant and 0 or 10, instant == true)
    end
end)

RegisterNetEvent('cd_easytime:SetTime', function(h, m, instant)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetTime(source, h, m, 0, instant and 0 or 5, instant == true)
    end
end)

RegisterNetEvent('cd_easytime:ToggleFreeze', function(s)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetGlobalFreeze(source, s)
    end
end)

RegisterNetEvent('cd_easytime:ToggleBlackout', function(s)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetBlackout(source, s)
    end
end)

RegisterNetEvent('cd_easytime:ToggleDynamic', function(s)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetDynamicWeather(source, s)
    end
end)

-- ====================================================================
-- vSync Specific Server Handlers
-- ====================================================================

RegisterNetEvent('vSync:updateWeather', function(w, instant)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetWeather(source, w, instant and 0 or 10, instant == true)
    end
end)

RegisterNetEvent('vSync:updateTime', function(h, m, instant)
    if Ak47TimeSync.Server.HasPermission(source) then
        Ak47TimeSync.Server.SetTime(source, h, m, 0, instant and 0 or 5, instant == true)
    end
end)

-- ====================================================================
-- qb-weathersync Specific Server Handlers
-- ====================================================================

RegisterNetEvent('qb-weathersync:server:setWeather', function(w)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        local success = Ak47TimeSync.Server.SetWeather(src, w, Config.DefaultWeatherTransitionSpeed or 10, false)
        if src > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(src, success and 'Weather has been updated.' or 'Invalid weather type.', success and 'success' or 'error')
        end
    end
end)

RegisterNetEvent('qb-weathersync:server:setTime', function(h, m)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        local argh = tonumber(h)
        local argm = tonumber(m) or 0
        local success = Ak47TimeSync.Server.SetTime(src, argh, argm, 0, Config.DefaultTimeTransitionSpeed or 5, false)
        if src > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(src, success and string.format('Time has been changed to %02d:%02d', argh, argm) or 'Invalid time specified.', success and 'success' or 'error')
        end
    end
end)

RegisterNetEvent('qb-weathersync:server:toggleBlackout', function(state)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        local isBlackout = Ak47TimeSync.Server.SetBlackout(src, state)
        if src > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(src, isBlackout and 'Blackout is now enabled' or 'Blackout is now disabled', 'info')
        end
    end
end)

RegisterNetEvent('qb-weathersync:server:toggleFreezeTime', function(state)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        local isFrozen = Ak47TimeSync.Server.SetFreezeTime(src, state)
        if src > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(src, isFrozen and 'Time is now frozen' or 'Time is now unfrozen', 'info')
        end
    end
end)

RegisterNetEvent('qb-weathersync:server:toggleDynamicWeather', function(state)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        local isDynamic = Ak47TimeSync.Server.SetDynamicWeather(src, state)
        if src > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(src, isDynamic and 'Dynamic weather is now enabled' or 'Dynamic weather is now disabled', 'info')
        end
    end
end)

RegisterNetEvent('qb-weathersync:server:setBlackout', function(s)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        Ak47TimeSync.Server.SetBlackout(src, s == true)
    end
end)

RegisterNetEvent('qb-weathersync:server:setTimeFreeze', function(s)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        Ak47TimeSync.Server.SetFreezeTime(src, s == true)
    end
end)

RegisterNetEvent('qb-weathersync:server:setWeatherFreeze', function(s)
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        Ak47TimeSync.Server.SetFreezeWeather(src, s == true)
    end
end)

RegisterNetEvent('qb-weathersync:server:nextWeatherStage', function()
    local src = source
    if Ak47TimeSync.Server.HasPermission(src) then
        Ak47TimeSync.Server.NextWeatherStage(src)
    end
end)


