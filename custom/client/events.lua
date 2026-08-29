-- ====================================================================
-- Ak47 Time & Weather Sync - Client-Side Custom Events & Hooks
-- ====================================================================

--- Triggered locally whenever the client time transitions
--- @param hours number New hour
--- @param mins number New minute
--- @param seconds number New second
--- @param isSmooth boolean Whether this was an interpolated transition
AddEventHandler('ak47_timesync:client:onLocalTimeUpdated', function(hours, mins, seconds, isSmooth)
    -- Custom actions (e.g. adjust lighting, ambient sounds) can be placed here
end)

--- Triggered locally whenever the client weather transitions
--- @param weatherType string New weather condition
--- @param transitionDuration number Transition length in seconds
AddEventHandler('ak47_timesync:client:onLocalWeatherUpdated', function(weatherType, transitionDuration)
    -- Custom actions (e.g. particle effects, vehicle wetness handling) can be placed here
end)

--- Triggered locally whenever blackout state changes
--- @param state boolean Blackout active
AddEventHandler('ak47_timesync:client:onLocalBlackoutUpdated', function(state)
    -- Custom actions (e.g. alarm sounds, emergency vehicle siren triggers)
end)
