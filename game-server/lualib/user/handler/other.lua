local skynet = require "skynet"
local handler = require "user.handler.handler"
local bson = require "bson"

local REQUEST = {}
local RESPONSE = {}
local handler = handler.new(REQUEST, RESPONSE)

local user
handler:init(function(u)
	user = u
end)

function REQUEST.HeartBeat(name, args)
	log.debug(user.data.name, "heart beat")
	return {}
end

return handler