local skynet = require "skynet"

SERVER_NAME = skynet.getenv("serverName")	-- 服务器名称
PACKET_HEAD_SIZE = 2						-- 包头字节数
PACKET_HEAD_PACK_FMT = ">I2"				-- 包头打包格式
PACKET_PACK_FMT = ">s2"						-- 包打包格式
