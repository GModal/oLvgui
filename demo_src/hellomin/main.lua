-- Hello world minimal
local oLvgui = require "oLv/oLvgui"
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++
local gui = {}

-- 		GUI callbacks
function doButton(state, user)
  oLvquit()
end
-- Quit when button pressed
function oLvquit()
	love.event.quit()
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
-- Std Love callbacks
function love.load()
  local myTheme = oLvgui.createTheme()
	oLvgui.initoLv('Hello World One', 960, 600, myTheme)
  oLvgui.createButton(gui, "Hello World", {'MOMENTARY'}, 200, 240, 320, 60, 'hi')
end

function love.update(dt)
	oLvgui.updateoLv(gui, dt)
end

function love.draw()
	oLvgui.drawoLv(gui)
end
  