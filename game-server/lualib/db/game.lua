local skynet = require "skynet"
local MongoDB = require "mongodb"

local gameDB = MongoDB.new()

skynet.init(function()
    gameDB:init(".gameDB", strToLuaObj(skynet.getenv("gameDB")))
end)

return gameDB