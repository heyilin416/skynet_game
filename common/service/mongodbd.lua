local skynet = require "skynet"
local mongo = require "mongo"

local maxConn
local pool = {}

local CMD = {}

function CMD.init(conf)
	maxConn = conf.maxConn
	assert(maxConn >= 1)

	for i = 1, maxConn do
		local client = mongo.client(conf)
		local db = client[conf.dbName]
		table.insert(pool, db)
	end
end

local index = 1
local function getDB()
	local db = pool[index]
	index = index + 1
	if index > maxConn then
		index = 1
	end
	return db
end

local function runCommand(command, collection, ...)
	local db = getDB()
	local collection = db[collection]
	local f = collection[command]
	if not f then
		error(string.format("%s command is not exist", command))
	end
    return f(collection, ...)
end

function CMD.find(collection, query, selector, other)
	local db = getDB()
	local cursor = db[collection]:find(query, selector)
	if other then
		if other.sort then
			cursor:sort(other.sort)
		end

		if other.skip then
			cursor:skip(other.skip)
		end

		if other.limit then
			cursor:limit(other.limit)
		end
	end

	local result = {}
	while cursor:hasNext() do
		table.insert(result, cursor:next())
	end
	cursor:close()
	return result
end

function CMD.findCount(collection, query)
	local db = getDB()
	local cursor = db[collection]:find(query, selector)
	return cursor:count()
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        if f then
        	skynet.retpack(f(...))
        else
        	skynet.retpack(runCommand(command, ...))
        end
    end)
end)