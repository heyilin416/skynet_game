local skynet = require "skynet"
local gameDB = require "db.game"
local bson = require "bson"
local cluster = require "cluster"
local userNameMgr = require "gate.username_mgr"

local traceback = debug.traceback

local loginServer
skynet.init(function()
	loginServer = cluster.query("login", "loginServer")
	loginServer = cluster.proxy("login", loginServer)
end)

local loginLocks = {}
local handler = {}

function handler.loginLock(accountId)
    for i = 1, 50 do
        if loginLocks[accountId] then
            skynet.sleep(10)
        else
            loginLocks[accountId] = true
            return true
        end
    end
    log.errorf("login lock timeout(accountId=%s)", strToHex(accountId))
end

function handler.loginUnlock(accountId)
	loginLocks[accountId] = nil
end

function handler.LoginGame(c, args)
	local result = skynet.call(loginServer, "lua", "checkToken", args.accountId, args.token)
	if result ~= ErrorCode.SUCCESS then
		return {result = result}
	end

	local users = gameDB:findAll("user", {accountId = args.accountId}, {name = 1, pic = 1, level = 1})
	if #users < 1 then
		local result = userNameMgr.newUserName()
		if result.result ~= ErrorCode.SUCCESS then
			return result
		end

		users = {{_id = result.id, accountId = args.accountId, name = result.name, pic = 1, level = 1}}
		gameDB:insert("user", users[1])
	end

	c.isCheck = true
	return {result = ErrorCode.SUCCESS, users = users}
end

function handler.LoginUser(c, args)
	local userId = args.userId
	local accountId = gameDB:getUserAccountId(userId)
	if not accountId then
		return {result = ErrorCode.ERR_USER_NOT_EXIST}
	end

	if not handler.loginLock(accountId) then
		return {result = ErrorCode.ERR_LOCK_TIMEOUT}
	end

	local result
	local ok, user = xpcall(handler.loginUser, traceback, c, accountId, userId)
	if ok then
        result = {result = ErrorCode.SUCCESS, user = user}
    else
        result = {result = ErrorCode.ERR_UNKNOW}
        log.errorf("login user failed(accountId=%s, userId=%s) : %s", strToHex(accountId), strToHex(userId), user)
    end
    handler.loginUnlock(accountId)
    return result
end

return handler