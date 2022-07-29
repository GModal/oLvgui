-- oLvgui
-- MIT License
-- Copyright (c) 2022 Doug Garmon
-- +++++++++++++++++++++++++
--	START oLv GUI code block
do
-- Leave this 'do' for block
oLvgui = {}

local theme = nil   -- a 'global' theme
local vPort = nil   -- the viewport (dimensions, etc)
local vpFlags = {fullscreen=false}
local firstTime = true    -- first time through draw callback
local guiIDcount = 0
local touchCnt = 0
local IDlock = -1
-- flag to block unfocused elements, for dlist overlap and mouse movement outside focused elements
local blockAll = 0
local keybuf = ''
local pastebuf = ''
local kbfActv = 0
local kbfClr = 0
-- Special Chars
local spch = {bs = 0, cr = 0, paste = 0}
-- The mouse
local mouse = {x = 250,y = 100,b = 0,lock = 0}
local tau = math.pi * 2
local touch = {}

-- Thx to  BrotSagtMist!
local oprt=love.graphics.print
gprint=function(text, x, y, r , sx, sy, ox, oy, kx, ky ) oprt(text, math.floor(x),math.floor(y), r, sx, sy, ox, oy, kx, ky) end

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
local defpoly  = {
0.998584,0.001425,0.305409,0.995922,0.000000,0.995922,0.732785,0.001425,
}
-- polygons for droplist
local arrowDn = {
0.50,0.999,0.999,0.15,0.999,0.001,0.001,0.001,
0.001,0.15,
}
local arrowUp = {
0.50,0.001,0.999,0.85,0.999,0.999,0.001,0.999,
0.001,0.85,
}
-- clamp val 
local function clamp(min, val, max)
	return math.max(min, math.min(val, max))
end

function oLvgui.createTheme()
	local lvTheme = {}
  
	lvTheme.drop = {x = 7, y = 6}		-- dropshadow x,y
  lvTheme.font = love.graphics.newFont(16)
	lvTheme.fontsize = 16
  
  lvTheme.cquad = { { 0.5, 0.5, 0.5 }, { 0.7, 0.7, 0.7 }, { 0.4, 0.4, 0.4 }, { 0.95, 0.95, 0.95 }}
  -- world fundimentals, class 1: set by a quad, and used as the basis to derive other colors
	lvTheme.canvas = { 0.5, 0.5, 0.5 }
	lvTheme.cmplColor = { 0.7, 0.7, 0.7 }  
	lvTheme.selColor = { 0.4, 0.4, 0.4 }
	lvTheme.labelColor = { 0.95, 0.95, 0.95 }    -- most fonts
  -- fundimentals, class 2: derived colors
	lvTheme.color = { 0.6, 0.6, 0.6 }
  lvTheme.outline = { 0.875, 0.875, 0.875 } 
	lvTheme.shadowColor = { 0.25, 0.25, 0.25 }   -- also for inactive 
	lvTheme.hiLtColor = { 0.67, 0.67, 0.67 }     -- a complementary color, different from cmplColor
  -- other fonts
	lvTheme.dlFontColor = { 0.3, 0.3, 0.3 }   -- font color for dl selection
  
return lvTheme
end

-- table with current viewport info
function oLvgui.createVPort(wname, vpX, vpY, flags)
  local vp = {}
  
  vp.OS = love.system.getOS()
  vp.flags = flags
  vp.winname = wname
  
	vp.VPwidth = 1    -- vp size AS SET, I.E., as used on the desktop
	vp.VPdepth = 2    --    This WILL be RESET on mobile devices
  
  vp.safeX = 0      -- ACTUAL ANDROID vp size AS RETURNED by getSafeArea()
  vp.safeY = 0
  vp.safeW = 0
  vp.safeH = 0
  vp.Sx = 1         -- screen scalers
  vp.Sy = 1
  vp.open = false
  vp.scaleRequest = false
  vp.orientate = 'unknown'
  vp.useTouch = false
  vp.syncNow = 0

  if flags == nil then
    vp.flags = vpFlags
  end

  if vpX ~= nil then
    vp.VPwidth = vpX
  end
  if vpY ~= nil then
    vp.VPdepth = vpY
  end
  
  if wname == nil or wname == '' and vp.winname == nil then
    vp.winname = 'oLv window'
  end
  
  return vp
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function popVPort(vp)
  vPort.orientate = love.window.getDisplayOrientation()
  vPort.safeX, vPort.safeY, vPort.safeW, vPort.safeH = love.window.getSafeArea()
end

function oLvgui.autoScale()
    vPort.scaleRequest = true
end

-- init oLv GUI, call before any controls defined
function oLvgui.initoLv(wname, vpX, vpY, newTheme, flags) -- name, viewport x,y
  theme = newTheme  
  vPort = oLvgui.createVPort(wname, vpX, vpY, flags)

	love.window.setTitle( wname )
  love.graphics.setBackgroundColor(newTheme.canvas)
end

function oLvgui.resetVP(list, vpX, vpY, flags)
  vPort = oLvgui.createVPort(wname, vpX, vpY, flags)
  popVPort()
  love.window.updateMode(vpX, vpY, flags)
    for _,v in ipairs(list) do
      if v.kind == 'dl' then
        doDLsync(v)
      end
    end
end

function oLvgui.scaleVP(sx, sy)
  if sx ~= 0 and sy ~= 0 then
    vPort.Sx = sx
    vPort.Sy = sy
  end
end

function oLvgui.setTheme(list, newTheme)
  for _,v in ipairs(list) do
      v.theme = newTheme
  end
  theme = newTheme
  love.graphics.setFont(newTheme.font)
  love.graphics.setBackgroundColor(newTheme.canvas)
end

function oLvgui.getTheme()
  return theme
end

function oLvgui.getVPort()
  return vPort
end

function incrIDs()
  guiIDcount = guiIDcount + 1
  return guiIDcount
end

function oLvgui.quit()
  oLvquit()   -- function must be present to use Android 'back' button
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++
--	main callbacks
function oLvgui.updateoLv(list, dtime)
  for _,v in ipairs(list) do
    if v.cbUpdate ~= nil then
      v.cbUpdate(v, dtime)
    end
  end
	incrMButton()
end

function oLvgui.drawoLv(list)

  if firstTime then
    while love.window.isOpen() == false do
    end
  
    if vPort.OS == 'Android' or vPort.OS == 'iOS' then
      love.window.updateMode( vPort.VPwidth, vPort.VPdepth )
      vPort.useTouch = true
        while love.window.getFullscreen() == false do
          love.window.setFullscreen(true)
        end
    else
      love.window.updateMode( vPort.VPwidth, vPort.VPdepth, vpFlags )
    end
    
      vPort.orientate = love.window.getDisplayOrientation()
      vPort.safeX, vPort.safeY, vPort.safeW, vPort.safeH = love.window.getSafeArea()
      
        if vPort.scaleRequest == true then
            if vPort.VPwidth < vPort.VPdepth and vPort.safeW > vPort.safeH then
              local tmpW = vPort.safeW
              vPort.safeW = vPort.safeH
              vPort.safeH = tmpW
            end

            vPort.Sx = vPort.safeW / vPort.VPwidth
            vPort.Sy = vPort.safeH / vPort.VPdepth         
            vPort.scaleRequest = false
        end
      firstTime = false
      vPort.open = true
  end
  love.graphics.setFont(theme.font)
  --love.graphics.translate(vPort.safeX, vPort.safeY)
  if vPort.Sx == 1 and vPort.Sy == 1 then else
    love.graphics.scale( vPort.Sx, vPort.Sy )
  end
  
  local dls = {}
	for _,v in ipairs(list) do
		if v.kind == 'dl' and IDlock == v.guiID then
      table.insert(dls, v)
		else
			if v.cbDraw ~= nil then
        v.cbDraw(v)
      end
    end
	end
	-- draw any working (expanded) droplist last
	for _,v in ipairs(dls) do
    if v.cbDraw ~= nil then
      v.cbDraw(v)
    end
  end
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function drawPoly (x, y, sx, sy, verts, mode)
	if verts ~= nil then
		love.graphics.push()
		love.graphics.setLineWidth(.03)
		love.graphics.translate(x, y)
		love.graphics.scale( sx, sy )
		love.graphics.polygon(mode, verts)
		love.graphics.pop()
	end
end

local function splitStr(ostr)
local stbl = {}
	for word in string.gmatch(ostr, "%w+") do 
		table.insert(stbl, word)
	end

return stbl
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++
local function getID()
    touchCnt = touchCnt + 1
    return touchCnt
end

-- val to normalize 0-1
local function normscale(val, min, max)
return((val-min)/(max-min))
end

-- reverse normalized
local function revscale(val, min, max)
return((max-min)*val + min)
end

local function midpoint(x1, y1, x2, y2)
return  ((x1+x2)/2), ((y1+y2)/2) 
end

-- mouse hit in a square
local function bxHit(cx, cy, cw, ch)
local qt = false
  if mouse.y > cy and mouse.y < (cy + ch) and mouse.x > cx  and mouse.x < (cx + cw) then 
    qt = true
	end
return qt, mouse.x, mouse.y
end

-- mouse hit in a square, touch version
local function tchHit(cx, cy, cw, ch)
local tx, ty, tid = 0, 0, -1
  for _,tch in pairs(touch) do
      if tch[2] > cy and tch[2] < (cy + ch) and tch[1] > cx  and tch[1] < (cx + cw) then 
        tx = tch[1]
        ty = tch[2]
        tid = tch[3]
      end
  end
return tx, ty, tid
end

-- mouse distance from point
local function mdistance ( x1, y1)
  local dx = x1 - mouse.x
  local dy = y1 - mouse.y
  return math.sqrt ( dx * dx + dy * dy )
end

local function findSteps(v)
	local stepi = (1 / (v.steps - 1))
	local nval = (normscale(v.value, v.min, v.max) / stepi)+ .5
return(revscale( math.floor(nval) * stepi, v.min, v.max) )
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function oLvgui.createMarker(list, label, user)
	local lvMarker = {}
	lvMarker.kind = 'ma'
	lvMarker.label = label
	lvMarker.user = user
	lvMarker.cbDraw = drawMarker
	lvMarker.cbUpdate = updateMarker
	-- Put the new marker in the list
    	table.insert(list, lvMarker)
	return(lvMarker)
end

function drawMarker(_)
end

function updateMarker(_)
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function oLvgui.createLabel(list, label, options, x, y, fontSize, color, user)
	local lvLabel = {}
	lvLabel.kind = 'la'
  lvLabel.guiID = -1
	lvLabel.active = 1
	lvLabel.visible = 1
	lvLabel.etype = 0
  lvLabel.fontSize = fontSize
  lvLabel.font = theme.font
	lvLabel.label = label
	lvLabel.x = x
	lvLabel.y = y
	lvLabel.user = user
	lvLabel.theme = theme
	lvLabel.color = nil
  lvLabel.cbDraw = drawLabel
	lvLabel.cbUpdate = updateLabel
  
  if color ~= nil then
    lvLabel.color = color
  end
  
  if fontSize ~= nil then
    lvLabel.font = love.graphics.newFont(fontSize)
  end
  
  lvLabel.guiID = incrIDs()
	
	-- Put the new slider in the list
    	table.insert(list, lvLabel)
	return(lvLabel)
end

function drawLabel(v)
  love.graphics.push()
    if v.visible == 1 and v.active == 1 then
        love.graphics.setColor(v.theme.labelColor)
        if v.color ~= nil then
          love.graphics.setColor(v.color)
        end
        --local tfont = love.graphics.getFont( )
        love.graphics.setFont(v.font)
        gprint(v.label, v.x, v.y)
        love.graphics.setFont(theme.font)
    end
  love.graphics.pop()
end

function updateLabel(v, dt)
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function oLvgui.createPanel(list, label, options, x, y, width, depth, color, user)
	local lvPanel = {}
	lvPanel.kind = 'pa'
  lvPanel.guiID = -1
  lvPanel.touchID = -1
  lvPanel.showHit = false
	lvPanel.active = 1
	lvPanel.visible = 1
	lvPanel.etype = 0
  lvPanel.state = 0
  lvPanel.fntSize = fntSize
	lvPanel.label = label
	lvPanel.x = x
	lvPanel.y = y
  lvPanel.width = width
	lvPanel.depth = depth
  lvPanel.tx = -1
  lvPanel.ty = -1
	lvPanel.user = user
	lvPanel.theme = theme
	lvPanel.color = color
  lvPanel.selcolor = nil
  lvPanel.drop = 1
  lvPanel.callback = doPanel
  lvPanel.cbDraw = drawPanel
	lvPanel.cbUpdate = updatePanel
  lvPanel.imagepath = nil
  lvPanel.image = nil
  lvPanel.img_sx = 1
  lvPanel.img_sy = 1
  lvPanel.img_width = 0
  lvPanel.img_height = 0
  
			-- iterate options
	for i,_ in ipairs(options) do
		if options[i] == 'DROPS_ON' then          -- DropShadow on
      lvPanel.drop = 1
    elseif options[i] == 'DROPS_OFF' then   -- DropShadow off
      lvPanel.drop = 0
    elseif options[i] == 'TYPE_INTERACT' then   -- interactive
      lvPanel.etype = 1
    elseif options[i] == 'SHOWHIT' then   -- draw xy dot
      lvPanel.showHit = true
    elseif options[i] == 'TYPE_NORM' then   -- no interactive
      lvPanel.etype = 0
    elseif options[i] == 'TYPE_IMAGE' then   -- no interactive
      if options[i+1] ~= nil then
        lvPanel.imagepath = options[i+1]
        local image = love.graphics.newImage(lvPanel.imagepath)
        if image ~= nil then
          lvPanel.image = image
          lvPanel.img_width = image:getWidth()
          lvPanel.img_height = image:getHeight()          
          lvPanel.img_sx = width / lvPanel.img_width
          lvPanel.img_sy = depth / lvPanel.img_height
        end
        i = i + 1
      end
		end
	end
  lvPanel.guiID = incrIDs()
	-- Put the new slider in the list
    	table.insert(list, lvPanel)
	return(lvPanel)
end

function drawPanel(v)
  	if v.visible == 1 and v.active == 1 or v.image ~= nil then
      love.graphics.push()
      if v.drop == 1 then
        love.graphics.setColor(v.theme.shadowColor)
        love.graphics.rectangle("fill", v.x+theme.drop.x, v.y+theme.drop.y, v.width, v.depth, 8, 8 )
      end
      love.graphics.setColor(v.color)
      if v.state == 1 then
        love.graphics.setColor(v.theme.selColor)
        if v.selcolor ~= nil then
          love.graphics.setColor(v.selcolor)
        end
      end
      
      if v.image ~= nil then
        love.graphics.draw(v.image, v.x, v.y, 0, v.img_sx, v.img_sy)
      else
        love.graphics.rectangle( "fill", v.x, v.y, v.width, v.depth, 8, 8)
      end
      
      if v.showHit then
        if v.state == 1 and v.tx ~= -1 and v.ty ~= -1 then
          love.graphics.setColor({.4,.4,.4})
          love.graphics.circle( 'line', v.tx -6, v.ty -6, 12 )
        end
      end
        
      love.graphics.pop()
    end
end

function updatePanel(v, dt)
	if v.visible == 1 and v.active == 1 and v.etype == 1 then
		if blockAll == 0 then		-- blockAll freezes all elements if a droplist is open
      
      if vPort.useTouch == true then    -- use touch
              local tx, ty, tid = tchHit(v.x, v.y, v.width, v.depth)
              v.tx = tx
              v.ty = ty
        
              if tid ~= -1 then   --  touch inside
                  if v.state == 0 then
                    v.state = 1
                    v.callback(v.state, v.user, (tx - v.x) / v.width, (ty - v.y) / v.depth)
                  end
              elseif v.state == 1 then -- touch outside 
                    v.state = 0
                    v.callback(v.state, v.user, (tx - v.x) / v.width, (ty - v.y) / v.depth)
              end       
      else    -- use mouse
              local test, tx, ty = bxHit(v.x, v.y, v.width, v.depth)
              v.tx = tx
              v.ty = ty
              if test == true then  -- a hit, mouse
                    if mouse.b >= 1 then   -- mouse b>1
                          if v.state == 0 then
                            v.state = 1
                            v.callback(v.state, v.user, (tx - v.x) / v.width, (ty - v.y) / v.depth)
                          end
                    elseif v.state == 1 then  -- deselected while inside (up button)
                            v.state = 0
                            v.callback(v.state, v.user, (tx - v.x) / v.width, (ty - v.y) / v.depth)
                    end

              elseif v.state == 1 then  -- deselect by moving out of panel
                      v.state = 0
                      v.callback(v.state, v.user, (tx - v.x) / v.width, (ty - v.y) / v.depth) 
              end
  
      end
    end
  end
end

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function oLvgui.createButton(list, text, options, x, y, width, depth, user, callbk)
	local lvButton = {}
	lvButton.kind = 'bu'
  lvButton.guiID = -1
	lvButton.active = 1
	lvButton.visible = 1
	lvButton.focusType = 0
	lvButton.state = 0
	lvButton.etype = 0        -- 0 == momentary, 1 == toggle
	lvButton.text = text
	lvButton.textOrig = (width - theme.font:getWidth(text)) /2
	lvButton.x = x
	lvButton.y = y
	lvButton.width = width
	lvButton.depth = depth
	lvButton.user = user
	lvButton.theme = theme
  lvButton.color = nil
  lvButton.colorSel = nil
  lvButton.textcolor = nil
	lvButton.selGraphic = defpoly
	lvButton.callback = doButton
	lvButton.cbDraw = drawButton
	lvButton.cbUpdate = updateButton
	
  if extra ~= nil then
    lvButton.extra = extra
  end
	if callbk ~= nil then
		lvButton.callback = callbk
	end
	-- iterate options
	-- default is momentary (type = 0)
	-- 	TOGGLEON & TOGGLEOFF are toggles (type = 1)
	--	*ON or *OFF set state (unsel = 0, sel = 1)
	--	MOMENTARY default type = 0
	for _,v in ipairs(options) do
		if v == 'TOGGLEON' then
			lvButton.etype = 1
			lvButton.state = 1
		elseif v == 'TOGGLEOFF' then
			lvButton.etype = 1
			lvButton.state = 0
		elseif v == 'MOMENTARY' then
			lvButton.etype = 0
			lvButton.state = 0
		end
	end
  
  lvButton.guiID = incrIDs()
	-- Put the new button in the list
    	table.insert(list, lvButton)
	return(lvButton)
end

function drawButton(v)
	love.graphics.push()	
	love.graphics.setLineWidth(1)
	if v.visible == 1 then 
		if v.active == 1 then
			love.graphics.setColor(v.theme.shadowColor)
			love.graphics.rectangle("fill", v.x+theme.drop.x, v.y+theme.drop.y, v.width, v.depth, 4, 4)
			love.graphics.setColor(v.theme.color)
      if v.color ~= nil then
        love.graphics.setColor(v.color)
      end
      if IDlock == v.guiID and mouse.b >= 1 then  -- body == selcolor only when clicked
        love.graphics.setColor(v.theme.cmplColor)
        if v.colorSel ~= nil then
          love.graphics.setColor(v.colorSel)
        end
      end
			love.graphics.rectangle( "fill", v.x, v.y, v.width, v.depth, 8, 8)
      local eoff = 0
			if v.etype == 1 then
        eoff = v.depth / 4
				love.graphics.setColor(v.theme.outline, 0.7)
				love.graphics.setLineWidth(.5)
				love.graphics.rectangle( "line", v.x + 8, v.y + v.depth/12, (v.depth * .85), (v.depth * .85), 8, 8)
				love.graphics.setColor(v.theme.hiLtColor)
				if v.state == 1 then
					drawPoly(v.x + 8 + v.depth*0.08, v.y+v.depth*0.17, (v.depth * 0.72), (v.depth * 0.67) , v.selGraphic, 'fill')
				end
			end
			love.graphics.setColor(v.theme.labelColor)
      if v.textcolor ~= nil then
        love.graphics.setColor(v.textcolor)
      end
			gprint(v.text, v.x + v.textOrig + eoff, v.y + v.depth/2 - v.theme.fontsize/2)
		else
			love.graphics.setColor(v.theme.shadowColor) -- inactive
			love.graphics.rectangle( "line", v.x, v.y, v.width, v.depth, 8, 8)
		end
	end
	love.graphics.pop()
end

local tcnt = 0
function updateButton(v)
    if v.visible == 1 and v.active == 1 and blockAll == 0 then
      local test,_,_ = bxHit(v.x, v.y, v.width, v.depth)
      
          if test == true then
              if mouse.b >= 1 and IDlock == -1 then
                  IDlock = v.guiID
              end
          end
          if mouse.b == 0  then  -- deselected while inside (up button)
            IDlock = -1
          end
    
          if IDlock == v.guiID then
              if mouse.b == 2 then
                if v.etype == 1 then
                  if v.state == 1 then
                    v.state = 0
                  else
                    v.state = 1
                  end
                end
                v.callback(v.state, v.user)
              end
          end
    end
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function oLvgui.createSlider(list, label, options, x, y, width, depth, value, min, max, user, callbk)
	local lvSlider = {}
	lvSlider.kind = 'sl'
  lvSlider.guiID = -1
	lvSlider.active = 1
	lvSlider.visible = 1
	lvSlider.focusType = 0
	lvSlider.etype = 'H'
	lvSlider.label = label
	lvSlider.labelsplit = ''
	lvSlider.x = x
	lvSlider.y = y
	lvSlider.width = width
	lvSlider.depth = depth
	lvSlider.value = value
	lvSlider.lastv = value
  lvSlider.defValue = value
	lvSlider.steps = 0
  lvSlider.showValue = true
  lvSlider.autoRet = false
	lvSlider.min = min
	lvSlider.max = max
	lvSlider.user = user
	lvSlider.theme = theme	
	lvSlider.color = nil
	lvSlider.handlecolor = nil
	lvSlider.labelcolor = nil
	lvSlider.handlewidth = 15
	lvSlider.handledepth = depth
	lvSlider.callback = doSlider
	lvSlider.cbDraw = drawSlider
	lvSlider.cbUpdate = updateSlider
	
	if callbk ~= nil then
		lvSlider.callback = callbk
	end
	-- iterate options
	for i,_ in ipairs(options) do
		if options[i] == 'HORIZ' then
			lvSlider.etype = 'H'
			lvSlider.handlewidth = 15
			lvSlider.handledepth = depth
		elseif options[i] == 'VERT' then
			lvSlider.etype = 'V'
			lvSlider.handlewidth = width
			lvSlider.handledepth = 15
			lvSlider.labelsplit = splitStr(lvSlider.label)
    elseif options[i] == 'SHOWV' then
      lvSlider.showValue = true
    elseif options[i] == 'NOSHOWV' then
      lvSlider.showValue = false
    elseif options[i] == 'RETURN' then
      lvSlider.autoRet = true
    elseif options[i] == 'NORETURN' then
      lvSlider.autoRet = false
		end
	end
  
  lvSlider.guiID = incrIDs()
	-- Put the new slider in the list
	table.insert(list, lvSlider)
	return(lvSlider)
end

function drawSHandle(v)
	love.graphics.setColor(v.theme.outline)
  if v.handlecolor ~= nil then
    love.graphics.setColor(v.handlecolor)
  end
	if v.etype == 'H' then
		love.graphics.rectangle("fill", clamp(v.x, normscale(v.value, v.min, v.max) * v.width + v.x - v.handlewidth/2, v.x + v.width - v.handlewidth), v.y, v.handlewidth, v.handledepth, 4, 4 )
	elseif v.etype == 'V' then
		love.graphics.rectangle("fill", v.x, clamp(v.y, normscale(v.value, v.min, v.max) * v.depth + v.y - v.handledepth/2, v.y + v.depth - v.handledepth), v.handlewidth, v.handledepth, 4, 4 )
	end
end

function drawSlider(v)
	love.graphics.push()
	love.graphics.setLineWidth(1)
		if v.visible == 1 then
			if v.active == 1 then
				love.graphics.setColor(v.theme.shadowColor)
				love.graphics.rectangle("fill", v.x+theme.drop.x, v.y+theme.drop.y, v.width, v.depth, 4, 4)
				love.graphics.setColor(v.theme.color)
        if v.color ~= nil then
          love.graphics.setColor(v.color)
        end
				love.graphics.rectangle("fill", v.x, v.y, v.width, v.depth, 4, 4)
				love.graphics.setColor(v.theme.outline)
				love.graphics.rectangle("line", v.x, v.y, v.width, v.depth, 4, 4)
				drawSHandle(v)
				love.graphics.push()
				
        love.graphics.setColor(v.theme.labelColor)
        
            if v.etype == 'V' then
              if v.showValue == true then
                local vstr = string.format("%.4f", v.value)
                love.graphics.printf( vstr, theme.font, math.floor(v.x + v.width/2 - 6), math.floor(v.y + 20), 16, 'left', 0, 1, .88, 0, 0, 0, 0 )
              end
              
              local leng, cloc = 0, 0
              for _, wd in ipairs(v.labelsplit) do 
                leng = string.len(wd)
                love.graphics.printf( wd, theme.font, math.floor(v.x + v.width + 6), math.floor(v.y + cloc * 15), 14, 'center', 0, 1, .85, 0, 0, 0, 0 )
                cloc = cloc + leng + 1.3
              end
              
            elseif v.etype == 'H' then
              gprint(string.format("%.5f", v.value), v.x + v.width * .2, v.y +10)
              gprint(v.label, v.x + 12, v.y - 20)
            end
				love.graphics.pop()
			else
				love.graphics.setColor(v.theme.shadowColor) -- inactive
				love.graphics.rectangle("line", v.x, v.y, v.width, v.depth, 4, 4)
			end
		end
	love.graphics.pop()
end

function updateSlider(v)
    if v.visible == 1 and v.active == 1 and blockAll == 0 then
      
        if vPort.useTouch == true then    -- use touch
            local tx, ty, tid = tchHit(v.x - 2, v.y - 2, v.width + 4, v.depth + 4)
            
              if tid ~= -1 then
                  if v.etype == 'H' then
                    v.value = clamp(v.min, revscale((tx - v.x)/v.width, v.min, v.max), v.max)
                  elseif v.etype == 'V' then
                    v.value = clamp(v.min, revscale((ty - v.y)/v.depth, v.min, v.max), v.max)
                  end
                  
                  if v.steps > 1 then
                    v.value = findSteps(v)
                  end
                  
                  if v.value ~= v.lastv then
                    v.callback(v.value, v.user)
                    v.lastv = v.value
                  end
                  
              elseif v.autoRet == true then
                  if v.value ~= v.defValue then
                    v.value = v.defValue
                    v.callback(v.value, v.user)
                  end
              end
              
        else  -- use mouse
            local test,_,_ = bxHit(v.x - 2, v.y - 2, v.width + 4, v.depth + 4)

              if test == true then
                    if mouse.b >= 1 and IDlock == -1 then
                        IDlock = v.guiID
                    end
              elseif mouse.b == 0 then  -- deselect by moving out of obj & mouse UP
                      IDlock = -1
              end
            
              if  IDlock == v.guiID then
                    if v.etype == 'H' then
                      v.value = clamp(v.min, revscale((mouse.x - v.x)/v.width, v.min, v.max), v.max)
                    elseif v.etype == 'V' then
                      v.value = clamp(v.min, revscale((mouse.y - v.y)/v.depth, v.min, v.max), v.max)
                    end
                    
                    if v.steps > 1 then
                      v.value = findSteps(v)
                    end
                    
                    if v.value ~= v.lastv then
                      v.callback(v.value, v.user)
                      v.lastv = v.value
                    end
                    
              elseif v.autoRet == true then
                    if v.value ~= v.defValue then
                      v.value = v.defValue
                      v.callback(v.value, v.user)
                    end
            end
        end
		end
end

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function oLvgui.createTxbox(list, label, options, x, y, width, depth, text, user, callbk)
	local lvTxbox = {}
	lvTxbox.kind = 'tb'
  lvTxbox.guiID = -1
	lvTxbox.visible = 1
	lvTxbox.active = 1
	lvTxbox.working = 0
	lvTxbox.etype = 'H'
	lvTxbox.label = label	
	lvTxbox.x = x
	lvTxbox.y = y
	lvTxbox.width = math.max(width, 100)
	lvTxbox.depth = math.max(depth, 25)
	lvTxbox.text = text
	lvTxbox.user = user
	lvTxbox.theme = theme
	lvTxbox.color = nil
	lvTxbox.labelcolor = nil
	lvTxbox.cursorcolor = nil
	lvTxbox.linestart = 1
	lvTxbox.ftHt = theme.font:getHeight()
	lvTxbox.callback = doTxbox
	lvTxbox.cbDraw = drawTxbox
	lvTxbox.cbUpdate = updateTxbox
	
	if callbk ~= nil then
		lvTxbox.callback = callbk
	end
  
  lvTxbox.guiID = incrIDs()
	-- Put the new text box in the list
	table.insert(list, lvTxbox)
	return(lvTxbox)
end

function drawTxbox(v)
	love.graphics.push()
	love.graphics.setLineWidth(1)
	if v.visible == 1 then
		if v.active == 1 then
			love.graphics.setColor(v.theme.shadowColor)
			love.graphics.rectangle("fill", v.x+theme.drop.x, v.y+theme.drop.y, v.width, v.depth, 4, 4)
	
			if v.working == 1 then
				love.graphics.setColor(v.theme.cmplColor)
				love.graphics.rectangle("fill", v.x + 3, v.y +3 , v.width - 6, v.depth -6, 4, 4)
			else
				love.graphics.setColor(v.theme.color)
				love.graphics.rectangle("fill", v.x, v.y, v.width, v.depth, 4, 4)
			end
			love.graphics.setColor(v.theme.outline)
			love.graphics.rectangle("line", v.x, v.y, v.width, v.depth, 4, 4)
			
			local fwid = theme.font:getWidth(string.sub(v.text, v.linestart))
			
			while fwid > v.width -25 do
				v.linestart = v.linestart + 1
				fwid = theme.font:getWidth(string.sub(v.text, v.linestart))
			end
			
			if fwid < v.width -25 then
				v.linestart = v.linestart - 1
				fwid = theme.font:getWidth(string.sub(v.text, v.linestart))
			end
			love.graphics.setColor(v.theme.labelColor)
			gprint(string.sub(v.text, v.linestart), v.x + 10, v.y + v.depth/2 - v.ftHt/2)
			
      love.graphics.setColor(v.theme.outline)
			love.graphics.rectangle("fill", v.x + fwid + 10, v.y, 6 , v.depth, 4, 4)
			love.graphics.setColor(v.theme.labelColor)
			gprint(v.label, v.x + 12, v.y - 20)
		else
			love.graphics.setColor(v.theme.shadowColor) -- inactive
			love.graphics.rectangle("line", v.x, v.y, v.width, v.depth, 4, 4)
		end
	end
	love.graphics.pop()
end

local delta = 0
function updateTxbox(v, dt)
	if v.visible == 1 and v.active == 1 then
		if blockAll == 0 then		-- blockAll freezes all elements if a droplist is open
    local test,_,_ = bxHit(v.x, v.y, v.width, v.depth)
			if test == true then
				if mouse.b == 2 then
					if v.working == 0 then
						keybuf = ''
						v.working = 1
						kbfActv = 1
						love.keyboard.setTextInput(true, 10, 700, 600, 300)
					else
						v.working = 0
						kbfActv = 0
					end
				end
			elseif mouse.b == 1 then
				v.working = 0
			end
			if v.working == 1 then
				if kbfClr == 0 then
					v.text = v.text..keybuf
					kbfClr = 1
				elseif spch.bs == 1 then
					v.text = string.sub(v.text, 1, -2)
					spch.bs = 0
				elseif spch.paste == 1 then
					v.text = v.text..pastebuf
					spch.paste = 0
				elseif spch.cr == 1 then
					v.working = 0
					spch.cr = 0
					doTxbox(v.text, v.user)
				end
			end
			delta = delta + dt/2
			if delta > 1 then 
				delta = 0 
			end
			v.cursorcolor = {delta, 0.6, 0.6}
		end
	end
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- sync various variables to droplist
-- called after updating items data, etc
function doDLsync(v)
  v.itemsTotal = #v.items
  v.itemsShow = v.itemsTotal
  -- total depth of all items in dl, in scrn coords
  local dlDepthTotal = v.depth * v.itemsTotal + 6
  -- low point of droplist, maybe below VP
	local lowPoint = v.y + dlDepthTotal
  -- shift up (neg offset) this amt
  local botOffset = vPort.VPdepth - lowPoint - 8
  
  -- set offset (shift up) to keep bottom of droplist in VP
  if lowPoint > vPort.VPdepth then
		v.offsety = botOffset
      if v.y + v.offsety < 0 then
        v.offsety = - v.y + 30
      end
	end
  -- total depth usable by dl, in scrn coord
  local dlDepthAllow = vPort.VPdepth - 18
  -- # of items that will fit on scrn
  local dlItemsFit = dlDepthAllow / v.depth
  dlItemsFit = math.floor(dlItemsFit + 0.5)
  if v.itemsTotal > dlItemsFit then
      v.itemsShow = dlItemsFit - 2
  end
  
  v.dropfont = love.graphics.newFont(v.depth - 10)
end

function oLvgui.createDroplist(list, label, items, options, x, y, width, depth, user, callbk)
	local lvDroplist = {}
	lvDroplist.kind = 'dl'
  lvDroplist.guiID = -1
	lvDroplist.visible = 1
	lvDroplist.active = 1
	lvDroplist.focusType = 0
	lvDroplist.working = 0
	lvDroplist.etype = 'H'
	lvDroplist.label = label
	lvDroplist.items = items
	lvDroplist.itemsTotal = 0
  lvDroplist.itemsTop = 0
  lvDroplist.itemsShow = #items
	lvDroplist.x = x
	lvDroplist.y = y
	lvDroplist.offsetx = 0
	lvDroplist.offsety = 0
	lvDroplist.width = math.max(width, 100)
	lvDroplist.depth = math.max(depth, 18)
	lvDroplist.text = text
	lvDroplist.user = user
	lvDroplist.selected = 0
  lvDroplist.spinSz = 26
	lvDroplist.theme = theme
	lvDroplist.color = nil
	lvDroplist.labelcolor = nil
	lvDroplist.dropfont = theme.font
	lvDroplist.callback = doDroplist
	lvDroplist.cbDraw = drawDroplist
	lvDroplist.cbUpdate = updateDroplist
  lvDroplist.sync = 0
	
	if callbk ~= nil then
		lvDroplist.callback = callbk
	end
	-- count items in table
	if items ~= nil then 
		lvDroplist.itemsTotal = #items
	end
		-- iterate options
	for i,_ in ipairs(options) do
		if options[i] == 'DESELECT' then          -- reselecting == reset to (none), callback as item #0
      lvDroplist.focusType = 0
    elseif options[i] == 'NO_DESELECT' then   -- reselecting == no change, no callback, no unselect
      lvDroplist.focusType = 1
    elseif options[i] == 'RESEND_SEL' then    -- reselecting == no change, but does callback
      lvDroplist.focusType = 2
    elseif options[i] == 'MENU' then    -- reselecting == no change, but does callback
      lvDroplist.focusType = 3
		end
	end
  
  doDLsync(lvDroplist)
  lvDroplist.guiID = incrIDs()
	-- Put the new droplist in the list
	table.insert(list, lvDroplist)
	return(lvDroplist)
end

local function dlTrimStr(v, i)
	local lleng = string.len(v.items[i])
	local fwid = v.dropfont:getWidth(string.sub(v.items[i], 1, lleng))
	while fwid > v.width -15 do
		lleng = lleng - 1
		fwid = v.dropfont:getWidth(string.sub(v.items[i], 1, lleng))
	end
return(lleng)
end

local crnr

function drawDroplist(v)
	love.graphics.push()
	love.graphics.setLineWidth(1)
	if v.visible == 1 then
		-- is active:
		if v.active == 1 then
        if v.sync == 1 then
          doDLsync(v)
          v.sync = 0
        end
        
      crnr = 5
      if v.focusType == 3 then
        crnr = 0
        love.graphics.setColor(v.theme.shadowColor)
        love.graphics.rectangle("fill", v.x+theme.drop.x + 3, v.y+theme.drop.y + 4, v.width, v.depth, crnr, crnr, 4 )
      else
        -- always draw nascent (unexpanded) droplist, so expanded box can be rendered anywhere (offsets)
        love.graphics.setColor(v.theme.shadowColor)
        love.graphics.rectangle("fill", v.x+theme.drop.x, v.y+theme.drop.y, v.width, v.depth, crnr, crnr, 4 )
      end
      
      love.graphics.setColor(v.theme.color)
      if v.color ~= nil then
        love.graphics.setColor(v.color)
      end
      love.graphics.rectangle("fill", v.x, v.y, v.width, v.depth, crnr, crnr, 4 )
      -- outline
      love.graphics.setColor(v.theme.outline)
      love.graphics.rectangle("line", v.x, v.y, v.width, v.depth, crnr, crnr, 4 )
			
			love.graphics.setFont(v.theme.font)
			love.graphics.setColor(v.theme.labelColor)
      
      if v.focusType ~= 3 then -- ------------------------------  not menu
              
        -- print label above droplist
        gprint(v.label, v.x + 12, v.y - 20)
        love.graphics.setFont(v.dropfont)

          for i=1, v.itemsTotal, 1 do
            local lleng = dlTrimStr(v, i)
            -- print the current selected txt to nascent box, if selection exists
            if i == v.selected then
              love.graphics.setColor(v.theme.dlFontColor)
              gprint(string.sub(v.items[i], 1, lleng), v.x + 12, v.y + v.depth / 7)
            end
          end

          if v.selected == 0 then
            love.graphics.setColor(v.theme.labelColor)
            gprint('(none)', v.x + 12, v.y + v.depth / 3 - 5.5 )			
          end
      else
            -- ------------------------------------------------  menu
            love.graphics.setColor(v.theme.outline)
            love.graphics.setLineWidth( 3 )
            love.graphics.rectangle("line", v.x - 3, v.y - 3, v.width +6 , v.depth + 6, crnr, crnr )
            love.graphics.setColor(v.theme.labelColor)
            love.graphics.setFont(v.dropfont)
            gprint(v.label, v.x + 12, v.y + v.depth / 7)
        
      end
			-- draw active (expanded) droplist
			if IDlock == v.guiID then
				love.graphics.setColor(v.theme.color)
        if v.color ~= nil then
          love.graphics.setColor(v.color)
        end
				love.graphics.rectangle("fill", v.offsetx + v.x - 2, v.offsety + v.y - 2 , v.width + 4, v.depth * v.itemsShow + 4, crnr, crnr, 4  )
				-- outline
				love.graphics.setColor(v.theme.outline)
				love.graphics.rectangle("line", v.offsetx + v.x - 2, v.offsety + v.y - 2 , v.width + 4, v.depth * v.itemsShow + 4, crnr, crnr, 4  )
        
        -- spin up/dn click area graphics
        if v.itemsShow < v.itemsTotal then
          love.graphics.setColor(v.theme.outline)
          love.graphics.rectangle("fill", v.offsetx + v.x - 2, v.offsety + v.y + v.depth * v.itemsShow , v.width + 4, v.spinSz, crnr, crnr, 4  )
          love.graphics.setColor(v.theme.labelColor)
          drawPoly(v.offsetx + v.x + v.width / 2 + v.width * 0.13, v.offsety + v.y + v.depth * v.itemsShow + 2, v.width / 2 * 0.3, v.spinSz - 4 , arrowDn, 'fill')
          drawPoly(v.offsetx + v.x + v.width * 0.23, v.offsety + v.y + v.depth * v.itemsShow + 2, v.width / 2 * 0.3, v.spinSz - 4 , arrowUp, 'fill')
        end
        
				-- print all the txt entries 
        --love.graphics.setColor(v.theme.labelColor)
				for i=1, v.itemsShow, 1 do
					local lleng = dlTrimStr(v, i + v.itemsTop)
					if i + v.itemsTop ~= v.selected or v.focusType == 3 then
						love.graphics.setColor(v.theme.labelColor)
					else
						love.graphics.setColor(v.theme.dlFontColor)
					end
					gprint(string.sub(v.items[i + v.itemsTop], 1, lleng), v.offsetx + v.x + 10, v.offsety +  v.y + v.depth * (i - 1) + 1)
				end
			end
		-- not visible, draw the blank unexpanded box
		else
			love.graphics.setColor(v.theme.shadowColor) -- inactive
			love.graphics.rectangle("line", v.x, v.y, v.width, v.depth, crnr, crnr, 4  )
		end
	end
	love.graphics.pop()
	love.graphics.setFont(theme.font)
end

function updateDroplist(v)
	if v.visible == 1 and v.active == 1  then
    local test
              if mouse.b > 1 then		
                      if blockAll == 0 then   -- a special flag set by droplist, due to overlap
                        test,_,_ = bxHit(v.x, v.y, v.width, v.depth)
                        if test == true then

                          if IDlock == -1 then
                            IDlock = v.guiID
                            blockAll = 1
                          end
                        end        
                      end
              end
			
      local oflag = 0     -- 'open' flag
      local spinArea = 0  -- extra space @ bottom for spinnin list up/down
      if v.itemsShow < v.itemsTotal then
        spinArea = v.spinSz
      end
      
      if mouse.b == 1 then
                if IDlock == v.guiID then
                  if mouse.y > v.y + v.offsety and mouse.y < v.depth * v.itemsShow + v.y + v.offsety + spinArea and mouse.x > v.x + v.offsetx and mouse.x < v.x + v.offsetx + v.width then
                  
                    if mouse.y > v.depth * v.itemsShow + v.y + v.offsety and mouse.x > v.x + v.offsetx + v.width / 2 then
                        -- do the downward spin (move long list down)
                      local newTop = v.itemsTop + 3
                      oflag = 1
                      if newTop < v.itemsTotal + 1 - v.itemsShow then
                        v.itemsTop = newTop
                      else
                        local newTop = v.itemsTop + 1
                        if newTop < v.itemsTotal + 1 - v.itemsShow then
                        v.itemsTop = newTop
                        end
                      end
                      
                    elseif mouse.y > v.depth * v.itemsShow + v.y + v.offsety and mouse.x < v.x + v.offsetx + v.width / 2 then
                      -- do the spin up
                      local newTop = v.itemsTop - 3
                      oflag = 1
                      if newTop < 0 then
                        newTop = v.itemsTop - 1
                      end
                      if newTop >= 0 then
                        v.itemsTop = newTop
                      end
                    else
                      -- not spin, do Selection / deselection
                      local subv =  ((mouse.y - v.y - v.offsety) /v.depth) + 1
                      local subSlot = math.floor(subv)
                      
                      if v.selected == subSlot + v.itemsTop and v.selected > 0 then
                        if v.focusType == 0 then
                          v.selected = 0
                          v.callback(v.selected, '(none)', v.user)
                        elseif v.focusType == 2 or v.focusType == 3 then  -- resend
                          v.callback(v.selected, v.items[v.selected], v.user)
                        end
                      elseif subSlot > 0 and subSlot <= v.itemsTotal then
                        v.selected = subSlot  + v.itemsTop
                        v.callback(v.selected, v.items[v.selected], v.user)
                      end
                      -- cludge to prevent underlying elements from receiving a mouse hit on exit
                      love.timer.sleep(0.3)
                    end
                  end
                  if oflag == 0 then
                      -- close the droplist
                      IDlock = -1
                      blockAll = 0
                      mouse.b = 0
                  end
                end
      end    

	end
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Knob support functions
local function valToAngle(val)
local na = val - 4.2
	if na < -math.pi then
		na = math.pi  - math.abs(val - 1.05)
	end
return na
end

local function revValue(val, min, max)
return(normscale(val, min, max) * (tau * 0.837) - 0.01)
end

local function sync(v)
  v.angle = valToAngle(revValue(v.value, v.min, v.max))
  v.labelLen = v.theme.font:getWidth(v.label)
end

function oLvgui.createKnob(list, label, options, x, y, size, value, min, max, user, callbk)
	local lvKnob = {}
	lvKnob.kind = 'kn'
  lvKnob.guiID = -1
	lvKnob.active = 1
	lvKnob.visible = 1
	lvKnob.focusType = 0
	lvKnob.etype = 'H'
	lvKnob.label = label
	lvKnob.labelLen = 50
	lvKnob.radius = size / 2
	lvKnob.x = x + lvKnob.radius/ 2
	lvKnob.y = y + lvKnob.radius/ 2
	lvKnob.angle = 0
	lvKnob.value = value
	lvKnob.lastv = value
	lvKnob.steps = 0
	lvKnob.min = min
	lvKnob.max = max
	lvKnob.user = user
	lvKnob.theme = theme
  lvKnob.color = nil
  lvKnob.handlecolor = nil
  lvKnob.numcolor = nil
	lvKnob.borderWidth = 2
	lvKnob.handlewidth = 15
	lvKnob.handledepth = depth
	lvKnob.callback = doKnob
	lvKnob.cbDraw = drawKnob
	lvKnob.cbUpdate = updateKnob
  lvKnob.sync = 0
	
	if callbk ~= nil then
		lvKnob.callback = callbk
	end
	
	lvKnob.angle = valToAngle(revValue(value, min, max))
	lvKnob.labelLen = theme.font:getWidth(label)
	
	-- iterate options
	for i,_ in ipairs(options) do
		if options[i] == 'HORIZ' then
		elseif options[i] == 'VERT' then
		end
	end

  lvKnob.guiID = incrIDs()
	-- Put the new slider in the list
	table.insert(list, lvKnob)
	return(lvKnob)
end

function drawKnob(v)
		love.graphics.push()
		love.graphics.translate(math.floor(v.radius/ 2), math.floor(v.radius/2))
		if v.visible == 1 then
			if v.active == 1 then
        if v.sync == 1 then
          sync(v)
          v.sync = 0
        end
				love.graphics.setLineWidth(v.borderWidth)
				-- label
				love.graphics.setColor(v.theme.labelColor)
				gprint(v.label, v.x  - v.labelLen/2, v.y - v.radius - 22)
				-- knob
				love.graphics.setColor(v.theme.shadowColor)
				love.graphics.circle( "fill", v.x+theme.drop.x, v.y+theme.drop.y,  v.radius )
				love.graphics.setColor(v.theme.color)
        if v.color ~= nil then
          love.graphics.setColor(v.color)
        end
				love.graphics.circle( "fill", v.x, v.y,  v.radius )
				
				love.graphics.setColor(v.theme.outline)
				love.graphics.circle( "line", v.x, v.y,  v.radius )
        
        love.graphics.setLineWidth(v.radius * .2)
        love.graphics.arc("line", 'open', v.x, v.y , v.radius * .75, 2.1, 1.04)
				-- pointer
				love.graphics.setColor(v.theme.labelColor)
        if v.handlecolor ~= nil then
          love.graphics.setColor(v.handlecolor)
        end
				love.graphics.setLineWidth(5)
				local xb = v.radius * math.cos(v.angle) + v.x
				local yb = v.radius * math.sin(v.angle) + v.y 
				local midx, midy = midpoint(v.x, v.y, xb, yb)
				love.graphics.line(midx, midy, xb, yb)
				-- #s
        love.graphics.setColor(v.theme.labelColor)
				local tStr = string.format("%.4f", v.value)
				local nln = theme.font:getWidth(tStr)
				gprint(tStr, v.x - nln/2, v.y - v.radius/3)
				
			else  -- draw inactive 
				love.graphics.setColor(v.theme.shadowColor)
				love.graphics.circle( "line", v.x, v.y,  v.radius )
			end
		end
	love.graphics.pop()
end

function updateKnob(v)
	if v.visible == 1 and v.active == 1 and blockAll == 0 then

      if mdistance(v.x + v.radius/2, v.y + v.radius/2) < v.radius then
          if mouse.b > 1 and IDlock == -1 then
            IDlock = v.guiID
          end
      else
          if mouse.b == 0 then  -- deselect by moving out of obj & mouse UP
            IDlock = -1
          end
      end

      if  IDlock == v.guiID then
          local angle =  math.atan2( (mouse.y - v.y - v.radius/2), (mouse.x  - v.x - v.radius/2) ) 
          local value = ((angle - tau * 0.333)  + tau) % tau
          
          if value < tau * 0.8333   then
            v.angle = angle
            value = value / (tau * 0.82) - 0.01
            v.value = clamp(v.min, revscale(value, v.min, v.max), v.max)
            if v.steps > 1 then
              v.value = findSteps(v)
            end
            if v.value ~= v.lastv then
              v.callback(v.value, v.user)
              v.lastv = v.value
            end
          end
      end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- access functions
function oLvgui.setActive(gList, state)
  if gList ~= nil then
    for _,v in ipairs(gList) do
      v.active = state
    end
  end
end

function oLvgui.setActiveIndex(gList, index, state)
	index = math.floor(index)
  if gList ~= nil then
    gList[index].active = state
  end
end

function oLvgui.setActiveByUser(gList, user, state)
	for _,v in ipairs(gList) do
		if user == v.user then
			v.active = state
			return
		end
	end
end

function oLvgui.getElementByUser(gList, user)
  local ele = nil
  for i,v in ipairs(gList) do
		if user == v.user then
			ele = v
		end
  end
  return (ele)
end

function oLvgui.getIndexByUser(gList, user)
  local ind = -1
  for i,v in ipairs(gList) do
		if user == v.user then
			ind = i
		end
  end
  return (ind)
end

function oLvgui.setValue(gList, index, value)
	if gList ~= nil and index ~= nil and value ~= nil then
		index = math.floor(index)
		gList[index].value = clamp(gList[index].min, value, gList[index].max)
	end
end

function oLvgui.setValueByUser(gList, user, value)
	for _,v in ipairs(gList) do
		if user == v.user then
			v.value = value
      if v.kind == 'kn' then
        v.sync = 1
      end
			return
		end
	end
end

function oLvgui.setSteps(elem, steps)
  if elem ~= nil then
    if steps > 1 then
      elem.steps = steps
      if elem.kind == 'sl' then
        if elem.etype == 'H' then
          elem.handlewidth = elem.width / (steps)
        elseif elem.etype == 'V' then
          elem.handledepth = elem.depth / (steps)
        end
      end
    end
  end
end

function oLvgui.deleteElementByUser(gList, user)
  for i,v in ipairs(gList) do
		if user == v.user then
			table.remove(gList, i)
		end
  end
end

function oLvgui.delAfterMarker(gList, user)
	local nlist = {}
	for _,v in ipairs(gList) do
		if user == v.user and v.kind == 'ma' then
			table.insert(nlist, v)
			return(nlist)
		else 
			table.insert(nlist, v)
		end
	end
return(nlist)
end

function oLvgui.delToMarker(gList, user)
	local nlist = {}
	local cpy = false
	for _,v in ipairs(gList) do
		if user == v.user and v.kind == 'ma' then
			cpy = true
		end
		if cpy then
			table.insert(nlist, v)
		end
	end
return(nlist)
end

function oLvgui.setLabel(gList, index, label)
	index = math.floor(index)
	gList[index].label = label
	if gList[index].txtype == 'V' then
		gList[index].labelsplit = splitStr(label)
	end
end

function oLvgui.dlSetItems(elem, items)
  if elem ~= nil then
      if elem.kind == 'dl' then
        elem.items = items
        elem.sync = 1
      end
  end
end

function oLvgui.dlSetSelect(elem, item)
  if elem ~= nil then
      if elem.kind == 'dl' then
        if item > 0 and item < elem.itemsTotal then
          elem.selected = item
          elem.sync = 1
        end
      end
  end
end

function oLvgui.setLabelByUser(gList, user, label)
	for _,v in ipairs(gList) do
		if user == v.user then
			if type(label) == 'strng' then
				v.label = label
			end
			return
		end
	end
end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function incrMButton()
	if mouse.b ~= 0 then
		mouse.b = mouse.b + 1
	end
end

function love.mousepressed(x, y, button, istouch)
		mouse.b = 1
		mouse.x = x  / vPort.Sx
		mouse.y = y  / vPort.Sy
end

function love.mousereleased(x, y, button)
		mouse.b = 0
		mouse.x = x / vPort.Sx
		mouse.y = y / vPort.Sy
end

function love.mousemoved( x, y, dx, dy, istouch )
	if mouse.b >= 1 then
		mouse.x = x / vPort.Sx
		mouse.y = y / vPort.Sy
    mouse.b = mouse.b + 1
	end
end

function love.touchpressed(id, x, y)
  touch[id] = {x / vPort.Sx, y / vPort.Sy, tid = getID()}
end

function love.touchmoved(id, x, y)
  touch[id][1] = x / vPort.Sx
  touch[id][2] = y / vPort.Sy
end

function love.touchreleased(id, x, y)
  touch[id] = nil
end

local function tchCnt()
  return #touch
end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++
function love.textinput(key)
	if kbfClr == 1 then
		keybuf = ''
	end
	if kbfActv == 1 then
		keybuf = keybuf..key
	end
	kbfClr = 0
end

function love.keypressed(key, scancode, isrepeat)
	if key == 'backspace' then
		spch.bs = 1
	elseif key == 'return' then
		spch.cr = 1
	elseif key == 'lalt' then
		spch.lalt = 1
  elseif key == "escape" then   -- 'Back' button quits Android app, 'escape' for others
      love.event.quit()
	end
	
	if love.keyboard.isDown('lctrl') and key == 'v' then
		pastebuf = keybuf..love.system.getClipboardText()
		spch.paste = 1
	end
end

return oLvgui
-- LEAVE THIS end FOR BLOCK
end
-- END GUI code block
