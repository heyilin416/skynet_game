local skynet = require "skynet"
local socket = require "socket"
local protoloader = require "proto.loader"
local loginHandler = require "handler.login"

local traceback = debug.traceback
local host, request = protoloader.loadClient()

local User = class("User")

function User:ctor(serverId, accountName, password)
    self.serverId = serverId
    self.accountName = accountName
    self.password = password

    self.sessionId = 0
    self.session = {}

    self.request = {}
    self.response = {}
    loginHandler:register(self)
end

function User:connect(ip, port)
    while true do
        local ok, fd = pcall(socket.open, ip, port)
        if ok then
            self.fd = fd
            self.lastReadBuff = ""
            skynet.fork(self.dispatchMsg, self)
            break
        end

        log.errorf("%s connect(ip=%s, port=%d) is error", self.accountName, ip, port)
        skynet.sleep(500)
    end
end

function User:login()
    local ip = skynet.getenv("loginIp")
    local port = tonumber(skynet.getenv("loginPort"))
    self:connect(ip, port)

    self:call("LoginAccount", {accountName = self.accountName, password = self.password})
end

function User:close(isActive)
    if self.fd then
        socket.shutdown(self.fd)
        self.fd = nil
    end

    if not isActive then
        self:login()
    end
end

function User:read(size)
    return socket.read(self.fd, size) or error(string.format("connection %d read error", self.fd))
end

function User:readMsg()
    local s = self:read(2)
    local size = s:byte(1) * 256 + s:byte(2)
    local msg = self:read(size)
    return host:dispatch(msg, size)
end

function User:dispatchMsg()
    local handle = function()
        self:handleMsg(self:readMsg())
    end

    while self.fd do
        local ok, err = xpcall(handle, traceback)
        if not ok then
            log.warningf("dispatchMsg error : %s", err)
            break
        end
    end

    if self.fd then
        self:close()
    end
end

function User:sendMsg(msg)
    local package = string.pack(">s2", msg)
    socket.write(self.fd, package)
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

function User:handleMsg(type, ...)
    if type == "REQUEST" then
        self:handleRequest(...)
    else
        self:handleResponse(...)
    end
end

function User:handleRequest(name, args, response)
    local f = self.request[name]
    if f then
        local ok, ret = xpcall(f, traceback, args)
        if not ok then
            log.warningf("handle message(%s) failed : %s", name, ret)
            self:close()
        else
            if response and ret then
                self:sendMsg(self.fd, response(ret))
            end
        end
    else
        log.warningf("unhandled message : %s", name)
        self:close()
    end
end

function User:handleResponse(id, args)
    local s = self.session[id]
    if not s then
        log.warningf("session %d not found", id)
        self:close()
        return
    end

    local f = self.response[s.name]
    if not f then
        log.warningf("unhandled response : %s", s.name)
        self:close()
        return
    end

    local ok, ret = xpcall(f, traceback, s.args, args)
    if not ok then
        log.warningf("handle response(%d-%s) failed : %s", id, s.name, ret)
        self:close()
    end
end

return User