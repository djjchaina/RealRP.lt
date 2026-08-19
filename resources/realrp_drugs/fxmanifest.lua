fx_version 'cerulean'
game 'gta5'

author 'RealRP'
description 'RealRP RP narkotiku sistema'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
