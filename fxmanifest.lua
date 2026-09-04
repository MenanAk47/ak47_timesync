fx_version 'cerulean'
game 'gta5'
description 'Ak47 Time & Weather Sync'
version '1.2.1'
author 'MenanAk47'
lua54 'yes'

ui_page 'web/index.html'
--ui_page 'http://localhost:5173'

files {
    'web/**/*',
}

shared_scripts {
    'config.lua',
    'locales/locale.lua',
    'locales/en.lua',
}

server_scripts {
    'webhooks.lua',
    'api/server/*.lua',
    'modules/**/server/*.lua',
    'compat/server/*.lua',
    'custom/server/*.lua',
}

client_scripts {
    'api/client/*.lua',
    'modules/**/client/*.lua',
    'compat/client/*.lua',
    'custom/client/*.lua',
}

dependencies {
    'ak47_lib',
}

provide 'qb-weathersync'
provide 'cd_easytime'
provide 'vSync'
provide 'vSyncR'
provide 'qbx_weathersync'
