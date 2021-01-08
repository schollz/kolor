local Pixels = {}
local pixel_graphics = {
delay = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{8,2,15},{1,3,15},{8,3,15},{1,4,15},{8,4,15},{1,5,15},{2,5,15},{3,5,15},{4,5,15},{5,5,15},{6,5,15},{7,5,15},{8,5,15},{1,7,15},{2,7,15},{3,7,15},{4,7,15},{5,7,15},{6,7,15},{7,7,15},{8,7,15},{1,8,15},{4,8,15},{8,8,15},{1,9,15},{4,9,15},{8,9,15},{1,10,15},{4,10,15},{8,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{5,12,15},{6,12,15},{7,12,15},{8,12,15},{8,13,15},{8,14,15},{8,15,15},{8,16,15}},
lpf = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{8,2,15},{8,3,15},{8,4,15},{1,6,15},{2,6,15},{3,6,15},{4,6,15},{5,6,15},{6,6,15},{7,6,15},{8,6,15},{1,7,15},{4,7,15},{1,8,15},{4,8,15},{1,9,15},{4,9,15},{1,10,15},{2,10,15},{3,10,15},{4,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{5,12,15},{6,12,15},{7,12,15},{8,12,15},{1,13,15},{4,13,15},{1,14,15},{4,14,15},{1,15,15},{4,15,15},{1,16,15}},
pan = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{4,2,15},{1,3,15},{4,3,15},{1,4,15},{4,4,15},{1,5,15},{2,5,15},{3,5,15},{4,5,15},{1,7,15},{2,7,15},{3,7,15},{4,7,15},{5,7,15},{6,7,15},{7,7,15},{8,7,15},{1,8,15},{5,8,15},{1,9,15},{5,9,15},{1,10,15},{2,10,15},{3,10,15},{4,10,15},{5,10,15},{6,10,15},{7,10,15},{8,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{5,12,15},{6,12,15},{7,12,15},{8,12,15},{2,13,15},{3,14,15},{4,14,15},{5,14,15},{6,14,15},{7,15,15},{1,16,15},{2,16,15},{3,16,15},{4,16,15},{5,16,15},{6,16,15},{7,16,15},{8,16,15}},
pitch = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{4,2,15},{1,3,15},{4,3,15},{1,4,15},{4,4,15},{1,5,15},{2,5,15},{3,5,15},{4,5,15},{1,7,15},{8,7,15},{1,8,15},{8,8,15},{1,9,15},{2,9,15},{3,9,15},{4,9,15},{5,9,15},{6,9,15},{7,9,15},{8,9,15},{1,10,15},{8,10,15},{1,11,15},{8,11,15},{1,13,15},{1,14,15},{1,15,15},{2,15,15},{3,15,15},{4,15,15},{5,15,15},{6,15,15},{7,15,15},{8,15,15},{1,16,15}},
probability = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{4,2,15},{1,3,15},{4,3,15},{1,4,15},{2,4,15},{3,4,15},{4,4,15},{1,6,15},{2,6,15},{3,6,15},{4,6,15},{5,6,15},{6,6,15},{7,6,15},{8,6,15},{1,7,15},{4,7,15},{5,7,15},{1,8,15},{4,8,15},{6,8,15},{1,9,15},{4,9,15},{7,9,15},{1,10,15},{2,10,15},{3,10,15},{4,10,15},{8,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{5,12,15},{6,12,15},{7,12,15},{8,12,15},{1,13,15},{8,13,15},{1,14,15},{8,14,15},{1,15,15},{8,15,15},{1,16,15},{2,16,15},{3,16,15},{4,16,15},{5,16,15},{6,16,15},{7,16,15},{8,16,15}},
res = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{4,2,15},{5,2,15},{1,3,15},{4,3,15},{6,3,15},{1,4,15},{4,4,15},{7,4,15},{1,5,15},{2,5,15},{3,5,15},{4,5,15},{8,5,15},{1,7,15},{2,7,15},{3,7,15},{4,7,15},{5,7,15},{6,7,15},{7,7,15},{8,7,15},{1,8,15},{4,8,15},{8,8,15},{1,9,15},{4,9,15},{8,9,15},{1,10,15},{4,10,15},{8,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{8,12,15},{1,13,15},{4,13,15},{8,13,15},{1,14,15},{4,14,15},{8,14,15},{1,15,15},{4,15,15},{8,15,15},{1,16,15},{4,16,15},{5,16,15},{6,16,15},{7,16,15},{8,16,15}},
retrig = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{4,2,15},{5,2,15},{1,3,15},{4,3,15},{6,3,15},{1,4,15},{2,4,15},{3,4,15},{4,4,15},{7,4,15},{8,4,15},{1,6,15},{2,6,15},{3,6,15},{4,6,15},{5,6,15},{6,6,15},{7,6,15},{8,6,15},{1,7,15},{4,7,15},{8,7,15},{1,8,15},{4,8,15},{8,8,15},{1,9,15},{4,9,15},{8,9,15},{1,10,15},{4,10,15},{8,10,15},{1,12,15},{1,13,15},{1,14,15},{2,14,15},{3,14,15},{4,14,15},{5,14,15},{6,14,15},{7,14,15},{8,14,15},{1,15,15},{1,16,15}},
reverb = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{1,2,15},{4,2,15},{5,2,15},{1,3,15},{4,3,15},{6,3,15},{1,4,15},{4,4,15},{7,4,15},{1,5,15},{2,5,15},{3,5,15},{4,5,15},{8,5,15},{1,7,15},{2,7,15},{3,7,15},{4,7,15},{5,7,15},{6,7,15},{7,7,15},{8,7,15},{1,8,15},{4,8,15},{8,8,15},{1,9,15},{4,9,15},{8,9,15},{1,10,15},{4,10,15},{8,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{5,13,15},{6,13,15},{7,13,15},{8,14,15},{5,15,15},{6,15,15},{7,15,15},{1,16,15},{2,16,15},{3,16,15},{4,16,15}},
sample_length = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{5,1,15},{6,1,15},{7,1,15},{8,1,15},{8,2,15},{8,3,15},{8,4,15},{1,6,15},{2,6,15},{3,6,15},{4,6,15},{5,6,15},{6,6,15},{7,6,15},{8,6,15},{1,7,15},{4,7,15},{8,7,15},{1,8,15},{4,8,15},{8,8,15},{1,9,15},{4,9,15},{8,9,15},{1,11,15},{2,11,15},{3,11,15},{4,11,15},{5,11,15},{6,11,15},{7,11,15},{8,11,15},{2,12,15},{3,13,15},{4,13,15},{4,14,15},{5,14,15},{6,14,15},{7,15,15},{1,16,15},{2,16,15},{3,16,15},{4,16,15},{5,16,15},{6,16,15},{7,16,15},{8,16,15}},
sample_start = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{8,1,15},{1,2,15},{4,2,15},{8,2,15},{1,3,15},{4,3,15},{8,3,15},{1,4,15},{4,4,15},{5,4,15},{6,4,15},{7,4,15},{8,4,15},{1,6,15},{1,7,15},{1,8,15},{2,8,15},{3,8,15},{4,8,15},{5,8,15},{6,8,15},{7,8,15},{8,8,15},{1,9,15},{1,10,15},{1,12,15},{2,12,15},{3,12,15},{4,12,15},{5,12,15},{6,12,15},{7,12,15},{8,12,15},{1,13,15},{4,13,15},{1,14,15},{4,14,15},{1,15,15},{4,15,15},{1,16,15},{2,16,15},{3,16,15},{4,16,15},{5,16,15},{6,16,15},{7,16,15},{8,16,15}},
volume = {{1,1,15},{2,1,15},{3,1,15},{4,1,15},{4,2,15},{5,2,15},{6,2,15},{7,2,15},{7,3,15},{8,3,15},{4,4,15},{5,4,15},{6,4,15},{7,4,15},{1,5,15},{2,5,15},{3,5,15},{4,5,15},{1,7,15},{2,7,15},{3,7,15},{4,7,15},{5,7,15},{6,7,15},{7,7,15},{8,7,15},{1,8,15},{8,8,15},{1,9,15},{8,9,15},{1,10,15},{8,10,15},{1,11,15},{2,11,15},{3,11,15},{4,11,15},{5,11,15},{6,11,15},{7,11,15},{8,11,15},{1,13,15},{2,13,15},{3,13,15},{4,13,15},{5,13,15},{6,13,15},{7,13,15},{8,13,15},{8,14,15},{8,15,15},{8,16,15}},
}

function Pixels.pixels(name)
	return pixel_graphics[name]
end

return Pixels
