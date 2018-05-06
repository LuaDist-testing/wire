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
-- Implementation of listen API function.
-- This method register UDP listener for IP and port specified. It also 
-- registers data exchange handler as a callback.
-- @param ip IP address (string) of a server.
-- @param port Port number of the server.
-- @param callback Handler of data exchange method. Must be defined as
-- function( data, socket_in_table ).
-- @return UDP handler in case a registration is successfully completed
-- or nil otherwise.
-------------------------------------------------------------------------------

function listen( server, callback )

	-- TODO; Add checking of types and values of the arguments
	-- TODO: Add start/stop receiving methods to 'server' object



	if server then
		server:recv_start( function ( nread, data, addr, flags )
			--print( "udp_recv_start, nread: ", nread, "data:", data, 
			--	"address:", address, "flags:", flags )
			if ( data ~= nil ) and ( addr ~= nil ) then
				if callback then 
					callback( data, addr )
				else
					logger:warn( string.format(
						"%s - Callback is nil for [%s:%d]", 
						mod_name, ip, port ) )
				end
			end
		end )
	end

	return server

end
