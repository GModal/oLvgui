local bindata

function loadBin(fn)
  local f = io.open(fn, "rb")
  bindata = f:read("*all")
  f:close()
end

function align4(n)
  return (math.floor((n-1)/4) + 1) * 4
end

function padBin(binD)
  for i=1, align4(#binD)-#binD do binD = binD..string.char(0) end
  return binD
end

function padBin2(binD)
  local blen = #binD

  return string.pack("!1>s[blen]", bin)
end


loadBin('fileS_34.bin')

print(#bindata, align4(#bindata))

bindata = padBin(bindata)

print(#bindata, align4(#bindata))