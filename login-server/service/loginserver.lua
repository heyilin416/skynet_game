local skynet = require "skynet"
local socket = require "socket"
local cluster = require "cluster"

local nslave
local slave = {}
local accountToken = {}
local sessionExpireTime

local CMD = {}

function CMD.init(conf)
    for i = 1, conf.slave do
        local s = skynet.newservice("loginslave")
        skynet.call(s, "lua", "init", skynet.self(), i, conf)
        table.insert(slave, s)
    end
    nslave = #slave

    sessionExpireTime = conf.sessionExpireTime * 100

    local host = conf.host or "0.0.0.0"
    local port = assert(tonumber(conf.port))
    local sock = socket.listen(host, port)
    skynet.error(string.format("Listen on %s:%d", host, port))

    local balance = 1
    socket.start(sock, function(fd, addr)
        local s = slave[balance]
        balance = balance + 1
        if balance > nslave then 
            balance = 1 
        end

        skynet.send(s, "lua", "auth", fd, addr)
        log.info("socket connect", fd, addr)
    end)

    cluster.register("loginServer")
end

function CMD.saveToken(accountId, token)
    accountToken[accountId] = token
    skynet.timeout(sessionExpireTime, function()
        if accountToken[accountId] then
            accountToken[accountId] = nil
            log.warningf("%s account of token is expire", accountId)
        end
    end)
end

function CMD.checkToken(accountId, token)
    if accountToken[accountId] == token then
        accountToken[accountId] = nil
        return ErrorCode.SUCCESS
    else
        return ErrorCode.ERR_TOKEN
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command])
        skynet.retpack(f(...))
    end)
end)
