--require('mobdebug').start()

local paths = require 'paths'
-- расширяем cpath для поиска нашей библиотеки с клиентом шины
local pwd = paths.cwd()
package.cpath = pwd .. '/lib/?.so; ' .. package.cpath

require 'busmtif'
require "pb"

ioCtrl=pb.require("proto/ioCtrl")
local config = Busmt.Config()
							 .set_timed(false)
							 .set_uri("tcp://172.22.4.12:61616")
							 .set_federation_id("Samson").
	set_federate_id("CmdSender").add_signal(ioCtrl.ioCtrlInput)
print("Configured.")
print("Connecting...")
local ses = config.connect()
print("Connected.")
local cnt = 0;
while true do
	--[[
  print("Enter message data and press 'Enter' to send it. Send empty message to exit.")
	local data = io.read()
	if '' == data then break end
  ]]--
	--print("Sending: '"..data.."'")
	local message = ioCtrl.ioCtrlInput()
	message.Mode = 200
	message.CmdParamExt = tostring( cnt ) --data
  cnt = cnt + 1
	ses.send(message)
  if ( cnt % 50000 == 0 ) then
    print( cnt, " messages are sent" )
  end
  
	--print("Sent.")
end
print("Press 'Enter' to disconnect.")
io.read()
print("Disconnecting...")
--[[function makeString(l)
	if l < 1 then return nil end -- Check for l < 1
	local s = "" -- Start string
	for i = 1, l do
		s = s .. string.char(math.random(32, 126)) -- Generate random number from 32 to 126, turn it into character and add to string
	end
	return s -- Return string
end]]--

--[[while true do
	local message = ioCtrl.ioCtrlInput()
	message.Mode = 2
	message.CmdCode = 9
  message.CmdParam = 1
	message.CmdParamExt = "Cya faggot!"
--while true do
	ses.send(message)
--end
ses.advance_time(1)
--end--]]
ses.close()

