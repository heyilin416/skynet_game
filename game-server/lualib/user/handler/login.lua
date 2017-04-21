local skynet = require "skynet"
local handler = require "handler.handler"
local bson = require "bson"

local REQUEST = {}
local RESPONSE = {}
local handler = handler.new(REQUEST, RESPONSE)

local user
handler:init(function(u)
	user = u
end)

function RESPONSE.LoginAccount(name, request, response)
    user:close(true)

    if response.result == ErrorCode.SUCCESS then
    	for _, server in ipairs(response.servers) do
    		if server.showId == user.serverId then
                user.accountId = response.accountId
                user:connect(table.unpack(string.split(server.address, ":")))
                user:call("LoginGame", {accountId = user.accountId, accountName = user.accountName, token = response.token})
    			return
    		end
    	end

    	log.errorf("%s serverId(%d) is not exist", user.accountName, user.serverId)
    else
        user:logRequestError(name, response.result)
    end
end

function RESPONSE.LoginGame(name, request, response)
    if response.result == ErrorCode.SUCCESS then
        user:call("LoginUser", {userId = bson.objectid()})
    else
        user:logRequestError(name, response.result)
    end
end

function RESPONSE.LoginUser(name, request, response)
    if response.result == ErrorCode.SUCCESS then
        print(response)
    else
        user:logRequestError(name, response.result)
    end
end

return handler