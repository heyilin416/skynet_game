local skynet = require "skynet"
local socket = require "socket"
local loginDB = require "db.login"
local protoloader = require "proto.loader"
local md5 = require "md5"
local bson = require "bson"

local traceback = debug.traceback

local master
local host
local authTimeout
local connection = {}

local CMD = {}

function CMD.init(m, id, conf)
    master = m
    host = protoloader.load()
    authTimeout = conf.authTimeout * 100
end

local function close(fd)
    if connection[fd] then
        socket.close(fd)
        connection[fd] = nil
        log.info("socket close", fd)
    end
end

local function read(fd, size)
    return socket.read(fd, size)
end

local function readMsg(fd)
    local s = read(fd, PACKET_HEAD_SIZE)
    if not s then
        close(fd)
        return s
    end

    local size = unpackPacketHead(s)
    local msg = read(fd, size)
    if not msg then
        close(fd)
        return msg
    end

    return host:dispatch(msg, size)
end

function CMD.auth(fd, addr)
    connection[fd] = addr
    skynet.timeout(authTimeout, function()
        if connection[fd] == addr then
            log.warningf("connection %d from %s auth timeout!", fd, addr)
            close(fd)
        end
    end)

    socket.start(fd)
    socket.limit(fd, 8192)

    local mType, name, args, response = readMsg(fd)
    if not mType then
        return
    end

    assert(mType == "REQUEST" and name == "LoginAccount")
    local accountInfo = loginDB:find("account", {accountName = args.accountName})
    if accountInfo then
        if accountInfo.password ~= args.password then
            sendMsg(fd, response{result = ErrorCode.ERR_PASSWORD})
            close(fd)
            return
        end
    else
        accountInfo = {_id = bson.objectid(), accountName = args.accountName, password = args.password}
        loginDB:insert("account", accountInfo)
    end

    local token = md5.sumhexa(accountInfo._id .. skynet.time())
    skynet.call(master, "lua", "saveToken", accountInfo._id, token)

    local servers = loginDB:findAll("server")
    local msg = response{
        result = ErrorCode.SUCCESS,
        accountId = accountInfo._id, 
        token = token,
        servers = servers,
    }
    sendMsg(fd, msg)
    close(fd)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local function ret(ok, ...)
            if not ok then
                log.warning(...)
                skynet.ret()
            else
                skynet.retpack(...)
            end
        end

        local f = assert(CMD[command])
        ret(xpcall(f, traceback, ...))
    end)
end)
