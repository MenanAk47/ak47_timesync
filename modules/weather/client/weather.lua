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
    rainLevel = -1.0,
    transitionDuration = 10,
    windSpeed = 0.0,
    windDirection = 0.0,
}

local SNOW_TYPES = { XMAS = true, SNOW = true, SNOWLIGHT = true, BLIZZARD = true }

function ApplyClientRainLevel(level)
    if ClientWeather.paused then return end
    ClientWeather.rainLevel = tonumber(level) or -1.0
    if ClientWeather.rainLevel >= 0.0 then
        SetRainLevel(ClientWeather.rainLevel + 0.0)
    else
        SetRainLevel(-1.0)
    end
end

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

    if ClientWeather.rainLevel >= 0.0 then
        SetRainLevel(ClientWeather.rainLevel + 0.0)
    else
        SetRainLevel(-1.0)
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
    ClientWeather.global = data.weather
    if not (ClientZoneWeather and ClientZoneWeather.enabled) then
        ApplyClientWeather(data.weather, data.transitionDuration or 10, forcedInstant or false)
    end
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
        ClientWeather.windSpeed = (tonumber(data.speed) or 0.0) + 0.0
        ClientWeather.windDirection = (tonumber(data.direction) or 0.0) + 0.0
        SetWind(ClientWeather.windSpeed)
        SetWindSpeed(ClientWeather.windSpeed)
        SetWindDirection(math.rad(ClientWeather.windDirection))
        SendUiUpdate({ windSpeed = ClientWeather.windSpeed, windDirection = ClientWeather.windDirection })
    end
end)

RegisterNetEvent('ak47_timesync:client:setRainLevel', function(level)
    ApplyClientRainLevel(level)
    SendUiUpdate({ rainLevel = ClientWeather.rainLevel })
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
