local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local table = table
local string = string
local traceback = debug.traceback

local handlerModules = {...}
local REQUEST = {}

local function response(fd, code, ...)
	local args = {...}
	if code ~= 200 then
		table.insert(args, string.format("http error code : %d", code))
	end

	local ok, err = httpd.write_response(sockethelper.writefunc(fd), code, table.unpack(args))
	if not ok then
		if err == sockethelper.socket_error then
			log.notice("http write response socket closed")
		else
			log.errorf("http write response error(fd=%d, err=%s)", fd, err)
		end
	end
end

skynet.start(function()
	for _, moduleName in ipairs(handlerModules) do
		table.merge(REQUEST, require(moduleName))
	end

	skynet.dispatch("lua", function (_, _, fd, addr)
		socket.start(fd)

		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
		if code then
			if code ~= 200 then
				response(fd, code)
			else
				local args = {}
				local path, query = urllib.parse(url)
				if method == "GET" then
					args = urllib.parse_query(query)
				elseif header["content-type"] == "application/x-www-form-urlencoded" then
					args = urllib.parse_query(body)
				end

				if log.canInfo() then
					log.infof("http read request(addr=%s, path=%s, args=%s)", addr, path, tostring(args))
				end

				local handleFunc = REQUEST[path:sub(2)]
				if handleFunc then
					local ok, result = xpcall(handleFunc, traceback, args, header, body)
					if ok then
						response(fd, code, result)
					else
						response(fd, 500)
						log.errorf("http read request(addr=%s, path=%s, args=%s, err=%s)", addr, path, tostring(args), result)
					end
				else
					response(fd, 404)
				end
			end
		else
			if url == sockethelper.socket_error then
				log.notice("http read request socket closed")
			else
				log.error("http read request url error :", url)
			end
		end
		socket.close(fd)
	end)
end)