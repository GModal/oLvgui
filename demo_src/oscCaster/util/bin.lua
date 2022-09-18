local out = io.open("file.bin", "wb")
local str = ''

for i=0,255 do 
  str = str..string.char(i)
end

out:write(str)
out:close()
