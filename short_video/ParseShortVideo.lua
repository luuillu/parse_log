dofile ("./LogParser.lua")
local downloadlog = "C:\\Users\\lxw\\AppData\\Local\\Temp\\server.log"

parser = LogParser.LogParser(downloadlog)

function ShortVideo ()
  local filters = {
    "XLCreateShortVideoTask",
    "XLGetTaskLocalUrl",
    "Session::HandleRecvSuccess SessionId=%[(%d+)%] State=%[(%w+)%] head=%[(%w+)",
    "Session::HandleRecvHead DoSend Respone SessionId=%[(%d+)%] Http=%[HTTP/1.1 (%d+)",
	"P2spTask::NotifyTaskFinish errcode:",
	"ShortVideoTask::onFileSize into E_DS_DOWNLOAD_VIDEO_CACHE TaskId="
    }
  parser:filterBy(filters):filterBy()
end

function doDownload()
  local filters = {
    "XLCreateShortVideoTask",
    "XLGetTaskLocalUrl",
    "Session::DoDownload"
    }
  parser:filterBy(filters):filterBy()
end

local mapNameToId = {}
local mapTaskIdInfo = {}

function filterCreateTask(logInfo, taskId, filename)
	mapNameToId[filename] = taskId
	mapTaskIdInfo[taskId] = {startTime = logInfo.mTimeStamp, fileName=filename}
end

function filterFinish(logInfo, errcode, taskId)
	if (mapTaskIdInfo[taskId] ~= nil) then
		mapTaskIdInfo[taskId].errCode=errcode
		mapTaskIdInfo[taskId].finishTime = logInfo.mTimeStamp
	end
end

function filterStop(logInfo, taskId, reason)
	if (mapTaskIdInfo[taskId] ~= nil) then
		mapTaskIdInfo[taskId].reason = reason
	end
end

function createStopTask()
  local filters = {
    ["XLCreateShortVideoTask TaskId=%[(%d+)%] rc=%[9000 XL_NO_ERRNO%] pstrFilename=%[(%w+)%.mp4%]"] = filterCreateTask,
	["P2spTask::NotifyTaskFinish errcode:(%d+), taskid:(%d+)"] = filterFinish,
	["XLStopTaskWithReason TaskId=%[(%d+)%] uReasonCode=%[(%d+)%]"] = filterStop
    }
  parser:filterBy(filters)
end

createStopTask()

for k, v in pairs(mapTaskIdInfo) do
	if (v.finishTime ~= nil) then
		print("taskId\t"..k.."\t reason\t"..v.reason.."\t download duration\t"..((v.finishTime.S-v.startTime.S)*1000 + (v.finishTime.MS-v.startTime.MS)))
	else
		print("task not finish taskId="..k.."\t reason="..v.reason)
	end
	--[[for k2, v2 in pairs(v) do
		print(k, k2, v2)
	end]]
end
