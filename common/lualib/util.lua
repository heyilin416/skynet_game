local skynet = require "skynet"

local util = {}

function util.strTime(time)
	return os.date("%Y-%m-%d %H:%M:%S", math.ceil(time))
end

function util.strNowTime()
	return util.strTime(skynet.time())
end

return util