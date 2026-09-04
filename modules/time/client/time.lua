-- ====================================================================
-- Ak47 Time & Weather Sync - Client Time Interpolation & Sync
-- ====================================================================

ClientTime = {
    hours = 12,
    mins = 0,
    seconds = 0,
    minuteDuration = 2000,
    freeze = false,
    paused = false,
    isTransitioning = false,
    forcedInstantTimeUpdate = false,
}

local transitionThreadId = 0

--- Sets the client engine timescale for game minutes
--- @param ms number Milliseconds per game minute
function SetGameMinuteDuration(ms)
    local duration = tonumber(ms) or 2000
    if duration <= 0 then duration = 2000 end
    ClientTime.minuteDuration = duration

    if NetworkOverrideClockMillisecondsPerGameMinute then
        pcall(NetworkOverrideClockMillisecondsPerGameMinute, duration)
    end
    if SetMillisecondsPerGameMinute then
        pcall(SetMillisecondsPerGameMinute, duration)
    end
end

--- Smoothly interpolates the in-game clock from current time to target time
--- @param data table { hours: number, mins: number, seconds: number }
--- @param transition_speed number Transition duration in seconds
function SmoothChangeTime(data, transition_speed)
    if ClientTime.paused then return end
    transition_speed = tonumber(transition_speed) or 5

    -- Instant update if speed is 0 or less
    if transition_speed <= 0 then
        ClientTime.forcedInstantTimeUpdate = true
        ClientTime.hours = data.hours
        ClientTime.mins = data.mins
        ClientTime.seconds = data.seconds or 0
        NetworkOverrideClockTime(data.hours, data.mins, data.seconds or 0)
        TriggerEvent('ak47_timesync:client:onLocalTimeUpdated', data.hours, data.mins, data.seconds or 0, false)
        return
    end

    -- Interrupt any previous transition
    transitionThreadId = transitionThreadId + 1
    local currentThread = transitionThreadId
    ClientTime.forcedInstantTimeUpdate = false
    ClientTime.isTransitioning = true

    CreateThread(function()
        local current_total_seconds = ((GetClockHours() % 24) * 3600) + ((GetClockMinutes() % 60) * 60) + (GetClockSeconds() % 60)
        local target_total_seconds = ((tonumber(data.hours or 0) % 24) * 3600) + ((tonumber(data.mins or 0) % 60) * 60) + (tonumber(data.seconds or 0) % 60)

        local diff = target_total_seconds - current_total_seconds
        if diff > 43200 then
            diff = diff - 86400
        elseif diff < -43200 then
            diff = diff + 86400
        end

        local start_time = GetGameTimer()
        local duration_ms = transition_speed * 1000

        while (GetGameTimer() - start_time < duration_ms) and (currentThread == transitionThreadId) and not ClientTime.forcedInstantTimeUpdate and not ClientTime.paused do
            local progress = (GetGameTimer() - start_time) / duration_ms
            local total_seconds = math.floor(current_total_seconds + (diff * progress)) % 86400
            if total_seconds < 0 then
                total_seconds = total_seconds + 86400
            end

            local hours = math.floor(total_seconds / 3600) % 24
            local mins = math.floor((total_seconds % 3600) / 60) % 60
            local seconds = math.floor(total_seconds % 60)

            NetworkOverrideClockTime(hours, mins, seconds)

            Wait(0)
        end

        if currentThread == transitionThreadId then
            ClientTime.isTransitioning = false
            if not ClientTime.forcedInstantTimeUpdate and not ClientTime.paused then
                ClientTime.hours = data.hours
                ClientTime.mins = data.mins
                ClientTime.seconds = data.seconds or 0
                NetworkOverrideClockTime(data.hours, data.mins, data.seconds or 0)
                TriggerEvent('ak47_timesync:client:onLocalTimeUpdated', data.hours, data.mins, data.seconds or 0, true)
            end
        end
    end)
end

-- Network Event: Server Time Tick Pulse
RegisterNetEvent('ak47_timesync:client:syncTimeTick', function(data)
    if ClientTime.paused or ClientTime.isTransitioning then return end

    ClientTime.hours = data.hours
    ClientTime.mins = data.mins
    ClientTime.seconds = data.seconds or 0

    NetworkOverrideClockTime(ClientTime.hours, ClientTime.mins, ClientTime.seconds)
    SendUiUpdate({ hours = data.hours, mins = data.mins, seconds = data.seconds })
end)

-- Network Event: Update Time (Smooth or Instant)
RegisterNetEvent('ak47_timesync:client:updateTime', function(data, transitionSpeed, forcedInstant)
    if ClientTime.paused then return end
    if forcedInstant then
        ClientTime.forcedInstantTimeUpdate = true
        ClientTime.hours = data.hours
        ClientTime.mins = data.mins
        ClientTime.seconds = data.seconds or 0
        NetworkOverrideClockTime(data.hours, data.mins, data.seconds or 0)
        TriggerEvent('ak47_timesync:client:onLocalTimeUpdated', data.hours, data.mins, data.seconds or 0, false)
    else
        SmoothChangeTime(data, transitionSpeed)
    end
    SendUiUpdate({ hours = data.hours, mins = data.mins, seconds = data.seconds })
end)

-- Network Event: Set Freeze Time
RegisterNetEvent('ak47_timesync:client:setFreezeTime', function(state)
    ClientTime.freeze = state == true
    SendUiUpdate({ freezeTime = state == true })
end)

-- Network Event: Set Minute Duration
RegisterNetEvent('ak47_timesync:client:setMinuteDuration', function(duration)
    SetGameMinuteDuration(duration)
end)

-- Client Clock Lock Thread (Enforces frozen time)
CreateThread(function()
    SetGameMinuteDuration(Config.MinuteDuration or 2000)
    while true do
        if ClientTime.freeze and not ClientTime.paused then
            NetworkOverrideClockTime(ClientTime.hours, ClientTime.mins, ClientTime.seconds)
            Wait(100)
        else
            Wait(1000)
        end
    end
end)
