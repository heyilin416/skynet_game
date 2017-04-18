local handler = {}
local mt = {__index = handler}

function handler.new(request, response, cmd)
	return setmetatable ({
		init_func = {},
		request = request,
		response = response,
		cmd = cmd,
	}, mt)
end

function handler:init(f)
	table.insert(self.init_func, f)
end

local function merge(dest, t)
	if not dest or not t then return end
	for k, v in pairs(t) do
		dest[k] = v
	end
end

function handler:register(user)
	for _, f in pairs(self.init_func) do
		f(user)
	end

	merge(user.request, self.request)
	merge(user.response, self.response)
	merge(user.cmd, self.cmd)
end

local function clean(dest, t)
	if not dest or not t then return end
	for k, _ in pairs(t) do
		dest[k] = nil
	end
end

function handler:unregister(user)
	clean(user.request, self.request)
	clean(user.response, self.response)
	clean(user.cmd, self.cmd)
end

return handler
