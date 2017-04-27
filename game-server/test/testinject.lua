--找到gated服务的地址(例如0x13),web执行http://127.0.0.1:32001/run?address=0x13&fileName=test/testinject.lua
local skynet = require "skynet"

local func = _P.lua.handler.open
local _, agentPool = getNameUpvalue(func, "agentPool")
local agent = agentPool[1]

local code = [[local func = _P.lua.CMD.login
local _, User = getNameUpvalue(func, "User")
if not User.test then
	User.test = function(self, ...)
		return "self :", self, "\nargs :", {...}
	end
end
print("function :", User.test)
print("call result :", User:test(1, 2, 3))]]

local ok, result = skynet.call(agent, "debug", "RUN", code, nil)
if ok then
	print("success :")
	print(result)
else
	print("error :")
	print(result)
end