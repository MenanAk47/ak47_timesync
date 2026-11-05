-- ====================================================================
-- Ak47 Time & Weather Sync - Server Zone-Based Weather Engine
-- ====================================================================

ZoneWeather = {
    enabled = (SyncState and SyncState.zoneWeatherEnabled == true) or (Config.ZoneWeather and Config.ZoneWeather.Enabled == true) or false,
    zones = {},
    history = {},
}


-- Biome compatibility mapping to ensure realistic local climates
local BIOME_WEATHER_RULES = {
    ['arid_desert'] = {
        ['SNOW'] = 'CLEAR',
        ['SNOWLIGHT'] = 'CLOUDS',
        ['BLIZZARD'] = 'FOGGY',
        ['XMAS'] = 'CLEAR',
        ['RAIN'] = 'THUNDER',
    },
    ['coastal_urban'] = {
        ['BLIZZARD'] = 'FOGGY',
    },
    ['urban_hills'] = {
        ['BLIZZARD'] = 'SNOWLIGHT',
    },
}

local function AdaptWeatherToBiome(weather, biome)
    if not biome or not BIOME_WEATHER_RULES[biome] then return weather end
    local override = BIOME_WEATHER_RULES[biome][weather]
    return override or weather
end

-- Initialize Zone States from Config
function ZoneWeather.Init()
    local defaultW = SyncState and SyncState.weather or Config.DefaultWeather or 'CLEAR'
    local nextW = SyncState and SyncState.nextWeather or 'CLEAR'

    ZoneWeather.zones = {}

    if Config.ZoneWeather and Config.ZoneWeather.Zones then
        for idx, z in ipairs(Config.ZoneWeather.Zones) do
            local baseWeather = defaultW
            -- Alternate slightly between zones to create a living world from start
            if idx % 3 == 0 then
                baseWeather = nextW
            elseif idx % 3 == 2 and WeatherCycles and WeatherCycles.GetNextWeather then
                baseWeather = WeatherCycles.GetNextWeather(defaultW)
            end

            baseWeather = AdaptWeatherToBiome(baseWeather, z.biome)
            local zoneNext = WeatherCycles and WeatherCycles.GetNextWeather and WeatherCycles.GetNextWeather(baseWeather) or 'CLEAR'
            zoneNext = AdaptWeatherToBiome(zoneNext, z.biome)

            ZoneWeather.zones[z.id] = {
                id = z.id,
                label = z.label,
                current = baseWeather,
                next = zoneNext,
                previous = defaultW,
                transitionDuration = Config.ZoneWeather.TransitionDuration or 12,
            }
        end
    end
end

ZoneWeather.Init()

--- Propagate dynamic weather front across the 7 zones
function ZoneWeather.AdvanceFront()
    if not ZoneWeather.enabled then return end

    local currentMaster = SyncState.weather or 'CLEAR'
    local nextMaster = SyncState.nextWeather or 'CLEAR'
    local futureMaster = WeatherCycles and WeatherCycles.GetNextWeather and WeatherCycles.GetNextWeather(nextMaster) or 'CLEAR'

    -- Wind heading dictates propagation vector (South to North or North to South)
    local windDir = SyncState.windDirection or 0.0
    local southToNorth = (windDir >= 315 or windDir <= 135)

    local zoneList = Config.ZoneWeather and Config.ZoneWeather.Zones or {}
    local total = #zoneList

    for idx, z in ipairs(zoneList) do
        local state = ZoneWeather.zones[z.id]
        if state then
            local posRatio = southToNorth and (idx / total) or ((total - idx + 1) / total)
            local assignedWeather = currentMaster

            if posRatio < 0.35 then
                assignedWeather = currentMaster
            elseif posRatio < 0.70 then
                assignedWeather = nextMaster
            else
                assignedWeather = futureMaster
            end

            assignedWeather = AdaptWeatherToBiome(assignedWeather, z.biome)
            local zoneNext = AdaptWeatherToBiome(futureMaster, z.biome)

            state.previous = state.current
            state.current = assignedWeather
            state.next = zoneNext
            state.transitionDuration = Config.ZoneWeather.TransitionDuration or 12
        end
    end

    ZoneWeather.Broadcast()
end

--- Broadcast zone state table to all clients or a specific source
function ZoneWeather.Broadcast(targetSource, forcedInstant)
    local target = targetSource or -1
    TriggerClientEvent('ak47_timesync:client:syncZoneWeather', target, {
        enabled = ZoneWeather.enabled,
        zones = ZoneWeather.zones,
        transitionDuration = Config.ZoneWeather.TransitionDuration or 12,
        instant = forcedInstant == true,
    })
end

--- Toggle Zone-Based Weather Mode
function ZoneWeather.SetEnabled(source, state)
    local isEnabled = (state == nil) and not ZoneWeather.enabled or (state == true)
    ZoneWeather.enabled = isEnabled
    SyncState.zoneWeatherEnabled = isEnabled

    if SyncState.SaveSettings then SyncState.SaveSettings() end
    ZoneWeather.Broadcast()

    TriggerEvent('ak47_timesync:server:onZoneWeatherToggled', source, isEnabled)
    return isEnabled
end

--- Set weather for a specific zone or ALL zones
function ZoneWeather.SetZoneWeather(source, zoneId, weatherType, transitionDuration, forcedInstant)
    weatherType = string.upper(tostring(weatherType))
    local duration = tonumber(transitionDuration) or Config.ZoneWeather.TransitionDuration or 12

    if zoneId == 'ALL' or zoneId == 'all' or not zoneId then
        for _, z in ipairs(Config.ZoneWeather.Zones or {}) do
            local adapted = AdaptWeatherToBiome(weatherType, z.biome)
            if ZoneWeather.zones[z.id] then
                ZoneWeather.zones[z.id].previous = ZoneWeather.zones[z.id].current
                ZoneWeather.zones[z.id].current = adapted
                ZoneWeather.zones[z.id].next = WeatherCycles and WeatherCycles.GetNextWeather and WeatherCycles.GetNextWeather(adapted) or 'CLEAR'
                ZoneWeather.zones[z.id].transitionDuration = duration
            end
        end
    else
        local zone = ZoneWeather.zones[zoneId]
        if zone then
            zone.previous = zone.current
            zone.current = weatherType
            zone.next = WeatherCycles and WeatherCycles.GetNextWeather and WeatherCycles.GetNextWeather(weatherType) or 'CLEAR'
            zone.transitionDuration = duration
        end
    end

    ZoneWeather.Broadcast(nil, forcedInstant)
    TriggerEvent('ak47_timesync:server:onZoneWeatherChanged', source, zoneId, weatherType, duration)
    return true
end

-- ====================================================================
-- Dynamic Weather Hook & Periodic Sync
-- ====================================================================
AddEventHandler('ak47_timesync:server:onDynamicWeatherCycle', function()
    if ZoneWeather.enabled and not SyncState.freezeWeather then
        ZoneWeather.AdvanceFront()
    end
end)

-- ====================================================================
-- Net Events
-- ====================================================================
RegisterNetEvent('ak47_timesync:server:toggleZoneWeather', function(state)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    local isEnabled = ZoneWeather.SetEnabled(src, state)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('zone_weather_toggled', isEnabled and _U('enabled') or _U('disabled')), 'info')
    end
end)

RegisterNetEvent('ak47_timesync:server:setZoneWeather', function(zoneId, weatherType, transitionDuration, forcedInstant)
    local src = source
    if not Ak47TimeSync.Server.HasPermission(src) then return end
    ZoneWeather.SetZoneWeather(src, zoneId, weatherType, transitionDuration, forcedInstant)
    if src > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(src, _U('zone_weather_updated', tostring(zoneId), tostring(weatherType)), 'success')
    end
end)

-- Chat Command for Zone Weather
RegisterCommand('zoneweather', function(source, args, rawCommand)
    if not Ak47TimeSync.Server.HasPermission(source) then
        if source > 0 and Lib47 and Lib47.Notify then Lib47.Notify(source, _U('no_permission'), 'error') end
        return
    end

    local zoneId = args[1] and string.upper(args[1])
    local weatherType = args[2] and string.upper(args[2])

    if not zoneId or not weatherType then
        if source > 0 and Lib47 and Lib47.Notify then
            Lib47.Notify(source, 'Usage: /zoneweather [zoneId|ALL] [weatherType]', 'error')
        else
            print('^1[ak47_timesync] Usage: /zoneweather [zoneId|ALL] [weatherType]^0')
        end
        return
    end

    ZoneWeather.SetZoneWeather(source, zoneId, weatherType)
    if source > 0 and Lib47 and Lib47.Notify then
        Lib47.Notify(source, _U('zone_weather_updated', zoneId, weatherType), 'success')
    end
end, false)
