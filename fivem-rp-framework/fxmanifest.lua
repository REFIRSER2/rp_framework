fx_version 'cerulean'
game 'gta5'

author 'RP Framework Team'
description 'RP Framework ported from RageMP to FiveM'
version '1.0.0'

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/account-system/*.html',
    'html/account-system/*.css',
    'html/account-system/*.js',
    'html/character-system/*.html',
    'html/character-system/*.css',
    'html/character-system/*.js',
    'config.json',
    'models.json'
}

-- Server scripts
server_scripts {
    'server/main.lua',
    'server/database.lua',
    'server/email-service.lua',
    'server/account-system.lua',
    'server/character-system.lua',
    'server/utils.lua'
}

-- Client scripts
client_scripts {
    'client/main.lua',
    'client/account-system.lua',
    'client/character-system.lua',
    'client/nui.lua'
}

-- Dependencies
dependencies {
    'mysql-async',
    'redis'
}