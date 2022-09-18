local oLvosc = require "oLv/oLvosc"
local oLvoscT = require "oLv/oLvoscT"
local oLvgui = require "oLv/oLvgui"
local oLvext = require "oLv/oLvext"
local oLvcolor = require "oLv/oLvcolor"

local utf8 = require("utf8")
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- declare a gui table; do this early if used in callbacks
local gui = {}
-- osc sockets
local threadT, channelData, channelName, cfont
local portCtrl, addrCtrl
local address, port = '0.0.0.0', 8000
local text = {}
local numLines = 10
local iterSuf = 0
local lcount = 0
local msgcnt = 0
local coff = 0
local strt = 1
local tTop, tLeft, tLines, rLimit = 80, 40, 39, 380
local tLineH = 20
local firsttime = true
local mode = 0

function openServer()
	if threadT == nil then
		if firsttime then
			text = {}
			lcount, coff = 0, 0
			firsttime = false
		end
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

function copyClip(amt)
	local cpst, cpamt = strt, strt + 40
	local clip =''
	if amt == 'all' then
		cpst, cpamt = 1, lcount
	end
	for i = cpst, cpamt, 1 do 
		if text[i] ~= nil then
			clip = clip..text[i]..'\n'
		end
	end
	love.system.setClipboardText(clip)
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
	elseif user == 'showPak' then
		mode = state
	elseif user == 'cpyscrn' then
		copyClip()
	elseif user == 'cpyall' then
		copyClip('all')
	elseif user == 'clr' then
		text = {}
		lcount, coff = 0, 0
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

function doDroplist(index, item, user)
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
	strt = math.floor((lcount - 39 - coff) + 0.5)
	strt = math.max(strt, 1)
	local thss

	love.graphics.setColor( 0.9,0.9,0.9)
	love.graphics.setFont(cfont)
	for i = 0, 40, 1 do
		thss = text[i + strt]
		if thss ~= nil then
			local tchar = string.byte(thss, 1)
			if tchar > 32  then
				love.graphics.setColor( 0.1, 0.1, 0.1 )
				love.graphics.print(thss, tLeft + 1, i*tLineH + tTop +2 )
				love.graphics.setColor( 0.96, 0.7, 0.6)
				love.graphics.print(thss, tLeft, i*tLineH + tTop )
				love.graphics.setColor( 0.9,0.9,0.9)
			else
				love.graphics.print(thss, tLeft, i*tLineH + tTop )
			end
		end
	end
end
-- print prefix for each tag/data
function prfx(i,tp)
	return '\t  '..i..')  '..tp..'  '
end

function printTxt(pstr)
	lcount = lcount + 1
	text[lcount] = pstr
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
function oscDecode(packet)
	local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
	local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)

	msgcnt = msgcnt + 1
	if mode == 0 then
		printTxt(msgcnt..')\tA: '..oscADDR) 
	else
		printTxt('----------------------------------------------   Data')
	end
	printTxt(' Type:\t'..oscTYPE)
	if dataT ~= nil then
		for i, v in ipairs(dataT) do
			local tys = string.sub(oscTYPE, i, i)
			if tys == 's' or tys == 'S' then
				local width, wrapped = cfont:getWrap( v, rLimit )
				for tx in pairs(wrapped) do
					if tx == 1 then
						printTxt(prfx(i,tys)..wrapped[tx])
					else
						printTxt('\t\t\t'..wrapped[tx])
					end
				end
			elseif string.find('ifdhcINTF[]', tys, nil , true) then
				printTxt(prfx(i,tys)..v)
			elseif tys == 'm' then
				local m1, m2, m3, m4 = oLvosc.unpackMIDI(v)
				printTxt(prfx(i,tys)..'MIDI ( '..m1..' '..m2..' '..m3..' '..m4..' )')
			elseif tys == 't' then
				local isec, ifrac = oLvosc.unpackTIME(v)
				printTxt(prfx(i,tys)..'TIME ( '..isec..' '..ifrac..' )')
			elseif tys == 'b' then
				local blobsz, blobb = oLvosc.unpackBLOB(v)
				printTxt(prfx(i,tys)..'BLOB ( Sz:'..blobsz..' )')

				blobbie, _ = string.gsub(blobb, '[%c]', '.')  -- replace all cntl chars in data blk
				local cline, clcnt = '', 0
				for i = 1, #blobbie do
					local d1, d2 = love.data.unpack('B', blobbie, i) -- get a single char
					cline = cline..string.format("%c",d1)
					clcnt = clcnt + 1
					if clcnt == 32 then
						printTxt('\t\t  '..cline)
						cline, clcnt = '', 0
					end
				end
				if clcnt > 0 then
					printTxt('\t\t  '..cline)
				end
			end
		end
	end
end

function oscDump(udpM)
	local padtab = {4, 3, 2, 1}
	local wd = 16
	local oA, oT, oD, cnt
	local addrBlk, typeBlk, dataBlk, dataBlkLoc = 0, 0, 0, 0
	local bd = ' 0000 '
	local bc = '      ' 

	oA, oT, oD = oLvosc.oscUnpack(udpM)
	addrBlk = align4(#oA)

	if oT ~= nil then
		typeBlk = align4(#oT+1)
		dataBlkLoc = addrBlk + typeBlk
		dataBlk = #udpM - dataBlkLoc
	end
	printTxt(' ')
	printTxt('• - • - • - • - • - • - • - •   OSC - Message #: '..msgcnt+1)
	printTxt(' Addr:\t'..oA)
	--printTxt('Type:\t'..oT)
	printTxt('  ADDR blkSz '..addrBlk..'\t\tTYPE blkSz '..typeBlk)
	printTxt('  DATA blkSz '..dataBlk..'\t\tDATA blk @ '..dataBlkLoc)

	oscDecode(udpM)
	printTxt('--------------------------------------------   Packet')

	for i = 1, #udpM do
		local d1 = string.byte(udpM, i)

		bd = bd..string.format("%02X",d1)..' '
		if d1 > 31 and d1 < 127 then
			bc = bc..string.format("%c",d1)..'  '
		else
			bc = bc..'.  '
		end 

		if i % wd == 0 then
			printTxt(bd)
			printTxt(bc)
			printTxt(' ')
			if i < #udpM then
				bd = ' '..string.format("%04X",i)..' '
				bc = '      '
			else
				bd = ''
			end
		end
		cnt = i % wd
	end
	if bd ~= '' then
		printTxt(bd)
		printTxt(bc)
	end
	if cnt ~= 0 then
		printTxt(' ')
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
				if mode == 0 then
					oscDecode(packet)
				else
					oscDump(packet)
				end
			end
		end	
	end
end

function startNotice()
	text[2] = '          \'oscMon\': OSC message monitor'
	text[5] = 'Click "OSC Server" above to start receiving packets'
	text[6] = '  Set Port and Address first, if required'
	text[7] = '  "Clr" will clear the text buffer'
	text[8] = '  "Copy Scrn" & "Copy All" copies text to the paste buffer'
	text[10] = 'Click "Dump" for a full packet dump'
	text[11] = '  -Unclick "Dump" for parsed Addr, Type and data only'
	text[13] = 'NO checking on Address entry format or validity'
	text[14] = '  Error here and socket won\'t open correctly'
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
	local sbutton = oLvgui.createButton(gui, "OSC Server", {'TOGGLE_OFF'}, 360, 20, 150, 30, 'server')
	sbutton.selGraphic = oLvext.checkMark

	oLvgui.createSlider(gui, '', {'VERT', 'SHOWV_OFF'}, 4, 80, 20, 800, 1, 0, 1, 'scroll')
	portCtrl = oLvgui.createTxbox(gui, 'Port', {}, 15, 25, 110, 25, '8000', 'port')
	addrCtrl = oLvgui.createTxbox(gui, 'Address', {}, 150, 25, 170, 25, '0.0.0.0', 'addr')

	oLvgui.createButton(gui, "Clr", {'MOMENTARY'}, 50, 910, 60, 30, 'clr')
	oLvgui.createButton(gui, "Copy Scrn", {'MOMENTARY'}, 150, 910, 100, 30, 'cpyscrn')
	oLvgui.createButton(gui, "Copy All", {'MOMENTARY'}, 270, 910, 100, 30, 'cpyall')
	local pbutton = oLvgui.createButton(gui, "Dump", {'TOGGLE_OFF'}, 400, 910, 150, 30, 'showPak')
	pbutton.selGraphic = oLvext.checkMark

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