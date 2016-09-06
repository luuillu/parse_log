dofile ("./LogParser.lua")
local downloadlog = "./server_test.log"

parser = LogParser.LogParser(downloadlog)


function testAll ()
  parser:filterBy()
end

function testString()
  parser:filterBy("p2sp"):filterBy()
end

function testFunction()
  parser:filterBy(function (logInfo) 
        print(logInfo.mRawLog[1])
      end)
end

function testTableString()
  parser:filterBy({"timer", "enter"}):filterBy();
end

function testTableStringRegex()
  parser:filterBy({["timer:(%d+)"]={{431}}, "enter"}):filterBy();
end

function testTableStringFunction()
  parser:filterBy({["timer:(%d+)"]=function(commonInfo, id) print(id) return nil end, "enter"}):filterBy();
end

function testTableStringAS()
  parser:filterBy({["timer:(%d+)"]={{AS="timerId"}}, "enter"}):filterBy({function(commonInfo) print (commonInfo.timerId) end});
end

testTableStringAS()

