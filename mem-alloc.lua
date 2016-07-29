--[[local downloadlog = "./sdcard1/server.log.8"]]
local downloadlog = "./local/server.log"
local f = assert(io.open(downloadlog,'r'))
io.input(f);


function string2time( timeString )
    local Y = string.sub(timeString , 1, 4)
    local M = string.sub(timeString , 5, 6)
    local D = string.sub(timeString , 7, 8)
    return os.time({year=Y, month=M, day=D, hour=0,min=0,sec=0})
end


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


local AllocInfo = {}
--[[key:0xx, value{0 alloc, 1, free, 3 diff }]]
local addrMap = {}

function getAllocAddr(str)
	local addr = string.match(str, "TaskDataMemroy::AllocMemory buffer=0x(%x+)")
	return addr
end

function getFreeAddr(str)
	local addr = string.match(str, "TaskDataMemroy::FreeMemory buffer=0x(%x+)")
	return addr
end

local result = {}

function setAllocInfo(addr, allocTime, freeTime)
	if addrMap[addr] == nil then
		addrMap[addr] = {0,0}
	end

	if allocTime >0 then
		addrMap[addr][1] = allocTime
	end

	if freeTime >0 then
		addrMap[addr][2] = freeTime
		--[[print ("alloc time="..os.date("%x %X",addrMap[addr][1]) .. ", free time="..os.date("%x %X",freeTime)..", addr="..addr)]]
		if (addrMap[addr][1]>0) then
			table.insert(result, {k=addr, v=addrMap[addr]})
		end
		addrMap[addr] = {0, 0}
	end
end

function getAllocSize(str)
	return string.match(str, "need=(%d+)")
end

local oldLine = nil
while (true)
do
	local line = io.read()
	if (line == nil) then
		break
	end

	local time = getTime(line)
	if (time ~= nil) then
		--[[print(os.date("%x %X", getTime(line)))]]

		local allocAddr = getAllocAddr(line)
		if (allocAddr ~= nil) then
			setAllocInfo(allocAddr, time, 0)

			if (oldLine ~= nil) then
				addrMap[allocAddr].allocSize = getAllocSize(oldLine)
				--[[print(getAllocSize(oldLine))]]
			end
		end

		local freeAddr = getFreeAddr(line)
		if (freeAddr ~= nil) then
			setAllocInfo(freeAddr, 0, time)
		end

		oldLine = line

	end
end

table.sort(result, function(a, b)
if (b == nil) then
	return false
end
--[[print("a="..tostring(a)..", b="..tostring(b))]]
		ta = a.v[1]
		tb = b.v[1]
		if (ta == tb) then
			return tostring(a) < tostring(b)
		end
		return ta < tb
end)

for i=1 ,#result do
	local size = "unknown"
	if (result[i].v.allocSize ~= nil) then
		size = result[i].v.allocSize
	end
	print ("alloc time="..os.date("%x %X",result[i].v[1]) .. ", free time="..os.date("%x %X",result[i].v[2])..", addr=0x"..result[i].k..", timeCost="..result[i].v[2]-result[i].v[1]..",\tallocSize="..size)
end


io.close(f)
