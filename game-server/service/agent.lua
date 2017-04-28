local skynet = require "skynet"
local User = require "user.user"
local protoloader = require "proto.loader"

local traceback = debug.traceback
local host, _ = protoloader.load()

local gated = tonumber(...)
local user

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function(msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function(_, _, type, ...)
		if user then
			user:handleMsg(type, ...)
		end
	end,
}

local CMD = {}

function CMD.login(fd, userId)
	if user then
		assert(user.data._id == userId)
	else
		user = User.new(gated, userId)
	end
	return user:login(fd)
end

function CMD.logout()
	if user then
		local oldUser = user
		user = nil
		oldUser:logout()
	end
end

function CMD.kick()
	if user then
		user:kick()
	end
end

function CMD.close()
	if user then
		user:close()
	end
end

function CMD.runUserCode(code)
	if user then
		local env = setmetatable({user = user}, {__index = _ENV})
		local func = load(code, nil, "bt", env)
		return {result = ErrorCode.SUCCESS, codeResult = func()}
	end
	return {result = ErrorCode.ERR_USER_NOT_EXIST}
end

skynet.start (function ()
	skynet.dispatch ("lua", function(_, _, command, ...)
		local f = CMD[command]
		if not f then
			log.warningf("agent unhandled message(%s)", command) 
			return skynet.ret()
		end

		local ok, ret = xpcall(f, traceback, ...)
		if not ok then
			log.warningf ("agent handle message(%s) failed : %s", command, ret) 
			return skynet.ret()
		end
		skynet.retpack(ret)
	end)
end)
