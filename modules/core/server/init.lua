-- ====================================================================
-- Ak47 Time & Weather Sync - Server Initialization & State Manager
-- ====================================================================

local SETTINGS_FILE = 'settings.json'

SyncState = {
    -- Time and Weather always initialize from Config defaults upon server start
    hours = Config.DefaultTime and Config.DefaultTime.hours or 12,
    mins = Config.DefaultTime and Config.DefaultTime.mins or 0,
    seconds = Config.DefaultTime and Config.DefaultTime.seconds or 0,
    minuteDuration = Config.MinuteDuration or 2000,
    freezeTime = Config.FreezeTime or false,

    weather = Config.DefaultWeather or 'CLEAR',
    nextWeather = 'CLEAR',
    transitionDuration = Config.DefaultWeatherTransitionSpeed or 10,
    freezeWeather = Config.FreezeWeather or false,
    blackout = Config.Blackout or false,
    snowTracks = Config.SnowOnGround or false,
    dynamicCycle = Config.DynamicWeather or true,
    newWeatherTimer = Config.NewWeatherTimer or 10,

    windSpeed = Config.DefaultWindSpeed or 0.0,
    windDirection = Config.DefaultWindDirection or 0.0,
    rainLevel = Config.DefaultRainLevel or -1.0,
    zoneWeatherEnabled = Config.ZoneWeather and Config.ZoneWeather.Enabled or false,
}

if WeatherCycles and WeatherCycles.GetNextWeather then
    SyncState.nextWeather = WeatherCycles.GetNextWeather(SyncState.weather)
end

function SyncState.SaveSettings()
    local data = {
        freezeTime = SyncState.freezeTime == true,
        freezeWeather = SyncState.freezeWeather == true,
        blackout = SyncState.blackout == true,
        snowTracks = SyncState.snowTracks == true,
        dynamicCycle = SyncState.dynamicCycle == true,
        newWeatherTimer = tonumber(SyncState.newWeatherTimer) or 10,
        windSpeed = tonumber(SyncState.windSpeed) or 0.0,
        windDirection = tonumber(SyncState.windDirection) or 0.0,
        rainLevel = tonumber(SyncState.rainLevel) or -1.0,
        zoneWeatherEnabled = SyncState.zoneWeatherEnabled == true,
    }
    SaveResourceFile(GetCurrentResourceName(), SETTINGS_FILE, json.encode(data, { indent = true }), -1)
end

function SyncState.LoadSettings()
    local fileContent = LoadResourceFile(GetCurrentResourceName(), SETTINGS_FILE)
    if fileContent and fileContent ~= '' then
        local ok, data = pcall(json.decode, fileContent)
        if ok and type(data) == 'table' then
            if data.freezeTime ~= nil then SyncState.freezeTime = data.freezeTime == true end
            if data.freezeWeather ~= nil then SyncState.freezeWeather = data.freezeWeather == true end
            if data.blackout ~= nil then SyncState.blackout = data.blackout == true end
            if data.snowTracks ~= nil then SyncState.snowTracks = data.snowTracks == true end
            if data.dynamicCycle ~= nil then SyncState.dynamicCycle = data.dynamicCycle == true end
            if data.newWeatherTimer ~= nil then SyncState.newWeatherTimer = tonumber(data.newWeatherTimer) or SyncState.newWeatherTimer end
            if data.windSpeed ~= nil then SyncState.windSpeed = tonumber(data.windSpeed) or SyncState.windSpeed end
            if data.windDirection ~= nil then SyncState.windDirection = tonumber(data.windDirection) or SyncState.windDirection end
            if data.rainLevel ~= nil then SyncState.rainLevel = tonumber(data.rainLevel) or SyncState.rainLevel end
            if data.zoneWeatherEnabled ~= nil then
                SyncState.zoneWeatherEnabled = data.zoneWeatherEnabled == true
                if ZoneWeather then ZoneWeather.enabled = SyncState.zoneWeatherEnabled end
            end
            return
        end
    end
    SyncState.SaveSettings()
end

SyncState.LoadSettings()

function SyncState.GetFullState()
    return {
        hours = SyncState.hours,
        mins = SyncState.mins,
        seconds = SyncState.seconds,
        minuteDuration = SyncState.minuteDuration,
        freezeTime = SyncState.freezeTime,
        weather = SyncState.weather,
        nextWeather = SyncState.nextWeather,
        transitionDuration = SyncState.transitionDuration,
        freezeWeather = SyncState.freezeWeather,
        blackout = SyncState.blackout,
        snowTracks = SyncState.snowTracks,
        dynamicCycle = SyncState.dynamicCycle,
        newWeatherTimer = SyncState.newWeatherTimer,
        windSpeed = SyncState.windSpeed,
        windDirection = SyncState.windDirection,
        rainLevel = SyncState.rainLevel,
        zoneWeatherEnabled = SyncState.zoneWeatherEnabled == true,
        zones = ZoneWeather and ZoneWeather.zones or {},
    }
end

function SyncState.Broadcast(targetSource, forcedInstant)
    local state = SyncState.GetFullState()
    local target = targetSource or -1

    TriggerClientEvent('ak47_timesync:client:syncState', target, state, forcedInstant or false)
    if ZoneWeather and ZoneWeather.Broadcast then
        ZoneWeather.Broadcast(target)
    end

    -- Compatibility client broadcasts
    TriggerClientEvent('qb-weathersync:client:SyncWeather', target, SyncState.weather, SyncState.blackout)
    TriggerClientEvent('qb-weathersync:client:SyncTime', target, 0, ((SyncState.hours or 12) * 60 + (SyncState.mins or 0)), SyncState.freezeTime)
    TriggerClientEvent('cd_easytime:ForceUpdate', target, {
        hours = SyncState.hours,
        mins = SyncState.mins,
        weather = SyncState.weather,
        dynamic = SyncState.dynamicCycle,
        freeze = SyncState.freezeTime,
        blackout = SyncState.blackout,
        instanttime = forcedInstant or false,
        instantweather = forcedInstant or false,
        tsunami = false,
        weathermethod = 'game',
        timemethod = 'game',
    })
    TriggerClientEvent('vSync:updateWeather', target, SyncState.weather, SyncState.blackout)
    TriggerClientEvent('vSync:updateTime', target, 0, ((SyncState.hours or 12) * 60 + (SyncState.mins or 0)), SyncState.freezeTime)
end

function SyncState.SetTime(source, hours, mins, seconds, transitionSpeed, forcedInstant)
    SyncState.hours = tonumber(hours) % 24
    SyncState.mins = tonumber(mins) % 60
    SyncState.seconds = tonumber(seconds or 0) % 60
    local speed = tonumber(transitionSpeed) or Config.DefaultTimeTransitionSpeed or 5

    TriggerClientEvent('ak47_timesync:client:updateTime', -1, {
        hours = SyncState.hours,
        mins = SyncState.mins,
        seconds = SyncState.seconds,
    }, speed, forcedInstant or false)

    -- Compatibility event broadcasts
    TriggerClientEvent('qb-weathersync:client:SyncTime', -1, 0, ((SyncState.hours or 12) * 60 + (SyncState.mins or 0)), SyncState.freezeTime)
    TriggerClientEvent('cd_easytime:SyncTime', -1, { hours = SyncState.hours, mins = SyncState.mins, instanttime = forcedInstant })
    TriggerClientEvent('vSync:updateTime', -1, 0, ((SyncState.hours or 12) * 60 + (SyncState.mins or 0)), SyncState.freezeTime)

    TriggerEvent('ak47_timesync:server:onTimeChanged', source, SyncState.hours, SyncState.mins, speed)
end

function SyncState.SetMinuteDuration(source, duration)
    SyncState.minuteDuration = tonumber(duration) or 2000
    TriggerClientEvent('ak47_timesync:client:setMinuteDuration', -1, SyncState.minuteDuration)
    TriggerEvent('ak47_timesync:server:onMinuteDurationChanged', source, SyncState.minuteDuration)
end

function SyncState.SetWeather(source, weatherType, transitionDuration, forcedInstant)
    weatherType = string.upper(tostring(weatherType))
    SyncState.weather = weatherType
    SyncState.transitionDuration = tonumber(transitionDuration) or Config.DefaultWeatherTransitionSpeed or 10

    if WeatherCycles and WeatherCycles.GetNextWeather then
        SyncState.nextWeather = WeatherCycles.GetNextWeather(SyncState.weather)
    end

    TriggerClientEvent('ak47_timesync:client:updateWeather', -1, {
        weather = SyncState.weather,
        nextWeather = SyncState.nextWeather,
        transitionDuration = SyncState.transitionDuration,
    }, forcedInstant or false)

    -- Compatibility event broadcasts
    TriggerClientEvent('qb-weathersync:client:SyncWeather', -1, SyncState.weather, SyncState.blackout)
    TriggerClientEvent('cd_easytime:SyncWeather', -1, { weather = SyncState.weather, instantweather = forcedInstant })
    TriggerClientEvent('vSync:updateWeather', -1, SyncState.weather, SyncState.blackout)

    TriggerEvent('ak47_timesync:server:onWeatherChanged', source, SyncState.weather, SyncState.transitionDuration)
    TriggerEvent('ak47_timesync:server:onDynamicWeatherCycle')
end


local function ToggleState(key, state)
    SyncState[key] = (state == nil) and not SyncState[key] or (state == true)
    SyncState.SaveSettings()
    return SyncState[key]
end

function SyncState.SetFreezeTime(source, state)
    local val = ToggleState('freezeTime', state)
    TriggerClientEvent('ak47_timesync:client:setFreezeTime', -1, val)
    TriggerClientEvent('qb-weathersync:client:SyncTime', -1, 0, ((SyncState.hours or 12) * 60 + (SyncState.mins or 0)), val)
    TriggerClientEvent('cd_easytime:ForceUpdate', -1, { freeze = val })
    TriggerEvent('ak47_timesync:server:onFreezeChanged', source, 'time', val)
end

function SyncState.SetFreezeWeather(source, state)
    local val = ToggleState('freezeWeather', state)
    TriggerClientEvent('ak47_timesync:client:setFreezeWeather', -1, val)
    TriggerEvent('ak47_timesync:server:onFreezeChanged', source, 'weather', val)
end

function SyncState.SetBlackout(source, state)
    local val = ToggleState('blackout', state)
    TriggerClientEvent('ak47_timesync:client:setBlackout', -1, val)
    TriggerClientEvent('qb-weathersync:client:SyncWeather', -1, SyncState.weather, val)
    TriggerClientEvent('cd_easytime:ForceUpdate', -1, { blackout = val })
    TriggerEvent('ak47_timesync:server:onBlackoutChanged', source, val)
end

function SyncState.SetSnowTracks(source, state)
    local val = ToggleState('snowTracks', state)
    TriggerClientEvent('ak47_timesync:client:setSnowTracks', -1, val)
end

function SyncState.SetDynamicCycle(source, state)
    local val = ToggleState('dynamicCycle', state)
    TriggerClientEvent('ak47_timesync:client:setDynamicCycle', -1, val)
end

function SyncState.SetRainLevel(source, level)
    SyncState.rainLevel = tonumber(level) or -1.0
    SyncState.SaveSettings()
    TriggerClientEvent('ak47_timesync:client:setRainLevel', -1, SyncState.rainLevel)
    TriggerEvent('ak47_timesync:server:onRainLevelChanged', source, SyncState.rainLevel)
end

-- Client Connection Handshake
RegisterNetEvent('ak47_timesync:server:requestSync', function()
    SyncState.Broadcast(source, true)
end)
