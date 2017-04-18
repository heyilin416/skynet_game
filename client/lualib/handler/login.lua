local handler = require "handler.handler"

local request = {}
local response = {}
local handler = handler.new(request, response)

local user
handler:init(function(u)
	user = u
end)

function response.LoginAccount(request, response)
    print(response)
    user:close(true)
end

return handler