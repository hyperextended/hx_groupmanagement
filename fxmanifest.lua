--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'hx_groupmanagement'
version      '0.4.0'
author       'Hyperextended'
repository   'https://github.com/hyperextended/hx_groupmangement'

--[[ Manifest ]]--
shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    '@ox_core/imports/client.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_core/imports/server.lua',
    'server/main.lua',
}
