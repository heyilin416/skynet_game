local skynet = require "skynet"
local log = require "log"

skynet.start(function()
	log.notice("server start")
	skynet.exit()
end)