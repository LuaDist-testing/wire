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

-------------------------------------------------------------------------------
-- Creates UDP object and binds it with a local interface.
-- @param ip IP address (string) of the local interface.
-- @param port Port number of the interface.
-- @return UDP handler in case a registration is successfully completed
-- or nil otherwise.
-------------------------------------------------------------------------------

function connect( ip, port )

	-- TODO; Add checking of types and values of the arguments

	logger:info( string.format( 
		"%s - Create connection to the local interface udp://%s:%d", 
		mod_name, ip, port ) )

	if not ip or ( ip == '' ) then
		ip = '0.0.0.0'
		logger:warn( string.format( 
			"%s - Empty IP! Default IP [%s] is used", 
			mod_name, ip ) )
	end

	local server = uv.new_udp()

	if server then
		server:bind( ip, port )
	else
		logger:fatal( utils.debug_message, debug.getinfo(1), 
			"Cannot create UDP object!" )
	end
	
	return server

end
