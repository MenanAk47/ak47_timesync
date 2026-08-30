-- ====================================================================
-- Ak47 Time & Weather Sync - Client Zone-Based Weather & Mount Chiliad
-- Hybrid Point-in-Polygon Engine
-- ====================================================================

ClientZoneWeather = {
    enabled = (Config.ZoneWeather and Config.ZoneWeather.Enabled == true) or false,
    zones = {},
    currentZoneId = 'LS_SOUTH',
    currentZoneLabel = 'Los Santos South & Harbor',
    chiliadTier = 0,
    chiliadZone = nil,
    polyZones = {},
}

--- Print debug info to client F8 console when debug mode is enabled
local function DebugPrintZoneWeather(zoneId, zoneLabel, weather, details)
    if Config.ZoneWeather and Config.ZoneWeather.Debug then
        print(("^2[ak47_timesync] [ZONE WEATHER]^0 Zone: ^3%s^0 (%s) | Weather: ^5%s^0%s"):format(
            tostring(zoneId),
            tostring(zoneLabel),
            tostring(weather),
            details and (' | ' .. tostring(details)) or ''
        ))
    end
end

--- 2D Ray-Casting Point in Polygon algorithm (100% elevation independent and robust)
local function IsPointInPolygon2D(px, py, points)
    if not points or #points < 3 then return false end
    local numPoints = #points
    local inside = false
    local j = numPoints

    for i = 1, numPoints do
        local xi, yi = points[i].x or points[i][1], points[i].y or points[i][2]
        local xj, yj = points[j].x or points[j][1], points[j].y or points[j][2]

        if ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end

    return inside
end

--- Get Zone ID, Label, and Altitude Tier for given coordinates
function ClientZoneWeather.GetZoneAtCoords(coords)
    if not coords then
        local ped = PlayerPedId()
        coords = GetEntityCoords(ped)
    end

    -- 1. Check Mount Chiliad Altitude Massif
    if Config.ZoneWeather and Config.ZoneWeather.MountChiliad and Config.ZoneWeather.MountChiliad.enabled then
        local mc = Config.ZoneWeather.MountChiliad
        if IsPointInPolygon2D(coords.x, coords.y, mc.points) then
            local z = coords.z
            local tiers = mc.tiers or {}
            for idx, t in ipairs(tiers) do
                if z >= t.minZ and z < t.maxZ then
                    return 'MOUNT_CHILIAD', ('Mount Chiliad (%s)'):format(t.label), idx, t
                end
            end
        end
    end

    -- 2. Check the 7 Map PolyZones
    local matches = {}
    local highestPriority = -999999
    local currentZoneStillMatches = false
    local currentZonePriority = 1

    local zones = Config.ZoneWeather and Config.ZoneWeather.Zones or {}
    for _, z in ipairs(zones) do
        if IsPointInPolygon2D(coords.x, coords.y, z.points) then
            local prio = z.priority or 1
            matches[#matches + 1] = {
                id = z.id,
                label = z.label,
                priority = prio,
                biome = z.biome,
            }
            if prio > highestPriority then
                highestPriority = prio
            end
            if z.id == ClientZoneWeather.currentZoneId then
                currentZoneStillMatches = true
                currentZonePriority = prio
            end
        end
    end

    -- If no polygon matched, fallback to default
    if #matches == 0 then
        return ClientZoneWeather.currentZoneId or 'LS_SOUTH', ClientZoneWeather.currentZoneLabel or 'Los Santos South & Harbor', 0, nil
    end

    -- Hysteresis: If current zone still contains player and has equal priority, keep it
    if currentZoneStillMatches and currentZonePriority >= highestPriority then
        return ClientZoneWeather.currentZoneId, ClientZoneWeather.currentZoneLabel, 0, nil
    end

    -- Return highest priority match
    for _, match in ipairs(matches) do
        if match.priority == highestPriority then
            return match.id, match.label, 0, nil
        end
    end

    return matches[1].id, matches[1].label, 0, nil
end

--- Update active zone and apply weather smoothly
local function UpdateCurrentZoneLocation(forceApply)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local zoneId, zoneLabel, chiliadTier, tierData = ClientZoneWeather.GetZoneAtCoords(coords)

    local wasChiliad = (ClientZoneWeather.chiliadTier > 0)
    local isChiliadNow = (chiliadTier > 0)
    local isPaused = ClientWeather and (ClientWeather.paused or ClientWeather.freeze)

    if isChiliadNow and tierData then
        if forceApply or ClientZoneWeather.chiliadTier ~= chiliadTier or ClientZoneWeather.currentZoneId ~= 'MOUNT_CHILIAD' then
            ClientZoneWeather.chiliadTier = chiliadTier
            ClientZoneWeather.currentZoneId = 'MOUNT_CHILIAD'
            ClientZoneWeather.currentZoneLabel = zoneLabel

            if ClientZoneWeather.enabled and not isPaused then
                local blendDuration = forcedInstant and 0 or (Config.ZoneWeather.TransitionDuration or 10)
                ApplyClientWeather(tierData.weather, blendDuration, forcedInstant == true)
                if tierData.windSpeed then
                    SetWind(tierData.windSpeed + 0.0)
                    SetWindSpeed(tierData.windSpeed + 0.0)
                end
                if tierData.snowTracks ~= nil then
                    SetForceVehicleTrails(tierData.snowTracks == true)
                    SetForcePedFootstepsTracks(tierData.snowTracks == true)
                end
            end

            DebugPrintZoneWeather('MOUNT_CHILIAD', zoneLabel, tierData.weather, ('Alt: %.1fm | Wind: %.1fm/s'):format(coords.z, tierData.windSpeed or 0.0))

            SendUiUpdate({
                currentZone = 'MOUNT_CHILIAD',
                currentZoneLabel = zoneLabel,
                weather = tierData.weather,
            })
        end
    else
        if wasChiliad then
            ClientZoneWeather.chiliadTier = 0
            -- Restore baseline global wind speed and direction
            local baseWind = (ClientWeather and ClientWeather.windSpeed) or 0.0
            local baseWindDir = (ClientWeather and ClientWeather.windDirection) or 0.0
            SetWind(baseWind + 0.0)
            SetWindSpeed(baseWind + 0.0)
            SetWindDirection(baseWindDir + 0.0)
            DebugPrintZoneWeather('MOUNT_CHILIAD', 'Exited Elevation Tier', 'Restoring Regional Weather & Wind', ('Alt: %.1fm | Wind: %.1fm/s'):format(coords.z, baseWind))
        end

        local zoneState = ClientZoneWeather.zones[zoneId]
        local targetWeather = (zoneState and zoneState.current) or ClientWeather.current or 'CLEAR'
        local blendDuration = forcedInstant and 0 or ((zoneState and zoneState.transitionDuration) or (Config.ZoneWeather and Config.ZoneWeather.TransitionDuration) or 12)

        if forceApply or ClientZoneWeather.currentZoneId ~= zoneId or wasChiliad then
            ClientZoneWeather.currentZoneId = zoneId
            ClientZoneWeather.currentZoneLabel = zoneLabel

            if ClientZoneWeather.enabled and not isPaused then
                ApplyClientWeather(targetWeather, blendDuration, forcedInstant == true)
            end

            DebugPrintZoneWeather(zoneId, zoneLabel, targetWeather, ('Transition: %ds'):format(blendDuration))

            SendUiUpdate({
                currentZone = zoneId,
                currentZoneLabel = zoneLabel,
                weather = targetWeather,
                nextWeather = zoneState and zoneState.next or ClientWeather.next,
            })
        elseif ClientZoneWeather.enabled and not isPaused and ClientWeather.current ~= targetWeather then
            -- Zone weather was updated (e.g. admin changed zone weather or dynamic cycle) while player stayed in the same zone
            ApplyClientWeather(targetWeather, blendDuration, forcedInstant == true)
            SendUiUpdate({
                currentZone = zoneId,
                currentZoneLabel = zoneLabel,
                weather = targetWeather,
                nextWeather = zoneState and zoneState.next or ClientWeather.next,
            })
        end
    end
end

ClientZoneWeather.EvaluateActiveZone = UpdateCurrentZoneLocation
ClientZoneWeather.UpdateCurrentZoneLocation = UpdateCurrentZoneLocation

-- On-demand initialization of Lib47.Zones.Poly instances for 3D Debugging visualization
local polyZonesInitialized = false
local function InitDebugPolyZones()
    if polyZonesInitialized or not Lib47 or not Lib47.Zones or not Lib47.Zones.Poly then
        return
    end

    local isDebug = Config.ZoneWeather and Config.ZoneWeather.Debug == true

    -- Initialize Mount Chiliad PolyZone
    if Config.ZoneWeather and Config.ZoneWeather.MountChiliad then
        local mc = Config.ZoneWeather.MountChiliad
        ClientZoneWeather.chiliadZone = Lib47.Zones.Poly({
            name = 'MOUNT_CHILIAD_MASSIF',
            points = mc.points,
            minZ = mc.minZ or 300.0,
            maxZ = mc.maxZ or 1500.0,
            thickness = (mc.maxZ or 1500.0) - (mc.minZ or 300.0),
            debug = isDebug,
        })
    end

    -- Initialize the 7 Map PolyZones
    if Config.ZoneWeather and Config.ZoneWeather.Zones then
        for _, z in ipairs(Config.ZoneWeather.Zones) do
            local zoneObj = Lib47.Zones.Poly({
                name = z.id,
                points = z.points,
                minZ = z.minZ or -200.0,
                maxZ = z.maxZ or 2500.0,
                thickness = (z.maxZ or 2500.0) - (z.minZ or -200.0),
                debug = isDebug,
            })

            ClientZoneWeather.polyZones[z.id] = {
                id = z.id,
                label = z.label,
                zoneObj = zoneObj,
                biome = z.biome,
                priority = z.priority or 1,
            }
        end
    end

    polyZonesInitialized = true
end

-- If debug was pre-configured, initialize debug visualizers
CreateThread(function()
    Wait(500)
    if Config.ZoneWeather and Config.ZoneWeather.Debug then
        InitDebugPolyZones()
    end
end)

-- Adaptive Spatial Location Tracker
CreateThread(function()
    while true do
        if ClientZoneWeather.enabled then
            UpdateCurrentZoneLocation()

            -- Adapt check rate based on player movement speed
            local ped = PlayerPedId()
            local speed = GetEntitySpeed(ped) -- m/s (0 = stationary, 10 = ~36 km/h, 30+ = >108 km/h)

            local sleepTime = 1500 -- Standing still or walking: check every 1.5s
            if speed > 25.0 then
                sleepTime = Config.ZoneWeather and Config.ZoneWeather.CheckInterval or 500 -- Aircraft / high-speed vehicles
            elseif speed > 5.0 then
                sleepTime = Config.ZoneWeather and Config.ZoneWeather.CheckInterval or 750 -- Driving
            end

            Wait(sleepTime)
        else
            -- When zone weather is disabled, sleep 2.5s (0.00ms resmon impact)
            Wait(2500)
        end
    end
end)

-- ====================================================================
-- Net Events & Handshake
-- ====================================================================
RegisterNetEvent('ak47_timesync:client:syncZoneWeather', function(data)
    if not data then return end

    local wasEnabled = ClientZoneWeather.enabled
    ClientZoneWeather.enabled = data.enabled == true
    ClientZoneWeather.zones = data.zones or ClientZoneWeather.zones

    if ClientZoneWeather.enabled then
        UpdateCurrentZoneLocation(true)
    elseif wasEnabled and not ClientZoneWeather.enabled then
        -- Reset back to global master weather
        ClientZoneWeather.chiliadTier = 0
        local baseWind = (ClientWeather and ClientWeather.windSpeed) or 0.0
        local baseWindDir = (ClientWeather and ClientWeather.windDirection) or 0.0
        SetWind(baseWind + 0.0)
        SetWindSpeed(baseWind + 0.0)
        SetWindDirection(baseWindDir + 0.0)
        if ClientWeather and ClientWeather.current then
            ApplyClientWeather(ClientWeather.current, 10, false)
        end
    end

    SendUiUpdate({
        zoneWeatherEnabled = ClientZoneWeather.enabled,
        zones = ClientZoneWeather.zones,
        currentZone = ClientZoneWeather.currentZoneId,
        currentZoneLabel = ClientZoneWeather.currentZoneLabel,
    })
end)

-- ====================================================================
-- Debug Chat Command: /zonedebug
-- ====================================================================
RegisterCommand('zonedebug', function()
    Config.ZoneWeather.Debug = not (Config.ZoneWeather and Config.ZoneWeather.Debug == true)
    local isDbg = Config.ZoneWeather.Debug

    if isDbg and not polyZonesInitialized then
        InitDebugPolyZones()
    end

    -- Update debug wireframes on all initialized zones
    if ClientZoneWeather.chiliadZone and ClientZoneWeather.chiliadZone.setDebug then
        ClientZoneWeather.chiliadZone:setDebug(isDbg)
    end
    for _, zData in pairs(ClientZoneWeather.polyZones or {}) do
        if zData.zoneObj and zData.zoneObj.setDebug then
            zData.zoneObj:setDebug(isDbg)
        end
    end

    UpdateCurrentZoneLocation()

    local curZone = ClientZoneWeather.currentZoneId or 'NONE'
    local curLabel = ClientZoneWeather.currentZoneLabel or 'Unknown'
    local curWeather = ClientWeather and ClientWeather.current or 'CLEAR'
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    print(("^2[ak47_timesync] Zone Weather Debug: ^3%s^0 | Active: ^3%s^0"):format(
        isDbg and '^2ENABLED^0' or '^1DISABLED^0',
        ClientZoneWeather.enabled and '^2YES^0' or '^1NO^0'
    ))
    print(("^2[ak47_timesync] Current Zone: ^3%s^0 (%s) | Weather: ^5%s^0 | Altitude: ^5%.1fm^0"):format(
        curZone, curLabel, curWeather, coords.z
    ))

    if Lib47 and Lib47.Notify then
        Lib47.Notify(0, ('Zone Debug: %s | Zone: %s (%s)'):format(isDbg and 'ON' or 'OFF', curZone, curWeather), isDbg and 'info' or 'error')
    end
end, false)
