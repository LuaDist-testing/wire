-- local definitions for using in the module
local _G       = _G
local print    = print
local require  = require
local module   = module	-- resolve global variables inside module
local string   = string

-- global objects
local logger   = _G.logger
local debug    = _G.debug

-- packages from torch
local uv       = require( 'luv' )

-- path of the module relatively to work directory of a main project
local mod_name = ...
local mod_path = string.match( mod_name, ".*%." ) or ''

local utils    = require( mod_path .. "utils" )

-------------------------------------------------------------------------------
-- module's code
-------------------------------------------------------------------------------

module( ... )

--function send( data, ip, port, callback )
function send(  )
	
	-- TODO; Add checking of types and values of the arguments

	--logger:info( string.format( "%s - Send to udp://%s:%d", 
	--	mod_name, ip, port ) )
	
	local client = uv.new_udp()

	sock = uv.new_udp()
	sock:bind( '127.0.0.1', 8485 )
	sock:set_broadcast( true )
	sock:send( 'data_test', '127.0.0.1', 8483, function() print( "sended" ) end )
end
