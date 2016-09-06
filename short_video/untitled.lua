local function f( ... )
  arg={...}
    for k, v in pairs(table) do print(k) end
  print ("arg.len=".. #arg)
end

f(table.unpack({1,3,2}))

printResult = ""
 
function print2(...)
    for i,v in ipairs(arg) do
       printResult = printResult .. tostring(v) .. "\t"
    end
    printResult = printResult .. "\n"
end

print2(2,1)
print (printResult)
