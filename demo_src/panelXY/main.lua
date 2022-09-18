-- panel2d element
local oLvosc = require "oLv/oLvosc"
local oLvgui = require "oLv/oLvgui"
local oLvcolor = require "oLv/oLvcolor"
local oLvext = require "oLv/oLvext"
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
local gui = {}
local cudp, packet
local panelA, tchModeB, opModeB, stickB, dtLabel
local ttm = 0
local timeFrac = 3
local returnOnce = 0
local tchMode = 0
local opMode = 0
local sticky = 0
local flipper = 0
local carlaSlotX, carlaParamX, carlaSlotY, carlaParamY = 2, 5, 1, 1
local cRangeX_lo, cRangeX_hi, cRangeY_lo, cRangeY_hi = .7, 0, 0.9, 0
local hX, hY, aX, aY = 0.5, 0.5, 0.5, 0.2
local homeX, homeY = 0.5, 0.5
local awayX, awayY = 0.25, 0.2
local swapX, swapY = awayX, awayY
local curX, curY = .01, .01
local mvX, mvY = 0.04, 0.04
local direction = 0
local thresh = 0.0015
local speed = 15
local currentUI = 'main'

local Cx, Cy = 0.0, 0.0
local aP, aRot = .5, 0
local rMaj, rMin = 0.4, 0.1

local spdFactor = 1.5 -- speed compress
local elliDirect = 1 -- ellipse direction, 1 or -1
local hesitation = 3

local tchModeTxt_L = {'Immediate', 'Return', 'Rewind', 'Ping-Pong'}
local tchModeTxt_E = {'Immediate', 'Clockwise', 'Counter-Clockwise'}
local opModeTxt = {'MODE: Line', 'MODE: Ellipse'}
local stickyTxt = {'Non-stick', 'Sticky: Away', 'Sticky: Home', 'Sticky: Shift' }

local tchModeTxt = tchModeTxt_L

local opModeCol = { oLvcolor.color.olvBlue, oLvcolor.color.olvForest}

local function cclamp(min, val, max)
	return math.max(min, math.min(val, max))
end

local function dist1D(p1, p2) return math.sqrt((p2 - p1) ^ 2) end

local function dist(x1, y1, x2, y2) return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end

local function swapc(dir)
	if dir == 1 then
		homeX, homeY = hX, hY
		awayX, awayY = aX, aY
	else
		homeX, homeY = aX, aY
		awayX, awayY = hX, hY
	end
end

local function map(x, in_min, in_max, out_min, out_max)
	return out_min + (x - in_min)*(out_max - out_min)/(in_max - in_min)
end

local function map1(x, out_min, out_max)
	return out_min + x*(out_max - out_min)
end

local function chkVal(txt, oN)
	local nn = tonumber(txt)
	if nn == nil then 
		nn = oN 
		return nn, false
	end
	return nn, true
end

local function elliFix()
	aRot = math.atan2(aY - hY, aX - hX)
	rMaj = dist(aX, aY, hX, hY)
end

local function mvCursor(tm)
	if tchMode > 0 then
		ttm = ttm + 1
		if ttm % timeFrac == 0 then
			if opMode == 0 then
				if math.abs(curX - homeX) > thresh or math.abs(curY - homeY) > thresh then
					mvX, mvY = dist1D(curX, homeX)/speed, dist1D(curY, homeY)/speed
					-- move to home
					if curY - homeY < thresh then curY = curY + mvY elseif curY - homeY > thresh then curY = curY - mvY end
					if curX - homeX < thresh then curX = curX + mvX elseif curX - homeX > thresh then curX = curX - mvX end
					oLvgui.setPanel(panelA, curX, curY)
				else
					--if returnOnce ~= 1 then doRet = 0 end
					--oLvgui.setPanel(panelA, homeX, homeY)
					if tchMode == 3 then
						swapc(direction % 2)
						direction = direction + 1
					end
					if tchMode == 2 then
						oLvgui.setPanel(panelA, awayX, awayY)
					end
				end
			elseif opMode == 1 then
				local elliadd = (0.4 - math.abs(math.cos(aP))/hesitation) / spdFactor
				aP = aP  % (math.pi * 2) + elliadd * elliDirect
				curX = rMaj * math.cos(aP) * math.cos(aRot) - rMin * math.sin(aP) * math.sin(aRot) + hX
				curY = rMaj * math.cos(aP) * math.sin(aRot) + rMin * math.sin(aP) * math.cos(aRot) + hY 

				oLvgui.setPanel(panelA, curX, curY)
			end

		end
	end
end

-- 		GUI callbacks
function doButton(state, user)
	if user == 'tchMode' then
		homeX, homeY, awayX, awayY = hX, hY, aX, aY
		swapX, swapY = aX, aY
		if opMode == 0 then
			tchModeTxt = tchModeTxt_L
			tchMode = (tchMode + 1) % 4
			oLvgui.setLabelByElement(gui, tchModeB, tchModeTxt[tchMode+1])
			direction = 0
		elseif opMode == 1 then
			tchModeTxt = tchModeTxt_E
			tchMode = (tchMode + 1) % 3
			oLvgui.setLabelByElement(gui, tchModeB, tchModeTxt[tchMode+1])
			if tchMode == 2 then
				elliDirect = -1
			else
				elliDirect = 1
			end
		end
	elseif user == 'setOpMd' then
		opMode = (opMode + 1) % 2
		showMainUI()
		oLvgui.setLabelByElement(gui, opModeB, opModeTxt[opMode+1])
		opModeB.color = opModeCol[opMode+1]
		tchMode = 0
		elliDirect = 1
		if opMode == 0 then
			tchModeTxt = tchModeTxt_L
			oLvgui.setLabelByElement(gui, tchModeB, tchModeTxt[tchMode+1])
		elseif opMode == 1 then
			tchModeTxt = tchModeTxt_E
			oLvgui.setLabelByElement(gui, tchModeB, tchModeTxt[tchMode+1])
		end
	elseif user == 'stick' then
		sticky = (sticky + 1) % 4
		oLvgui.setLabelByElement(gui, stickB, stickyTxt[sticky+1])
	elseif user == 'sethm' then
		_, homeX, homeY = oLvgui.getPanel(panelA)
		hX = homeX
		hY = homeY
		elliFix()
	elseif user == 'setaway' then
		_, awayX, awayY = oLvgui.getPanel(panelA)
		aX = awayX
		aY = awayY
		elliFix()
	elseif user == 'fliptog' then
		if state == 1 then
			oLvgui.flipVertUI()
			flipper = 1
		else
			oLvgui.unflipVertUI()
			flipper = 0
		end
	elseif user == 'settings' then
		if state == 1 then
			showSettings()
			currentUI = 'set'
		else
			showMainUI()
			currentUI = 'main'
		end
	end
end

function doSlider(value, user)
	if user == 'speed' then
		speed = value
	elseif user == 'skipTm' then
		timeFrac = value
		dtLabel.label = 'Move every 1/'..timeFrac..' Delta tick'
	elseif user == 'sadj' then
		spdFactor = value
	elseif user == 'radMin' then
		rMin = value
	elseif user == 'hesi' then
		hesitation = value
	elseif user == 'xSlot' then
		carlaSlotX = value
	elseif user == 'xParam' then
		carlaParamX = value
	elseif user == 'ySlot' then
		carlaSlotY = value
	elseif user == 'yParam' then
		carlaParamY = value
	end
end

-- std Txbox callback
function doTxbox(text, user)
	local valid = true
	if user == 'xRangeLo' then
		cRangeX_lo, valid = chkVal(text, cRangeX_lo)
	elseif user == 'xRangeHi' then
		cRangeX_hi, valid = chkVal(text, cRangeX_hi)
	elseif user == 'yRangeLo' then
		cRangeY_lo, valid = chkVal(text, cRangeY_lo)
	elseif user == 'yRangeHi' then
		cRangeY_hi, valid = chkVal(text, cRangeY_hi)
	end
	if valid == false then
		oLvgui.getElementByUser(gui, user).text = 'REDO'
	end
end

function doPanel(state, user, x, y)
	if user == 'p2d' then
		if state ~= 0 then
			packet = oLvosc.oscPacket('/Carla/'..(carlaSlotX-1)..'/set_parameter_value', 'if', {math.floor(carlaParamX+.5) - 1, map1(x, cRangeX_lo, cRangeX_hi) } )
			oLvosc.sendOSC(cudp, packet)
			packet = oLvosc.oscPacket('/Carla/'..(carlaSlotY-1)..'/set_parameter_value', 'if', {math.floor(carlaParamY+.5) - 1, map1(y, cRangeY_lo, cRangeY_hi) } )
			oLvosc.sendOSC(cudp, packet)
			curX, curY = x, y
		end

		if state == 1 then
			if sticky == 1 then
				awayX, awayY = x, y
				aX, aY = awayX, awayY
				elliFix()
				aP = math.atan2(aY - hY, aX - hX) -aRot
			elseif sticky == 2 then
				homeX, homeY = x, y
				hX, hY = homeX, homeY
				elliFix()
			elseif sticky == 3 then
				local mX = hX - x
				local mY = hY - y
				aX, aY = cclamp(0, aX - mX, 1), cclamp(0, aY - mY, 1)
				hX = x
				hY = y
				if direction == 0 then
					homeX, homeY = hX, hY
					awayX, awayY = aX, aY
				else
					homeX, homeY = aX, aY
					awayX, awayY = hX, hY
				end
				elliFix()
			end
		end

	end
end

-- Quit when button pressed
function oLvquit()
	love.event.quit()
end

function showSettings()
	gui = oLvgui.delAfterMarker(gui, 'Mk1')

	oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_IMAGE', 'oLv/arrowH.png'}, 500, 15, 160, 20, {1,1,1,1.0}, 'varrow')
	oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_IMAGE', 'oLv/arrowV.png'}, 720, 330, 20, 170, {1,1,1,1.0}, 'varrow')

	local flipB = oLvgui.createButton(gui, "Flip", {'TOGGLE_OFF'}, 200, 150, 120, 50, 'fliptog')
	flipB.selGraphic = oLvext.xMark
	flipB.state = flipper

	local tSkip = oLvgui.createSlider(gui, 'Delta Time Skip Fraction', {}, 50, 300, 300, 30, timeFrac, 1, 6, 'skipTm')
	oLvgui.setSteps(tSkip, 6)
	dtLabel = oLvgui.createLabel(gui, 'Move every 1/'..timeFrac..' Delta tick', {}, 60, 340, 17, oLvcolor.color.olvMustard , 'skpL')

	oLvgui.createLabel(gui, 'Horizontal Dimension', {}, 400, 30, 26, oLvcolor.color.olvMustard , 'l1')
	local slideX = oLvgui.createSlider(gui, 'Set Carla Slot (plugin #)', {}, 400, 80, 300, 40, carlaSlotX, 1, 16, 'xSlot')
	oLvgui.setSteps(slideX, 16)
	local paramX = oLvgui.createSlider(gui, 'Set Parameter #', {}, 400, 150, 300, 40, carlaParamX, 1, 48, 'xParam')
	oLvgui.setSteps(paramX, 48)
	oLvgui.createTxbox(gui, 'Range Low ', {}, 400, 220, 100, 30, tostring(cRangeX_lo), 'xRangeLo')
	oLvgui.createTxbox(gui, 'Range Hi ', {}, 600, 220, 100, 30, tostring(cRangeX_hi), 'xRangeHi')

	oLvgui.createLabel(gui, 'Vertical Dimension', {}, 400, 290, 26, oLvcolor.color.olvMustard , 'l2')
	local slideY = oLvgui.createSlider(gui, 'Set Carla Slot (plugin #)', {}, 400, 340, 300, 40, carlaSlotY, 1, 16, 'ySlot')
	oLvgui.setSteps(slideY, 16)
	local paramY = oLvgui.createSlider(gui, 'Set Parameter #', {}, 400, 410, 300, 40, carlaParamY, 1, 48, 'yParam')
	oLvgui.setSteps(paramY, 48)
	oLvgui.createTxbox(gui, 'Range Low ', {}, 400, 480, 100, 30, tostring(cRangeY_lo), 'yRangeLo')
	oLvgui.createTxbox(gui, 'Range Hi ', {}, 600, 480, 100, 30, tostring(cRangeY_hi), 'yRangeHi')
end

function showMainUI()
	gui = oLvgui.delAfterMarker(gui, 'Mk1')
	oLvgui.createButton(gui, "Set Home", {'MOMENTARY'}, 30, 30, 120, 70, 'sethm')
	oLvgui.createButton(gui, "Set Away", {'MOMENTARY'}, 220, 30, 120, 70, 'setaway')


	panelA = oLvgui.createPanel(gui, "XY", {'DROPS_OFF', 'TYPE_INTERACT', 'SHOWHIT_ON', 'FOLLOW_ON'}, 400, 160, 500, 430, {0.4, 0.4, 0.4}, 'p2d', 3)
	tchModeB = oLvgui.createButton(gui, tchModeTxt[tchMode+1], {'MOMENTARY'}, 80, 450, 200, 100, 'tchMode')
	tchModeB.text = tchModeTxt[tchMode+1]

	stickB = oLvgui.createButton(gui, stickyTxt[sticky+1], {'MOMENTARY'}, 90, 130, 180, 60, 'stick')

	opModeB = oLvgui.createButton(gui, opModeTxt[opMode+1], {'MOMENTARY'}, 450, 30, 260, 70, 'setOpMd')
	opModeB.color = opModeCol[opMode+1]

	if opMode == 0 then
		oLvgui.createSlider(gui, 'fast      <-    Speed    ->      slow', {}, 35, 300, 300, 50, speed, 2, 30, 'speed')
	elseif opMode == 1 then
		oLvgui.createSlider(gui, 'Ellipse Speed Adj', {}, 35, 230, 300, 40, spdFactor, .05 , 7.5, 'sadj')
		oLvgui.createSlider(gui, 'Radius Min', {}, 35, 300, 300, 40, rMin, 0, .65, 'radMin')
		oLvgui.createSlider(gui, 'Hesitation', {}, 35, 370, 300, 40, hesitation, 2.5 , 6, 'hesi')
	end
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW, canvH = 960, 600

-- Std Love callbacks
function love.load()
	local myTheme = oLvgui.createTheme()
	myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv('Panel XY -> OSC -> Carla ', canvW, canvH, myTheme)
	oLvgui.autoScale()

	-- setup OSC send (client)
	-- sample options: '127.0.0.1', 'localhost', or the local machine addr
	-- and the multicast addr, something like: '224.0.0.1'
	cudp = oLvosc.cliSetup('224.0.0.1', 22752)

	oLvgui.createButton(gui, "X", {'MOMENTARY'}, 900, 24, 28, 28, 9999, oLvquit)
	settingB = oLvgui.createButton(gui, "Settings", {'TOGGLE_OFF'}, 760, 24, 130, 28, 'settings')
	settingB.selGraphic = oLvext.xMark
	oLvgui.createMarker(gui, 'Marker','Mk1')

	elliFix()
	showMainUI()
end

function love.update(dt)
	mvCursor(td)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
	if panelA ~= nil and currentUI == 'main' then
		oLvgui.drawMark(panelA.x + hX * panelA.width, panelA.y + hY * panelA.depth, 14, 14, oLvext.xMark, 'fill')
		oLvgui.drawMark(panelA.x + aX * panelA.width, panelA.y + aY * panelA.depth, 14, 14, oLvext.xMark, 'line')
	end
end
