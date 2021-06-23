fx_version 'adamant'
game 'gta5'

description 'Inventory Made By Axis fixed up by ihyajb'

dependencies {
    "mrp_core"
}

server_scripts {
    '@mrp_core/shared/MRPShared.lua',
    'config.lua',
    'server/main.lua',
}

client_scripts {
    '@mrp_core/shared/MRPShared.lua',
    'config.lua',
    'client/main.lua',
}

ui_page {
    'html/ui.html'
}

files {
    'html/ui.html',
    'html/css/main.css',
    'html/js/app.js',
    'html/images/*.png',
    'html/images/*.jpg',
    'html/ammo_images/*.png',
    'html/attachment_images/*.png',
    'html/*.ttf',
}