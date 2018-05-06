-- require('mobdebug').start()

local paths = require 'paths'
-- расширяем cpath для поиска нашей библиотеки с клиентом шины
local pwd = paths.cwd()
package.cpath = pwd .. '/lib/?.so; ' .. package.cpath
--print(package.cpath)

require 'busmtif'
require "pb"

ioCtrl = pb.require("proto/ioCtrl")
local config = Busmt.Config()
							 .set_uri("tcp://192.168.52.1:61616")
							 .set_federation_id("Samson")
							 .set_federate_id("CmdReceiver")
							 .add_signal(ioCtrl.ioCtrlInput)
							 .add_signal(ioCtrl.ioCtrlRespond)
local ses, err = config.connect()
--[[if err then
	print(err)
	return
end]]--
print("Connected.")
function print_r ( t )  
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t,"  ")
		print("}")
	else
		sub_print_r(t,"  ")
	end
	print()
end
print('listen Respond')
ses.add_signal_listener(ioCtrl.ioCtrlRespond, function(msg)
	print_r(msg)
end)
print('listen Input')
local cnt = 0
ses.add_signal_listener(ioCtrl.ioCtrlInput, function(msg)
--	print_r(msg)
	cnt = cnt + 1
--	local _, err = ses.send(msg, true)
--	if nil ~= err then
--		print(err)
--	end
end)
print('looping')
local err
while true do
	local progress = true
	while progress do
		progress, err = ses.poll()
		if nil ~= err then
			print(err)
		end
    
    if ( cnt % 50000 == 0) then
      print( cnt, " messages are received" )
    end
  
	end

	
	Busmt.Sleep(1)
end

