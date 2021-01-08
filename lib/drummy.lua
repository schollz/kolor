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
  o.is_recording = false
  o.pressed_trig_area = false 
  o.pressed_row_top = false 
  o.pressed_row_effect = false 
  o.pressed_buttons = {}
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
	  		pos={1,1},
	  		pos_max={2,4},
	  		trig={},
	  	}
	  	-- fill in default trigs
	  	for row=1,4 do 
  			o.pattern[i].track[j].trig[row]={}
	  		for col=1,64 do
	  			o.pattern[i].track[j].trig[row][col]={
	  				playing=false,
	  				selected=false,
	  				active=false,
	  				effects={table.unpack(o.effects_last)}
	  			}
	  		end
	  	end
  	end
  end
  -- lattice 
  o.beat_started = 0
  o.beat_current = 0
  o.lattice = lattice:new({
  	ppqn=4
  })
  o.sixteenth_note_pattern = o.lattice:new_pattern{
  	action=function(t)
			o:sixteenth_note(t)
  	end,
  	division=1/16
  }
  o.lattice:start()
  return o
end

-- sixteenth note is played
function Drummy:sixteenth_note(t)
	self.beat_current = t 
	if self.is_playing then 
		print(self.beat_current-self.beat_started)
		for i,_ in ipairs(self.pattern[self.current_pattern].track) do 
			self.pattern[self.current_pattern].track[i].pos[2] = self.pattern[self.current_pattern].track[i].pos[2] + 1
			if self.pattern[self.current_pattern].track[i].pos[2] > self.pattern[self.current_pattern].track[i].pos_max[2] then 
				self.pattern[self.current_pattern].track[i].pos[2] = 1
				self.pattern[self.current_pattern].track[i].pos[1] = self.pattern[self.current_pattern].track[i].pos[1] + 1
			end
			if self.pattern[self.current_pattern].track[i].pos[1] > self.pattern[self.current_pattern].track[i].pos_max[1] then 
				self.pattern[self.current_pattern].track[i].pos[1] = 1
			end
			-- TODO emit track if something is there
		end
	end
	-- print("sixteenth_note ",t) 
end

-- returns the visualization of the matrix
function Drummy:get_grid()
	-- clear visual
	for row=1,8 do 
		for col=1,16 do 
			self.visual[row][col]=0
		end
	end

	-- draw top bar gradient
	if self.pressed_row_effect then 
		for i=0,15 do 
			self.visual[5][i+1]=i
		end
	else
		for i=0,16 do 
			if (i-1)%4 == 0 then 
				self.visual[5][i]=14
			elseif (i-1)%4 == 2 then 
				self.visual[5][i]=4
			else
				self.visual[5][i]=2
			end
		end
	end

	-- illuminate active/selected trigs
	for row=1,4 do 
		for col=1,64 do 
			if self.pattern[self.current_pattern].track[self.current_track].trig[row][col].selected then 
				self.visual[row][col] = 14 
			elseif self.pattern[self.current_pattern].track[self.current_track].trig[row][col].active then 
				self.visual[row][col] = 3 
			end
		end
	end				

	-- illuminate currently playing trig on currnetly selected track
	if self.is_playing and self.pattern[self.current_pattern].track[self.current_track].pos[2] > 0 then 
		self.visual[self.pattern[self.current_pattern].track[self.current_track].pos[1]][self.pattern[self.current_pattern].track[self.current_track].pos[2]] = self.visual[self.pattern[self.current_pattern].track[self.current_track].pos[1]][self.pattern[self.current_pattern].track[self.current_track].pos[2]]  + 7
		if self.visual[self.pattern[self.current_pattern].track[self.current_track].pos[1]][self.pattern[self.current_pattern].track[self.current_track].pos[2]] > 15 then 
			self.visual[self.pattern[self.current_pattern].track[self.current_track].pos[1]][self.pattern[self.current_pattern].track[self.current_track].pos[2]] = 15 
		end
	end

	-- illuminate non-muted tracks
	for i,track in ipairs(self.pattern[self.current_pattern].track) do 
		if not track.muted then 
			self.visual[8][i+1] = 14
		end
	end

	-- draw buttons
	if self.is_playing then 
		self.visual[8][1] = 15 -- play button
		self.visual[7][1] = 4  -- stop button
	else
		self.visual[8][1] = 4
		self.visual[7][1] = 15 
	end
	if self.is_recording then 
		self.visual[6][1] = 15 
	else
		self.visual[6][1] = 4
	end

	-- illuminate currently pressed button
	for k,_ in pairs(self.pressed_buttons) do
		row,col = k:match("(%d+),(%d+)")
		self.visual[tonumber(row)][tonumber(col)] = 15
	end

	return self.visual
end

-- set a key
function Drummy:key_press(row,col,on)
	if on then 
		self.pressed_buttons[row..","..col]=true
	else
		self.pressed_buttons[row..","..col]=nil
	end


	if row==5 then 
		self.pressed_row_top = on 
	elseif row >= 1 and row <= 4 and on then 
		self:press_trig(row,col)
	elseif row==6 and col==1 then 
		self:press_rec(on)
	elseif row==7 and col==1 then 
		self:press_stop(on)
	elseif row==8 and col==1 then 
		self:press_play(on)
	elseif row==8 and col >= 2 and col <= 7 then 
		self:press_track(col-1,on)
	elseif row==7 and col >= 2 and col <= 7 then 
		self:press_mute(col-1,on)
	end
end

function Drummy:press_track(track,on)

end

function Drummy:press_mute(track,on)
	if on then 
		self.pattern[self.current_pattern].track[track].muted = not self.pattern[self.current_pattern].track[track].muted 
	end
end

function Drummy:press_rec(on)

end

function Drummy:press_stop(on)
	if self.is_playing then 
		self.is_playing = false 
	end
end

function Drummy:press_play(on)
	print("press_play")
	if not self.is_playing then 
		self.is_playing = true
		self.beat_started = self.beat_current
		-- reset tracks
		for i,_ in ipairs(self.pattern[self.current_pattern].track) do
			self.pattern[self.current_pattern].track[i].pos = {1,0}
		end
	end
end


function Drummy:press_trig(row,col)
	print("press_trig",row,col)
	if row > self.pattern[self.current_pattern].track[self.current_track].pos_max[1] then 
		do return end 
	end
	if col > self.pattern[self.current_pattern].track[self.current_track].pos_max[2] then 
		do return end 
	end

	if self.pattern[self.current_pattern].track[self.current_track].trig[row][col].selected then 
		self.pattern[self.current_pattern].track[self.current_track].trig[row][col].selected = false
		self.pattern[self.current_pattern].track[self.current_track].trig[row][col].active = false
		do return end
	end

	-- unselect all others and select current
	for r=1,4 do 
		for c=1,16 do 
			self.pattern[self.current_pattern].track[self.current_track].trig[r][c].selected = false 
		end
	end
	self.pattern[self.current_pattern].track[self.current_track].trig[row][col].selected = true
	self.pattern[self.current_pattern].track[self.current_track].trig[row][col].active = true

	
end


return Drummy