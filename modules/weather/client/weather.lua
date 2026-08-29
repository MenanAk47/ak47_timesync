-- ====================================================================
-- Ak47 Time & Weather Sync - Client Weather & Environment
-- ====================================================================

ClientWeather = {
    current = 'CLEAR',
    next = 'CLEAR',
    freeze = false,
    blackout = false,
    paused = false,
    snowTracks = false,
    transitionDuration = 10,
}

local SNOW_TYPES = { XMAS = true, SNOW = true, SNOWLIGHT = true, BLIZZARD = true }

function ApplyClientWeather(weatherType, transitionDuration, forcedInstant)
    if ClientWeather.paused then return end
    weatherType = string.upper(tostring(weatherType))
    ClientWeather.current = weatherType
    transitionDuration = tonumber(transitionDuration) or 10

    if forcedInstant or transitionDuration <= 0 then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypePersist(weatherType)
        SetWeatherTypeNow(weatherType)
        SetWeatherTypeNowPersist(weatherType)
    else
        ClearOverrideWeather()
        SetWeatherTypeOvertimePersist(weatherType, transitionDuration + 0.0)
    end

    local isSnow = (SNOW_TYPES[weatherType] == true) or (ClientWeather.snowTracks == true)
    SetForceVehicleTrails(isSnow)
    SetForcePedFootstepsTracks(isSnow)

    TriggerEvent('ak47_timesync:client:onLocalWeatherUpdated', weatherType, transitionDuration)
end

function ApplyClientBlackout(state)
    if ClientWeather.paused then return end
    ClientWeather.blackout = state == true
    SetArtificialLightsState(ClientWeather.blackout)
    SetArtificialLightsStateAffectsVehicles(false)
    TriggerEvent('ak47_timesync:client:onLocalBlackoutUpdated', ClientWeather.blackout)
end

RegisterNetEvent('ak47_timesync:client:updateWeather', function(data, forcedInstant)
    if ClientWeather.paused then return end
    ClientWeather.next = data.nextWeather or ClientWeather.next
    ApplyClientWeather(data.weather, data.transitionDuration or 10, forcedInstant or false)
    SendUiUpdate({
        weather = data.weather,
        nextWeather = data.nextWeather or ClientWeather.next,
        transitionDuration = data.transitionDuration or 10,
    })
end)

RegisterNetEvent('ak47_timesync:client:setFreezeWeather', function(state)
    ClientWeather.freeze = state == true
    SendUiUpdate({ freezeWeather = state == true })
end)

RegisterNetEvent('ak47_timesync:client:setBlackout', function(state)
    ApplyClientBlackout(state)
    SendUiUpdate({ blackout = state == true })
end)

RegisterNetEvent('ak47_timesync:client:setSnowTracks', function(state)
    ClientWeather.snowTracks = state == true
    local isSnow = (SNOW_TYPES[ClientWeather.current] == true) or (ClientWeather.snowTracks == true)
    SetForceVehicleTrails(isSnow)
    SetForcePedFootstepsTracks(isSnow)
    SendUiUpdate({ snowTracks = state == true })
end)

RegisterNetEvent('ak47_timesync:client:setDynamicCycle', function(state)
    ClientWeather.dynamic = state == true
    SendUiUpdate({ dynamicCycle = state == true, dynamic = state == true })
end)

RegisterNetEvent('ak47_timesync:client:setWind', function(data)
    if data then
        SetWind((data.speed or 0) + 0.0)
        SetWindSpeed((data.speed or 0) + 0.0)
        SetWindDirection((data.direction or 0) + 0.0)
        SendUiUpdate({ windSpeed = data.speed or 0, windDirection = data.direction or 0 })
    end
end)

CreateThread(function()
    while true do
        if not ClientWeather.paused then
            if ClientWeather.blackout then
                SetArtificialLightsState(true)
                SetArtificialLightsStateAffectsVehicles(false)
                Wait(500)
            elseif ClientWeather.freeze then
                SetWeatherTypePersist(ClientWeather.current)
                Wait(2000)
            else
                Wait(2000)
            end
        else
            Wait(1000)
        end
    end
end)
