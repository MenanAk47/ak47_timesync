-- ====================================================================
-- Ak47 Time & Weather Sync - Client NUI Callback Handlers
-- ====================================================================

RegisterNUICallback('close', function(_, cb)
    CloseUI()
    cb({ success = true })
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('ak47_timesync:server:setTime', tonumber(data.hours) or 12, tonumber(data.mins) or 0, tonumber(data.seconds) or 0, tonumber(data.transitionSpeed) or 5, data.instant == true)
    cb({ success = true })
end)

RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('ak47_timesync:server:setWeather', tostring(data.weather or 'CLEAR'), tonumber(data.transitionDuration) or 10, data.instant == true)
    cb({ success = true })
end)

RegisterNUICallback('setWind', function(data, cb)
    TriggerServerEvent('ak47_timesync:server:setWind', tonumber(data.speed) or 0, tonumber(data.direction) or 0)
    cb({ success = true })
end)

RegisterNUICallback('setRainLevel', function(data, cb)
    TriggerServerEvent('ak47_timesync:server:setRainLevel', tonumber(data.level) or -1.0)
    cb({ success = true })
end)

local toggleEvents = {
    toggleFreezeTime = 'ak47_timesync:server:toggleFreezeTime',
    toggleFreezeWeather = 'ak47_timesync:server:toggleFreezeWeather',
    toggleBlackout = 'ak47_timesync:server:setBlackout',
    toggleSnowTracks = 'ak47_timesync:server:setSnowTracks',
    setDynamicCycle = 'ak47_timesync:server:setDynamicCycle',
}

for cbName, srvEvt in pairs(toggleEvents) do
    RegisterNUICallback(cbName, function(data, cb)
        TriggerServerEvent(srvEvt, data.state)
        cb({ success = true })
    end)
end
