# rjson
Another lua&lt;->json realization

### Install via luarocks
```sh
luarocks install rjson
```
It depends only on lua header files in LUA_INCDIR.
Here you can find it:
```sh
luarocks config --lua-incdir
```
And add lua.h and lauxlib.h to it, if they are missing.

## Differences from lua_cjson
* **Important: it is for sending and recieving json, not for package.json and kinda stuff**
```json
[{"key":"value"}] // ok

/* not ok */
[
  {"key": "value"}
]
```
* In hashes `null` become `nil`, **not in arrays**, `nil` in array will break it, so there are rjson.null
```lua
t = rjson.decode('{"key":null}')
if (t.key) then
	print"good!"
end
t = cjson.decode('{"key":null}')
if (t.key) then
	print"OH SHI--"
end
```
* In javascript empty `array` acts like empty `hash`, not vice versa, so lua `{}` -> json `[]`
```lua
print(rjson.encode{}) -- []
print(cjson.encode{}) -- {}
```
* You don't want nulls in hashes, they are useless and only increases size.
```lua
print(rjson.encode({key = rjson.null})) -- []
print(cjson.encode({key = cjson.null})) -- {"key":null}
```
* Outputed arrays has the same length and items, as in lua, so `{nil, 1, 2}` isn't an array, and `#{1, nil, 2}` is `2`.
```lua
local rjson = require "rjson"
local cjson = require "cjson"

print(rjson.encode{1, nil, 2}) -- [1]
print(cjson.encode{1, nil, 2}) -- [1,null,2]
print(rjson.encode{nil, 1, 2}) -- {"2":1,"3":2}
print(cjson.encode{nil, 1, 2}) -- [null,1,2]

-- if you need array with nulls
print(rjson.encode({1,rjson.null,2})) -- [1,null,2]
```
* `to_json` property, **not** metamethod, it can be useable as here, also can be use for caching json's for special tables.
```lua
local secret_fields = { password = true, IQ = true } -- secret fields!

clear = require "table.clear" -- from luajit
local temp = {} -- we don't want to create table each time
local meta = { __index = { to_json = function ( self )
	clear(temp)
	for k, v in pairs(self) do
		if secret_fields[k] == nil then
			temp[k] = v
		end
	end
	rjson.encode(temp)
end } }

print(rjson.encode(setmetatable( { login = "xxx", password = "yyy" }, meta )))
```


# Speed!
Decoding is faster than cjson ~10%, encoding is slower ~5%, thanks to `as_json`.
