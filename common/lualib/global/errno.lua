ErrorCode = {
	SUCCESS = 0, 				-- 成功
	ERR_PACKET_TYPE = 1,		-- 包类型
	ERR_UNKNOW = 2,				-- 服务端异常
	ERR_PASSWORD = 3, 			-- 密码错误
	ERR_TOKEN = 4,				-- token错误
	ERR_GAME_NOT_CHECK = 5, 	-- 未进行Game验证
	ERR_USER_NOT_EXIST = 6,		-- 角色不存在
	ERR_LOCK_TIMEOUT = 7,		-- 获取锁超时
	ERR_USERNAME_EXIST = 8,		-- 角色名称已经存在
	ERR_USERNAME_NOT_EXIST = 9,	-- 角色名称不存在
}
