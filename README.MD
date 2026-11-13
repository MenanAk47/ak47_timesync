# AK47 Time & Weather Sync

[![Discord](https://img.shields.io/badge/Discord-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/menanak47)
[![Support](https://img.shields.io/badge/Support-Community-blue?style=flat-square)](https://discord.gg/menanak47)

High-performance, modern Time and Weather synchronization resource for FiveM with smooth time interpolation, probabilistic dynamic weather cycles, environmental FX (blackout, snow footprints, wind physics), multi-framework admin UI, and 100% drop-in compatibility for existing scripts.

---
![image](https://github.com/user-attachments/assets/19b002f3-ac7e-446d-b9b7-9976ce08840c)
---

## ⚡ Features

- **Smooth Clock Transitions & Custom Timescales:** Interpolates in-game clock across the shortest 24h circular path with full support for custom timescales (e.g. `Config.MinuteDuration = 60000` for 1:1 real-time 24h cycle) and zero clock/sky snapping.
- **Probabilistic Dynamic Weather:** Realistic Markov-chain weather forecast cycles with weighted transitions.
- **Zone-Based Dynamic Weather:** Partitions San Andreas into 7 seamless geographic PolyZones powered by `ak47_lib` (`Lib47.Zones.Poly`) with meteorological front propagation (`Current`, `Next`, and `Previous` wave states).
- **Mount Chiliad Alpine Everest Elevation:** Multi-tier height-based weather layer scaling smoothly into high-altitude fog, sub-zero snow, and summit whiteout blizzards ($Z > 700\text{m}$).
- **Environmental Controls:** City-wide blackout, persistent snow tracks/footprints, wind speed and heading physics.
- **Modern NUI Admin Center:** Sleek React 18 + Tailwind UI with live zone overview chips, zone weather toggle, sound feedback, instant presets, and fine sliders.
- **Multi-Framework Permission System:** Native support for Ace Permissions, ESX, QBCore, Qbox, License, or Identifiers.
- **Discord Webhook Logging:** Embedded logs for time, weather, blackout, and freeze modifications.
- **100% Drop-In Replacement:** Provides native export & event compatibility for `qb-weathersync`, `qbx_weathersync`, `cd_easytime`, `vSync`, and `vSyncR`.
- **Ultra Low Resmon:** `0.00ms` idle client execution (leveraging C-level GLM spatial grids).


---

## 📦 Dependencies & Installation

1. Ensure **`ak47_lib`** is installed and started before this resource.
2. Place `ak47_timesync` into your server's `resources` directory.
3. Add to your `server.cfg`:
```cfg
ensure ak47_lib
ensure ak47_timesync
```
*(Optional)* If replacing `qb-weathersync`, `cd_easytime`, or `vSync`, you can remove or disable them. `ak47_timesync` provides all their exports and network events automatically.

---

## 🔑 Permissions Setup

Configure admin access in `config.lua`:

```lua
Admin = {}
Admin.WithAce = true                    -- Use FiveM Ace permissions
Admin.WithLicense = {
    ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
}
Admin.WithIdentifier = {
    ['fivem:xxxxxxxx'] = true,
}
Admin.WithGroup = {
    ['superadmin'] = true,
    ['god'] = true,
    ['admin'] = true,
}
```

---

## 🎮 Chat Commands

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `/timesync` | None | Open Time & Weather Admin Panel UI |
| `/weather` | `<WEATHER_TYPE>` | Set weather (`CLEAR`, `EXTRASUNNY`, `RAIN`, `THUNDER`, `XMAS`, etc.) |
| `/zoneweather` | `<zoneId\|ALL> <WEATHER_TYPE>` | Set weather for a specific zone (`LS_SOUTH`, `DESERT`, `MOUNT_CHILIAD`, etc.) |
| `/time` | `<hour> [minute]` | Set server clock time (0-23, 0-59) |

| `/freezetime` | None | Toggle global clock freeze |
| `/freezeweather` | None | Toggle global weather freeze |
| `/blackout` | None | Toggle city blackout mode |
| `/morning` | None | Quick set time to 09:00 |
| `/noon` | None | Quick set time to 12:00 |
| `/evening` | None | Quick set time to 18:30 |
| `/night` | None | Quick set time to 00:00 |

---

## 🛠️ API & Exports Reference

### Server-Side Exports

```lua
-- Get Time (returns table: { hours, mins, seconds, hour, minute, [1] = hours, [2] = mins })
local time = exports['ak47_timesync']:GetTime()
print(('Current Time: %02d:%02d'):format(time.hour, time.minute))

-- Set Time (hours, mins, seconds, transitionSpeedSec, instantSnap)
exports['ak47_timesync']:SetTime(12, 0, 0, 5, false)

-- Timescale / Minute Duration (ms per in-game minute)
local durationMs = exports['ak47_timesync']:GetMinuteDuration() -- returns ms (default 2000)
exports['ak47_timesync']:SetMinuteDuration(60000)               -- set to 60000 for 1:1 real-time sync

-- Get & Set Weather
local weather = exports['ak47_timesync']:GetWeather() -- returns string (e.g. 'CLEAR')
exports['ak47_timesync']:SetWeather('RAIN', 10, false) -- weather, durationSeconds, instant

-- Next Weather Forecast
local nextWeather = exports['ak47_timesync']:GetNextWeather()
exports['ak47_timesync']:NextWeatherStage()

-- Set & Toggle Environment Features
exports['ak47_timesync']:SetBlackout(true)           -- Enable city blackout
exports['ak47_timesync']:SetFreezeTime(true)         -- Freeze time
exports['ak47_timesync']:SetFreezeWeather(true)      -- Freeze weather
exports['ak47_timesync']:SetDynamicWeather(true)     -- Enable dynamic cycling
exports['ak47_timesync']:SetSnowTracks(true)         -- Enable snow tracks
exports['ak47_timesync']:SetRainLevel(0.8)           -- Override rain intensity (-1.0 = auto, 0.0 - 1.0 = custom)

-- Zone-Based Weather Exports (Server)
exports['ak47_timesync']:SetZoneWeatherEnabled(true)                     -- Enable 7-Zone Dynamic Weather
exports['ak47_timesync']:SetZoneWeather('DESERT', 'THUNDER', 10, false)  -- Set specific zone weather
local allZones = exports['ak47_timesync']:GetAllZoneWeathers()           -- Get all zone states

-- Full Snapshot
local state = exports['ak47_timesync']:GetFullState()
```

### Client-Side Exports

```lua
-- Get Time & Timescale
local time = exports['ak47_timesync']:GetTime()
local minuteDuration = exports['ak47_timesync']:GetMinuteDuration()

-- Get Weather, Blackout & Rain
local weather = exports['ak47_timesync']:GetWeather()
local isBlackout = exports['ak47_timesync']:GetBlackout()
local rainLevel = exports['ak47_timesync']:GetRainLevel()

-- Zone-Based Weather Queries (Client)
local isZoneMode = exports['ak47_timesync']:IsZoneWeatherEnabled()
local zoneId, zoneLabel = exports['ak47_timesync']:GetCurrentZone()      -- e.g. 'DESERT', 'Grand Senora Desert'
local isInsideChiliad, tier = exports['ak47_timesync']:IsInsideChiliad() -- true if on Mount Chiliad elevation

-- Pause Sync Locally (for clothing stores, apartment cutscenes, etc.)

exports['ak47_timesync']:SetPauseSync(true, 20) -- pauses sync and sets client hour to 20:00
exports['ak47_timesync']:SetPauseSync(false)    -- resumes server sync

-- Check if Sync is Paused
local isPaused = exports['ak47_timesync']:IsSyncPaused()
```

---

## 🔄 Drop-In Compatibility

`ak47_timesync` provides built-in compatibility for other sync systems. All calls to the following exports and net events work seamlessly without modifying your existing scripts:

- **`qb-weathersync` / `qbx_weathersync`:** `getWeatherState`, `getTimeState`, `getBlackoutState`, `getTimeFreezeState`, `setWeather`, `setTime`, `setBlackout`, `setTimeFreeze`, etc.
- **`cd_easytime`:** `GetWeather`, `GetTime`, `GetPauseSyncState`, `SetPauseSync`, `TogglePauseSync`, `GetAllData`, `GetRealData`, etc.
- **`vSync` / `vSyncR`:** `getWeather`, `getTime`, `updateWeather`, `updateTime`, `toggle`, etc.
- **`esx_weather`:** `ToggleWeatherSync`, `ToggleTimeSync`, `esx_weather:server:setZoneWeather`, `esx_weather:client:time:setTime`, etc.

---

## 🔔 Discord Webhook Setup

Configure `webhooks.lua`:
```lua
Webhooks = {
    enabled = true,
    url = 'https://discord.com/api/webhooks/...',
    botName = 'AK47 Time & Weather Sync',
    avatar = 'https://i.imgur.com/8Q9j9sZ.png',
}
```

---


## 📄 License & Credits

- Developed by **MenanAk47**
- **Support & Discord:** [discord.gg/menanak47](https://discord.gg/menanak47)
