local oLvosc = require "oLv/oLvosc"
local oLvgui = require "oLv/oLvgui"
local oLvcolor = require "oLv/oLvcolor"
local oLvext = require "oLv/oLvext"

local gui = {}
local cudp, sudp
local alpha = 0.5
local bgPanel, xLabel, yLabel
local vpflags = {}

local lines = {} -- empty table
local patchNames = {}

function loadFile(fname)
local line
	for line in love.filesystem.lines(fname) do 
	  table.insert(lines, line)
	end
end

function atomsFamily()
local lnatoms = {}
	for i,v in ipairs(lines) do
	local aline = {}
		for word in v:gmatch("%w+") do 
		table.insert(aline, word)
		end
		table.insert(patchNames, aline[1])
		table.insert(lnatoms, aline)
	end
return(lnatoms)
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
  elseif user == 'reset' then
    oLvgui.resetVP(gui, tonumber( xLabel.label), tonumber( yLabel.label), vpflags)
  elseif user == 'flag1' then
    if state == 1 then
      vpflags = {fullscreen=true}
    else
      vpflags = {fullscreen=false}
    end
	end
end

-- std slider callback
function doSlider(value, user)
	if user == 'alphaSlide' then
    bgPanel.color = {1,1,1,value}
  elseif user == 'bgW' then
    bgPanel.img_sx = value
    xLabel.label = value * bgPanel.img_width
  elseif user == 'bgH' then
    bgPanel.img_sy = value
    yLabel.label = value * bgPanel.img_height
  end
end

-- std Txbox callback
function doTxbox(text, user)
	print("The TX: "..text.." from: "..user)
end

-- std Droplist callback
function doDroplist(index, text, user)
	if user == 'patcher' then
		local msgT = {"@closepatch"}
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 's', msgT)
		oLvosc.sendOSC(cudp, packet)
	
		if index == 1 then
			local msgT = {"@openpatch", "./pd/phase_vo.pd"}
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'ss', msgT)
			oLvosc.sendOSC(cudp, packet)
		elseif index == 2 then
			local msgT = {"@openpatch", "./pd/rev_vo.pd"}
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'ss', msgT)
			oLvosc.sendOSC(cudp, packet)
		end
	else
	print("The TX: "..text.." # "..index.." Usr: "..user)
	end
end
-- + + + + + + + + + + + + + + + + + + + + + + +
-- all custom callbacks below
-- set these in the callback argument in the create function
function oLvquit()
	love.event.quit()
end

function doKnob(value, user)
end

-- activate or deactivate all widgets (a button callback), 
--	while always (re)activating this button
function doStateAll(state, user)
	oLvgui.setActive(gui, state)
	--setActiveIndex(gui, getIndexbyUser(gui, user), 1)
  oLvgui.setActiveByUser(gui, user, 1)
  -- keep quit button active
  oLvgui.setActiveByUser(gui, 9999, 1)
end

-- send an OSC msg on button press
function doLongSend(state, user)
		local msgT = {"@sendprogc", state, 120}
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'sff', msgT)
		oLvosc.sendOSC(cudp, packet)
end

-- deactivate a widget (slider) -- the slider obj is the user arg
function doRangeTest(value, user)
	if value > 2 then
		user.active = 0
	else
		user.active = 1
	end
end

-- set active state by an index -- the list (table) of all widgets is the user arg
function setByIndex(value, user)
	oLvgui.setActiveIndex(gui, value, 0)
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- poll the OSC server 
function myServ(slst)
	local packet = oLvosc.oscPoll()
	if packet then
		local oscADDR, oscTYPE, oscDATA, oscID, oscCMD = osc.oscUnpack(packet)
		local dataT = oLvosc.oscDataUnpack(oscTYPE, oscDATA)
		
		-- we are cheating & only using the "cmd" part of the address that's extracted from the packet
		if oscCMD == 'pp' then
			oLvgui.setValueByUser(slst, dataT[1], dataT[2])
		elseif oscCMD == 'labl' then
			oLvgui.setLabel(slst, dataT[1], dataT[2])
		elseif oscCMD == 'widget' then
			print( dataT[1], dataT[2], dataT[3], dataT[4], dataT[5], dataT[6])
		end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW, canvH
-- canvW, canvH = love.graphics.getDimensions()

canvW = 600
canvH = 960

-- Std Love callbacks
function love.load()
  local myTheme = oLvgui.createTheme(18)
  myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv("oLv Demo", canvW, canvH, myTheme)
  oLvgui.autoScale()
  
	-- setup OSC send (client)
	cudp = oLvosc.cliSetup("224.0.0.1", 20331)	
	-- and OSC receive (server)
	sudp = oLvosc.servSetup("224.0.0.1", 20341)
	
	loadFile("gtx_banks_2.txt")
	atomsFamily()
	-- createSlider(table, 'label', {options}, x, y, width, height, value, min, max, user (, callback (, extra)))
	--	option arg is a list of options
	--	user field can be single variable (anything) or a table of anything
  
  bgPanel = oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_IMAGE', 'oLv/gwCrop.jpg'}, 0, 0, canvW, canvH, {1,1,1,.3}, 'firstPanel')
  
	oLvgui.createSlider(gui, 'Transparency', {'HORIZ'}, 30, 100, 500, 48, 0.3, 0, 1, 'alphaSlide')
	oLvgui.createSlider(gui, 'BG Width', {'HORIZ'}, 30, 180, 500, 48, bgPanel.img_sx, 0.1, 1.1, 'bgW')
	oLvgui.createSlider(gui, 'BG Height', {'HORIZ'}, 30, 260, 500, 48, bgPanel.img_sy, 0.1, 1.1, 'bgH')
  
  xLabel = oLvgui.createLabel(gui, canvW, {}, 50, 330, 20, {0.9,0.9,0.9})
  yLabel = oLvgui.createLabel(gui, canvH, {}, 250, 330, 20, {0.9,0.9,0.9})
  
  local f1Button = oLvgui.createButton(gui, "FullScrn", {'TOGGLE_OFF'}, 100, 360, 110, 35, 'flag1')
	-- set the selection graphic to a different polygon
	f1Button.selGraphic = oLvext.xMark

  oLvgui.createButton(gui, "Reset VP", {'MOMENTARY'}, 150, 20, 90, 30, 'reset')
  
	-- create and get a slider
	local aSlider = oLvgui.createSlider(gui, 'Stereo/Mono', {'HORIZ'}, 30, 420, 500, 48, 0.0, 0, 1, 5)
	-- set slider steps
	oLvgui.setSteps(aSlider, 11)
	
	-- createButton(table, 'label', {options}, x, y, width, height, user (, callback))
	--	user field can be single variable (anything) or a table of anything
	-- 	here setting the callback separately, not in the create function
	local aButton = oLvgui.createButton(gui, "Bye!", {'MOMENTARY'}, 30, 20, 70, 30, 9999)
	-- set the callback for this button
	aButton.callback = oLvquit
  aButton.color = oLvcolor.color.olvRed
	
	local bButton = oLvgui.createButton(gui, "DSP", {'TOGGLE_ON'}, 30, 500, 80, 60, 'dsp')
  bButton.selGraphic = oLvext.checkMark
	
	local cButton = oLvgui.createButton(gui, "Bypass", {'TOGGLE_OFF'}, 120, 500, 110, 60, 'bypass')
	-- set the selection graphic to a different polygon
	cButton.selGraphic = oLvext.xMark

	-- here user field is table of sliders, the callback is to change state of those sliders
	local dButton = oLvgui.createButton(gui, "Activate +/-", {'TOGGLE_ON'}, 240, 500, 180, 60, 505, doStateAll, 505)
	-- set the selection graphic to a different polygon
	dButton.selGraphic = oLvext.talkBubble
	
	-- here user field is {table of siders, an index #} and a callback, which changes state of the indexed slider
	oLvgui.createButton(gui, "Long send", {'MOMENTARY'}, 430, 500, 110, 60, 5, doLongSend)
	
	local cbiSlider = oLvgui.createSlider(gui, 'Change by Index', {'VERT'}, 35, 590, 50, 250, 1, 1, 6, 777, setByIndex)
	-- set slider # of steps
	oLvgui.setSteps(cbiSlider, 6)
	
	-- text box test
	oLvgui.createTxbox(gui, 'TextBox demo', {}, 155, 590, 390, 25, '', 33)
	oLvgui.createTxbox(gui, 'Text2', {}, 155, 650, 390, 25, '', 39)
	
	-- droplist
	oLvgui.createDroplist(gui, 'Choose one', patchNames, {}, 150, 710, 280, 42, 'dropOne')
	
	-- droplist items
	local dlst2 = {'Phaser', 'Reverb'}
	-- droplist 2
	oLvgui.createDroplist(gui, 'Choose Pd Patch', dlst2, {}, 350, 50, 150, 24, 'patcher')
	
	 oLvgui.createKnob(gui, 'Knob', {}, 175, 790, 100, .5, -1, 4, 6)
	 local aknob = oLvgui.createKnob(gui, 'Knob Too', {}, 400, 780, 150, .6, 0, 1, 7)
	 oLvgui.setSteps(aknob, 6)
	
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
	myServ(gui)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
