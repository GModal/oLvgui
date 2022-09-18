local oLvosc = require "oLv/oLvosc"
local oLvoscT = require "oLv/oLvoscT"
local oLvgui = require "oLv/oLvgui"
local oLvext = require "oLv/oLvext"
local oLvcolor = require "oLv/oLvcolor"
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- declare a gui table; do this early if used in callbacks
local gui = {}
-- osc sockets
local cudp, threadT, chanT, chanNm
local debugging = 0

-- gonna change these in callbacks...
local jumpVal = 4
local rPanel, rLabel, tPortLabel, jumpdl, trackDList, menudl, rButton, lButton
local punchIn, punchOut
local tstate = 0
local lstate = 0

local tracks = {}
local ardtemp = {}

-- 		GUI callbacks
-- std button callback
function doButton(state, user)
	if user == 'record' then
		local packet = oLvosc.oscPacket('/rec_enable_toggle')
		oLvosc.sendOSC(cudp, packet)

	elseif user == 'roll' then
		local packet
		if state == 1 then
			packet = oLvosc.oscPacket('/transport_play')
		else
			packet = oLvosc.oscPacket('/transport_stop')
		end
		oLvosc.sendOSC(cudp, packet)
		tstate = state
		rButton.state = state

	elseif user == 'loop' then
		local packet
		if state == 1 then
			packet = oLvosc.oscPacket('/loop_toggle', 'f', {1})
			tstate = 1
			rButton.state = 1
		else
			packet = oLvosc.oscPacket('/transport_stop')
			--packet = oLvosc.oscPacket('/loop_toggle', 'f', {1})
			tstate = 0
			rButton.state = 0
		end
		oLvosc.sendOSC(cudp, packet)
		lstate = state

	elseif user == 'start' then
		packet = oLvosc.oscPacket('/goto_start')
		oLvosc.sendOSC(cudp, packet)  

	elseif user == 'end' then
		packet = oLvosc.oscPacket('/goto_end')
		oLvosc.sendOSC(cudp, packet)  

	elseif user == 'prevMark' then
		packet = oLvosc.oscPacket('/prev_marker')
		oLvosc.sendOSC(cudp, packet)   

	elseif user == 'nextMark' then
		packet = oLvosc.oscPacket('/next_marker')
		oLvosc.sendOSC(cudp, packet)   

	elseif user == 'jmpBack' then
		packet = oLvosc.oscPacket('/jump_bars', 'f', {-jumpVal})
		oLvosc.sendOSC(cudp, packet)

	elseif user == 'jmpFwd' then
		packet = oLvosc.oscPacket('/jump_bars', 'f', {jumpVal})
		oLvosc.sendOSC(cudp, packet) 

	elseif user == 'pin' then
		packet = oLvosc.oscPacket('/toggle_punch_in')
		oLvosc.sendOSC(cudp, packet)

	elseif user == 'pout' then
		packet = oLvosc.oscPacket('/toggle_punch_out')
		oLvosc.sendOSC(cudp, packet)     

	elseif user == 'pset' then
		packet = oLvosc.oscPacket('/access_action', 's', {'Editor/set-auto-punch-range'})
		oLvosc.sendOSC(cudp, packet) 

	elseif user == 'query' then   -- query Ardour
		packet = oLvosc.oscPacket('/strip/list')
		oLvosc.sendOSC(cudp, packet)  

	elseif user == 'trackTgl' then
		packet = oLvosc.oscPacket('/access_action', 's', {'Editor/track-record-enable-toggle'})
		oLvosc.sendOSC(cudp, packet)

	elseif user == 'undo' then 
		packet = oLvosc.oscPacket('/undo')
		oLvosc.sendOSC(cudp, packet) 

	elseif user == 'redo' then 
		packet = oLvosc.oscPacket('/redo')
		oLvosc.sendOSC(cudp, packet)

	end
end

-- define an oLvquit() function
-- it's REALLY important if a thread is running...and user closes LOVE with the Android 'back' button
function oLvquit()
	local tchn = oLvoscT.getTermChan(chanNm)    -- get the channel to terminate the thread
	oLvoscT.closeServ(tchn)                     -- send a close msg over that channel
	threadT:wait( )                             -- wait for server thread to close...(hint, it's the timeout value)
	love.event.quit()
end

-- std Droplist callback
function doDroplist(index, text, user)
	local jumpAmts = {1, 2, 3, 4, 6, 8, 12, 24}

	if user == 'jump' then
		if index == 0 then
			jumpVal = 4
		else
			jumpVal = jumpAmts[index]
		end
	elseif user == 'tracks' then
		if #tracks ~= 0 then
			if index == 0 then
				packet = oLvosc.oscPacket('/access_action', 's', {'Common/deselect-all'})
			else
				packet = oLvosc.oscPacket('/strip/select', 'ff', {tracks[index].ssid, 1})
			end
			oLvosc.sendOSC(cudp, packet) 
		end

	elseif user == 'menu' then -- punch in/out menu
		if text == 'Quit' then
			oLvquit()
		end
		--  menu entry state is handled by the server, from Ardour feedback msgs
		if index == 1 then
			packet = oLvosc.oscPacket('/toggle_punch_in')
			oLvosc.sendOSC(cudp, packet)
		elseif index == 2 then
			packet = oLvosc.oscPacket('/toggle_punch_out')
			oLvosc.sendOSC(cudp, packet)
		elseif index == 4 then
			if tPortLabel.active == 0 then
				tPortLabel.active = 1
				oLvgui.dlMenuSelect(menudl, 4)
			else
				tPortLabel.active = 0
				oLvgui.dlMenuUnSelect(menudl, 4)
			end

		end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
function myServ(chan, slst)

	while chan:getCount() ~= 0 do
		local packet = chan:pop()   -- packet data passed through a channel queue
		if packet ~= nil then
			local oscADDR, oscTYPE, oscDATA = oLvosc.oscUnpack(packet)
			local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)

			-- dump all incoming data to console: debugging
			if debugging == 1 then
				print(oscADDR, oscTYPE)
				if dataT ~= nil then
					for i, v in ipairs(dataT) do
						print(i..')', v)
					end
				end
			end

			if oscADDR == '/position/bbt' then
				dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
				tPortLabel.label = string.sub(dataT[1],1,11)
			elseif oscADDR == '/rec_enable_toggle' then
				if dataT[1] == 0 then
					rPanel.color = {0.2, .3, .5}
					rLabel.label = 'Record OFF'
					rPanel.state = 0
				else
					rPanel.color = {.8, 0, 0}
					rLabel.label = '* ARMED! *'
					rPanel.state = 1
				end
			elseif oscADDR == '/toggle_punch_in' then   -- 'Master Section' Feedback setting required to reset menu text
				punchIn = dataT[1]
				if punchIn == 0 then
					oLvgui.dlMenuUnSelect(menudl, 1)
				else
					oLvgui.dlMenuSelect(menudl, 1)
				end
			elseif oscADDR == '/toggle_punch_out' then  -- 'Master Section' Feedback setting required...
				punchOut = dataT[1]
				if punchOut == 0 then
					oLvgui.dlMenuUnSelect(menudl, 2)
				else
					oLvgui.dlMenuSelect(menudl, 2)
				end
			elseif oscADDR == '/loop_toggle' then  -- 'Master Section' Feedback setting required...
				if dataT[1] == 0 then
					lstate = 0
					lButton.state = 0
					tstate = 0
					rButton.state = 0
				else
					lstate = 1
					lButton.state = 1
				end

			elseif oscADDR == '/transport_play' then  -- 'Master Section' Feedback setting required...
				if dataT[1] == 1 then
					tstate = 1
					rButton.state = 1
				else
--              lstate = 0
--              lButton.state = 0
				end
			elseif oscADDR == '#reply' then
				if dataT[1] == 'AT' or dataT[1] == 'MT' then    -- audio or midi tracks
					local trkItem = {name = dataT[2], ssid = dataT[7]}
					table.insert(tracks, trkItem)
					table.insert(ardtemp, dataT[2])
				elseif dataT[1] == 'end_route_list' then
					if ardtemp ~= nil then
						oLvgui.dlSetItems(trackDList, ardtemp)
					end
					-- reset temp table
					ardtemp = {}
				end
			end
		end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW = 960
local canvH = 600
-- Std Love callbacks
function love.load()
	local myTheme = oLvgui.createTheme(20)
	myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv("Ardour Cntl", canvW, canvH, myTheme)
	oLvgui.autoScale()

	-- setup OSC send (client)
	-- sample options: '127.0.0.1', 'localhost', or the local machine addr
	-- and the multicast addr, something like: '224.0.0.1'
	cudp = oLvosc.cliSetup('224.0.0.1', 3819)

	-- setup OSC server, (blocking) LÖVE ONLY, not pure Lua
	--    NOTE: the module name is 'oLvoscT' not 'oLvosc' -- T for threads
	-- MUCH more reliable than non-blocking, but requires threads
	-- same address & port options + channel name
	-- standard 'oLvosc' packet/data functions work with data
	-- needs channels to pass data to main thread
	chanNm = 'sOSC'     -- a channel for data, give it a name
	-- init the server
	threadT = oLvoscT.servSetup('0.0.0.0', 8000, chanNm)

	-- if no thread, no channel
	if threadT ~= nil then
		-- get the actual channel created for our name
		chanT = love.thread.getChannel( chanNm )
	end

	rPanel = oLvgui.createPanel(gui, "", {}, 80, 24, 170, 100, oLvcolor.color.olvBlue)

	local cButton = oLvgui.createButton(gui, "Record", {'MOMENTARY'}, 115, 35, 95, 50, 'record')
	-- set the selection graphic to a different polygon
	cButton.selGraphic = oLvext.checkMark
	cButton.color = oLvcolor.color.olvGreen

	rLabel = oLvgui.createLabel(gui, "Record OFF", {}, 110, 92, 20)

	oLvgui.createPanel(gui, "", {}, 200, 480, 550, 100, oLvcolor.color.olvBlue)
	oLvgui.createButton(gui, "Query", {'MOMENTARY'}, 220, 510, 60, 45, 'query')
	oLvgui.createButton(gui, "Track Rec On/Off", {'MOMENTARY'}, 550, 510, 190, 45, 'trackTgl')
	-- droplist : Ardour tracks
	trackDList = oLvgui.createDroplist(gui, 'Ardour Track Select', {}, {}, 300, 520, 230, 28, 'tracks')  

	rButton = oLvgui.createButton(gui, "Roll Transport", {'TOGGLE_OFF'}, 200, 170, 550, 190, 'roll')
	rButton.selGraphic = oLvext.chunkyX
	rButton.color = {0.57293, 0.21025, 0.25402} 

	oLvgui.createButton(gui, "Undo", {'MOMENTARY'}, 30, 480, 70, 40, 'undo')
	oLvgui.createButton(gui, "Redo", {'MOMENTARY'}, 30, 530, 70, 40, 'redo') 

	oLvgui.createButton(gui, "Start", {'MOMENTARY'}, 30, 210, 90, 130, 'start')
	oLvgui.createButton(gui, "End", {'MOMENTARY'}, 830, 210, 90, 130, 'end')	  

	oLvgui.createButton(gui, "< Jump", {'MOMENTARY'}, 350, 380, 90, 50, 'jmpBack')   
	oLvgui.createButton(gui, "< Marker", {'MOMENTARY'}, 200, 380, 100, 50, 'prevMark')  
	oLvgui.createButton(gui, "Marker >", {'MOMENTARY'}, 650, 380, 100, 50, 'nextMark')
	oLvgui.createButton(gui, "Jump >", {'MOMENTARY'}, 500, 380, 90, 50, 'jmpFwd')

	lButton = oLvgui.createButton(gui, "Loop", {'TOGGLE_OFF'}, 780, 380, 150, 70, 'loop')
	lButton.selGraphic = oLvext.xMark

	-- droplist : Jump amt
	jumpdl = oLvgui.createDroplist(gui, 'Jump', {'1', '2', '3', '4', '6', '8', '12', '24'},{'NO_DESELECT'}, 810, 540, 40, 40, 'jump')
	oLvgui.dlSetSelect(jumpdl, 4)

	menudl = oLvgui.createDroplist(gui, 'Settings', {'Punch In', 'Punch Out', '\t\t- - -', 'Show Bar/Beat', '\t\t- - -', 'Quit'},{'MENU'}, 690, 36, 230, 36, 'menu')

	tPortLabel = oLvgui.createLabel(gui, "001|01|0000", {}, 320, 60, 42)  
	tPortLabel.active = 0
end

function love.update(dt)
	oLvoscT.error(threadT)    -- check server thread for errors
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	myServ(chanT, gui)    -- poll the server
	oLvgui.drawoLv(gui)
end
