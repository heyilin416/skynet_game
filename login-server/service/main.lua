local skynet = require "skynet"
local loginDB = require "db.login"
local protoloader = require "proto.loader"

skynet.start(function()
	log.notice("server start")
	
	protoloader.init()
	loginDB:init(strToLuaObj(skynet.getenv("loginDB")))
	
	skynet.exit()
end)