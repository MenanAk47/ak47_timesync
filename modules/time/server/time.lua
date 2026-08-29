-- ====================================================================
-- Ak47 Time & Weather Sync - Server Time Management
-- ====================================================================

CreateThread(function()
    while true do
        local interval = SyncState.minuteDuration or 2000
        Wait(interval)

        if not SyncState.freezeTime then
            SyncState.mins = SyncState.mins + 1
            if SyncState.mins >= 60 then
                SyncState.mins = 0
                SyncState.hours = (SyncState.hours + 1) % 24
            end

            TriggerClientEvent('ak47_timesync:client:syncTimeTick', -1, {
                hours = SyncState.hours,
                mins = SyncState.mins,
                seconds = SyncState.seconds,
            })
        end
    end
end)

RegisterNetEvent('ak47_timesync:server:setTime', function(hours, mins, seconds, transitionSpeed, forcedInstant)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then
        if src > 0 and Lib47 and Lib47.Notify then Lib47.Notify(src, _U('no_permission'), 'error') end
        return
    end

    local ok = Ak47TimeSync.Server.SetTime(src, hours, mins, seconds, transitionSpeed, forcedInstant)
    if ok and src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, string.format(_U('time_updated'), tonumber(hours), tonumber(mins), 'Smooth'), 'success')
    end
end)

RegisterNetEvent('ak47_timesync:server:toggleFreezeTime', function(state)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    local isFrozen = Ak47TimeSync.Server.SetFreezeTime(src, state)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, string.format(_U('freeze_time_toggled'), isFrozen and _U('enabled') or _U('disabled')), 'info')
    end
end)

