local skynet = require "skynet"
local protoloader = require "proto.loader"

skynet.start(function()
	protoloader.init()

	local login = skynet.uniqueservice("loginserver")
	skynet.call(login, "lua", "init", strToLuaObj(skynet.getenv("loginServer")))

	log.notice("server start finish")
	skynet.exit()
end)