-- ====================================================================
-- Ak47 Time & Weather Sync - Drop-In Compatibility Layer (Client)
-- Provides full 100% interoperability for cd_easytime, qb-weathersync, and vSync
-- Reusable adapter delegating to Ak47TimeSync.Client API
-- ====================================================================

PauseSync = PauseSync or {
    state = false,
    hours = 20,
}

self = self or {
    tsunami = false,
    weathermethod = 'game',
    timemethod = 'game',
    instanttime = false,
    instantweather = false,
}

setmetatable(self, {
    __tostring = function()
        return Ak47TimeSync.Client.GetWeather()
    end,
    __index = function(t, k)
        local state = Ak47TimeSync.Client.GetFullState()
        if k == 'weather' then return state.weather end
        if k == 'hours' then return state.hours end
        if k == 'mins' then return state.mins end
        if k == 'seconds' then return state.seconds end
        if k == 'freeze' then return state.freezeTime end
        if k == 'blackout' then return state.blackout end
        if k == 'dynamic' then return state.dynamic end
        if k == 'rainLevel' then return state.rainLevel end
        return rawget(t, k)
    end
})

-- ====================================================================
-- Sync Pause / Disable / Enable Handlers
-- ====================================================================

RegisterNetEvent('cd_easytime:PauseSync', function(boolean, hours)
    Ak47TimeSync.Client.SetPauseSync(boolean, hours)
end)

RegisterNetEvent('qb-weathersync:client:DisableSync', function()
    Ak47TimeSync.Client.SetPauseSync(true, 18)
end)

RegisterNetEvent('qb-weathersync:client:EnableSync', function()
    Ak47TimeSync.Client.SetPauseSync(false)
end)

RegisterNetEvent('vSync:toggle', function(boolean)
    Ak47TimeSync.Client.SetPauseSync(boolean)
end)

-- ====================================================================
-- Weather Sync Events
-- ====================================================================

RegisterNetEvent('cd_easytime:SyncWeather', function(weather, instant)
    if Ak47TimeSync.Client.IsSyncPaused() then return end
    local w = type(weather) == 'table' and weather.weather or weather
    local inst = type(weather) == 'table' and weather.instantweather or instant
    if w then
        ApplyClientWeather(w, inst and 0 or 10, inst == true)
    end
end)

for _, evt in ipairs({'vSync:updateWeather', 'qb-weathersync:client:SyncWeather'}) do
    RegisterNetEvent(evt, function(weather, blackout)
        if Ak47TimeSync.Client.IsSyncPaused() then return end
        if weather then
            ApplyClientWeather(weather, 10, false)
        end
        if blackout ~= nil then
            ApplyClientBlackout(blackout)
        end
    end)
end

-- ====================================================================
-- Time Sync Events
-- ====================================================================

RegisterNetEvent('cd_easytime:SyncTime', function(hours, mins, instant)
    if Ak47TimeSync.Client.IsSyncPaused() or Ak47TimeSync.Client.IsTimeFrozen() then return end
    local h = type(hours) == 'table' and hours.hours or hours
    local m = type(hours) == 'table' and hours.mins or mins
    local inst = type(hours) == 'table' and hours.instanttime or instant
    if h and m then
        if inst then
            ClientTime.hours = h
            ClientTime.mins = m
            ClientTime.seconds = 0
            NetworkOverrideClockTime(h, m, 0)
        else
            SmoothChangeTime({ hours = h, mins = m, seconds = 0 }, 5)
        end
    end
end)

for _, evt in ipairs({'vSync:updateTime', 'qb-weathersync:client:SyncTime'}) do
    RegisterNetEvent(evt, function(baseTime, timeOffset, freeze)
        if Ak47TimeSync.Client.IsSyncPaused() then return end
        if type(baseTime) == 'number' and type(timeOffset) == 'number' then
            local totalMins = (baseTime or 0) + (timeOffset or 0)
            local hours = math.floor((totalMins / 60) % 24)
            local mins = math.floor(totalMins % 60)
            SmoothChangeTime({ hours = hours, mins = mins, seconds = 0 }, 5)
        elseif type(baseTime) == 'number' and type(timeOffset) == 'nil' and freeze == nil then
            SmoothChangeTime({ hours = baseTime, mins = 0, seconds = 0 }, 5)
        end
        if freeze ~= nil then
            ClientTime.freeze = freeze == true
        end
    end)
end

-- ====================================================================
-- Full ForceUpdate Handler (cd_easytime client compatibility)
-- ====================================================================

RegisterNetEvent('cd_easytime:ForceUpdate', function(data)
    if not data or type(data) ~= 'table' then
        TriggerServerEvent('ak47_timesync:server:requestSync')
        return
    end

    if not Ak47TimeSync.Client.IsSyncPaused() then
        if data.weather and data.weather ~= Ak47TimeSync.Client.GetWeather() then
            ApplyClientWeather(data.weather, data.instantweather and 0 or 10, data.instantweather == true)
        end
        if data.hours ~= nil or data.mins ~= nil then
            local h = data.hours or ClientTime.hours or 12
            local m = data.mins or ClientTime.mins or 0
            if data.instanttime then
                ClientTime.hours = h
                ClientTime.mins = m
                ClientTime.seconds = 0
                NetworkOverrideClockTime(h, m, 0)
            else
                SmoothChangeTime({ hours = h, mins = m, seconds = 0 }, 5)
            end
        end
        if data.blackout ~= nil then
            ApplyClientBlackout(data.blackout == true)
        end
    end

    if data.freeze ~= nil then
        ClientTime.freeze = data.freeze == true
    end
end)

RegisterNetEvent('qb-weathersync:client:RequestTime', function()
    TriggerServerEvent('ak47_timesync:server:requestSync')
end)