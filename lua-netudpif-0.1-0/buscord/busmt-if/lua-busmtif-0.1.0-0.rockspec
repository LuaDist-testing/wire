#!/usr/bin/env lua

package	= "lua-busmtif"
version	= "0.1.0-0"
source	= {
	url	= "git://cloud.lmks.ru:30000/v_romashkin/buscord.git",
	dir = "busmt-if"
	--module = "busmt-if",
	--branch = "v0.1.1",
}
description	= {
	summary    = "A simple API to use Bus-MT",
	detailed   = [[
LuaBusMT provides a simple API to use Bus-MT features in Lua.
This is module with high level interface to Bus-MT.
Currently supports ...
	]],
	homepage   = "https://cloud.lmks.ru:30000/v_romashkin/buscord",
	maintainer = "Gregory Trifonov, Vladimir Romashkin"
	--license	= "MIT/X11",
}
dependencies = {
	"lua >= 5.1",
	--"luajit >= 2.0.0",
	"lua-pb",
	--"paths >= scm-1", -- use module from torch
}
build = {
	type = "none",
	install = {
		lua = {
			-- adding to the root of LuaRocks' modules directory (<...>/share/lua/5.1/)
			-- file paths ralated to root of repository
			['busmtif'] = "src/busmtif.lua",
			-- copy files to 'busmt-if' subfolder
			['busmtif.busmtif'] = "src/busmtif/busmtif.h",
		},
		lib = {
			['busmt-if'] = "lib/libbusmt-client.so"
		},
	},
}