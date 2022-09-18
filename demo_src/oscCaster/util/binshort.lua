local out = io.open("fileS.bin", "wb")
local str = ''

str = str..string.char(0)
for i=0,31 do 
  str = str..string.char(i+32)
end
str = str..string.char(0)
str = str..string.char(1)

out:write(str)
out:close()
