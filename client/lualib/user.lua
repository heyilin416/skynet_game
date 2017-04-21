local skynet = require "skynet"
local socket = require "socket"
local md5 = require "md5"
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

    self.REQUEST = {}
    self.RESPONSE = {}
    loginHandler:register(self)
end

function User:connect(ip, port)
    while true do
        local fd, err = socket.open(ip, port)
        if not err then
            self.fd = fd
            self.lastReadBuff = ""
            skynet.fork(self.dispatchMsg, self, self.fd)
            log.infof("%s connect(ip=%s, port=%s) is success", self.accountName, ip, port)
            return
        end

        log.errorf("%s connect(ip=%s, port=%s) is error", self.accountName, ip, port)
        skynet.sleep(500)
    end
end

function User:login()
    local ip = skynet.getenv("loginIp")
    local port = tonumber(skynet.getenv("loginPort"))
    self:connect(ip, port)

    log.infof("%s start login", self.accountName)
    self:call("LoginAccount", {accountName = self.accountName, password = md5.sumhexa(self.password)})
end

function User:close(isActive)
    if self.fd then
        socket.shutdown(self.fd)
        self.fd = nil
    end

    if not isActive then
        log.infof("%s after 5 sec login again", self.accountName)
        skynet.sleep(500)
        self:login()
    end
end

function User:read(size)
    return socket.read(self.fd, size)
end

function User:readMsg()
    local s = self:read(PACKET_HEAD_SIZE)
    if not s then
        return s
    end

    local size =unpackPacketHead(s)
    local msg = self:read(size)
    if not msg then
        return msg
    end

    return host:dispatch(msg, size)
end

function User:dispatchMsg(fd)
    local handle = function()
        self:handleMsg(self:readMsg())
    end

    while self.fd == fd do
        local ok, err = xpcall(handle, traceback)
        if not ok then
            log.errorf("dispatchMsg error : %s", err)
			self:close()
            break
        end
    end
end

function User:sendMsg(msg)
    sendMsg(self.fd, msg)
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
    if not mType then
        log.errorf("%s socket by remote closed", self.accountName)
        self:close()
    elseif mType == "REQUEST" then
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
            self:close()
        else
            if response and ret then
                self:sendMsg(self.fd, response(ret))
            end
        end
    else
        log.errorf("unhandled request : %s", name)
        self:close()
    end
end

function User:handleResponse(id, args)
    local s = self.session[id]
    if not s then
        log.errorf("session %d not found", id)
        self:close()
        return
    end

    local f = self.RESPONSE[s.name]
    if not f then
        log.errorf("unhandled response : %s", s.name)
        self:close()
        return
    end

    local ok, ret = xpcall(f, traceback, s.name, s.args, args)
    if not ok then
        log.errorf("handle response(%d-%s) failed : %s", id, s.name, ret)
        self:close()
    end
end

function User:logRequestError(name, errorCode)
    log.errorf("%s request %s is error(%s)", self.accountName, name, errorCode)
end

return User