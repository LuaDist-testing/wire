-- local definitions for using in the module
local _G = _G
local require = require
local print = print

local logger   = _G.logger
local debug    = _G.debug
local socket   = _G.socket

-- packages from torch
--threads = require( 'threads' )
--socket = require( 'socket' )
local uv = require( 'luv' )

local M = {} -- public interface of the module

-------------------------------------------------------------------------------
-- module's code
-------------------------------------------------------------------------------

module( ... )

-- path of the module relatively to work directory of a main project
local mod_name = ...

-------------------------------------------------------------------------------
-- libUV c binding
-------------------------------------------------------------------------------

M.uv = uv

-------------------------------------------------------------------------------
-- API function.
-- Creates UDP object and binds it with a local interface.
-- @param ip IP address (string) of the local interface.
-- @param port Port number of the interface.
-- @return UDP handler in case a registration is successfully completed
-- or nil otherwise.
-------------------------------------------------------------------------------

local connect_worker
function M.connect( ip, port )
	-- dynamically load the implementation
	if not connect_worker then
		connect_worker = require( mod_name .. ".connect" )
	end

	-- call the implementation
	return connect_worker.connect( ip, port )
end

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

local listen_worker
function M.listen( ip, port, callback )
	-- dynamically load the implementation
	if not listen_worker then
		listen_worker = require( mod_name .. ".listen" )
	end

	-- create connection (bind socket)
	local server = M.connect( ip, port )

	-- call the implementation
	return listen_worker.listen( server, callback )
end

-------------------------------------------------------------------------------
-- send function
--
-------------------------------------------------------------------------------

local send_worker
function M.send(  )
	-- dynamically load the implementation
	if not send_worker then
		send_worker = require( mod_name .. ".send" )
	end

	-- call the implementation
	send_worker.send()
end

-------------------------------------------------------------------------------
-- Creating a simple setTimeout wrapper.
-- Timer fires once after specified timeout and calles callback.
-- @param timeout Timeout in milliseconds.
-- @param callback Fired callback.
-------------------------------------------------------------------------------

function M.setTimeout( timeout, callback )
	local timer = uv.new_timer()
	timer:start( timeout, 0, function ()
		timer:stop()
		timer:close()
		callback()
	end )
	return timer
end

-------------------------------------------------------------------------------
-- Creating a simple setInterval wrapper
-- Timer fires periodically with specified interval and calles callback.
-- @param interval Interval in milliseconds.
-- @param callback Fired callback.
-------------------------------------------------------------------------------

function M.setInterval( interval, callback )
	local timer = uv.new_timer()
	timer:start( interval, interval, function ()
		callback()
	end )
	return timer
end

-------------------------------------------------------------------------------
-- Stops and clears timer.
-- @param timer Timer to stop.
-------------------------------------------------------------------------------

function M.clearInterval( timer )
	timer:stop()
	timer:close()
end

return M
