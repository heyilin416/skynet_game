local skynet = require "skynet"
local protoloader = require "proto.loader"

skynet.start(function()
	protoloader.init()
	skynet.uniqueservice("debug_console", skynet.getenv("debug_console"))

	local serverId = tonumber(skynet.getenv("serverId"))
	local password = skynet.getenv("password")
	local clientBegin = tonumber(skynet.getenv("clientBegin"))
	local clientEnd = tonumber(skynet.getenv("clientEnd"))
	for i = clientBegin, clientEnd do
		local accountName = skynet.getenv("accountPrefixName") .. i
		local client = skynet.newservice("client")
		skynet.call(client, "lua", "init", serverId, accountName, password)
	end

	log.notice("client start finish")
	skynet.exit()
end)