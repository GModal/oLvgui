-- Hello world one
local oLvosc = require "oLv/oLvosc"
local oLvgui = require "oLv/oLvgui"
local oLvcolor = require "oLv/oLvcolor"
local oLvext = require "oLv/oLvext"
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
local gui = {}
local helloButton
local clkcnt = 10

-- 		GUI callbacks
function oLvquit()
	love.event.quit()
end

function doButton(state, user)
  if user == 'hello' then
    clkcnt = clkcnt - 1
    helloButton.text = 'Click me '..clkcnt..' times'
    helloButton.x = love.math.random(50,500)
    helloButton.y = love.math.random(50,500)
    if clkcnt == 0 then
      oLvquit()
    end
  end
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local canvW, canvH
canvW = 960
canvH = 600

-- Std Love callbacks
function love.load()
  local myTheme = oLvgui.createTheme()
  myTheme = oLvcolor.buildColors(oLvcolor.colorT.standard, myTheme)
	oLvgui.initoLv('Hello World One', canvW, canvH, myTheme)
  oLvgui.autoScale()

  helloButton = oLvgui.createButton(gui, 'Click me 10 times', {'MOMENTARY'}, 200, 240, 320, 60, 'hello')
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
  