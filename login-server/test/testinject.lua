--找到loginserver服务的地址(例如0x15),web执行http://127.0.0.1:22001/run?address=0x15&fileName=test/testinject.lua

local func = _P.lua.CMD.init
local up, value = getNameUpvalue(func, "sessionExpireTime")
print(up, value)

debug.setupvalue(func, up, value + 1)
print(getNameUpvalue(func, "sessionExpireTime"))