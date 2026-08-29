# AK47 Time & Weather Sync

High-performance, modern Time and Weather synchronization resource for FiveM with smooth time interpolation, probabilistic dynamic weather cycles, environmental FX (blackout, snow footprints, wind physics), multi-framework admin UI, and 100% drop-in compatibility for existing scripts.

---
![image](https://github.com/user-attachments/assets/19b002f3-ac7e-446d-b9b7-9976ce08840c)
---

## ⚡ Features

- **Smooth Clock Transitions:** Interpolates in-game clock across the shortest 24h circular path.
- **Probabilistic Dynamic Weather:** Realistic Markov-chain weather forecast cycles with weighted transitions.
- **Environmental Controls:** City-wide blackout, persistent snow tracks/footprints, wind speed and heading physics.
- **Modern NUI Admin Center:** Sleek React 18 + Tailwind UI with sound feedback, instant presets, and fine sliders.
- **Multi-Framework Permission System:** Native support for Ace Permissions, ESX, QBCore, Qbox, License, or Identifiers.
- **Discord Webhook Logging:** Embedded logs for time, weather, blackout, and freeze modifications.
- **100% Drop-In Replacement:** Provides native export & event compatibility for `qb-weathersync`, `qbx_weathersync`, `cd_easytime`, `vSync`, and `vSyncR`.
- **Ultra Low Resmon:** `0.00ms` idle client execution.

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

-- Get & Set Weather
local weather = exports['ak47_timesync']:GetWeather() -- returns string (e.g. 'CLEAR')
exports['ak47_timesync']:SetWeather('RAIN', 10, false) -- weather, durationSeconds, instant

-- Next Weather Forecast
local nextWeather = exports['ak47_timesync']:GetNextWeather()
exports['ak47_timesync']:NextWeatherStage()

-- Blackout
local isBlackout = exports['ak47_timesync']:GetBlackout()
exports['ak47_timesync']:SetBlackout(true) -- or toggle with nil

-- Freeze Controls
local isTimeFrozen = exports['ak47_timesync']:IsTimeFrozen()
local isWeatherFrozen = exports['ak47_timesync']:IsWeatherFrozen()
exports['ak47_timesync']:SetTimeFreeze(true)
exports['ak47_timesync']:SetWeatherFreeze(true)
exports['ak47_timesync']:SetGlobalFreeze(true)

-- Dynamic Cycle
local isDynamic = exports['ak47_timesync']:IsDynamicWeather()
exports['ak47_timesync']:SetDynamicWeather(true)

-- Snow Tracks
exports['ak47_timesync']:SetSnowTracks(true)

-- Full Snapshot
local state = exports['ak47_timesync']:GetFullState()
```

### Client-Side Exports

```lua
-- Get Time
local time = exports['ak47_timesync']:GetTime()

-- Get Weather & Blackout
local weather = exports['ak47_timesync']:GetWeather()
local isBlackout = exports['ak47_timesync']:GetBlackout()

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

Developed by **MenanAk47**.
