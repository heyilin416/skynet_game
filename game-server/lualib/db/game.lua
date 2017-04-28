local skynet = require "skynet"
local MongoDB = require "mongodb"

local gameDB = MongoDB.new()

skynet.init(function()
    gameDB:init(".gameDB", strToLuaObj(skynet.getenv("gameDB")))
end)

function gameDB:getUserAccountId(userId)
	local user = self:findId("user", userId, {accountId = 1})
	if user then
		return user._id
	end
end

return gameDB