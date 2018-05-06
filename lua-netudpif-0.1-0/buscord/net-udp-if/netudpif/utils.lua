-- packages from torch
--threads = require( 'threads' )
--socket = require( 'socket' )

-- local definitions for using in the module
local _G      = _G
local print   = print
local require = require
local module  = module	-- resolve global variables inside module
local string  = string

-- global objects
local logger  = _G.logger
local debug   = _G.debug

local ffi = require( "ffi" )

-------------------------------------------------------------------------------
-- module's code
-------------------------------------------------------------------------------

module( ... )

-------------------------------------------------------------------------------
-- Prepare message with debug info for logging
-- @param info Object of debug.info
-- @param msg Message string
-- @return Formatted string
-- @usage logger:info( utils.debug_message, debug.getinfo(1), string.format( "%s", "custom log" ) )
-------------------------------------------------------------------------------

function debug_message( info, msg )
	return string.format( "%s:%d - %s", info.short_src, info.currentline, msg )
end

ffi.cdef[[
void Sleep(int ms);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]

local sleep
if ffi.os == "Windows" then
  function sleep(s)
    ffi.C.Sleep(s)
  end
else
  function sleep(s)
    ffi.C.poll(nil, 0, s)
  end
end