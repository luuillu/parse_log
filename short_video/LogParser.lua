LogParser = {}


--¿ò¼Ü²¿·Ö
function getTime(str)
--[[2016-07-27 22:03:08:352]]
	local Y, Mo, D, H, M, S, mS = string.match(str, "^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+):(%d+)")
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
			if (#logInfo >0) then
				doFilter(time, logInfo)
			end
			logInfo = {line}
		else
			if (#logInfo > 0) then
				table.insert(logInfo, line);
			end
		end
	end

	if (#logInfo >0) then
		doFilter(time, logInfo)
	end
end

--[[
CommonInfo = {
  mRawLog = {},
  mTimeStamp,
  mLineNo,
  mThreadId,
  mDebugLevel,
  mModule,
  mFunction,
}]]

local function isExistInArray(array, value) 
  if (array == nil) then
    return false
  end
  for i, v in ipairs(array) do
    if (tostring(v) == value) then
      return true;
    end
  end
  return false
end

local function doMatch(commonInfo, param, ...) 
  arg = {...}
  if (#arg == 0) then
    return nil
  end
  
  if (param == nil) then
    return commonInfo 
  end

  if ("function" == type(param)) then
    return param(commonInfo, table.unpack(arg))
  end
  
  local find = true
  for i, v in ipairs(arg) do
    assert (param[i] == nil or "table" == type(param[i]), "the param ".. tostring(param[i]) .. " must be table")

    if (param[i] ~= nil and (#param[i])>0) then
      if (not isExistInArray(param[i], v)) then
        find = false
      end
    end
  end
  
  if (find) then
    for i, v in ipairs(arg) do
      if (param[i] ~= nil and param[i].AS ~= nil) then
        commonInfo[param[i].AS] = v
      end
    end
    return commonInfo
  else
    return nil 
  end
end

local function stringPatternFilter(commonInfo, strPattern, param)
	return doMatch(commonInfo, param, string.match(commonInfo.mRawLog[1], strPattern))
end

local function printFilter(commonInfo)
  for i, line in ipairs(commonInfo.mRawLog) do
    print("line:" .. commonInfo.mLineNo + (i-1) .."\t"..commonInfo.mRawLog[i])
  end
end

local function doFilter(filters, logInfo)
  if (filters == nil) then
    return printFilter(logInfo)
  elseif ("string" == type(filters)) then
    return stringPatternFilter(logInfo, filters)
  elseif ("table" == type(filters)) then
    for k, v in pairs(filters) do
      if ("number" == type(k)) then
        if ("string" == type(v)) then
          local obj = stringPatternFilter(logInfo, v)
          if (nil ~=  obj) then
            return obj
          end
        elseif ("function" == type(v)) then
          local obj = v(logInfo)
          if (nil ~=  obj) then
            return obj
          end
        end
      elseif ("string" == type(k)) then
        local obj = stringPatternFilter(logInfo, k, v)
        if (nil ~=  obj) then
          return obj
        end
      end
    end
  elseif ("function" == type(filters)) then
    return filters(logInfo)
  end
end

local function parseCommonInfo (strLine)
  local Y, Mo, D, H, M, S, mS,tid, level, strModule, strFunction = string.match(strLine,"^(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+):(%d+)%s+%[(%d+)%]%[(%w+)%]%[([%w_]+)%]%[([%w_]+:%d+)%]")
	if Y == nil then
    --[[print ("parseCommonInfo strLine=" .. strLine)]]
		return nil
	end
	mS = tonumber(mS)
	S = tonumber(S)
	if (mS > 500) then
		S = S+1
	end
  
  commonInfo = {}
	commonInfo.mTimeStamp = os.time({year=Y, month=Mo, day=D, hour=H,min=M,sec=S})
  commonInfo.mThreadId = tid
  commonInfo.mDebugLevel = level
  commonInfo.mModule = strModule
  commonInfo.mFunction = strFunction
  return commonInfo;
end

function LogParser:initParser()
	local rawLog = {}
  local logInfos = {}
  local lineNo = 0
  local oldCommonInfo = nil
	while (true) do
    lineNo = lineNo + 1
    local line = io.read()
    if (line == nil) then
      break
    end

    local commonInfo = parseCommonInfo(line)
    if (commonInfo ~= nil) then
      commonInfo.mRawLog = {line}
      commonInfo.mLineNo = lineNo
      table.insert(logInfos, commonInfo)
      oldCommonInfo = commonInfo
    elseif (oldCommonInfo ~= nil) then
      table.insert(oldCommonInfo.mRawLog, line)
    end
  end
  self.mLogInfos = logInfos
end


local function createObject()
  local obj = {}
  setmetatable(obj, {__index = LogParser})
  return obj
end
function LogParser.LogParser(strFilePath)
  local f = assert(io.open(strFilePath,'r'))
  io.input(f)
  local obj = createObject()
  obj:initParser()
  io.close(f)
  return obj
end

function LogParser:filterBy(filters)
  local logInfos = {}
  for i, v in ipairs(self.mLogInfos) do
    local obj = doFilter(filters, v)
    if (nil ~= obj) then
      table.insert(logInfos, obj)
    end
  end
  local result = createObject()
  result.mLogInfos = logInfos
  --[[print ("result.mLogInfos getn=" .. #logInfos)]]
  return result;
end

--[[
function LogParser:groupBy(...)
  arg = {...}
  if (arg.n == 0) then
    return self
  end
  
  local logInfos = {}
  for i, info in ipairs (self.mLogInfos) do
    boolean isValid = true
    for ai, av in ipairs(arg) do
      if (info[av] == nil) then
        isValid = false
      end
    end
    if (isValid) then
      table.insert(logInfos, info)
    end
  end
  
  table.sort(logInfos, function (logInfoA, logInfoB) 
    for k, v in pairs(arg) do
      if (logInfoA[v]< logInfoB[v]) then
        return true
      elseif (logInfoA[v]> logInfoB[v]) then
        return false
      end
    end
    return false
  end)
  local result = createObject()
  result.mLogInfos = logInfos
  return result;
end]]





