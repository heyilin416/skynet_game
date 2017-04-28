local skynet = require "skynet"
local bson = require "bson"
local gameDB = require "db.game"

local nameToIds = {}
skynet.init(function()
	local users = gameDB:findAll("user", nil, {name = 1})
	for _, user in ipairs(users) do
		nameToIds[user.name] = user._id
	end
end)

local CMD = {}

function CMD.getUserID(name)
	return nameToIds[name]
end

function CMD.newUserName()
	for i = 1, 100000 do
		local userName = "user" .. i
		if not nameToIds[userName] then
			local userId = bson.objectid()
			nameToIds[userName] = userId
			return {result = ErrorCode.SUCCESS, id = userId, name = userName}
		end
	end
	return {result = ErrorCode.UNKNOW}
end

function CMD.modifyUserName(oldName, newName)
	local userId = nameToIds[oldName]
	if not userId then
		return {result = ErrorCode.ERR_USERNAME_NOT_EXIST}
	end

	if nameToIds[newName] then
		return {result = ErrorCode.ERR_USERNAME_EXIST}
	end

	nameToIds[oldName] = nil
	nameToIds[newName] = userId
	return {result = ErrorCode.SUCCESS}
end

return CMD