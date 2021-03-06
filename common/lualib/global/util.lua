local skynet = require "skynet"
local socketdriver = require "socketdriver"

log = {
	prefix = {
		"[debug]",
		"[info]",
		"[notice]",
		"[warning]",
		"[error]",
	},
}

local level
function log.level(lv)
	level = lv
end

local function write(priority, ...)
	if priority >= level then
		skynet.error(log.prefix[priority], ...)
	end
end

local function writef(priority, ...)
	if priority >= level then
		skynet.error(log.prefix[priority], string.format(...))
	end
end

function log.canDebug()
	return level <= 1
end

function log.debug(...)
	write(1, ...)
end

function log.debugf(...)
	writef(1, ...)
end

function log.canInfo()
	return level <= 2
end

function log.info(...)
	write(2, ...)
end

function log.infof(...)
	writef(2, ...)
end

function log.canNotice()
	return level <= 3
end

function log.notice(...)
	write(3, ...)
end

function log.noticef(...)
	writef(3, ...)
end

function log.canWarning()
	return level <= 4
end

function log.warning(...)
	write(4, ...)
end

function log.warningf(...)
	writef(4, ...)
end

function log.canError()
	return level <= 5
end

function log.error(...)
	write(5, ...)
end

function log.errorf(...)
	writef(5, ...)
end

log.level(tonumber(skynet.getenv("logLevel")) or 3)

function fileExists(name)
	local file, err = io.open(name)
	if file then
		file:close()
	end
	return not err or string.find(err, "No such file or directory") == nil
end

function strTime(time)
	return os.date("%Y-%m-%d %H:%M:%S", math.ceil(time))
end

function strNowTime()
	return strTime(skynet.time())
end

function strToLuaObj(str)
	return load("return " .. str)()
end

function strToHex(str)
	local hex = ""
	for i=1, #str do
		hex = hex .. string.format("%02x", str:byte(i))
	end
	return hex
end

function unpackPacketHead(msg)
	return string.unpack(PACKET_HEAD_PACK_FMT, msg)
end

function sendMsg(fd, msg)
    local package = string.pack(PACKET_PACK_FMT, msg)
    socketdriver.send(fd, package)
end

function getNameUpvalue(func, name)
	local i = 1
	while true do
		local vname, value = debug.getupvalue(func, i)
		if vname == nil then
			return
		elseif vname == name then
			return i, value
		end
		i=i+1
	end
end

function reloadModule(moduleName)
    local oldModule = _G[moduleName]

    package.loaded[moduleName] = nil
    require(moduleName)

    local newModule = _G[moduleName]
    for k, v in pairs(newModule) do
        oldModule[k] = v
    end

    package.loaded[moduleName] = oldModule
end