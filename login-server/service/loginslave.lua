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
    end
end

local function read(fd, size)
    return socket.read(fd, size) or error(string.format("connection %d read error", fd))
end

local function readMsg(fd)
    local s = read(fd, 2)
    local size = s:byte(1) * 256 + s:byte(2)
    local msg = read(fd, size)
    return host:dispatch(msg, size)
end

local function sendMsg(fd, msg)
    local package = string.pack(">s2", msg)
    socket.write(fd, package)
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

    local type, name, args, response = readMsg(fd)
    assert(type == "REQUEST", name == "LoginAccount")
    local accountInfo = loginDB:find("account", {accountName = args.accountName})
    if accountInfo then
        if accountInfo.password ~= args.password then
            sendMsg(fd, response {result = errorCode})
            close(fd)
            return
        end
    else
        accountInfo = {_id = bson.objectid(), accountName = args.accountName, password = md5.sumhexa(args.password)}
        loginDB:insert("account", accountInfo)
    end

    local token = md5.sumhexa(accountInfo._id .. skynet.time())
    skynet.call(master, "lua", "saveToken", accountInfo._id, token)

    local msg = response{
        result = ErrorCode.SUCCESS,
        accountID = accountInfo._id, 
        token = token,
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
