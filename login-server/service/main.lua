local skynet = require "skynet"
local cluster = require "cluster"
local protoloader = require "proto.loader"

skynet.start(function()
	protoloader.init()

	local login = skynet.uniqueservice("loginserver")
	skynet.call(login, "lua", "init", strToLuaObj(skynet.getenv("loginServer")))

	cluster.open("login")

	log.notice("server start finish")
	skynet.exit()
end)