-- ====================================================================
-- Ak47 Time & Weather Sync - Client Initialization & NUI Routing
-- ====================================================================

local isUiOpen = false

function SendUiUpdate(stateData)
    if isUiOpen and stateData then
        SendNUIMessage({
            action = 'updateState',
            data = stateData,
        })
    end
end

RegisterNetEvent('ak47_timesync:client:syncState', function(state, forcedInstant)
    if not state then return end

    ClientTime.hours = state.hours
    ClientTime.mins = state.mins
    ClientTime.seconds = state.seconds or 0
    ClientTime.minuteDuration = state.minuteDuration or Config.MinuteDuration or 2000
    ClientTime.freeze = state.freezeTime == true

    if SetGameMinuteDuration then
        SetGameMinuteDuration(ClientTime.minuteDuration)
    end

    ClientWeather.freeze = state.freezeWeather == true
    ClientWeather.snowTracks = state.snowTracks == true
    ClientWeather.next = state.nextWeather or 'CLEAR'
    ClientWeather.global = state.weather
    ClientWeather.rainLevel = tonumber(state.rainLevel) or -1.0
    if state.windSpeed ~= nil then ClientWeather.windSpeed = tonumber(state.windSpeed) or 0.0 end
    if state.windDirection ~= nil then ClientWeather.windDirection = tonumber(state.windDirection) or 0.0 end

    if state.zoneWeatherEnabled ~= nil and ClientZoneWeather then
        ClientZoneWeather.enabled = state.zoneWeatherEnabled == true
        ClientZoneWeather.zones = state.zones or ClientZoneWeather.zones
        if ClientZoneWeather.EvaluateActiveZone then
            ClientZoneWeather.EvaluateActiveZone(true, forcedInstant)
        end
    end

    local isPaused = (ClientTime and ClientTime.paused) or (PauseSync and PauseSync.state)

    if not isPaused then
        if forcedInstant then
            ClientTime.forcedInstantTimeUpdate = true
            NetworkOverrideClockTime(state.hours, state.mins, state.seconds or 0)
        else
            SmoothChangeTime(state, state.transitionDuration or 5)
        end

        if not (ClientZoneWeather and ClientZoneWeather.enabled) then
            ApplyClientWeather(state.weather, state.transitionDuration or 10, forcedInstant)
        end
        ApplyClientBlackout(state.blackout == true)
        ApplyClientRainLevel(state.rainLevel)
        if state.windSpeed ~= nil then
            SetWind(ClientWeather.windSpeed + 0.0)
            SetWindSpeed(ClientWeather.windSpeed + 0.0)
            SetWindDirection(math.rad(ClientWeather.windDirection or 0.0))
        end
    end

    SendUiUpdate(state)
end)


RegisterNetEvent('ak47_timesync:client:openAdminMenu', function(initialState)
    if isUiOpen then return end
    isUiOpen = true
    SetNuiFocus(true, true)

    if ClientZoneWeather and ClientZoneWeather.EvaluateActiveZone then
        ClientZoneWeather.EvaluateActiveZone(true)
    end

    local clientState = Ak47TimeSync.Client.GetFullState()
    if initialState and type(initialState) == 'table' then
        for k, v in pairs(initialState) do
            if clientState[k] == nil then
                clientState[k] = v
            end
        end
    end

    SendNUIMessage({
        action = 'openUI',
        data = {
            mode = 'admin',
            state = clientState,
            presets = Presets,
            weatherTypes = WeatherCycles and WeatherCycles.WeatherTypes or {},
            locales = Locales[Config.Locale] or Locales['en'] or {},
        }
    })
end)

function CloseUI()
    if not isUiOpen then return end
    isUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeUI' })
end

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('ak47_timesync:server:requestSync')
end)

-- ====================================================================
-- Chat Suggestions
-- ====================================================================
CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/timesync', _U('cmd_timesync_desc'))
    TriggerEvent('chat:addSuggestion', '/time', _U('cmd_time_desc'), {
        { name = 'hour', help = _U('cmd_time_h_param') },
        { name = 'minute', help = _U('cmd_time_m_param') },
    })
    TriggerEvent('chat:addSuggestion', '/weather', _U('cmd_weather_desc'), {
        { name = 'weather', help = _U('cmd_weather_param') },
    })
    TriggerEvent('chat:addSuggestion', '/freezetime', _U('cmd_freezetime_desc'))
    TriggerEvent('chat:addSuggestion', '/freezeweather', _U('cmd_freezeweather_desc'))
    TriggerEvent('chat:addSuggestion', '/blackout', _U('cmd_blackout_desc'))
    TriggerEvent('chat:addSuggestion', '/zoneweather', _U('cmd_zoneweather_desc'), {
        { name = 'zoneId', help = _U('cmd_zoneweather_zone_param') },
        { name = 'weather', help = _U('cmd_zoneweather_type_param') },
    })
    TriggerEvent('chat:addSuggestion', '/zonedebug', 'Toggle Zone Weather debug mode and print current zone/weather info')
    TriggerEvent('chat:addSuggestion', '/debugzone', 'Toggle Zone Weather debug mode and print current zone/weather info')
    TriggerEvent('chat:addSuggestion', '/morning', _U('cmd_morning_desc'))
    TriggerEvent('chat:addSuggestion', '/noon', _U('cmd_noon_desc'))
    TriggerEvent('chat:addSuggestion', '/evening', _U('cmd_evening_desc'))
    TriggerEvent('chat:addSuggestion', '/night', _U('cmd_night_desc'))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isUiOpen then
            isUiOpen = false
            SetNuiFocus(false, false)
        end
        TriggerEvent('chat:removeSuggestion', '/timesync')
        TriggerEvent('chat:removeSuggestion', '/time')
        TriggerEvent('chat:removeSuggestion', '/weather')
        TriggerEvent('chat:removeSuggestion', '/zoneweather')
        TriggerEvent('chat:removeSuggestion', '/zonedebug')
        TriggerEvent('chat:removeSuggestion', '/debugzone')
        TriggerEvent('chat:removeSuggestion', '/freezetime')
        TriggerEvent('chat:removeSuggestion', '/freezeweather')
        TriggerEvent('chat:removeSuggestion', '/blackout')
        TriggerEvent('chat:removeSuggestion', '/morning')
        TriggerEvent('chat:removeSuggestion', '/noon')
        TriggerEvent('chat:removeSuggestion', '/evening')
        TriggerEvent('chat:removeSuggestion', '/night')
    end
end)


