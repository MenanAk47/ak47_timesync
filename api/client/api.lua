-- ====================================================================
-- Ak47 Time & Weather Sync - Client API & Export Engine
-- ====================================================================

Ak47TimeSync = Ak47TimeSync or {}
Ak47TimeSync.Client = {}

-- ====================================================================
-- Queries & State Getters
-- ====================================================================

--- Returns the current in-game time snapshot table
--- @return table { hours: number, mins: number, seconds: number, hour: number, minute: number, [1]: number, [2]: number }
function Ak47TimeSync.Client.GetTime()
    local h = ClientTime and ClientTime.hours or 12
    local m = ClientTime and ClientTime.mins or 0
    local s = ClientTime and ClientTime.seconds or 0
    return {
        hours = h,
        mins = m,
        seconds = s,
        hour = h,
        minute = m,
        [1] = h,
        [2] = m,
    }
end

--- Returns current hours and minutes as tuple values
--- @return number hours, number minutes
function Ak47TimeSync.Client.GetTimeTuple()
    local h = ClientTime and ClientTime.hours or 12
    local m = ClientTime and ClientTime.mins or 0
    return h, m
end

--- Returns current weather type string
--- @return string Weather name (e.g. 'CLEAR')
function Ak47TimeSync.Client.GetWeather()
    return ClientWeather and ClientWeather.current or 'CLEAR'
end

--- Returns upcoming forecast weather type string
--- @return string Weather name
function Ak47TimeSync.Client.GetNextWeather()
    return ClientWeather and ClientWeather.next or 'CLEAR'
end

--- Returns current blackout state
--- @return boolean
function Ak47TimeSync.Client.GetBlackout()
    return ClientWeather and (ClientWeather.blackout == true) or false
end

--- Returns time freeze state
--- @return boolean
function Ak47TimeSync.Client.IsTimeFrozen()
    return ClientTime and (ClientTime.freeze == true) or false
end

--- Returns weather freeze state
--- @return boolean
function Ak47TimeSync.Client.IsWeatherFrozen()
    return ClientWeather and (ClientWeather.freeze == true) or false
end

--- Returns dynamic weather cycle state
--- @return boolean
function Ak47TimeSync.Client.IsDynamicWeather()
    return ClientWeather and (ClientWeather.dynamic == true) or false
end

--- Returns current rain level override (-1.0 = auto, 0.0 - 1.0 = custom)
--- @return number
function Ak47TimeSync.Client.GetRainLevel()
    return ClientWeather and ClientWeather.rainLevel or -1.0
end

--- Returns whether sync is paused locally (e.g. character selector, clothing store)
--- @return boolean
function Ak47TimeSync.Client.IsSyncPaused()
    return (ClientTime and ClientTime.paused == true) or (PauseSync and PauseSync.state == true) or false
end

--- Returns the complete client state snapshot
--- @return table
function Ak47TimeSync.Client.GetFullState()
    return {
        hours = ClientTime and ClientTime.hours or 12,
        mins = ClientTime and ClientTime.mins or 0,
        seconds = ClientTime and ClientTime.seconds or 0,
        freezeTime = Ak47TimeSync.Client.IsTimeFrozen(),
        weather = Ak47TimeSync.Client.GetWeather(),
        nextWeather = Ak47TimeSync.Client.GetNextWeather(),
        transitionDuration = ClientWeather and ClientWeather.transitionDuration or 10,
        freezeWeather = Ak47TimeSync.Client.IsWeatherFrozen(),
        blackout = Ak47TimeSync.Client.GetBlackout(),
        snowTracks = ClientWeather and ClientWeather.snowTracks == true or false,
        dynamic = Ak47TimeSync.Client.IsDynamicWeather(),
        dynamicCycle = Ak47TimeSync.Client.IsDynamicWeather(),
        rainLevel = Ak47TimeSync.Client.GetRainLevel(),
        windSpeed = 0,
        windDirection = 0,
        paused = Ak47TimeSync.Client.IsSyncPaused(),
    }
end

-- ====================================================================
-- Sync Pause / Resume Controls
-- ====================================================================

--- Pause or resume client time and weather synchronization
--- @param state boolean True to pause, false to resume
--- @param overrideHour number Optional hour to lock clock to while paused (defaults to 20)
function Ak47TimeSync.Client.SetPauseSync(state, overrideHour)
    local isPaused = state == true
    if PauseSync then
        if PauseSync.state == isPaused then return end
        PauseSync.state = isPaused
        PauseSync.hours = overrideHour or 20
    end

    if ClientTime then ClientTime.paused = isPaused end
    if ClientWeather then ClientWeather.paused = isPaused end

    if isPaused then
        ApplyClientWeather('EXTRASUNNY', 0, true)
        CreateThread(function()
            while PauseSync and PauseSync.state do
                Wait(0)
                NetworkOverrideClockTime(overrideHour or 20, 0, 0)
            end
        end)
    else
        Wait(300)
        TriggerServerEvent('ak47_timesync:server:requestSync')
    end
end

--- Returns a self table object compatible with cd_easytime with string metamethod
--- @return table
function Ak47TimeSync.Client.GetWeatherObject()
    if self then return self end
    local obj = {
        weather = Ak47TimeSync.Client.GetWeather(),
        hours = ClientTime and ClientTime.hours or 12,
        mins = ClientTime and ClientTime.mins or 0,
        dynamic = Ak47TimeSync.Client.IsDynamicWeather(),
        freeze = Ak47TimeSync.Client.IsTimeFrozen(),
        blackout = Ak47TimeSync.Client.GetBlackout(),
    }
    setmetatable(obj, {
        __tostring = function() return Ak47TimeSync.Client.GetWeather() end
    })
    return obj
end

-- ====================================================================
-- Universal Multi-Resource Export Handlers (Client)
-- Binds exports to ak47_timesync, qb-weathersync, cd_easytime, vSync, vSyncR, qbx_weathersync
-- ====================================================================

local RESOURCE_ALIASES = {
    'ak47_timesync',
    'qb-weathersync',
    'cd_easytime',
    'vSync',
    'vSyncR',
    'qbx_weathersync',
}

local function RegisterExport(exportName, func)
    exports(exportName, func)
    for _, resName in ipairs(RESOURCE_ALIASES) do
        AddEventHandler(('__cfx_export_%s_%s'):format(resName, exportName), function(setCB)
            setCB(func)
        end)
    end
end

RegisterExport('getTime', Ak47TimeSync.Client.GetTime)
RegisterExport('GetTime', Ak47TimeSync.Client.GetTime)
RegisterExport('getTimeState', Ak47TimeSync.Client.GetTime)
RegisterExport('GetTimeState', Ak47TimeSync.Client.GetTime)

RegisterExport('getWeather', Ak47TimeSync.Client.GetWeather)
RegisterExport('GetWeather', Ak47TimeSync.Client.GetWeatherObject)
RegisterExport('getWeatherState', Ak47TimeSync.Client.GetWeather)
RegisterExport('GetWeatherState', Ak47TimeSync.Client.GetWeather)
RegisterExport('getNextWeather', Ak47TimeSync.Client.GetNextWeather)
RegisterExport('GetNextWeather', Ak47TimeSync.Client.GetNextWeather)

RegisterExport('getAllData', Ak47TimeSync.Client.GetWeatherObject)
RegisterExport('GetAllData', Ak47TimeSync.Client.GetWeatherObject)

RegisterExport('getBlackout', Ak47TimeSync.Client.GetBlackout)
RegisterExport('GetBlackout', Ak47TimeSync.Client.GetBlackout)
RegisterExport('getBlackoutState', Ak47TimeSync.Client.GetBlackout)
RegisterExport('GetBlackoutState', Ak47TimeSync.Client.GetBlackout)

RegisterExport('getTimeFreezeState', Ak47TimeSync.Client.IsTimeFrozen)
RegisterExport('GetTimeFreezeState', Ak47TimeSync.Client.IsTimeFrozen)
RegisterExport('isTimeFrozen', Ak47TimeSync.Client.IsTimeFrozen)
RegisterExport('IsTimeFrozen', Ak47TimeSync.Client.IsTimeFrozen)

RegisterExport('getWeatherFreezeState', Ak47TimeSync.Client.IsWeatherFrozen)
RegisterExport('GetWeatherFreezeState', Ak47TimeSync.Client.IsWeatherFrozen)
RegisterExport('isWeatherFrozen', Ak47TimeSync.Client.IsWeatherFrozen)
RegisterExport('IsWeatherFrozen', Ak47TimeSync.Client.IsWeatherFrozen)

RegisterExport('isDynamicWeather', Ak47TimeSync.Client.IsDynamicWeather)
RegisterExport('IsDynamicWeather', Ak47TimeSync.Client.IsDynamicWeather)
RegisterExport('getDynamicWeather', Ak47TimeSync.Client.IsDynamicWeather)
RegisterExport('GetDynamicWeather', Ak47TimeSync.Client.IsDynamicWeather)

RegisterExport('getRainLevel', Ak47TimeSync.Client.GetRainLevel)
RegisterExport('GetRainLevel', Ak47TimeSync.Client.GetRainLevel)

RegisterExport('isSyncPaused', Ak47TimeSync.Client.IsSyncPaused)
RegisterExport('IsSyncPaused', Ak47TimeSync.Client.IsSyncPaused)
RegisterExport('getPauseSyncState', Ak47TimeSync.Client.IsSyncPaused)
RegisterExport('GetPauseSyncState', Ak47TimeSync.Client.IsSyncPaused)
RegisterExport('setPauseSync', Ak47TimeSync.Client.SetPauseSync)
RegisterExport('SetPauseSync', Ak47TimeSync.Client.SetPauseSync)
RegisterExport('togglePauseSync', function(s, h) Ak47TimeSync.Client.SetPauseSync(s, h) end)
RegisterExport('TogglePauseSync', function(s, h) Ak47TimeSync.Client.SetPauseSync(s, h) end)

RegisterExport('getFullState', Ak47TimeSync.Client.GetFullState)
RegisterExport('GetFullState', Ak47TimeSync.Client.GetFullState)
