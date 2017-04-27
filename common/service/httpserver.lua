local skynet = require "skynet"
local socket = require "socket"

local envKey = ...

local nslave
local slave = {}

skynet.start(function()
	local conf = strToLuaObj(skynet.getenv(envKey))
	for i= 1, conf.slave do
		slave[i] = skynet.newservice("httpslave", table.unpack(conf.handlerModules))
	end
	nslave = #slave
	
	local host = conf.host or "0.0.0.0"
    local port = assert(tonumber(conf.port))
	local sock = socket.listen(host, port)
	skynet.error(string.format("Listen on %s:%d", host, port))

	local balance = 1
	socket.start(sock , function(fd, addr)
		skynet.send(slave[balance], "lua", fd, addr)

		balance = balance + 1
		if balance > #slave then
			balance = 1
		end
	end)
end)