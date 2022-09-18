local num = 222

function align4(n)
  return (math.floor((n-1)/4) + 1) * 4
end

if arg[1] ~= nil then
  num = tonumber(arg[1])
end

print (align4(num))