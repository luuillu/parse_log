--[[local downloadlog = "./sdcard1/server.log.8"]]
local downloadlog = "./server.log"
local f = assert(io.open(downloadlog,'r'))
io.input(f)
Filters = {}


--[[
日志过滤器logInfo 为数组，为了处理一条日志被分为多行的情况，
第一个元素代码第一行，即有时间那一行]]

function Filters.XLCreateShortVideoTask(time, logInfo)
	local str = logInfo[1]
	local log = string.match(str, "XLCreateShortVideoTask")
	if (log ~= nil) then
		print(str)
		return true
	else
		return false;
	end
end

function Filters.XLGetTaskLocalUrl(time, logInfo)
	local str = logInfo[1]
	local log = string.match(str, "XLGetTaskLocalUrl")
	if (log ~= nil) then
		print(str)
		return true
	else
		return false;
	end
end

function Filters.SessionReceive(time, logInfo)
	local str = logInfo[1]
	--[[Session::HandleRecvSuccess SessionId=[0] State=[wait] head=[GET]]
	local log = string.match(str, "Session::HandleRecvSuccess SessionId=%[(%d+)%] State=%[(%w+)%] head=%[(%w+)")
	if (log ~= nil) then
		print(str)
		return true
	else
		return false;
	end
end

function Filters.SessionReceive(time, logInfo)
	local str = logInfo[1]
	--[[Session::HandleRecvHead DoSend Respone SessionId=[0] Http=[HTTP/1.1 200 OK]]
	local log = string.match(str, "Session::HandleRecvHead DoSend Respone SessionId=%[(%d+)%] Http=%[HTTP/1.1 (%d+) OK")
	if (log ~= nil) then
		print(str)
		return true
	else
		return false;
	end
end







--框架部分
function getTime(str)
--[[2016-07-27 22:03:08:352]]
	local Y, Mo, D, H, M, S, mS = string.match(str, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+):(%d+)")
	if mS == nil then
		return nil
	end
	mS = tonumber(mS)
	S = tonumber(S)
	if (mS > 500) then
		S = S+1
	end
	--[[print(Y, Mo, D, H, M, S, mS)]]
	return os.time({year=Y, month=Mo, day=D, hour=H,min=M,sec=S})
end

function doFilter (time, logInfo)
	for k,filter in pairs(Filters) do
		if (filter(time, logInfo)) then
			break;
		end
	end
end

function Parse()
	local logInfo = {}
	while (true)
	do
		local line = io.read()
		if (line == nil) then
			break
		end

		local time = getTime(line)
		if (time ~= nil) then
			--[[print(os.date("%x %X", getTime(line)))]]
			if (table.getn(logInfo) >0) then
				doFilter(time, logInfo)
			end
			logInfo = {line}
		else
			if (table.getn(logInfo) > 0) then
				table.insert(logInfo, line);
			end
		end
	end

	if (table.getn(logInfo) >0) then
		doFilter(time, logInfo)
	end
end

Parse()




