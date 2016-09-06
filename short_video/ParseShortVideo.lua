dofile ("./LogParser.lua")
local downloadlog = "./server_shortvideo.log"

parser = LogParser.LogParser(downloadlog)

function ShortVideo ()
  local filters = {
    "XLCreateShortVideoTask",
    "XLGetTaskLocalUrl",
    "Session::HandleRecvSuccess SessionId=%[(%d+)%] State=%[(%w+)%] head=%[(%w+)",
    "Session::HandleRecvHead DoSend Respone SessionId=%[(%d+)%] Http=%[HTTP/1.1 (%d+) OK"
    }
  parser:filterBy(filters):filterBy()
end

ShortVideo ()