local inspect = require 'inspect'
package.cpath = "./?.so"
local rjson = require('rjson')
local rdecode = rjson.decode
local rencode = rjson.encode

local json = [=[[1, 2, 3]]=]

print(inspect(rdecode(json)))
