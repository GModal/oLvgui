-- OSC keyboard
local oLvosc = require "oLv/oLvosc"
local oLvgui = require "oLv/oLvgui"
local oLvcolor = require "oLv/oLvcolor"
local oLvext = require "oLv/oLvext"

local lines = {}
-- load a file into lines
function loadFile(fname)
	local line
	for line in love.filesystem.lines(fname) do 
		table.insert(lines, line)
	end
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
local gui = {}
local cudp, packet
local chrdLabels

local wkymatrix = {48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71,}
local b1matrix = {49, 51, 54, 56, 58}
local b2matrix = {61, 63, 66, 68, 70}
local midiChan = 1
local chordChan = 16
local nvolume = 64
local chdVol = 64
local octA = 0
local octB = 0
local lmatrx = {36, 38, 40, 41, 43, 45, 47}

local romanMaj = 'I\t ii\t iii\tIV\t V\tvi\tvii'
local romanMin = 'i\t ii\t III\tiv\t V\tVI\tVII'

local function getNotes(user)
	local note = 0
	if user <= 14 then note = wkymatrix[user]
	elseif user < 30 then note = b1matrix[user-15]
	else note = b2matrix[user-30]
	end
	return (note + octA)
end

-- 		GUI callbacks
function doButton(state, user)
end

local lstbnd, lstmod
-- std slider callback
function doSlider(value, user)
	if user == 'octA' then
		octA = (value - 4) * 12
	elseif user == 'octB' then    -- left 'chords' keybd
		octB = value
		local packet = oLvosc.oscPacket('/P2Jcli/0/P2JoR', 'si', {'cOctave', value})
		oLvosc.sendOSC(cudp, packet)
	elseif user == 'mmod' then
		local flip = math.abs(value - 1) * 127
		if flip ~= lstmod then
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'siii', {"@c", midiChan, 1, flip })
			oLvosc.sendOSC(cudp, packet)
			lstmod = flip
		end
	elseif user == 'pbend' then
		local bnd = math.floor(value + 0.5)
		if bnd ~= lstbnd then
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'sii', {"@b", midiChan, bnd })
			oLvosc.sendOSC(cudp, packet)
			lstbnd = bnd
		end
	elseif user == 'chordvol' then
		chdVol = math.floor(value + 0.5)
	end
end

-- std Droplist callback
function doDroplist(index, text, user)
	if user == 'patchrt' then
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'sii', {"@sendprogc", midiChan, index - 1 })
		oLvosc.sendOSC(cudp, packet)
	elseif user == 'patchlt' then
		local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'sii', {"@sendprogc", chordChan, index - 1 })
		oLvosc.sendOSC(cudp, packet)
	elseif user == 'chordb' then
		local packet = oLvosc.oscPacket('/P2Jcli/0/P2JoR', 'si', {'chordScale', index})
		oLvosc.sendOSC(cudp, packet)
		if index == 1 or index == 3 then
			chrdLabels.label = romanMaj
		else
			chrdLabels.label = romanMin
		end

	elseif user == 'key' then
		local packet = oLvosc.oscPacket('/P2Jcli/0/P2JoR', 'si', {'key', index})
		oLvosc.sendOSC(cudp, packet)
	end
end

function doPanel(state, user, x, y)
	if user < 50 then
		local note = getNotes(user)
		local tvol = math.max(0.3, y) 
		if y < 0.15 then
			tvol= (math.abs(y - 0.25) + .1) * 2.8
		end

		if state == 1 then
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'siii', {"@n", midiChan, note, tvol * 127})
			oLvosc.sendOSC(cudp, packet)
		else
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'siii', {"@n", midiChan, note, 0 })
			oLvosc.sendOSC(cudp, packet)
		end
	elseif user >= 50 then

		if state == 1 then
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'siii', {"@n", chordChan, user-50, chdVol})
			oLvosc.sendOSC(cudp, packet)
		else
			local packet = oLvosc.oscPacket('/P2Jcli/0/cmd', 'siii', {"@n", chordChan, user-50, 0 })
			oLvosc.sendOSC(cudp, packet)
		end
	end
end

-- Quit when button pressed
function oLvquit()
	love.event.quit()
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW, canvH
canvW = 960
canvH = 600

local wkeyW = 52
local wkeyH = 150
local wkeyOrigX = 60
local wkeyXincr = wkeyW + 10
local wkeyOrigY = 440

local bkeyW = 48
local bkeyH = 100
local bkeyOrigX = 90
local ckeyOrigX = 285
local bkeyXincr = wkeyW + 10
local bkeyOrigY = 340

local shiftkX = -50

-- Std Love callbacks
function love.load()
	local myTheme = oLvgui.createTheme()
	myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv('oLvgui OSC Keyboard', canvW, canvH, myTheme)
	oLvgui.autoScale()
	-- setup OSC send (client)
	-- sample options: '127.0.0.1', 'localhost', or the local machine addr
	-- and the multicast addr, something like: '224.0.0.1'
	cudp = oLvosc.cliSetup('224.0.0.1', 20331)

	loadFile("gmbanknm.txt")

	oLvgui.createButton(gui, "X", {'MOMENTARY'}, 20, 24, 28, 28, 9999, oLvquit)

	oLvgui.createDroplist(gui, 'GM Patch Keys', lines, {'RESEND_SEL'}, 530, 280, 230, 30, 'patchrt')
	oLvgui.createDroplist(gui, 'GM Patch Chords', lines, {'RESEND_SEL'}, 530, 220, 230, 30, 'patchlt')
	local oscBSlider = oLvgui.createSlider(gui, 'Octave Keys', {'HORIZ'}, 790, 280, 150, 30, 4, 2, 7, 'octA')
	-- set slider # of steps
	oLvgui.setSteps(oscBSlider, 6)

	local chrddl = oLvgui.createDroplist(gui, 'Chord base', {'Major', 'Minor', 'Major 7', 'Minor 7'}, {'NO_DESELECT', 'RESEND_SEL'}, 640, 80, 100, 30, 'chordb')
	oLvgui.dlSetSelect(chrddl, 1)

	local keysTxt = {'C','C#/Db','D','D#/Eb','E','F','F#/Gb','G','G#/Ab','A','Bb','B',}
	local keydl = oLvgui.createDroplist(gui, 'Key', keysTxt, {'NO_DESELECT', 'RESEND_SEL'}, 640, 134, 30, 26, 'key')
	oLvgui.dlSetSelect(keydl, 1)
	local octASlider = oLvgui.createSlider(gui, 'Octave Chords', {'HORIZ'}, 790, 80, 150, 26, 4, 2, 7, 'octB')
	oLvgui.setSteps(octASlider, 6)
	oLvgui.createSlider(gui, 'Chord Volume', {'HORIZ'}, 640, 26, 300, 26, 64, 0, 127, 'chordvol')  

	oLvgui.createSlider(gui, 'MIDI Mod Keys', {'VERT', 'NOSHOWV'}, 10, 140, 40, 400, 1, 0, 1, 'mmod')
	oLvgui.createSlider(gui, 'Bend Keys', {'HORIZ', 'RETURN_ON'}, 100, 200, 400, 110, 0, -8192, 8191, 'pbend')
	oLvgui.createLabel(gui, '|', {}, 396, 240, 18, {0.1,0.1,0.4})
	oLvgui.createLabel(gui, '|', {}, 196, 240, 18, {0.1,0.1,0.4})
	oLvgui.createLabel(gui, 'O', {}, 294, 240, 18, {0.1,0.1,0.4})

	-- draw keyboard
	for i=1,14 do 
		oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_INTERACT'}, (wkeyOrigX + wkeyXincr * i) + shiftkX, wkeyOrigY, wkeyW, wkeyH, {0.9, 0.9, 0.9}, i)
	end

	for i=1,2 do 
		for j=1,2 do
			oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_INTERACT'}, (bkeyOrigX + bkeyXincr * j) + shiftkX, bkeyOrigY, bkeyW, bkeyH, {0.2, 0.2, 0.2}, i*15 + j)
		end
		bkeyOrigX =  wkeyOrigX + wkeyW * 9 - 4
	end
	for i = 1,2 do
		for j=1,3 do
			oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_INTERACT'}, (ckeyOrigX + bkeyXincr * j) + shiftkX, bkeyOrigY, bkeyW, bkeyH, {0.2, 0.2, 0.2}, (i*15 + j+2))
		end
		ckeyOrigX = 715
	end

	for k = 1, 7 do
		oLvgui.createPanel(gui, "", {'DROPS_OFF', 'TYPE_INTERACT'}, (40 + 70 * k), 30, 60, 120, {0.9, 0.9, 0.9}, k + 50)
	end

	chrdLabels = oLvgui.createLabel(gui, romanMaj, {}, 133, 110, 32, {0.1,0.1,0.4})
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
