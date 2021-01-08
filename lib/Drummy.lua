lattice = include("lib/lattice")
local Drummy = {}

--- instantiate a new drummy
-- @tparam[opt] table args optional named attributes are:
-- - "auto" (boolean) turn off "auto" pulses from the norns clock, defaults to true
-- - "meter" (number) of quarter notes per measure, defaults to 4
-- - "ppqn" (number) the number of pulses per quarter note of this superclock, defaults to 96
-- @treturn table a new lattice
function Drummy:new(args)
  local o = setmetatable({}, { __index = Drummy })
  local args = args == nil and {} or args
  o.meter = args.meter == nil and 4 or args.meter

  o.is_playing = false 
  o.is_stopped = true 
  o.is_recording = false
  o.pressed_trig_area = false 
  o.pressed_row_top = false 
  o.pressed_row_effect = false 
  o.pressed_button_stop = false 
  o.pressed_button_play = false 
  o.pressed_button_record = false 
  o.pressed_button = {0,0}
  o.trig_selected = {0,0}
  o.trig_playing = {0,0}
  o.effects_last = {
  	velocity=0.5,
  	probability=1.0,
  }
  o.visual = {}
  for i=1,8 do 
  	o.visual[i] = {} 
  	for j=1,16 do 
  		o.visual[i][j] = 0
  	end
  end
  o.current_pattern = 1 
  o.current_track = 1
  o.pattern = {}
  for i=1,9 do 
  	o.pattern[i] = {}
  	o.pattern[i].next_pattern={}
  	for j=1,9 do 
	  	o.pattern[i].next_pattern[j] = 0
	  	if i==j then 
		  	o.pattern[i].next_pattern[j] = 1
		end
  	end
  	o.pattern[i].track = {}
  	for j=1,6 do 
	  	o.pattern[i].track[j] = {
	  		muted=false,
	  		pos_current={1,1},
	  		pos_max={4,64},
	  		trig={},
	  	}
	  	-- fill in default trigs
	  	for row=1,4 do 
  			o.pattern[i].track[j].trig[row]={}
	  		for col=1,64 do
	  			o.pattern[i].track[j].trig[row][col]={
	  				selected=false,
	  				active=false,
	  				effects={table.unpack(o.effects_last)}
	  			}
	  		end
	  	end
  	end
  end
  -- lattice 
  o.lattice = lattice:new({
  	ppqn=4
  })
  o.sixteenth_note = o.lattice:new_pattern{
  	action=o:sixteenth_note,
  	division=1/16
  }
  o.lattice:start()
  return o
end

-- sixteenth note is played
function Drummy:sixteenth_note(t)
	print("sixteenth_note ",t) 
end

-- returns the visualization of the matrix
function Drummy:get_visual()
	-- illuminate active trigs
	for row=1,4 do 
		for col=1,64 do 
			if self.pattern[self.current_pattern].track[self.current_track].trig[row][col].selected then 
				self.visual[row+1][col] = 14 
			elseif self.pattern[self.current_pattern].track[self.current_track].trig[row][col].selected then 
				self.visual[row+1][col] = 7 
			end
		end
	end				

	-- illuminate currently playing trig 
	if self.is_playing then 
		self.visual[self.trig_playing[1]][self.trig_playing[2]] = self.visual[self.trig_playing[1]][self.trig_playing[2]] + 7 
	end

	-- illuminate currently pressed button
	if self.pressed_button[1] > 0 and self.pressed_button[2] > 0 then 
		self.visual[self.pressed_button[1]][self.pressed_button[2]] = 15
	end
end

-- set a key
function Drummy:key_press(i,j,z)
	local on = z==1
	if i==1 then 
		o.pressed_row_top = on_off 
	elseif i >= 2 and i <= 5 then 
		self:trig_press(i,j,on)
	end

	if o.pressed_trig_area then 

	end
end

function Drummy:trig_press(i,j,on)
	o.pressed_trig_area = on
	if on then 
	end
end




return Drummy