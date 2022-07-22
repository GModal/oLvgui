local oLvosc = require "oLv/oLvosc"
local oLvoscT = require "oLv/oLvoscT"
local oLvgui = require "oLv/oLvgui"
local oLvext = require "oLv/oLvext"
local oLvcolor = require "oLv/oLvcolor"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- declare a gui table; do this early if used in callbacks
local gui = {}
-- osc sockets
local threadT, channelData, channelName
local portCtrl, addrCtrl
local address, port = '0.0.0.0', 8000
local text = {}
local cfont
local iterSuf = 0
local lcount = 0
local msgcnt = 0
local coff = 0
local tTop, tLeft, tLines, rLimit = 80, 40, 39, 400
local tLineH = 20

function openServer()
  if threadT == nil then
    text = {}
    lcount, coff = 0, 0
    iterSuf = iterSuf + 1         -- unique channel name for each instantiation
    
    channelName = 'sOSC'..iterSuf     -- a channel for incoming OSC data, give it a name
    threadT = oLvoscT.servSetup(address, port, channelName)
    if threadT ~= nil then
      -- after starting, get the actual channel created for our name
      channelData = love.thread.getChannel( channelName )
    end
  end
end

function closeServer()
  local channelKill = oLvoscT.getTermChan(channelName)    -- get the channel to terminate the thread
  if channelKill ~= nil then
    oLvoscT.closeServ(channelKill)     -- send a close msg over that channel
    threadT:wait()
    threadT = nil
  end
end
-- ++++++++++++++++++++++++++++++++++++++
-- 		GUI callbacks
-- std button callback`
function doButton(state, user)
	if user == 'quit' then
    oLvquit()
  elseif user == 'server' then
    if state == 1 then
        openServer()
        portCtrl.active = 0
        addrCtrl.active = 0
    else
        closeServer()
        portCtrl.active = 1
        addrCtrl.active = 1
    end
  end
end
-- std Slider callback
function doSlider(value, user)
  if user == 'scroll' then
    value = math.abs(value - 1)   -- reverse values
    coff = (lcount - tLines)  * value
  end
end
-- std Txbox callback
function doTxbox(text, user)
  if user == 'port' then
    local tnum = tonumber(text)
    if tnum ~= nil then
      if tnum > 1024 and tnum < 65536 then
        port = tnum
      else
        portCtrl.text = 'Bad Range'
      end
    else
      portCtrl.text = 'Not Valid'
    end
  elseif user == 'addr' then
    address = text
  end
end
-- define an oLvquit() function
-- it's REALLY important if a thread is running...and user closes LOVE with the Android 'back' button
function oLvquit()
  if threadT ~= nil then
    closeServer()
  end
  love.event.quit()
end

-- ++++++++++++++++++++++++++++++++++++++++++++++++++
-- a simple text display
function printText()
  local strt = math.floor((lcount - 39 - coff) + 0.5)
  if strt < 1 then
    strt = 1
  end
--  local myvp = oLvgui.getVPort()
--  text[1] = 'Debug: '..myvp.VPwidth..' '..myvp.VPdepth..' '..myvp.safeW..' '..myvp.safeH..' '..myvp.Sx..' '..myvp.Sy
  love.graphics.setColor( 0.9,0.9,0.9)
  love.graphics.setFont(cfont)
  for i = 0, 40, 1 do
    if text[i + strt] ~= nil then
      love.graphics.print(text[i + strt], tLeft, i*tLineH + tTop )
    end
  end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
function myServ(chanD)
  -- check the OSC server channel for items in the queue
  if chanD ~= nil then
    while chanD:getCount() ~= 0 do
      local packet = chanD:pop()   -- OSC packet data passed through a channel queue
      if packet ~= nil then
        local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
        local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
    
        lcount = lcount + 1
        msgcnt = msgcnt + 1
        if oscTYPE == nil then
          text[lcount] = msgcnt..')\tA: '..oscADDR  -- some appli's send only an addr...lookin' at you, Ardour
        else 
          text[lcount] = msgcnt..')\tA: '..oscADDR..'\t\tT: \''..oscTYPE..'\''
        end
        if dataT ~= nil then
          
          for i, v in ipairs(dataT) do
            local tys = string.sub(oscTYPE, i, i)
            if tys == 's' then
              local width, wrapped = cfont:getWrap( v, rLimit )
              for tx in pairs(wrapped) do
                lcount = lcount + 1
                if tx == 1 then
                  text[lcount] = '\t  '..i..': '..wrapped[tx]
                else
                  text[lcount] = '\t  '..' '..'  '..wrapped[tx]
                end
              end
            elseif tys == 'f' or tys == 'i' or tys == 'H' or tys == 'd' then
              lcount = lcount + 1
              text[lcount] = '\t  '..i..':  '..v
            elseif tys == 'm' then
              m1, m2, m3, m4 = oLvosc.unpackMIDI(v)
              lcount = lcount + 1
              text[lcount] = '\t  '..i..': MIDI ( '..m1..' '..m2..' '..m3..' '..m4..' )'
            end
          end
        end
      end
    end
  end
  
end

function startNotice()
  text[2] = ' \'oscmon\': OSC message monitor'
  text[5] = 'NO checking on Address entry format or validity'
  text[6] = '\tError here and socket won\'t open correctly'
  text[8] = 'Receiving extended OSC types such as 64 bit numbers are'
  text[9] = '\tlimited to 53 bits by LÖVE 11.3, and are problematic.'
  text[10] = '\t(still work within the ranges set by LÖVE,'
  text[11] = '\tbut too-large integers will throw exceptions)'
  text[13] = 'However, the OSC msg should be correct.'
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++

local canvH = 960
local canvW = 600
-- Std Love callbacks
function love.load()
  local myTheme = oLvgui.createTheme()
  myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
  oLvgui.initoLv("OSC Monitor", canvW, canvH, myTheme)
  oLvgui.autoScale()

  oLvgui.createButton(gui, "Quit", {'MOMENTARY'}, 530, 20, 50, 30, 'quit')
  local sbutton = oLvgui.createButton(gui, "OSC Server", {'TOGGLEOFF'}, 360, 20, 150, 30, 'server')
  sbutton.selGraphic = oLvext.checkMark
  
  oLvgui.createSlider(gui, '', {'VERT', 'NOSHOWV'}, 4, 80, 20, 800, 1, 0, 1, 'scroll')
  portCtrl = oLvgui.createTxbox(gui, 'Port', {}, 15, 25, 110, 25, '8000', 'port')
  addrCtrl = oLvgui.createTxbox(gui, 'Address', {}, 150, 25, 170, 25, '0.0.0.0', 'addr')
  
  cfont = love.graphics.newFont('VeraMono.ttf', 15)
  startNotice()
end

function love.update(dt)
  myServ(channelData)    -- chk server queue
  oLvoscT.error(threadT)    -- check server thread for errors
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
  printText()
end
