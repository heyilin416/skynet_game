local skynet = require "skynet"
local User = require "user"

local user

local CMD = {}

function CMD.init(serverId, accountName, password)
	user = User.new(serverId, accountName, password)
	user:login()
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.retpack(f(...))
    end)
end)