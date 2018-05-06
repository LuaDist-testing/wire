--require('mobdebug').start()

-- packages from torch
paths   = require( 'paths' )

-- configure logging
require( "logging.rolling_file", package.seeall )

local LOG_DIR  = paths.cwd() ..'/logs/'
local LOG_NAME = "netif.log"
local LOG_SIZE = 10 * 1024 * 1024 -- in bytes
local LOG_ARCH = 10

if not paths.dirp( LOG_DIR ) then
	paths.mkdir( LOG_DIR )
end

logger = logging.rolling_file( LOG_DIR .. LOG_NAME, LOG_SIZE, LOG_ARCH )
--logger:setLevel( logging.INFO )

-- Size of a thread pool
local NPOOL = 5

local utils = require( 'netudpif.utils' )

netif = require( 'netudpif' )

-------------------------------------------------------------------------------
-- Async logic
-------------------------------------------------------------------------------

logger:info( "test_receive: check interface" )

--local listenpool = netif.initialize( NPOOL )
--local sock = assert( netif.connect() )

function test_exchange ( data, addr )
	print( string.format( "Data received from [%s:%d]: %s", 
		addr.ip, addr.port, data ) )
end

function RandomString( length )
	length = length or 1
	if length < 1 then return nil end
	local array = {}
	for i = 1, length do
		array[ i ] = string.char( math.random( 32, 126 ) )
	end
	return table.concat( array )
end

local data = RandomString( 8 * 1000 )	-- имитация 1000 параметров модели
local recvpacketcounter = 0
local recvdatavolume = 0


local server = netif.listen( '127.0.0.1', 8483, function( data, addr )
	recvpacketcounter = recvpacketcounter + 1
	recvdatavolume = recvdatavolume + data:len()
end )


local client = netif.connect( '', 8486 )
--client:send( "data_test", '127.0.0.1', 8483, nil )

--netif.send()

-- timed high speed sender
sendtimer = netif.setInterval( 1, function()
	client:send( data, '127.0.0.1', 8483, nil )
end )

-- stop all routines
local meassuretime = 10
stoptimer = netif.setTimeout( meassuretime * 1000, function()
	netif.clearInterval( sendtimer )
	server:recv_stop()
	print( string.format( "Received: %d packets", recvpacketcounter ) )
	print( string.format( "Total data volume: %d KiB", recvdatavolume / 1024 ) )
	print( string.format( "Packets speed: %d packets/s", 
		recvpacketcounter / meassuretime ) )
	print( string.format( "Bitrate: %d KiB/s", 
		recvdatavolume / 1024 / meassuretime ) )
end )

-- run main event loop
netif.uv.run()

--require('mobdebug').done()
