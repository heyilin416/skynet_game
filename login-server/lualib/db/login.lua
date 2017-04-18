local skynet = require "skynet"
local MongoDB = require "mongodb"

local loginDB = MongoDB.new()

skynet.init(function()
    loginDB:init(".loginDB", strToLuaObj(skynet.getenv("loginDB")))
end)

return loginDB