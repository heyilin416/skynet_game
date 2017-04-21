local skynet = require "skynet"
local protoloader = require "proto.loader"

skynet.start(function()
	protoloader.init()

	local gated = skynet.uniqueservice("gated")
	skynet.call(gated, "lua", "open", strToLuaObj(skynet.getenv("gameServer")))

	log.notice("server start finish")
	skynet.exit()
end)