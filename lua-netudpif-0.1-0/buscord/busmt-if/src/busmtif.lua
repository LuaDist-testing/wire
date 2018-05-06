local ffi = require( "ffi" )

local paths = require 'paths'	-- load torch modules

-- prepare paths and init module
-- get module's work directory path
local filePath = paths.thisfile()
local moduleDir = paths.dirname( filePath ) .. '/busmtif/'

local header = io.open( moduleDir .. "busmtif.h", "r" )
local api = header:read( "*all" )
header:close()

-- path to module's library. search in LUA_CPATH by name
local libDir = package.searchpath('libbusmt-client', package.cpath)

local clt = ffi.load( libDir )
ffi.cdef(api)

local report = function(_err)
	if nil == _err[0] then
		return nil
	end
	local err = ffi.string(_err[0])
	clt.delete_str(_err)
	return err
end

local TimeType = "TimeType"
local ProtobufType = "ProtobufType"

local function check_clt(message)
	if not clt then
		local status, err = pcall(clt)
		print("\n-------------------------------------")
		print("Error in function:",message)
		print("status:",status)
		print("err",err)
		print("-------------------------------------")
		return
	end
end

local CAPI = ffi.typeof('API')
ffi.metatype(CAPI, {
	__gc = function(self)
		check_clt("__gc")
		local _err = ffi.new("cstr_mut[1]")
		if 0 ~= clt.busmt_api_close(self, _err) then
			print("Raised on gc by capi close: "..report(_err))
		end
		-- we reuse _err only because the actual string it was pointing to is alread destroyed by report
		if 0 ~= clt.busmt_delete_api(self, _err) then
			print("Raised on gc by capi delete: "..report(_err))
		end
	end,
	__index = {
		poll = function(self)
			check_clt("__index:poll")
			local _msg = ffi.new("Message*[1]")
			local _err = ffi.new("cstr_mut[1]")
			-- print("api.lua::poll::before clt.busmt_api_poll(self, _msg, _err)")
			local error_code = clt.busmt_api_poll(self, _msg, _err)
			-- print("api.lua::poll::after self =",self,"_msg == ",_msg," _err == ",_err)
			-- print("error_code",error_code);
			if clt.DID_NOTHING == error_code then
				-- print("clt.DID_NOTHING",clt.DID_NOTHING);
				return nil, false, nil
			elseif clt.OK == error_code then
				-- print("clt.OK",clt.OK);
				ffi.gc(_msg[0], clt.delete_message)
				if clt.Protobuf == _msg[0]["type"] then
					return {
						tpe = ProtobufType,
						signal_type = ffi.string(_msg[0].proto_data.signal_type),
						payload = ffi.string(_msg[0].proto_data.payload, _msg[0].proto_data.payload_len),
					}, true, nil
				else
					return {
						tpe = TimeType,
						time = _msg[0].time_data.time,
					}, true, nil
				end
			else
				return nil, true, report(_err)
			end
		end,
		close = function(self)
			check_clt("__index:close")
			local _err = ffi.new("cstr_mut[1]")
			-- print("api.lua::close::before clt.busmt_api_close(self, _err)")
			if 0 ~= clt.busmt_api_close(self, _err) then
				-- print("api.lua::close::before clt.busmt_api_close(self ==",self,"_err == ",_err,")")
				return report(_err)
			end
			return nil
		end,
		listen_signal = function(self, signal_type)
			check_clt("__index:listen_signal")
			local _err = ffi.new("cstr_mut[1]")
			-- print("api.lua::listen_signal::clt.busmt_api_listen_signal(self, signal_type():FullName(), _err)")
			if 0 ~= clt.busmt_api_listen_signal(self, signal_type():FullName(), _err) then
				-- print("api.lua::listen_signal::clt.busmt_api_listen_signal(self ==",self," signal_type():FullName() == ",signal_type():FullName()," _err == ",_err,")")
				return self, report(_err)
			end
			return self, nil
		end,
		listen_time = function(self)
			check_clt("__index:listen_time")
			local _err = ffi.new("cstr_mut[1]")
				--print("api.lua::listen_time::clt.busmt_api_listen_time(self, signal_type():FullName(), _err)")
			if 0 ~= clt.busmt_api_listen_time(self, signal_type():FullName(), _err) then
				--print("api.lua::listen_time::clt.busmt_api_listen_time(self ==",self," signal_type():FullName() == ",signal_type():FullName()," _err == ",_err,")")
				return self, report(_err)
			end
			return self, nil
		end,
		send = function(self, message, broadcast, route)
			check_clt("__index:send")
			local bin, errmsg = message:Serialize()
			local _broadcast = broadcast or false
			local _route = route or ''
			if errmsg then
				return self, errmsg
			end
			local _err = ffi.new("cstr_mut[1]")
				--print("api.lua::send::before clt.busmt_api_close(self ==",self,"_err == ",_err,")")
			if clt.OK ~= clt.busmt_api_send(self, message:FullName(), #bin, ffi.cast("void*", bin), _broadcast, _route, _err) then
				--print("api.lua::listen_time::clt.busmt_api_send(self ==",self," message:FullName(), == ",message:FullName()," #bin == ",#bin," _broadcast== ",_broadcast," _route == ",_route," _err == ",_err)
				return self, report(_err)
			end
			return self, nil
		end,
		advance_time = function(self, delta)
			check_clt("__index:advance_time")
			local _err = ffi.new("cstr_mut[1]")
				--print("api.lua::advance_time::clt.busmt_api_advance_time(self, delta, _err)")
			if clt.OK ~= clt.busmt_api_advance_time(self, delta, _err) then
				--print("api.lua::advance_time::clt.busmt_api_advance_time(self ==",self," delta == ",delta,", _err == ",_err,")")
				return self, report(_err)
			end
			return self, nil
		end
	},
})


local CAPIConfig = ffi.typeof('APIConfig')
ffi.metatype(CAPIConfig, {
	__new = function()
		check_clt("CAPIConfig:__new")
		local config = clt.busmt_new_config()
		return ffi.gc(config, __gc)
	end,
	__gc  = function(self)
		check_clt("CAPIConfig:__gc")
		clt.busmt_delete_config(self)
	end,
	__index = {
		set_uri = function(self, uri)
			check_clt("CAPIConfig:__index:set_uri")
			clt.busmt_config_set_uri(self, uri)
			return self
		end,
		uri = function(self)
			check_clt("CAPIConfig:__index:uri")
			return ffi.string(clt.busmt_config_get_uri(self))
		end,
		set_federation_id = function(self, federation_id)
			check_clt("CAPIConfig:__index:set_federation_id")
			clt.busmt_config_set_federation_id(self, federation_id)
			return self
		end,
		federation_id = function(self)
			check_clt("CAPIConfig:__index:federation_id")
			return ffi.string(clt.busmt_config_get_federation_id(self))
		end,
		set_federate_id = function(self, federate_id)
			check_clt("CAPIConfig:__index:set_federate_id")
			clt.busmt_config_set_federate_id(self, federate_id)
			return self
		end,
		federate_id = function(self)
			check_clt("CAPIConfig:__index:federate_id")
			return ffi.string(clt.busmt_config_get_federate_id(self))
		end,
		set_polling = function(self, polling)
			check_clt("CAPIConfig:__index:set_polling")
			clt.busmt_config_set_polling(self, polling)
			return self
		end,
		polling = function(self)
			check_clt("CAPIConfig:__index:polling")
			return clt.busmt_config_get_polling(self)
		end,
		set_timed = function(self, timed)
			check_clt("CAPIConfig:__index:set_timed")
			clt.busmt_config_set_timed(self, timed)
			return self
		end,
		timed = function(self)
			check_clt("CAPIConfig:__index:timed")
			return clt.busmt_config_get_timed(self)
		end,
		add_signal = function(self, signal_type)
			check_clt("CAPIConfig:__index:add_signal")
			local msg = signal_type()
			local _err = ffi.new("cstr_mut[1]")
			local e = clt.busmt_config_add_proto(self, msg:FileName(), _err)
			if 0 ~= e then
				return self, report(_err)
			end
			e = clt.busmt_config_add_signal(self, msg:FullName(), _err)
			if 0 ~= e then
				return self, report(_err)
			end
			return self, nil
		end,
		connect = function(self)
			check_clt("CAPIConfig:__index:connect")
			local capi = ffi.new("API*[1]")
			local _err = ffi.new("cstr_mut[1]")
			e = clt.busmt_new_api(self, capi, _err)
			ffi.gc(capi[0], getmetatable(CAPI).__gc)
			return capi[0], report(_err)
		end,
	},
})


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

local function errorReporter(err)
	local tbl = {}
	local report = function(table, key)
			print("Session is corrupted due to: "..err)
			return tbl
	end
	setmetatable(tbl, {
		__index = report,
		__call  = report,
	})
	return tbl
end

Busmt = {
	Config = function()
		local methods = {}
		local self = {
			polling = true,
			timed = false,
			uri = "tcp://localhost:61616",
			federation_id = "federation",
			federate_id = "federate",
			signals = {},
		}

		function methods.timed()
			return self.timed
		end

		function methods.set_timed(timed)
			self.timed = timed
			return methods
		end

		function methods.uri()
			return self.uri
		end

		function methods.set_uri(uri)
			self.uri = uri
			return methods
		end

		function methods.federation_id()
			return self.federation_id
		end

		function methods.set_federation_id(federation_id)
			self.federation_id = federation_id
			return methods
		end

		function methods.federate_id()
			return self.federate_id
		end

		function methods.set_federate_id(federate_id)
			self.federate_id = federate_id
			return methods
		end

		function methods.add_signal(signal)
			table.insert(self.signals, signal)
			return methods
		end

		function methods.connect()
			local capi_config = CAPIConfig():
				set_uri(self.uri):
				set_federation_id(self.federation_id):
				set_federate_id(self.federate_id):
				set_timed(self.timed):
				set_polling(self.polling)
				local err
			for i = 1, #self.signals do
				local _, err = capi_config:add_signal(self.signals[i])
				if err then
					return errorReporter(err), err
				end
			end
			local capi, err = capi_config:connect()
			if err then
				return errorReporter(err), err
			end
			local api_self = {
				capi = capi,
				parsers = {},
				signal_listeners = {},
				time_listeners = {},
			}
			local api_methods = {}
			function api_methods.close()
				return capi:close()
			end
			function api_methods.poll()
				local msg, effect, err = capi:poll()
				if err then
					return true, err
				end
				if not effect then
					return false, nil
				end
				local parser = api_self.parsers[msg.signal_type]
				if parser then
					local m = parser():ParsePartial(msg.payload)
					local listeners = api_self.signal_listeners[m:FullName()]
					if listeners then
						for i = 1, #listeners-1 do
						local copy = parser():CopyFrom(m)
							listeners[i](copy)
						end
						listeners[#listeners](m)
					end
				end
				return true, nil
			end
			function api_methods.add_signal_listener(signal_type, callback)
				local ref = signal_type()
				if nil == api_self.signal_listeners[ref:FullName()] then
					api_self.signal_listeners[ref:FullName()] = {}
					api_self.parsers[ref:FullName()] = signal_type
					capi:listen_signal(signal_type)
				end
				table.insert(api_self.signal_listeners[ref:FullName()], callback)
				return api_methods
			end
			function api_methods.add_time_listener(callback)
				if #api_self.time_listeners == 0 then
					capi:listen_time()
				end
				table.insert(api_self.time_listeners, callback)
				return api_methods
			end
			function api_methods.current_time()
				return capi:get_current_time()
			end
			function api_methods.advance_time(delta)
				local _, err = capi:advance_time(delta)
				if err then
					return errorReporter(err), err
				end
				return methods, nil
			end
			function api_methods.get_advance()
				return capi:get_advance()
			end
			function api_methods.add_time_listener(callback)
				table.insert(api_self.time_listeners, callback)
				return api_methods
			end
			function api_methods.send(msg, broadcast, route)
				local _, err = capi:send(msg, broadcast, route)
				if err then
					return errorReporter(err), err
				end
				return api_methods, nil
			end
			return api_methods, nil
		end

		return methods
	end,
	Descriptor = function(path)
		return
			pb.require(path)
	end,
	Sleep = sleep,
}
