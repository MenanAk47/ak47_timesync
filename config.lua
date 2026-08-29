Lib47 = exports['ak47_lib']:GetLibObject()

Config = {}
Config.Locale = 'en'

--You can set admin in alternative ways-------------------
--Ace Permission
Admin = {}
Admin.WithAce = true
--Or license
Admin.WithLicense = {
    ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
}
--Or identifier
Admin.WithIdentifier = {
    ['xxxxxxxx'] = true,
}
--Or group
Admin.WithGroup = {
    ['superadmin'] = true,
    ['god'] = true,
    ['admin'] = true,
}
----------------------------------------------------------

-- ====================================================================
-- TIME SETTINGS
-- ====================================================================
Config.DefaultTime = {
    hours = 12,
    mins = 0,
    seconds = 0,
}

-- Timescale settings
-- 2000 ms per game minute = 48 real minutes per full in-game 24h day/night cycle.
-- 1000 ms = 24 real minutes per game day.
-- 60000 ms = 24 real hours per game day (1:1 real time).
Config.MinuteDuration = 2000

-- Default Time Transition Speed
Config.DefaultTimeTransitionSpeed = 5       -- Seconds taken to smoothly slide the clock to target time
Config.FreezeTime = false                   -- Freeze time by default

-- ====================================================================
-- WEATHER SETTINGS
-- ====================================================================
Config.DefaultWeather = 'CLEAR'             -- Initial weather upon server boot
Config.DefaultWeatherTransitionSpeed = 10   -- Seconds taken to blend between weather types
Config.FreezeWeather = false                -- Freeze weather by default
Config.Blackout = false                     -- Disable city lighting / blackout mode by default
Config.SnowOnGround = false                 -- Enable vehicle tracks & pedestrian snow footprints

-- Dynamic Weather Automated Cycling
Config.DynamicWeather = true                -- Automatically cycle weather based on probabilistic forecast sequence
Config.NewWeatherTimer = 10                 -- Interval in minutes between automatic weather transitions

-- Atmospheric & Environmental Dynamics
Config.DefaultWindSpeed = 0.0               -- Default wind speed (0 - 12 m/s)
Config.DefaultWindDirection = 0.0           -- Default wind direction (0 - 360 degrees)
Config.DefaultRainLevel = -1.0              -- Default rain level override (-1.0 = auto/game weather default, 0.0 - 1.0 = manual override)


Presets = {}

-- Time Quick Presets
Presets.Times = {
    { id = 'dawn', label = 'Dawn', hours = 6, mins = 0, seconds = 0, icon = 'Sunrise' },
    { id = 'morning', label = 'Morning', hours = 9, mins = 0, seconds = 0, icon = 'SunMedium' },
    { id = 'noon', label = 'Noon', hours = 12, mins = 0, seconds = 0, icon = 'Sun' },
    { id = 'afternoon', label = 'Afternoon', hours = 15, mins = 30, seconds = 0, icon = 'SunMedium' },
    { id = 'sunset', label = 'Sunset', hours = 18, mins = 30, seconds = 0, icon = 'Sunset' },
    { id = 'dusk', label = 'Dusk', hours = 21, mins = 0, seconds = 0, icon = 'MoonStar' },
    { id = 'midnight', label = 'Midnight', hours = 0, mins = 0, seconds = 0, icon = 'Moon' },
    { id = 'night', label = 'Deep Night', hours = 3, mins = 0, seconds = 0, icon = 'Moon' },
}

-- Weather Information, Groupings & Visual Meta for UI
Presets.Weathers = {
    { id = 'EXTRASUNNY', label = 'Extra Sunny', category = 'Clear', icon = 'Sun', color = 'amber', description = 'Intense radiant sunshine with zero cloud cover.' },
    { id = 'CLEAR', label = 'Clear Sky', category = 'Clear', icon = 'SunMedium', color = 'amber', description = 'Pleasant clear sky with light atmospheric breeze.' },
    { id = 'CLOUDS', label = 'Cloudy', category = 'Clouds', icon = 'Cloud', color = 'blue', description = 'Partially overcast with moving cloud formations.' },
    { id = 'OVERCAST', label = 'Overcast', category = 'Clouds', icon = 'Clouds', color = 'slate', description = 'Dense gray skies with minimal sunlight penetration.' },
    { id = 'RAIN', label = 'Rain', category = 'Rain', icon = 'CloudRain', color = 'blue', description = 'Steady rainfall with wet road surfaces.' },
    { id = 'CLEARING', label = 'Clearing', category = 'Rain', icon = 'CloudSun', color = 'emerald', description = 'Rain dissipating with sunlight breaking through.' },
    { id = 'THUNDER', label = 'Thunderstorm', category = 'Rain', icon = 'CloudLightning', color = 'purple', description = 'Severe electrical storm with lightning bolts and heavy rain.' },
    { id = 'SMOG', label = 'Smog', category = 'Atmosphere', icon = 'Wind', color = 'yellow', description = 'Dense urban haze and atmospheric pollution.' },
    { id = 'FOGGY', label = 'Foggy', category = 'Atmosphere', icon = 'CloudFog', color = 'slate', description = 'Thick misty fog drastically reducing long-distance visibility.' },
    { id = 'SNOW', label = 'Snow', category = 'Winter', icon = 'Snowflake', color = 'cyan', description = 'Steady snowfall with drifting flurries.' },
    { id = 'SNOWLIGHT', label = 'Light Snow', category = 'Winter', icon = 'CloudSnow', color = 'cyan', description = 'Gentle dusting of falling snowflakes.' },
    { id = 'BLIZZARD', label = 'Blizzard', category = 'Winter', icon = 'Snowflake', color = 'cyan', description = 'Extreme sub-zero gale with whiteout snow conditions.' },
    { id = 'XMAS', label = 'Christmas Snow', category = 'Winter', icon = 'Gift', color = 'emerald', description = 'Holiday Christmas wonderland with frosted landscapes.' },
    { id = 'HALLOWEEN', label = 'Halloween', category = 'Special', icon = 'Skull', color = 'red', description = 'Eerie orange-green twilight with supernatural lightning strikes.' },
    { id = 'NEUTRAL', label = 'Neutral', category = 'Special', icon = 'CircleDot', color = 'gray', description = 'Neutral standard lighting test state.' },
}


WeatherCycles = {}

-- All Valid GTA V Weather Types
WeatherCycles.WeatherTypes = {
    'EXTRASUNNY',
    'CLEAR',
    'CLOUDS',
    'OVERCAST',
    'RAIN',
    'CLEARING',
    'THUNDER',
    'SMOG',
    'FOGGY',
    'XMAS',
    'SNOW',
    'SNOWLIGHT',
    'BLIZZARD',
    'HALLOWEEN',
    'NEUTRAL',
}

-- Probabilistic Next Weather Transitions for Dynamic Cycling
WeatherCycles.Transitions = {
    ['EXTRASUNNY'] = {
        { weather = 'CLEAR', weight = 55 },
        { weather = 'CLOUDS', weight = 25 },
        { weather = 'SMOG', weight = 20 },
    },
    ['CLEAR'] = {
        { weather = 'EXTRASUNNY', weight = 40 },
        { weather = 'CLOUDS', weight = 40 },
        { weather = 'OVERCAST', weight = 20 },
    },
    ['CLOUDS'] = {
        { weather = 'CLEAR', weight = 30 },
        { weather = 'OVERCAST', weight = 40 },
        { weather = 'SMOG', weight = 20 },
        { weather = 'FOGGY', weight = 10 },
    },
    ['OVERCAST'] = {
        { weather = 'RAIN', weight = 45 },
        { weather = 'CLOUDS', weight = 30 },
        { weather = 'CLEARING', weight = 15 },
        { weather = 'FOGGY', weight = 10 },
    },
    ['RAIN'] = {
        { weather = 'THUNDER', weight = 30 },
        { weather = 'CLEARING', weight = 45 },
        { weather = 'OVERCAST', weight = 25 },
    },
    ['THUNDER'] = {
        { weather = 'RAIN', weight = 50 },
        { weather = 'CLEARING', weight = 50 },
    },
    ['CLEARING'] = {
        { weather = 'CLOUDS', weight = 40 },
        { weather = 'CLEAR', weight = 40 },
        { weather = 'EXTRASUNNY', weight = 20 },
    },
    ['SMOG'] = {
        { weather = 'FOGGY', weight = 35 },
        { weather = 'CLEAR', weight = 35 },
        { weather = 'CLOUDS', weight = 30 },
    },
    ['FOGGY'] = {
        { weather = 'SMOG', weight = 30 },
        { weather = 'OVERCAST', weight = 40 },
        { weather = 'CLOUDS', weight = 30 },
    },
    ['XMAS'] = {
        { weather = 'SNOW', weight = 40 },
        { weather = 'SNOWLIGHT', weight = 40 },
        { weather = 'BLIZZARD', weight = 20 },
    },
    ['SNOW'] = {
        { weather = 'SNOWLIGHT', weight = 50 },
        { weather = 'XMAS', weight = 30 },
        { weather = 'BLIZZARD', weight = 20 },
    },
    ['SNOWLIGHT'] = {
        { weather = 'SNOW', weight = 45 },
        { weather = 'XMAS', weight = 35 },
        { weather = 'CLEAR', weight = 20 },
    },
    ['BLIZZARD'] = {
        { weather = 'SNOW', weight = 60 },
        { weather = 'SNOWLIGHT', weight = 40 },
    },
    ['HALLOWEEN'] = {
        { weather = 'HALLOWEEN', weight = 70 },
        { weather = 'FOGGY', weight = 20 },
        { weather = 'THUNDER', weight = 10 },
    },
    ['NEUTRAL'] = {
        { weather = 'CLEAR', weight = 60 },
        { weather = 'EXTRASUNNY', weight = 40 },
    },
}

-- Returns the next probabilistic weather state
function WeatherCycles.GetNextWeather(currentWeather)
    local transitions = WeatherCycles.Transitions[currentWeather]
    if not transitions or #transitions == 0 then
        return 'CLEAR'
    end

    local totalWeight = 0
    for _, t in ipairs(transitions) do
        totalWeight = totalWeight + (t.weight or 1)
    end

    local randomNum = math.random(1, totalWeight)
    local currentWeight = 0

    for _, t in ipairs(transitions) do
        currentWeight = currentWeight + (t.weight or 1)
        if randomNum <= currentWeight then
            return t.weather
        end
    end

    return transitions[1].weather or 'CLEAR'
end
