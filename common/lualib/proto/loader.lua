local sprotoloader = require "sprotoloader"

local loader = {
	C2S = 0,
	S2C = 1,
}

local host, request

function loader.init()
	sprotoloader.register("../common/lualib/proto/C2S.proto", loader.C2S)
	sprotoloader.register("../common/lualib/proto/S2C.proto", loader.S2C)
end

function loader.load()
	if host and request then
		return host, request
	end

	host = sprotoloader.load(loader.C2S):host("package")
	request = host:attach(sprotoloader.load(loader.S2C))
	return host, request
end

return loader