local skynet = require "skynet"
local gameDB = require "db.game"
local bson = require "bson"
local cluster = require "cluster"

local loginServer
skynet.init(function()
	loginServer = cluster.query("login", "loginServer")
	loginServer = cluster.proxy("login", loginServer)
end)

local handler = {}

function handler.LoginGame(args)
	local result = skynet.call(loginServer, "lua", "checkToken", args.accountId, args.token)
	if result ~= ErrorCode.SUCCESS then
		return {result = result}
	end

	local users = gameDB:findAll("user", {accountId = args.accountId}, {name = 1, pic = 1, level = 1})
	if #users < 1 then
		users = {{_id = bson.objectid(), accountId = args.accountId, name = args.accountName, pic = 1, level = 1}}
		gameDB:insert("user", users[1])
	end

	return {result = ErrorCode.SUCCESS, users = users}
end

function handler.LoginUser(args)
	local user = gameDB:findId("user", args.userId, {accountId = 1})
	if not user then
		return {result = ErrorCode.ERR_USER_NOT_EXIST}
	end

	return {result = ErrorCode.SUCCESS, user = user}
end

return handler