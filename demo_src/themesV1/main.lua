-- color picker
local oLvgui = require 'oLv/oLvgui'
local oLvext = require 'oLv/oLvext'
local oLvcolor = require 'oLv/oLvcolor'

local gui = {}
local themes = {oLvcolor.colorT.standard, oLvcolor.colorT.green, oLvcolor.colorT.burnt, oLvcolor.colorT.orange, oLvcolor.colorT.yellow, oLvcolor.colorT.vocals, oLvcolor.colorT.milkshake, oLvcolor.colorT.mindi, oLvcolor.colorT.bread, oLvcolor.colorT.greystoker, oLvcolor.colorT.coolscape, oLvcolor.colorT.elmstr, oLvcolor.colorT.uv, oLvcolor.colorT.redhot}
local themenms = {'Std', 'Green', 'Burnt', 'Orange', 'Yellow', 'Vocals', 'Milkshake', 'Mindi', 'Bread', 'Greystoker', 'Coolscape', 'Elmstr', 'UV', 'RedHot'}
local cPanel, strLabel
local thisColor = {0.5, 0.5, 0.5}
local tblname = 'cname'
local droplst
local dlTheme

local scrnPalette = { {0.5, 0.5, 0.5}, {0.5, 0.5, 0.5}, {0.5, 0.5, 0.5}, {0.5, 0.5, 0.5}, }
-- 		GUI callbacks
function doButton(state, user)
  if user == 'print' then
    local cform = string.format("%.5f, %.5f, %.5f", thisColor[1],thisColor[2],thisColor[3])
    cform = 'cname = {'..cform..'},'
    print(cform)
    strLabel.label = cform
  elseif user == 'printall' then
    local cform, ctmp
    cform = tblname..' = {'
    for i = 1, 4 do
      ctmp = string.format("%.5f, %.5f, %.5f", scrnPalette[i][1], scrnPalette[i][2], scrnPalette[i][3])
      cform = cform..' {'..ctmp..'},'
    end
    cform = cform..' },'
    print(cform)
    strLabel.label = cform
    love.system.setClipboardText(cform)
  elseif user == 'setpal' then
    local myTheme = oLvgui.createTheme()
    myTheme = oLvcolor.buildColors(scrnPalette, myTheme)
    oLvgui.setTheme(gui, myTheme)
  elseif user == 'topal' then
    local atheme = oLvgui.getTheme()
    if atheme ~= nil then
      for i = 1, 4 do
        scrnPalette[i][1] = atheme.cquad[i][1]
        scrnPalette[i][2] = atheme.cquad[i][2]
        scrnPalette[i][3] = atheme.cquad[i][3]
      end
    end
  elseif user >= 1 and user <= 4 then
    scrnPalette[user][1] = thisColor[1]
    scrnPalette[user][2] = thisColor[2]
    scrnPalette[user][3] = thisColor[3]
  elseif user >= 11 and user <= 14 then
    local idex = user - 10
    thisColor[1] = scrnPalette[idex][1]
    thisColor[2] = scrnPalette[idex][2]
    thisColor[3] = scrnPalette[idex][3]
    oLvgui.setValueByUser(gui, 'r', scrnPalette[idex][1])
    oLvgui.setValueByUser(gui, 'g', scrnPalette[idex][2])
    oLvgui.setValueByUser(gui, 'b', scrnPalette[idex][3])
  end
end

-- std Droplist callback
function doDroplist(index, text, user)
  if user == 'presets' then
    local newTheme = oLvgui.createTheme()
    newTheme = oLvcolor.buildColors(themes[index], newTheme)
    oLvgui.setTheme(gui, newTheme)
    --droplst.theme = dlTheme -- reset dl theme after setTheme() for gui list
  end
end

-- std Txbox callback
function doTxbox(text, user)
  if user == 'name' then
    tblname = text
  end
end

function doPanel(state, user)
  print('a hit: '..user..' state: '..state)
end

function doSlider(value, user)
end

function doKnob(value, user)
  if user == 'r' then
    thisColor[1] = value
    cPanel.color = thisColor
  elseif user == 'g' then
    thisColor[2] = value
    cPanel.color = thisColor
  elseif user == 'b' then
    thisColor[3] = value
    cPanel.color = thisColor
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

-- Std Love callbacks
function love.load()
  dlTheme = oLvgui.createTheme()
  dlTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, dlTheme)
  oLvgui.initoLv("Theme Editor", canvW, canvH, dlTheme)
  oLvgui.autoScale()
  
  local b1 = oLvgui.createButton(gui, "X", {'MOMENTARY'}, 20, 24, 28, 28, 9999, oLvquit)
  b1.color = oLvcolor.color.olvRed
  b1.textcolor = oLvcolor.color.olvYellow
  local b2 = oLvgui.createButton(gui, "Print Color", {'MOMENTARY'}, 120, 20, 100, 28, 'print')
  local b3 = oLvgui.createButton(gui, "Print Palette Tbl", {'MOMENTARY'}, 240, 20, 160, 28, 'printall')
  strLabel = oLvgui.createLabel(gui, "Color Defs Copied to Clipbd", {}, 50, 70, 11) 

  cPanel = oLvgui.createPanel(gui, "", {}, 60, 100, 680, 180, thisColor)  
  oLvgui.createKnob(gui, 'Red', {}, 115, 170, 130, thisColor[1], 0, 1, 'r')
	oLvgui.createKnob(gui, 'Green', {}, 340, 170, 130, thisColor[2], 0, 1, 'g')
  oLvgui.createKnob(gui, 'Blue', {}, 580, 170, 130, thisColor[3], 0, 1, 'b')
  
  local slid = oLvgui.createSlider(gui, 'Slider test', {}, 50, 490, 150, 30, 1, 1, 6, 777)
  oLvgui.createTxbox(gui, 'Palette Tbl Name', {}, 700, 30, 210, 25, 'cname', 'name')
  
  oLvgui.createButton(gui, "Pull", {'MOMENTARY'}, 290, 375, 30, 20, 1)
  oLvgui.createButton(gui, "\\/", {'MOMENTARY'}, 410, 375, 30, 20, 2)
  oLvgui.createButton(gui, "\\/", {'MOMENTARY'}, 530, 375, 30, 20, 3)
  oLvgui.createButton(gui, "\\/", {'MOMENTARY'}, 650, 375, 30, 20, 4)
  
  oLvgui.createPanel(gui, "", {'DROPS_OFF'}, 290, 400, 114, 100, scrnPalette[1])
  oLvgui.createPanel(gui, "", {'DROPS_OFF'}, 410, 400, 114, 100, scrnPalette[2])
  oLvgui.createPanel(gui, "", {'DROPS_OFF'}, 530, 400, 114, 100, scrnPalette[3])
  oLvgui.createPanel(gui, "", {'DROPS_OFF'}, 650, 400, 114, 100, scrnPalette[4])
  
  oLvgui.createButton(gui, "Set", {'MOMENTARY'}, 290 + 70, 505, 30, 20, 11)
  oLvgui.createButton(gui, "/\\", {'MOMENTARY'}, 410 + 70, 505, 30, 20, 12)
  oLvgui.createButton(gui, "/\\", {'MOMENTARY'}, 530 + 70, 505, 30, 20, 13)
  oLvgui.createButton(gui, "/\\", {'MOMENTARY'}, 650 + 70, 505, 30, 20, 14)
  
  droplst = oLvgui.createDroplist(gui, 'Presets', themenms, {'RESEND_SEL'},  50, 350, 180, 30, 'presets')
  oLvgui.dlSetSelect(droplst, 1)
  droplst.theme = dlTheme
  
  oLvgui.createButton(gui, "Preset -> Palette", {'MOMENTARY'}, 50, 400, 180, 28, 'topal')
  oLvgui.createButton(gui, "Palette -> Theme", {'MOMENTARY'}, 410, 320, 180, 28, 'setpal')
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
  