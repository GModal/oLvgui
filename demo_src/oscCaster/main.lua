-- Carla controller, TAP Reverberator
local oLvosc = require "oLv/oLvosc"
local oLvgui = require "oLv/oLvgui"
local oLvcolor = require "oLv/oLvcolor"
local oLvext = require "oLv/oLvext"

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
local gui = {}
local typearr = {'i', 'f', 's', 'd', 'm', 't', 'T', 'F', 'I', 'N'}
local freqarr = {'Slow', 'Medium', 'Fast'}
local port = 8000
local address = '224.0.0.1'
local curFreq = 1
local cudp, sentLbl, portCtrl, addrCtrl
local freqMod = 300
local sending = 0
local tcount = 0  -- 'tick' count
local mcount = 0  -- msg count
local bindata

local lines = {} -- empty table
local patchNames = {}

local function loadFile(fname)
	local line
	for line in love.filesystem.lines(fname) do 
		table.insert(lines, line)
	end
end

local function loadBin(fn)
	local f = io.open(fn, "rb")
	bindata = f:read("*all")
	f:close()
end

local function makebin()
	local str = 'QQQ+++'
	for i=0, math.random(3, 280) do 
		--str = str..'+'
		str = str..string.char(math.random(0,127))
	end
	str = str..'+++ZZZ'
	return(str)
end

-- 		GUI callbacks
function doButton(state, user)
	if user == 'send' then
		if state == 0 then
			oLvosc.close(cudp)
			portCtrl.active = 1
			addrCtrl.active = 1      
		else
			-- setup OSC send (client)
			-- sample options: '127.0.0.1', 'localhost', or the local machine addr
			-- and the multicast addr, something like: '224.0.0.1'
			cudp = oLvosc.cliSetup(address, port)     
			portCtrl.active = 0
			addrCtrl.active = 0
		end
		sending = state
	elseif user == 'auto' then
		autoset = state
	elseif user == 'btest' then
		-- types with no data should still have a 'placeholder' in the table
		local bpakket = {'hello',  makebin(),  33, '', '£'}
		local packet = oLvosc.oscPacket('/oscCaster/'..mcount..'/'..freqarr[curFreq], 'sbiIc', bpakket )
		oLvosc.sendOSC(cudp, packet)
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
-- std Droplist callback
function doDroplist(index, text, user)
	if user == 'freq' then
		if index == 1 then
			freqMod = 300
			curFreq = 1
		elseif index == 2 then
			freqMod = 25
			curFreq = 2
		elseif index == 3 then
			freqMod = 5
			curFreq = 3
		end
	end
end

-- oLv quit function
function oLvquit()
	love.event.quit()
end

local function sendOSC(tick)
	tcount = tcount + 1
	if tcount % freqMod == 0 then
		local tstr = ''
		local sdata = {}

		if sending == 1 then
			mcount = mcount + 1
			local stype, idat

			for i = 1, math.random(1, 8), 1 do
				stype = math.floor(math.random(1, 10) + 0.5)
				tstr = tstr..typearr[stype]
				idat = '-'
				if stype == 1 then
					idat = math.floor(math.random(1, 500) + 0.5)
				elseif stype == 2 or stype == 4 then
					idat = math.random() * 5
				elseif stype == 3 then
					idat = lines[math.floor(math.random(1,33) + 0.5)]
				elseif stype == 5 then
					local mtable = oLvosc.packMIDI(math.random(1,16), 144, math.random(32,72), math.random(1,120))
					idat = mtable
				elseif stype == 6 then
					idat = math.floor(math.random(1, 99999999) + 0.5)
				elseif stype == 7 then
					local isec, ifrac, ffrac, epoch = oLvosc.time()
					local mytime = oLvosc.packTIME(isec, ifrac)
					idat = mytime
				elseif stype >= 8 and stype <= 11 then
					idat = ''
				end

				table.insert(sdata, idat)
			end
			local packet = oLvosc.oscPacket('/oscCaster/'..mcount..'/'..freqarr[curFreq], tstr, sdata )
			oLvosc.sendOSC(cudp, packet)

			sentLbl.label = 'Total Sent: '..mcount
			sentDesc.label = 'Sent Types: '..tstr

		end
	end 
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW, canvH = 960, 600

-- Std Love callbacks
function love.load()
	local myTheme = oLvgui.createTheme()
	myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv("Theme Editor", canvW, canvH, myTheme)
	oLvgui.autoScale()

	loadFile('random.txt')
	loadBin('oscCaster/util/file.bin') -- lua path is calling path, not love dir

	math.randomseed(os.time()) -- random initialize

	oLvgui.createButton(gui, "X", {'MOMENTARY'}, 20, 24, 28, 28, 9999, oLvquit)
	autoButton = oLvgui.createButton(gui, "Send OSC msgs", {'TOGGLE_OFF'}, 100, 150, 190, 28, 'send')
	autoButton.selGraphic = oLvext.checkMark

	local freqdl = oLvgui.createDroplist(gui, 'Msg Freq', freqarr, {'RESEND_SEL'},  400, 150, 120, 28, 'freq')
	oLvgui.dlSetSelect(freqdl, 1)

	oLvgui.createLabel(gui, 'Transmit OSC messages (test oLvosc & oLvoscT modules)', {}, 150, 50, 18) 
	portCtrl = oLvgui.createTxbox(gui, 'Port', {}, 100, 350, 28, 25, '8000', 'port')
	addrCtrl = oLvgui.createTxbox(gui, 'Address', {}, 400, 350, 170, 25, '224.0.0.1', 'addr')

	sentLbl = oLvgui.createLabel(gui, 'Total Sent: ', {}, 150, 200, 18)
	sentDesc = oLvgui.createLabel(gui, 'Sent Types: ', {}, 150, 240, 16)  

	oLvgui.createButton(gui, "Blob test", {'MOMENTARY'}, 150, 500, 80, 28, 'btest')
end

function love.update(dt)
	sendOSC(dt)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
end