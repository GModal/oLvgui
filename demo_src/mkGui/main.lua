local oLvgui = require 'oLv/oLvgui'
local oLvext = require 'oLv/oLvext'
local oLvcolor = require 'oLv/oLvcolor'
local oLvosc = require 'oLv/oLvosc'
-- declare a gui table
local gui = {}
-- osc sockets
local cudp, sudp
local patches = { './pd/noFX_dyna.pd', './pd/phase_dyna.pd', './pd/rev_dyna.pd', './pd/echo_dyna.pd' }
-- origin values for building gui's
local guiorigY = 200
local guiorigX = 50

local knobSize = 80
local sliderRow = 80
local rowLimit = 560
local nudge = 20;
local knobIncr
local knobRow
local lastWidg = ''

local function updateGuiVari()
	knobIncr = knobSize + knobSize /4
	knobRow = knobSize + knobSize /4
end

local lines = {}
local lineAtoms = {}
local patchNames = {}
-- load a file into lines
local function loadFile(fname)
	local line
	for line in love.filesystem.lines(fname) do 
		table.insert(lines, line)
	end
end

-- break lines into individual elements
local function atomsFamily()
	local lineatoms = {}
	for i,v in ipairs(lines) do
		local aline = {}
		for word in v:gmatch("%w+") do 
			table.insert(aline, word)
		end
		table.insert(patchNames, aline[1])
		table.insert(lineatoms, aline)
	end
	return(lineatoms)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- 					GUI callbacks
-- std button callback
function doButton(state, user)
	if user == 'bypass' then
		local msgT = {"@bypass", state}
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'sf', msgT)
		oLvosc.sendOSC(cudp, packet)		
	elseif user == 'dsp' then
		local msgT = {"@dsp", state}
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'sf', msgT)
		oLvosc.sendOSC(cudp, packet)
	end
end

-- std slider callback
function doSlider(value, user)
	local msgT = {user, value}
	local packet = oLvosc.oscPacket('/P2Jcli/0/pp', 'ff', msgT)
	oLvosc.sendOSC(cudp, packet)
end

-- std knob callback
function doKnob(value, user)
	local msgT = {user, value}
	local packet = oLvosc.oscPacket('/P2Jcli/0/pp', 'ff', msgT)
	oLvosc.sendOSC(cudp, packet)
end

-- std Txbox callback
function doTxbox(text, user)
	print('The TX: '..text..' from: '..user)
end

-- std Droplist callback
function doDroplist(index, text, user)
	if user == 'patcher' then

		local msgT = {'@closepatch'}
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 's', msgT)
		oLvosc.sendOSC(cudp, packet)

		msgT = {'@openpatch', patches[index]}
		packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'ss', msgT)
		oLvosc.sendOSC(cudp, packet)

	elseif user == 'preset' then
		print(index, text)
	end
end
-- + + + + + + + + + + + + + + + + + + + + + + +
-- all custom callbacks below
-- set these in the callback argument in the create function

-- Quit when button pressed
function doQuitNow(state, user)
	love.event.quit()
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
local function myServ(serv, slst)
	local packet = oLvosc.oscPoll(serv)
	if packet then
		local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
		local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)

		local oscCMD = oLvosc.oscAddrCmd(oscADDR)
		-- print(oscADDR, oscCMD, oscTYPE)

		local addrSplit = oLvosc.oscAddrSplit(oscADDR)
--  if addrSplit ~= nil then
--    for i, v in ipairs(addrSplit) do
--       print('Atom: '..i..' '..v)
--    end
--    print ('# of atoms: '..#addrSplit)
--  end
		if #addrSplit >= 3 then
			local addrID = tonumber(addrSplit[#addrSplit - 1])
--      if type(addrID) == 'number' then
--        print('ID: '..addrID)
--      end
		end

--  if dataT ~= nil then
--    for i, v in ipairs(dataT) do
--      print(i..')', v)
--    end
--  end

		-- using the "cmd" part of the address that's extracted from the packet
		if oscCMD == 'pp' then
			oLvgui.setValueByUser(slst, dataT[1], dataT[2])
		elseif oscCMD == 'labl' then
			oLvgui.setLabelByUser(slst, dataT[1], dataT[2])

			-- add a widget to gui
		elseif oscCMD == 'newWidget' then
			if dataT[3] == 'slider' then
				if lastWidg == 'kn' then
					guiorigY = guiorigY + knobRow
				end
				-- slider
				-- user, label, type, value, min, max
				oLvgui.createSlider(gui, dataT[2] , {'HORIZ'}, 50, guiorigY, 500, 40, dataT[4] , dataT[5] , dataT[6] , dataT[1] )
				guiorigY = guiorigY + sliderRow
				guiorigX = 50
				lastWidg = 'sl'
			elseif dataT[3] == 'knob' then
				if guiorigX + knobSize > rowLimit then
					guiorigX = 50 + nudge
					guiorigY = guiorigY + knobIncr
				end
				-- knob
				-- user, label, type, value, min, max
				oLvgui.createKnob(gui, dataT[2] , {}, guiorigX, guiorigY, knobSize, dataT[4] , dataT[5] , dataT[6] , dataT[1] )
				guiorigX = guiorigX + knobIncr
				lastWidg = 'kn'
				-- print('Knob: '..knobSize..' Incr: '..knobIncr)
			end
			-- delete all widgets AFTER the marker (after the std group), prepare for new ones
		elseif oscCMD == 'clrWidgets' then
			-- delete widgets after the std group
			gui = oLvgui.delAfterMarker(gui, 'Mk1')
			guiorigY = 200
			guiorigX = 50
			nudge = 20
			knobSize = 80
			updateGuiVari()
			lastWidg = ''
			-- resize knobs
		elseif oscCMD == 'knobSz' then
			if guiorigX ~= 50 then
				guiorigY = guiorigY + knobIncr
				guiorigX = 650 + nudge
			end
			knobSize = dataT[1]
			updateGuiVari()
			-- nudge row right (knobs)
		elseif oscCMD == 'nudge' then
			nudge = 20 * dataT[1]
			guiorigX = guiorigX + nudge
		end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- a group of "standard" widgets for pd2jack (mute, DSP, quit, etc)
function stdWidgets()
	oLvgui.createButton(gui, "Bye!", {'MOMENTARY'}, 480, 50, 60, 50, 9999, doQuitNow)
	local aButton = oLvgui.createButton(gui, "DSP", {'TOGGLE_ON'}, 50, 50, 80, 60, 'dsp')
	aButton.selGraphic = oLvext.checkMark
	local bButton = oLvgui.createButton(gui, "Bypass", {'TOGGLE_OFF'}, 140, 50, 110, 60, 'bypass')
	bButton.selGraphic = oLvext.xMark	

	-- droplist items
	local dlst1 = {'No Fx', 'Phaser', 'Reverb', 'Echo'}
	-- droplist
	oLvgui.createDroplist(gui, 'Choose Pd Patch', dlst1, {'RESEND_SEL'}, 290, 70, 140, 34, 'patcher')
	--oLvgui.createDroplist(gui, 'Choose Preset', patchNames, {'RESEND_SEL'}, 270, 50, 190, 24, 'preset')
	-- insert a marker, use to delete all widgets after this "std" group 
	oLvgui.createMarker(gui, 'Marker1','Mk1')
end

-- Love callbacks
local canvW = 601
local canvH = 906

function love.load()
	local myTheme = oLvgui.createTheme()
	myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv("Patches", canvW, canvH, myTheme)

	loadFile("gtx_banks_2.txt")
	lineAtoms = atomsFamily()

	-- setup OSC send (client)
	-- sample options: '127.0.0.1', 'localhost', or the local machine addr
	-- and the multicast addr, something like: '224.0.0.1'
	cudp = oLvosc.cliSetup('224.0.0.1', 20331)

	-- setup OSC receive (server)
	-- sample options: '127.0.0.1', 'localhost','*', '0.0.0.0', or the local machine addr
	-- and the multicast addr, something like: '224.0.0.1'
	-- '0.0.0.0' works well for mobile devices (server only), listens to all the senders on network
	sudp = oLvosc.servSetup('0.0.0.0', 20341)

	stdWidgets()
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
	myServ(sudp, gui)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
