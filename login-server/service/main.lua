local skynet = require "skynet"
local loginDB = require "db.login"

skynet.start(function()
	log.notice("server start")
	
	loginDB:init(strToLuaObj(skynet.getenv("loginDB")))

	skynet.newservice("testmongodb")
	
	skynet.exit()
end)