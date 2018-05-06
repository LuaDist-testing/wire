-- packages from torch
threads = require( 'threads' )
socket = require( 'socket' )

-- local definitions for using in the module
local _G    = _G
local print = print

-------------------------------------------------------------------------------
-- module's code
-------------------------------------------------------------------------------

module( ... )

function poll()
	print( "poll" )
end
