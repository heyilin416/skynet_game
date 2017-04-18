local skynet = require "skynet"
require "skynet.manager"

local MongoDB = class("MongoDB")

local function checkResult(result, n)
	if result.ok ~= 1 or result.writeErrors or result.writeConcernError or (n and result.n ~= n) then
		error(tostring(result))
	end
end

function MongoDB:init(localName, conf)
    local addr = skynet.localname(localName)
    if not addr then
        addr = skynet.newservice("mongodbd")
        skynet.name(localName, addr)
        skynet.call(addr, "lua", "init", conf)
    end
    self._serviceAddr = addr
end

function MongoDB:insert(collection, doc)
	result = skynet.call(self._serviceAddr, "lua", "safe_insert", collection, doc)
	checkResult(result, 1)
	return result
end

function MongoDB:insertMore(collection, docs)
	result = skynet.call(self._serviceAddr, "lua", "safe_batch_insert", collection, docs)
	checkResult(result, #docs)
	return result
end

function MongoDB:update(collection, query, update, upsert)
	result = skynet.call(self._serviceAddr, "lua", "safe_update", collection, query, update, upsert, false)
	checkResult(result, 1)
	return result
end

function MongoDB:updateId(collection, id, update, upsert)
	result = skynet.call(self._serviceAddr, "lua", "safe_update", collection, {_id = id}, update, upsert, false)
	checkResult(result, 1)
	return result
end

function MongoDB:updateAll(collection, query, update, upsert)
	result = skynet.call(self._serviceAddr, "lua", "safe_update", collection, query, update, upsert, true)
	checkResult(result)
	return result
end

function MongoDB:delete(collection, query)
	result = skynet.call(self._serviceAddr, "lua", "safe_delete", collection, query, true)
	checkResult(result, 1)
	return result
end

function MongoDB:deleteId(collection, id)
	result = skynet.call(self._serviceAddr, "lua", "safe_delete", collection, {_id = id}, true)
	checkResult(result, 1)
	return result
end

function MongoDB:deleteAll(collection, query)
	result = skynet.call(self._serviceAddr, "lua", "safe_delete", collection, query, false)
	checkResult(result)
	return result
end

function MongoDB:find(collection, query, items)
	return skynet.call(self._serviceAddr, "lua", "findOne", collection, query, items)
end

function MongoDB:findId(collection, id, items)
	return skynet.call(self._serviceAddr, "lua", "findOne", collection, {_id = id}, items)
end

function MongoDB:findAll(collection, query, items, other)
	return skynet.call(self._serviceAddr, "lua", "find", collection, query, items, other)
end

function MongoDB:findCount(collection, query)
	return skynet.call(self._serviceAddr, "lua", "findCount", collection, query)
end

function MongoDB:findAndModify(collection, doc)
	result = skynet.call(self._serviceAddr, "lua", "findAndModify", collection, doc)
	checkResult(result)
	return result
end

function MongoDB:createIndex(collection, ...)
	result = skynet.call(self._serviceAddr, "lua", "createIndexes", collection, ...)
	checkResult(result)
	return result
end

function MongoDB:dropIndex(collection, indexName)
	result = skynet.call(self._serviceAddr, "lua", "dropIndex", collection, indexName)
	checkResult(result)
	return result
end

function MongoDB:dropIndexAll(collection)
	result = skynet.call(self._serviceAddr, "lua", "dropIndex", collection, "*")
	checkResult(result)
	return result
end

function MongoDB:drop(collection)
	result = skynet.call(self._serviceAddr, "lua", "drop", collection)
	checkResult(result)
	return result
end

return MongoDB