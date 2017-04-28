local skynet = require "skynet"
local REQUEST = require "gm_handler"

function REQUEST.runUserCode(args, header, body)
	local result
	if args.userId then
		result = skynet.call(".gated", "lua", "runUserCodeById", args.userId, args.code)
	else
		result = skynet.call(".gated", "lua", "runUserCodeByName", args.userName, args.code)
	end
	return tostring(result)
end

return REQUEST