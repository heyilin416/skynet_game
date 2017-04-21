local skynet = require "skynet"
local gameDB = require "db.game"
local protoloader = require "proto.loader"

local traceback = debug.traceback
local _, request = protoloader.load()

local User = class("User")

function User:ctor(gated, userId)
    self.gated = gated
    self.data = gameDB:findId("user", userId)

    self.sessionId = 0
    self.session = {}

    self.REQUEST = {}
    self.RESPONSE = {}
end

function User:login(fd)
    self.fd = fd
    log.infof("%s user login", self.data.name)
    return self.data
end

function User:logout()
    skynet.call(self.gated, "lua", "logout", self.data.accountId)
    log.infof("%s user logout", self.data.name)
end

function User:kick()
    if self.fd then
        skynet.call(self.gated, "lua", "kick", self.fd)
        log.infof("%s user kick", self.data.name)
    end
end

function User:close()
    if self.fd then
        self.fd = nil
    end
end

function User:sendMsg(msg)
    if self.fd then
        sendMsg(self.fd, msg)
    end
end

function User:call(name, args)
    local sessionId = self.sessionId + 1
    self.sessionId = sessionId
    self:sendMsg(request(name, args, sessionId))
    self.session[sessionId] = { name = name, args = args }
end

function User:send(name, args)
    self:sendMsg(request(name, args))
end

function User:handleMsg(mType, ...)
    if mType == "REQUEST" then
        self:handleRequest(...)
    else
        self:handleResponse(...)
    end
end

function User:handleRequest(name, args, response)
    local f = self.REQUEST[name]
    if f then
        local ok, ret = xpcall(f, traceback, name, args)
        if not ok then
            log.errorf("handle request(%s) failed : %s", name, ret)
            self:kick()
        else
            if response and ret then
                self:sendMsg(self.fd, response(ret))
            end
        end
    else
        log.errorf("unhandled request : %s", name)
        self:kick()
    end
end

function User:handleResponse(id, args)
    local s = self.session[id]
    if not s then
        log.errorf("session %d not found", id)
        self:kick()
        return
    end

    local f = self.RESPONSE[s.name]
    if not f then
        log.errorf("unhandled response : %s", s.name)
        self:kick()
        return
    end

    local ok, ret = xpcall(f, traceback, s.name, s.args, args)
    if not ok then
        log.errorf("handle response(%d-%s) failed : %s", id, s.name, ret)
        self:kick()
    end
end

return User