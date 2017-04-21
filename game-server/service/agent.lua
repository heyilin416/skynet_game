local skynet = require "skynet"
local User = require "user.user"

local traceback = debug.traceback

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
			user.handleMsg(type, ...)
		end
	end,
}

local CMD = {}

function CMD.login(fd, userId)
	if not user then
		user = User.new(gated, fd, userId)
	end
	return user.data
end

function CMD.logout()
	if user then
		oldUser = user
		user = nil
		oldUser:logout()
	end
end

function CMD.kick()
	if user then
		user:kick()
	end
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
