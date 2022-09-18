-- oLvgui
-- MIT License
-- Copyright (c) 2022 Doug Garmon
do
-- Leave this 'do' for block
	oLvcolor = {}

-- clamp val 
	local function cclamp(min, val, max)
		return math.max(min, math.min(val, max))
	end

-- modified from https://github.com/icrawler/luacolors
-- Convert HSL to RGB, {0-360, 0-1, 0-1}
	local function hsl2rgb(h, s, l)
		h = h%360
		if s<=0 then 
			return { l,l,l }   
		end
		h, s, l = h/360*6, s, l
		local c = (1-math.abs(2*l-1))*s
		local x = (1-math.abs(h%2-1))*c
		local m,r,g,b = (l-.5*c), 0,0,0
		if h < 1     then r,g,b = c,x,0
		elseif h < 2 then r,g,b = x,c,0
		elseif h < 3 then r,g,b = 0,c,x
		elseif h < 4 then r,g,b = 0,x,c
		elseif h < 5 then r,g,b = x,0,c
		else              r,g,b = c,0,x
		end 
		return {(r+m),(g+m),(b+m)}
	end

-- modified from https://github.com/icrawler/luacolors
-- convert RGB to HSL, {0-1, 0-1, 0-1}
	local function rgb2hsl(r, g, b)
		local M, m =  math.max(r, g, b), math.min(r, g, b)
		local c, H = M - m, 0
		if M == r then H = (g-b)/c%6
		elseif M == g then H = (b-r)/c+2
		elseif M == b then H = (r-g)/c+4
		end	
		local L = 0.5*M+0.5*m
		local S = c == 0 and 0 or c/(1-math.abs(2*L-1))
		return {((1/6)*H)*360%360, S, L}
	end

-- returns euclidean color distance, (0-3)
	local function rgbColorDist(c1, c2)
		local rmean = ( c1[1] + c2[1] )/2
		local r = c1[1] - c2[1]
		local g = c1[2] - c2[2]
		local b = c1[3] - c2[3]
		return math.sqrt((((512+rmean)*r*r)/256) + 4*g*g + (((767-rmean)*b*b)/256))
	end

-- returns color luma, (0-1)
	local function luma(col)
		return (col[1]+col[1]+col[2]+col[2]+col[2]+col[3])/6
	end

-- amt values < 1.0 are darker, > 1.0 are lighter
	local function brightness(col, amt)
		return {cclamp(0, col[1] * amt, 1), cclamp(0, col[2] * amt, 1), cclamp(0, col[3] * amt, 1) }
	end

	local function cmix(col1, col2)
		return {(col1[1]+col2[1])/2, (col1[2]+col2[2])/2, (col1[3]+col2[3])/2 }
	end

	local function complementRGB(oc, amt)
		return { 1.0 - cclamp(0, oc[1] * amt, 1), 1.0 - cclamp(0, oc[2] * amt, 1), 1.0 - cclamp(0, oc[3] * amt, 1) }
	end

	function oLvcolor.hsl2rgb(h, s, l) return hsl2rgb(h, s, l) end
	function oLvcolor.rgb2hsl(r, g, b) return rgb2hsl(r, g, b) end
	function oLvcolor.rgbColorDist(c1, c2) return rgbColorDist(c1, c2) end
	function oLvcolor.luma(col) return luma(col) end
	function oLvcolor.brightness(col, amt) return brightness(col, amt) end
	function oLvcolor.cmix(col1, col2) return cmix(col1, col2) end
	function oLvcolor.complementRGB(oc, amt) return complementRGB(oc, amt) end
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- experimental (HACK!!) : derive colors algorithmically
	function oLvcolor.buildColors(cQuad, ttheme)

		ttheme.cquad = cQuad
		ttheme.canvas = cQuad[1]
		ttheme.cmplColor = cQuad[2]
		ttheme.selColor = cQuad[3]
		ttheme.labelColor = cQuad[4]

		local ccc = brightness(ttheme.canvas, 1.15)
		ttheme.color = ccc  

		ccc = brightness(ttheme.canvas, 0.5)
		ttheme.shadowColor = ccc

		if luma(ttheme.canvas) < 0.8 then
			ccc = brightness(ttheme.canvas, 1.75)
		else
			ccc = brightness(ttheme.canvas, 0.9)
		end
		ttheme.outline = ccc

		ccc =  rgb2hsl(ttheme.cmplColor[1], ttheme.cmplColor[2], ttheme.cmplColor[3])
		local sf = 1.3
		local lf = 0.1
		if ccc[3] > 0.6 then
			lf = -0.3
		end

		ccc = {cclamp(0, ccc[1], 1), cclamp(0, ccc[2] * sf, 1), cclamp(0,ccc[3] +lf, 1)}
		ccc = hsl2rgb(ccc[1], ccc[2], ccc[3])
		--ttheme.selColor = ccc
		ttheme.hiLtColor = brightness(ccc, 1.7)
		ttheme.dlFontColor = brightness(ccc, 1.9)

		local cy = luma(ttheme.color)
		local dly = luma(ttheme.dlFontColor)
		local ly = luma(ttheme.labelColor)
		local dlc_dist = rgbColorDist(ttheme.dlFontColor, ttheme.color)

		if dlc_dist < 1.5 then
			if dly < cy then
				ttheme.dlFontColor = brightness(ttheme.dlFontColor, 0.6)
			else
				ttheme.dlFontColor = brightness(ttheme.dlFontColor, 1.3)
			end
		end

		local font_dist = rgbColorDist(ttheme.dlFontColor, ttheme.labelColor)

		if font_dist < 1.75 then
			if dly > 0.5 then
				ttheme.dlFontColor = brightness(ttheme.dlFontColor, 0.3)
			else
				ttheme.dlFontColor = brightness(ttheme.dlFontColor, 1.8)
			end
		end 
		return (ttheme)
	end
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	local color = {}
-- colors from 'rgb.txt', made with 'csort.lua' utility
	oLvcolor.color = {
		gray40 = { 0.4, 0.4, 0.4 },			-- "dpBlue" rgb.txt error: 5.1%
		SkyBlue3 = { 0.424, 0.651, 0.804 },	-- "mdBlue" rgb.txt error: 5.0%
		lavender = { 0.902, 0.902, 0.98 },		-- "ltBlue" rgb.txt error: 5.2%
		gray20 = { 0.2, 0.2, 0.2 },			-- "dpGrey" rgb.txt error: 0.1%
		gray25 = { 0.251, 0.251, 0.251 },		-- "shadow" rgb.txt error: 5.1%
		gray60 = { 0.6, 0.6, 0.6 },			-- "mdGrey" rgb.txt error: 0.1%
		brown = { 0.647, 0.165, 0.165 },		-- "dkRed" rgb.txt error: 4.8%
		firebrick2 = { 0.933, 0.173, 0.173 },	-- "brtRed" rgb.txt error: 3.4%
		brown1 = { 1.0, 0.251, 0.251 },		-- "ltRed" rgb.txt error: 0.1%
		chocolate2 = { 0.933, 0.463, 0.129 },	-- "ltOrange" rgb.txt error: 3.8%
		khaki = { 0.941, 0.902, 0.549 },		-- "amber" rgb.txt error: 0.5%
		tan1 = { 1.0, 0.647, 0.31 },			-- "burnt" rgb.txt error: 5.3%
		white = { 1.0, 1.0, 1.0 },				-- "white" rgb.txt error: 0.1%

		-- 'rgb.txt' colors chosen, not derived
		slategray = { 0.44, 0.5, 0.56 },
		gray80 = { 0.8, 0.8, 0.8 },
		gray85 = { 0.851, 0.851, 0.851 },

		-- some custom colors, not in rgb.txt
		deepBlue = { 0.4, 0.4, 0.5 },
		bluish = { 0.35, 0.35, 0.45 },
		ltBlueGray = {0.8, 0.8, 0.9},

		-- some basic custom colors
		olvGreen = {0.25, .7, .45},
		olvBlue = {0.2, .3, .5},
		olvOrange = {0.83971, 0.33834, 0.08245},
		olvRed = {0.75, 0.15, 0.15},
		olvMustard = {0.87923, 0.70227, 0.39909},
		olvForest = {0.21697, 0.33383, 0.26165},
		olvTan = {0.82244, 0.72892, 0.65853},
		olvKhaki = {0.85786, 0.72437, 0.55986},
		olvBlush = {0.95981, 0.68929, 0.64846},
		olvAqua = {0.17725, 0.84863, 0.72277},
		olvSalmon = {0.87863, 0.37436, 0.40321},
	}

	local colorT = {}
-- ct = color tables
	oLvcolor.colorT = {
		primary = {{1.0,0.0,0.0},{0.0,1.0,0.0},{0.0,0.0,1.0},{1.0,1.0,1.0}},
		CMYK = {{0.0,1.0,1.0},{1.0,0.0,1.0},{1.0,1.0,0.0},{0.0,0.0,0.0}},
		RYB = {{1.0,0.0,0.0},{1.0,1.0,0.0},{0.0,0.0,1.0},{0.0,0.0,0.0}},

		standard = {oLvcolor.color.bluish, oLvcolor.color.brown, oLvcolor.color.firebrick2, oLvcolor.color.lavender},
		green = { oLvcolor.color.olvForest, oLvcolor.color.olvSalmon, oLvcolor.color.olvBlue, oLvcolor.color.olvKhaki },
		yellow = { oLvcolor.color.olvMustard, oLvcolor.color.olvForest, oLvcolor.color.olvOrange, oLvcolor.color.olvSalmon },
		orange = {oLvcolor.color.olvOrange, oLvcolor.color.brown, oLvcolor.color.firebrick2, oLvcolor.color.lavender},
		burnt = {oLvcolor.color.brown, oLvcolor.color.olvOrange, oLvcolor.color.firebrick2, oLvcolor.color.lavender},

		vocals = { {0.96017, 0.90831, 0.90116}, {0.40569, 0.70069, 0.73490}, {0.75440, 0.65486, 0.87664}, {0.75440, 0.27224, 0.35806}, },
		mindi = { {0.95362, 0.72430, 0.67852}, {0.90316, 0.52893, 0.58134}, {0.74509, 0.86710, 0.87498}, {0.28192, 0.60156, 0.62058}, },
		bread = { {0.97446, 0.72259, 0.55865}, {0.66324, 0.75174, 0.77587}, {0.57293, 0.46022, 0.77136}, {0.57293, 0.21025, 0.25402}, },
		milkshake = { {0.79975, 0.63438, 0.50000}, {0.58853, 0.75463, 0.47489}, {0.50162, 0.47839, 0.75509}, {0.50000, 0.28183, 0.13790}, },
		coolscape = { {0.48470, 0.49494, 0.49135}, {0.50000, 0.69942, 0.50000}, {0.48470, 0.36827, 0.41501}, {0.72956, 0.80341, 0.98625}, },
		greystoker = { {0.60174, 0.60010, 0.60055}, {0.40675, 0.28365, 0.57910}, {0.33373, 0.21180, 0.20336}, {0.94973, 1.00000, 1.00000}, },
		elmstr = { {0.74285, 0.50000, 0.50000}, {0.86891, 0.66118, 0.70092}, {0.74285, 0.50000, 0.93172}, {0.74285, 0.06679, 0.38164}, },
		uv = { {0.42404, 0.21939, 0.32414}, {0.56902, 0.16901, 0.35478}, {0.50000, 0.20059, 0.50000}, {0.90714, 0.42251, 0.44841}, },
		squid = { {0.35533, 0.00000, 0.25611}, {0.53059, 0.13233, 0.39191}, {0.50000, 0.20059, 0.50000}, {0.87863, 0.37436, 0.40321}, },
		redhot = { {0.64700, 0.16500, 0.16500}, {0.83971, 0.33834, 0.08245}, {0.93300, 0.17300, 0.17300}, {0.98625, 0.80827, 0.00000}, },
	}
-- +++++++++++++++++++++
	return oLvcolor
-- LEAVE THIS end FOR BLOCK
end
-- END COLOR code block