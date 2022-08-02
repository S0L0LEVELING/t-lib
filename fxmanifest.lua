fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Trase'
description 'Libary for all Trase.Dev products and assets.'
version '1.0.0'

shared_script 'init.lua'
client_script 'client/*.lua'
server_script 'server/*.lua'

dependencies {
	'/server:5104',
    '/onesync',
}