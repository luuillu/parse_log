dofile ("./LogParser.lua")
local downloadlog = "C:\\Users\\lxw\\AppData\\Local\\Temp\\server.log"

parser = LogParser.LogParser(downloadlog)

local mapTaskIdInfo = {}

local function filterCreateTask(logInfo, taskId, filename)
	mapTaskIdInfo[taskId] = {taskId = tonumber(taskId),startTime = logInfo.mTimeStamp, fileName=filename}
	return logInfo
end

function filterFinish(logInfo, errcode, taskId)
	if (mapTaskIdInfo[taskId] ~= nil) then
		mapTaskIdInfo[taskId].errCode=errcode
		mapTaskIdInfo[taskId].finishTime = logInfo.mTimeStamp
	end
	return logInfo
end

local function filterStop(logInfo, taskId, reason)
	if (mapTaskIdInfo[taskId] ~= nil) then
		mapTaskIdInfo[taskId].reason = reason
	end
	return logInfo
end

local function filterFilesize(logInfo, taskId, fileSize)
	if (mapTaskIdInfo[taskId] ~= nil) then
		mapTaskIdInfo[taskId].fileSize = fileSize
	end
	return logInfo
end

local function createStopTask()
  local filters = {
    ["XLCreateShortVideoTask TaskId=%[(%d+)%] rc=%[9000 XL_NO_ERRNO%] pstrFilename=%[(%w+)%.mp4%]"] = filterCreateTask,
	["P2spTask::NotifyTaskFinish errcode:(%d+), taskid:(%d+)"] = filterFinish,
	["XLStopTaskWithReason TaskId=%[(%d+)%] uReasonCode=%[(%d+)%]"] = filterStop,
	["download file is download complete. taskid:(%d+), name:[^,]+, has_size:1, filesize:(%d+)"] = filterFilesize
    }
  parser:filterBy(filters)
end

createStopTask()


local function diffTimeStamp (finishStamp, startStamp)
	if (finishStamp == nil or startStamp == nil) then
		return -1
	end
	return (finishStamp.S-startStamp.S)*1000 + (finishStamp.MS-startStamp.MS)
end

local function statTaskDuration()
	local result = {}
	for k, v in pairs(mapTaskIdInfo) do
		table.insert(result, v)
	end

	table.sort(result, function (a, b) return a.taskId < b.taskId end)

	for i,v in ipairs(result) do
		if (v.finishTime ~= nil) then
			print("taskId\t"..v.taskId.."\t reason\t"..v.reason.."\t download duration\t"..diffTimeStamp(v.finishTime, v.startTime))
		else
			print("task not finish taskId="..v.taskId.."\t reason="..v.reason)
		end
	end
end

--statTaskDuration()

----------- stat PipeId open close time

local function getPipeInfo(taskId, pipeId)
	if (mapTaskIdInfo[taskId] == nil) then
		return nil
	end

	if (mapTaskIdInfo[taskId].PipIdMap == nil) then
		mapTaskIdInfo[taskId].PipIdMap = {}
	end

	if (mapTaskIdInfo[taskId].PipIdMap[pipeId] == nil) then
		mapTaskIdInfo[taskId].PipIdMap[pipeId] = {}
	end
	return mapTaskIdInfo[taskId].PipIdMap[pipeId]
end

local MapPipeIdToTaskId = {}
local function filterOpenPipe(logInfo, taskId, state, resId, pipeId)
	local pipeInfo = getPipeInfo(taskId, pipeId)

	if (pipeInfo == nil) then
		print("filterOpenPipe taskId="..taskId.."\t pipeId="..pipeId)
		return nil
	end

	pipeInfo.resId = resId
	pipeInfo.state = state
	pipeInfo.OpenTime = logInfo.mTimeStamp

	MapPipeIdToTaskId[pipeId] = taskId
	return logInfo
end

local function statClosePipe(reason)

	return function (logInfo, pipeId)
		local taskId = MapPipeIdToTaskId[pipeId]
		if (taskId == nil) then
			print("statClosePipe MapPipeIdToTaskId nil pipeid="..pipeId)
			return logInfo
		end
		local pipeInfo = getPipeInfo(taskId, pipeId)

		if (pipeInfo == nil) then
			print("statClosePipe taskId="..taskId.."\t pipeId="..pipeId)
			return logInfo
		end

		if (pipeId=="195") then
			print("reason="..reason)
		end

		pipeInfo.CloseTime = logInfo.mTimeStamp
		pipeInfo.CloseReason = reason
		return logInfo
	end
end

local function openDestroyPipe()
  local filters = {
    ["ShortVideoTask::openOriginPipe TaskId=%[(%d+)%] state=%[(%d+)%] ResId=%[(%d+)%] PipeId=%[(%d+)%]"] = filterOpenPipe,
	["ShortVideoTask::onFileSize ClosePipe PipeId=%[(%d+)%]"] = statClosePipe("onFileSize"),
	["ShortVideoTask::update first pipe recved close pipe, PipeId=%[(%d+)%]"] = statClosePipe("fistPipeFinish"),
	["ShortVideoTask::assignRange can't assign range, PipeId=%[(%d+)%]"] = statClosePipe("cacheFinish")
    }
  parser:filterBy(filters)
end



local function statPipeOpenClose()
	openDestroyPipe()
	for taskId, v in pairs(mapTaskIdInfo) do
		if (v.reason == "9410") then
			print ("----------stat begin taskId=".. taskId.."\t filename="..v.fileName.."\t fileSize="..v.fileSize)
			local pipeIdmap = v.PipIdMap
			if (pipeIdmap ~= nil) then
				for pipeId, info in pairs(pipeIdmap) do
					if (info.CloseReason ~= nil) then
						print ("pipeId="..pipeId.."\t duration="..diffTimeStamp(info.CloseTime, info.OpenTime).."\t reason="..tostring(info.CloseReason))
					else
						--print ("pipeId="..pipeId.."\t no close reason state="..info.state)
						print ("pipeId="..pipeId.."\t duration="..diffTimeStamp(v.finishTime, info.OpenTime).."\t no close reason state="..tostring(info.state))
					end
				end
			end
		end

	end
end

statPipeOpenClose()




