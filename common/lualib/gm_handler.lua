local skynet = require "skynet"

local REQUEST = {}

function REQUEST.test(args, header, body)
	return "args:" .. tostring(args) .. "\n\nheader:" .. tostring(header) .. "\n\nbody:" .. tostring(body)
end

function REQUEST.run(args, header, body)
	local fileName = args.fileName
	local code = args.code
	if fileName then
		local f = io.open(fileName, "rb")
		if not f then
			return "Can't open " .. fileName
		end
		code = f:read "*a"
		f:close()
	end

	local ok, output = skynet.call(tonumber(args.address), "debug", "RUN", code, fileName)
	if ok == false then
		error(output)
	end
	return output
end

return REQUEST