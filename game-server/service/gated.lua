local skynet = require "skynet"
require "skynet.manager"
local gateserver = require "snax.gateserver"
local protoloader = require "proto.loader"
local packetHandler = require "gate_handler"

local traceback = debug.traceback

local host
local connections = {}
local agentPool = {}
local onlineAccounts = {}
local onlineUsers = {}
local loginLocks = {}

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
}

local handler = {}

function handler.open(source, conf)
    skynet.register(".gated")
    host = protoloader.load()

    if conf.agentInitPool then
        local gated = skynet.self()
        for i = 1, conf.agentInitPool do
            table.insert(agentPool, skynet.newservice("agent", gated))
        end
    end
end

function handler.connect(fd, addr)
    local c = {
        fd = fd,
        ip = addr,
    }
    connections[fd] = c
    gateserver.openclient(fd)
    log.info("socket connect", fd, addr)
end

local function loginUser(fd, userData)
    local c = connections[fd]
    if not c then
        return
    end

    local agent
    local accountInfo = onlineAccounts[userData.accountId]
    if accountInfo then
        if accountInfo.userId == userData._id then
            if accountInfo.c.fd then
                skynet.call(accountInfo.c.agent, "lua", "kick")
            end
            agent = accountInfo.c.agent
        else
            skynet.call(accountInfo.c.agent, "lua", "logout")
        end
    end

    if not agent then
        if #agentPool == 0 then
            agent = skynet.newservice("agent", skynet.self())
            log.noticef("agent pool is empty, new agent(%d) created", agent)
        else
            agent = table.remove(agentPool)
            log.infof("agent(%d) assigned, %d remain in pool", agent, #agentPool)
        end
    end

    c.agent = agent
    onlineAccounts[userData.accountId] = { c = c, userId = userData._id }
    onlineUsers[userData._id] = c
    return skynet.call(agent, "lua", "login", fd, userData._id)
end

local function close(fd)
    local c = connections[fd]
    if c then
        c.fd = nil
        connections[fd] = nil
        skynet.call(c.agent, "lua", "close")
    end
end

local function kick(fd)
    if connections[fd] then
        close(fd)
        gateserver.closeclient(fd)
    end
end

function handler.disconnect(fd)
    close(fd)
    log.info("socket close", fd)
end

function handler.error(fd, msg)
    close(fd)
    log.info("socket error", fd, msg)
end

function handler.warning(fd, size)
    log.warning("socket warning", fd, size)
end

function handler.message(fd, msg, size)
    local c = connections[fd]
    local agent = c.agent
    if agent then
    	skynet.redirect(agent, 0, "client", 0, msg, size)
    else
        local mType, name, args, response = host:dispatch(msg, size)
        if mType ~= "REQUEST" then
            if response then
                sendMsg(fd, response { result = ErrorCode.ERR_PACKET_TYPE })
            end

            kick(fd)
            log.warningf("%s packet type(%s) error", fd, mType)
            return
        elseif name ~= "LoginGame" and not c.isCheck then
            if response then
                sendMsg(fd, response { result = ErrorCode.ERR_GAME_NOT_CHECK })
            end

            kick(fd)
            log.warningf("%s %s is not check login", fd, name)
        end

        local f = packetHandler[name]
        if f then
            local ok, ret = xpcall(f, traceback, args)
            if not ok then
                log.errorf("%s handle message(%s) failed : %s", fd, name, ret)
                kick(fd)
            else
                if ret then
                    if ret.result == ErrorCode.SUCCESS then
                        if name == "LoginGame" then
                            c.isCheck = true
                        elseif name == "LoginUser" then
                            local accountId = ret.user.accountId
                        	if loginLocks[accountId] then
                        		ret = {result = ErrorCode.ERR_USER_IS_LOGINING}
                        	else
                        		loginLocks[accountId] = true
                            	local ok, user = xpcall(loginUser, traceback, fd, ret.user)
                            	if ok then
                            		ret.user = user
                            	else
                            		log.error("login user failed :", user)
                            	end
                            	loginLocks[accountId] = nil
                            end
                        end
                    end

                    if response then
                        sendMsg(fd, response(ret))
                        if ret.result ~= ErrorCode.SUCCESS and not ret.isKeepAlive then
                            kick(fd)
                        end
                    end
                end
            end
        else
            log.warningf("%s unhandled message : %s", fd, name)
            kick(fd)
        end
    end
end

local CMD = {}

function CMD.kick(fd)
    kick(fd)
end

function CMD.logout(accountId)
    local accountInfo = onlineAccounts[accountId]
    if accountInfo then
        onlineAccounts[accountId] = nil
        onlineUsers[accountInfo.userId] = nil

        local agent = accountInfo.c.agent
        table.insert(agentPool, agent)
        log.infof("agent(%d) recycle, %d remain in pool", agent, #agentPool)

        kick(accountInfo.c.fd)
    end
end

function handler.command(cmd, _, ...)
    local f = assert(CMD[cmd])
    return f(...)
end

gateserver.start(handler)
