local skynet = require "skynet"
local cluster = require "cluster"
local protoloader = require "proto.loader"

skynet.start(function()
	protoloader.init()
	cluster.open("login")
	skynet.uniqueservice("debug_console", skynet.getenv("debug_console"))

	local login = skynet.uniqueservice("loginserver")
	skynet.call(login, "lua", "init", strToLuaObj(skynet.getenv("loginServer")))

	log.notice("server start finish")
	skynet.exit()
end)