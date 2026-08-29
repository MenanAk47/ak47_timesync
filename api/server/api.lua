-- ====================================================================
-- Ak47 Time & Weather Sync - Server API & Export Engine
-- ====================================================================

Ak47TimeSync = Ak47TimeSync or {}
Ak47TimeSync.Server = {}

-- ====================================================================
-- Permission Validation
-- ====================================================================

--- Validates whether a source has permission to execute time/weather changes
--- @param src number|string Player source or 0 for server console
--- @return boolean
function Ak47TimeSync.Server.HasPermission(src)
    if src == 0 or src == '0' or src == '' or src == nil then return true end
    local s = tonumber(src) or 0
    if s == 0 then return true end
    if Lib47 and Lib47.HasPermission and Lib47.HasPermission(s, Admin) then return true end
    if IsPlayerAceAllowed(s, 'command') or IsPlayerAceAllowed(s, 'command.weather') or IsPlayerAceAllowed(s, 'command.time') or IsPlayerAceAllowed(s, 'admin') then return true end
    return false
end

-- ====================================================================
-- State Queries & Getters
-- ====================================================================

--- Returns current time dictionary
--- @return table { hours: number, mins: number, seconds: number, hour: number, minute: number, [1]: number, [2]: number }
function Ak47TimeSync.Server.GetTime()
    local h = SyncState and SyncState.hours or 12
    local m = SyncState and SyncState.mins or 0
    local s = SyncState and SyncState.seconds or 0
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
function Ak47TimeSync.Server.GetTimeTuple()
    local h = SyncState and SyncState.hours or 12
    local m = SyncState and SyncState.mins or 0
    return h, m
end

--- Returns current weather type string
--- @return string Weather name
function Ak47TimeSync.Server.GetWeather()
    return SyncState and SyncState.weather or 'CLEAR'
end

--- Returns next forecast weather type string
--- @return string Weather name
function Ak47TimeSync.Server.GetNextWeather()
    return SyncState and SyncState.nextWeather or 'CLEAR'
end

--- Returns current blackout state
--- @return boolean
function Ak47TimeSync.Server.GetBlackout()
    return SyncState and (SyncState.blackout == true) or false
end

--- Returns time freeze state
--- @return boolean
function Ak47TimeSync.Server.IsTimeFrozen()
    return SyncState and (SyncState.freezeTime == true) or false
end

--- Returns weather freeze state
--- @return boolean
function Ak47TimeSync.Server.IsWeatherFrozen()
    return SyncState and (SyncState.freezeWeather == true) or false
end

--- Returns dynamic weather cycle state
--- @return boolean
function Ak47TimeSync.Server.IsDynamicWeather()
    return SyncState and (SyncState.dynamicCycle == true) or false
end

--- Returns full server environment state snapshot
--- @return table
function Ak47TimeSync.Server.GetFullState()
    if SyncState and SyncState.GetFullState then
        return SyncState.GetFullState()
    end
    return {
        hours = SyncState and SyncState.hours or 12,
        mins = SyncState and SyncState.mins or 0,
        seconds = SyncState and SyncState.seconds or 0,
        minuteDuration = SyncState and SyncState.minuteDuration or 2000,
        freezeTime = Ak47TimeSync.Server.IsTimeFrozen(),
        weather = Ak47TimeSync.Server.GetWeather(),
        nextWeather = Ak47TimeSync.Server.GetNextWeather(),
        transitionDuration = SyncState and SyncState.transitionDuration or 10,
        freezeWeather = Ak47TimeSync.Server.IsWeatherFrozen(),
        blackout = Ak47TimeSync.Server.GetBlackout(),
        snowTracks = SyncState and SyncState.snowTracks == true or false,
        dynamicCycle = Ak47TimeSync.Server.IsDynamicWeather(),
        newWeatherTimer = SyncState and SyncState.newWeatherTimer or 10,
    }
end

--- Returns real-world weather and time data block
--- @return table
function Ak47TimeSync.Server.GetRealWorldData()
    return {
        hours = SyncState and SyncState.hours or 12,
        mins = SyncState and SyncState.mins or 0,
        gta_weather = SyncState and SyncState.weather or 'CLEAR',
        real_weather = SyncState and SyncState.weather or 'CLEAR',
        real_weather_description = 'Synced Weather',
        country = 'US',
        city = 'Los Santos',
    }
end

-- ====================================================================
-- State Mutations & Setters
-- ====================================================================

--- Set server clock time
--- @param source number Source of the change (0 for console/server)
--- @param hours number Hours (0-23)
--- @param mins number Minutes (0-59)
--- @param seconds number Optional seconds (0-59)
--- @param transitionSpeed number Optional transition speed in seconds
--- @param instant boolean True for instant snap
--- @return boolean Success
function Ak47TimeSync.Server.SetTime(source, hours, mins, seconds, transitionSpeed, instant)
    local h = tonumber(hours)
    local m = tonumber(mins) or 0
    local s = tonumber(seconds) or 0

    if not h or h < 0 or h > 24 then return false end
    if h >= 24 then h = 0 end
    if m < 0 or m > 59 then m = 0 end
    if s < 0 or s > 59 then s = 0 end

    local speed = tonumber(transitionSpeed) or (instant and 0) or Config.DefaultTimeTransitionSpeed or 5

    SyncState.SetTime(source or 0, h, m, s, speed, instant == true or speed <= 0)
    return true
end

--- Set server weather
--- @param source number Source of the change (0 for console/server)
--- @param weatherType string Weather condition name
--- @param transitionDuration number Optional blend duration in seconds
--- @param instant boolean True for instant weather change
--- @return boolean Success
function Ak47TimeSync.Server.SetWeather(source, weatherType, transitionDuration, instant)
    if type(weatherType) ~= 'string' then return false end
    local w = string.upper(weatherType)

    local isValid = false
    for _, wt in ipairs((WeatherCycles and WeatherCycles.WeatherTypes) or {}) do
        if wt == w then isValid = true break end
    end
    if not isValid and w ~= 'CLEAR' and w ~= 'EXTRASUNNY' and w ~= 'RAIN' and w ~= 'THUNDER' then
        return false
    end

    local duration = tonumber(transitionDuration) or (instant and 0) or Config.DefaultWeatherTransitionSpeed or 10

    SyncState.SetWeather(source or 0, w, duration, instant == true or duration <= 0)
    return true
end

--- Set or toggle blackout state
--- @param source number Source of the change
--- @param state boolean|nil True/false to set, or nil to toggle
--- @return boolean New blackout state
function Ak47TimeSync.Server.SetBlackout(source, state)
    SyncState.SetBlackout(source or 0, state)
    return SyncState.blackout == true
end

--- Set or toggle time freeze
--- @param source number Source of the change
--- @param state boolean|nil True/false to set, or nil to toggle
--- @return boolean New freeze state
function Ak47TimeSync.Server.SetFreezeTime(source, state)
    SyncState.SetFreezeTime(source or 0, state)
    return SyncState.freezeTime == true
end

--- Set or toggle weather freeze
--- @param source number Source of the change
--- @param state boolean|nil True/false to set, or nil to toggle
--- @return boolean New freeze state
function Ak47TimeSync.Server.SetFreezeWeather(source, state)
    SyncState.SetFreezeWeather(source or 0, state)
    return SyncState.freezeWeather == true
end

--- Set or toggle global (both time and weather) freeze
--- @param source number Source of the change
--- @param state boolean|nil True/false to set, or nil to toggle
--- @return boolean New freeze state
function Ak47TimeSync.Server.SetGlobalFreeze(source, state)
    SyncState.SetFreezeTime(source or 0, state)
    SyncState.SetFreezeWeather(source or 0, state)
    return SyncState.freezeTime == true
end

--- Set or toggle dynamic weather cycle
--- @param source number Source of the change
--- @param state boolean|nil True/false to set, or nil to toggle
--- @return boolean New dynamic cycle state
function Ak47TimeSync.Server.SetDynamicWeather(source, state)
    SyncState.SetDynamicCycle(source or 0, state)
    return SyncState.dynamicCycle == true
end

--- Set or toggle snow tracks
--- @param source number Source of the change
--- @param state boolean|nil True/false to set, or nil to toggle
--- @return boolean New snow tracks state
function Ak47TimeSync.Server.SetSnowTracks(source, state)
    SyncState.SetSnowTracks(source or 0, state)
    return SyncState.snowTracks == true
end

--- Advances to next probabilistic weather stage
--- @param source number Source of the change
function Ak47TimeSync.Server.NextWeatherStage(source)
    local nextW = SyncState.nextWeather or (WeatherCycles and WeatherCycles.GetNextWeather and WeatherCycles.GetNextWeather(SyncState.weather)) or 'CLEAR'
    SyncState.SetWeather(source or 0, nextW, Config.DefaultWeatherTransitionSpeed or 10, false)
end

--- Returns an easytime-compatible weather state table with string metatable
--- @return table
function Ak47TimeSync.Server.GetWeatherObject()
    local data = {
        weather = SyncState and SyncState.weather or 'CLEAR',
        hours = SyncState and SyncState.hours or 12,
        mins = SyncState and SyncState.mins or 0,
        dynamic = SyncState and SyncState.dynamicCycle == true,
        freeze = SyncState and SyncState.freezeTime == true,
        blackout = SyncState and SyncState.blackout == true,
        tsunami = false,
        weathermethod = 'game',
        timemethod = 'game',
        instanttime = false,
        instantweather = false,
    }
    setmetatable(data, {
        __tostring = function() return SyncState and SyncState.weather or 'CLEAR' end
    })
    return data
end

-- ====================================================================
-- Universal Multi-Resource Export Handlers (Server)
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

RegisterExport('getTime', Ak47TimeSync.Server.GetTime)
RegisterExport('GetTime', Ak47TimeSync.Server.GetTime)
RegisterExport('getTimeState', Ak47TimeSync.Server.GetTime)
RegisterExport('GetTimeState', Ak47TimeSync.Server.GetTime)
RegisterExport('setTime', function(h, m, s, spd, inst) return Ak47TimeSync.Server.SetTime(0, h, m, s, spd, inst) end)
RegisterExport('SetTime', function(h, m, s, spd, inst) return Ak47TimeSync.Server.SetTime(0, h, m, s, spd, inst) end)

RegisterExport('getWeather', Ak47TimeSync.Server.GetWeather)
RegisterExport('GetWeather', Ak47TimeSync.Server.GetWeatherObject)
RegisterExport('getWeatherState', Ak47TimeSync.Server.GetWeather)
RegisterExport('GetWeatherState', Ak47TimeSync.Server.GetWeather)
RegisterExport('getNextWeather', Ak47TimeSync.Server.GetNextWeather)
RegisterExport('GetNextWeather', Ak47TimeSync.Server.GetNextWeather)
RegisterExport('setWeather', function(w, dur, inst) return Ak47TimeSync.Server.SetWeather(0, w, dur, inst) end)
RegisterExport('SetWeather', function(w, dur, inst) return Ak47TimeSync.Server.SetWeather(0, w, dur, inst) end)

RegisterExport('getBlackout', Ak47TimeSync.Server.GetBlackout)
RegisterExport('GetBlackout', Ak47TimeSync.Server.GetBlackout)
RegisterExport('getBlackoutState', Ak47TimeSync.Server.GetBlackout)
RegisterExport('GetBlackoutState', Ak47TimeSync.Server.GetBlackout)
RegisterExport('setBlackout', function(s) return Ak47TimeSync.Server.SetBlackout(0, s) end)
RegisterExport('SetBlackout', function(s) return Ak47TimeSync.Server.SetBlackout(0, s) end)
RegisterExport('toggleBlackout', function(s) return Ak47TimeSync.Server.SetBlackout(0, s) end)
RegisterExport('ToggleBlackout', function(s) return Ak47TimeSync.Server.SetBlackout(0, s) end)

RegisterExport('getTimeFreezeState', Ak47TimeSync.Server.IsTimeFrozen)
RegisterExport('GetTimeFreezeState', Ak47TimeSync.Server.IsTimeFrozen)
RegisterExport('isTimeFrozen', Ak47TimeSync.Server.IsTimeFrozen)
RegisterExport('IsTimeFrozen', Ak47TimeSync.Server.IsTimeFrozen)
RegisterExport('setTimeFreeze', function(s) return Ak47TimeSync.Server.SetFreezeTime(0, s) end)
RegisterExport('SetTimeFreeze', function(s) return Ak47TimeSync.Server.SetFreezeTime(0, s) end)
RegisterExport('toggleFreezeTime', function(s) return Ak47TimeSync.Server.SetFreezeTime(0, s) end)
RegisterExport('ToggleFreezeTime', function(s) return Ak47TimeSync.Server.SetFreezeTime(0, s) end)

RegisterExport('getWeatherFreezeState', Ak47TimeSync.Server.IsWeatherFrozen)
RegisterExport('GetWeatherFreezeState', Ak47TimeSync.Server.IsWeatherFrozen)
RegisterExport('isWeatherFrozen', Ak47TimeSync.Server.IsWeatherFrozen)
RegisterExport('IsWeatherFrozen', Ak47TimeSync.Server.IsWeatherFrozen)
RegisterExport('setWeatherFreeze', function(s) return Ak47TimeSync.Server.SetFreezeWeather(0, s) end)
RegisterExport('SetWeatherFreeze', function(s) return Ak47TimeSync.Server.SetFreezeWeather(0, s) end)
RegisterExport('toggleFreezeWeather', function(s) return Ak47TimeSync.Server.SetFreezeWeather(0, s) end)
RegisterExport('ToggleFreezeWeather', function(s) return Ak47TimeSync.Server.SetFreezeWeather(0, s) end)

RegisterExport('toggleFreeze', function(s) return Ak47TimeSync.Server.SetGlobalFreeze(0, s) end)
RegisterExport('ToggleFreeze', function(s) return Ak47TimeSync.Server.SetGlobalFreeze(0, s) end)
RegisterExport('setFreeze', function(s) return Ak47TimeSync.Server.SetGlobalFreeze(0, s) end)
RegisterExport('SetFreeze', function(s) return Ak47TimeSync.Server.SetGlobalFreeze(0, s) end)

RegisterExport('isDynamicWeather', Ak47TimeSync.Server.IsDynamicWeather)
RegisterExport('IsDynamicWeather', Ak47TimeSync.Server.IsDynamicWeather)
RegisterExport('getDynamicWeather', Ak47TimeSync.Server.IsDynamicWeather)
RegisterExport('GetDynamicWeather', Ak47TimeSync.Server.IsDynamicWeather)
RegisterExport('setDynamicWeather', function(s) return Ak47TimeSync.Server.SetDynamicWeather(0, s) end)
RegisterExport('SetDynamicWeather', function(s) return Ak47TimeSync.Server.SetDynamicWeather(0, s) end)
RegisterExport('toggleDynamic', function(s) return Ak47TimeSync.Server.SetDynamicWeather(0, s) end)
RegisterExport('ToggleDynamic', function(s) return Ak47TimeSync.Server.SetDynamicWeather(0, s) end)
RegisterExport('toggleDynamicWeather', function(s) return Ak47TimeSync.Server.SetDynamicWeather(0, s) end)
RegisterExport('ToggleDynamicWeather', function(s) return Ak47TimeSync.Server.SetDynamicWeather(0, s) end)

RegisterExport('setSnowTracks', function(s) return Ak47TimeSync.Server.SetSnowTracks(0, s) end)
RegisterExport('SetSnowTracks', function(s) return Ak47TimeSync.Server.SetSnowTracks(0, s) end)
RegisterExport('toggleSnowTracks', function(s) return Ak47TimeSync.Server.SetSnowTracks(0, s) end)
RegisterExport('ToggleSnowTracks', function(s) return Ak47TimeSync.Server.SetSnowTracks(0, s) end)

RegisterExport('nextWeatherStage', function() Ak47TimeSync.Server.NextWeatherStage(0) end)
RegisterExport('NextWeatherStage', function() Ak47TimeSync.Server.NextWeatherStage(0) end)

RegisterExport('getFullState', Ak47TimeSync.Server.GetFullState)
RegisterExport('GetFullState', Ak47TimeSync.Server.GetFullState)
RegisterExport('getAllData', Ak47TimeSync.Server.GetWeatherObject)
RegisterExport('GetAllData', Ak47TimeSync.Server.GetWeatherObject)
RegisterExport('getRealData', Ak47TimeSync.Server.GetRealWorldData)
RegisterExport('GetRealData', Ak47TimeSync.Server.GetRealWorldData)
RegisterExport('getPauseSyncState', function() return false end)
RegisterExport('GetPauseSyncState', function() return false end)
