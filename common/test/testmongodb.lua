local skynet = require "skynet"
local MongoDB = require "mongodb"

local testDB = MongoDB.new()
local testCollection = "test"

local function test_createIndex()
	testDB:drop(testCollection)

	local result = testDB:createIndex(testCollection, {"key1", "key2", unique = true})
	print("test_createIndex", result)
	assert(result.ok == 1 and result.numIndexesBefore == 1 and result.numIndexesAfter == 2)

	result = testDB:createIndex(testCollection, {"key3", "key4", unique = true}, {"key5", "key6", unique = true})
	print("test_createIndexes", result)
	assert(result.ok == 1 and result.numIndexesBefore == 2 and result.numIndexesAfter == 4)
end

local function test_dropIndex()
	testDB:drop(testCollection)
	testDB:createIndex(testCollection, {"key1", "key2", unique = true})

	local result = testDB:dropIndex(testCollection, "key1_1_key2_1")
	print("test_dropIndex", result)
	assert(result.ok == 1 and result.nIndexesWas == 2)
end

local function test_dropIndexAll()
	testDB:drop(testCollection)
	testDB:createIndex(testCollection, {"key1", "key2", unique = true}, {"key3", "key4", unique = true})

	local result = testDB:dropIndexAll(testCollection)
	print("test_dropIndexAll", result)
	assert(result.ok == 1 and result.nIndexesWas == 3)
end

local function test_insert()
	testDB:drop(testCollection)

	local result = testDB:insert(testCollection, {_id = 0})
	print("test_insert", result)
	assert(result.ok == 1 and result.n == 1)

	local ok, result = pcall(testDB.insert, testDB, testCollection, {_id = 0})
	print("test_insert", ok, result)
	assert(not ok)
end

local function test_insertMore()
	testDB:drop(testCollection)

	local result = testDB:insertMore(testCollection, {{_id = 1}, {_id = 2}})
	print("test_insertMore", result)
	assert(result.ok == 1 and result.n == 2)

	local ok, result = pcall(testDB.insertMore, testDB, testCollection, {{_id = 1}, {_id = 2}})
	print("test_insertMore", ok, result)
	assert(not ok)
end

local function test_update()
	testDB:drop(testCollection)

	local ok, result = pcall(testDB.update, testDB, testCollection, {_id = 1}, {value = 2})
	print("test_update", ok, result)
	assert(not ok)

	testDB:insert(testCollection, {_id = 1, value = 1})
	result = testDB:update(testCollection, {_id = 1}, {value = 2})
	print("test_update", result)
end

local function test_updateId()
	testDB:drop(testCollection)

	local ok, result = pcall(testDB.updateId, testDB, testCollection, 1, {value = 2})
	print("test_updateId", ok, result)
	assert(not ok)

	testDB:insert(testCollection, {_id = 1, value = 1})
	result = testDB:updateId(testCollection, 1, {value = 2})
	print("test_updateId", result)
end

local function test_updateAll()
	testDB:drop(testCollection)

	local result = testDB:updateAll(testCollection, {value = {["$gt"] = 0}}, {["$set"] = {value = 2}})
	print("test_updateAll", result)

	testDB:insertMore(testCollection, {{_id = 1, value = 1}, {_id = 2, value = 2}})
	result = testDB:updateAll(testCollection, {value = {["$gt"] = 0}}, {["$set"] = {value = 2}})
	print("test_updateAll", result)
	assert(result.ok == 1 and result.n == 2)
end

local function test_delete()
	testDB:drop(testCollection)

	local ok, result = pcall(testDB.delete, testDB, testCollection, {_id = 1})
	print("test_delete", ok, result)
	assert(not ok)

	testDB:insert(testCollection, {_id = 1, value = 1})
	result = testDB:delete(testCollection, {_id = 1})
	print("test_delete", result)
end

local function test_deleteId()
	testDB:drop(testCollection)

	local ok, result = pcall(testDB.deleteId, testDB, testCollection, 1)
	print("test_deleteId", ok, result)
	assert(not ok)

	testDB:insert(testCollection, {_id = 1, value = 1})
	result = testDB:deleteId(testCollection, 1)
	print("test_deleteId", result)
end

local function test_deleteAll()
	testDB:drop(testCollection)
	local result = testDB:deleteAll(testCollection, {value = {["$gt"] = 0}})
	print("test_deleteAll", result)

	testDB:insertMore(testCollection, {{_id = 1, value = 1}, {_id = 2, value = 2}})
	result = testDB:deleteAll(testCollection, {value = {["$gt"] = 0}})
	print("test_deleteAll", result)
	assert(result.ok == 1 and result.n == 2)
end

local function test_find()
	testDB:drop(testCollection)

	testDB:insert(testCollection, {_id = 1, value1 = 1, value2 = 2})
	result = testDB:find(testCollection, {_id = 1})
	print("test_find", result)
	assert(result.value1 == 1 and result.value2 == 2)
end

local function test_findId()
	testDB:drop(testCollection)

	testDB:insert(testCollection, {_id = 1, value1 = 1, value2 = 2})
	result = testDB:findId(testCollection, 1, {value2 = 1})
	print("test_findId", result)
	assert(result.value1 == nil and result.value2 == 2)
end

local function test_findAll()
	testDB:drop(testCollection)

	testDB:insertMore(testCollection, {{_id = 1, value = 1}, {_id = 2, value = 2}})
	result = testDB:findAll(testCollection, {value = {["$gt"] = 0}})
	print("test_findAll", result)
	assert(#result == 2)
end

local function test_findCount()
	testDB:drop(testCollection)

	testDB:insertMore(testCollection, {{_id = 1, value = 1}, {_id = 2, value = 2}})
	result = testDB:findCount(testCollection, {value = {["$gt"] = 0}})
	print("test_findCount", result)
	assert(result == 2)
end

local function test_findAndModify()
	testDB:drop(testCollection)

	local result = testDB:findAndModify(testCollection, {query = {_id = 1}, update = {value = 2}})
	print("test_findAndModify", result)

	testDB:insert(testCollection, {_id = 1, value = 1})
	result = testDB:findAndModify(testCollection, {query = {_id = 1}, update = {value = 2}})
	print("test_findAndModify", result)

	result = testDB:findAndModify(testCollection, {query = {_id = 1}, remove = true})
	print("test_findAndModify", result)
end

skynet.start(function()
	testDB:init({maxConn = 8, dbName = "test", host = "127.0.0.1"})
	pcall(testDB.drop, testDB, testCollection)
	testDB:createIndex(testCollection, {"key1", "key2", unique = true})

	test_createIndex()
	test_dropIndex()
	test_dropIndexAll()
	test_insert()
	test_insertMore()
	test_update()
	test_updateId()
	test_updateAll()
	test_delete()
	test_deleteId()
	test_deleteAll()
	test_find()
	test_findId()
	test_findAll()
	test_findCount()
	test_findAndModify()

	print("mongodb test finish.");
end)
