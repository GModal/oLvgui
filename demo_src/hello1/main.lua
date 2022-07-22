-- Hello world one
local oLvgui = require "oLv/oLvgui"
local oLvcolor = require "oLv/oLvcolor"
local oLvext = require "oLv/oLvext"
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
local gui = {}
local helloButton
local clkcnt = 0

-- 		GUI callbacks
function doButton(state, user)
  if user == 'hello' then
    clkcnt = clkcnt + 1
    helloButton.text = 'Hello # '..clkcnt
  end
end

-- Quit when button pressed
function oLvquit()
	love.event.quit()
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW, canvH = 960, 600

-- Std Love callbacks
function love.load()
  local myTheme = oLvgui.createTheme()
  myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv('Hello World One', canvW, canvH, myTheme)
  oLvgui.autoScale()
  
  oLvgui.createButton(gui, "X", {'MOMENTARY'}, 20, 24, 28, 28, 9999, oLvquit)
  helloButton = oLvgui.createButton(gui, "Hello World", {'MOMENTARY'}, 200, 240, 320, 60, 'hello')
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
  