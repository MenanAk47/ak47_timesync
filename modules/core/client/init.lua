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
    ClientTime.freeze = state.freezeTime == true

    ClientWeather.freeze = state.freezeWeather == true
    ClientWeather.snowTracks = state.snowTracks == true
    ClientWeather.next = state.nextWeather or 'CLEAR'

    local isPaused = (ClientTime and ClientTime.paused) or (PauseSync and PauseSync.state)

    if not isPaused then
        if forcedInstant then
            ClientTime.forcedInstantTimeUpdate = true
            NetworkOverrideClockTime(state.hours, state.mins, state.seconds or 0)
        else
            SmoothChangeTime(state, state.transitionDuration or 5)
        end

        ApplyClientWeather(state.weather, state.transitionDuration or 10, forcedInstant)
        ApplyClientBlackout(state.blackout == true)
    end

    SendUiUpdate(state)
end)

RegisterNetEvent('ak47_timesync:client:openAdminMenu', function(initialState)
    if isUiOpen then return end
    isUiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        data = {
            mode = 'admin',
            state = initialState or Ak47TimeSync.Client.GetFullState(),
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
        TriggerEvent('chat:removeSuggestion', '/freezetime')
        TriggerEvent('chat:removeSuggestion', '/freezeweather')
        TriggerEvent('chat:removeSuggestion', '/blackout')
        TriggerEvent('chat:removeSuggestion', '/morning')
        TriggerEvent('chat:removeSuggestion', '/noon')
        TriggerEvent('chat:removeSuggestion', '/evening')
        TriggerEvent('chat:removeSuggestion', '/night')
    end
end)

