local skynet = require "skynet"
require "skynet.manager"
local util = require "util"

local file = nil
local isPrint = skynet.getenv("logIsPrint") == "true" and true or false

local function flush()
	local interval = 100 * tonumber(skynet.getenv("logFlushInterval"))
	while true do
		skynet.sleep(interval)
		file:flush()
	end
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
		content = string.format("%s(:%08x): %s", util.strNowTime(), address, msg)
		file:write(content, "\n")

		if isPrint then
			print(content)
		end
	end
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function()
		file:close()
	end
}

skynet.start(function()
	filePath = skynet.getenv("logPath") .. os.date("/%Y-%m-%d_%H.%M.%S.log", math.ceil(skynet.time()))
	file = io.open(filePath, "w")
	if not file then
		print(string.format("%s file open fail", filePath))
		skynet.sleep(500)
		os.exit()
	else
		file:setvbuf("full")
		skynet.fork(flush)
	end

	skynet.register ".logger"
end)