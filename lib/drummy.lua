lattice = include("lib/lattice")
graphic_pixels = include("lib/pixels")
local Drummy = {}

engine.name="Drummy"

local effect_available = {
  	volume = {default={8,nil},value={}},
  	pitch = {default={8,nil},value={-2,-1.5,-1.25,-1,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1,1.25,1.5,2}},
  	pan = {default={7,9},value={-7/7,-6/7,-5/7,-4/7,-3/7,-2/7,-1/7,0,1/7,2/7,3/7,4/7,5/7,6/7,7/7}},
  	lpf = {default={15,nil},value={}},
  	resonance = {default={8,nil},value={}},
  	hpf = {default={1,nil},value={}},
  	sample_start = {default={0,nil},value={}},
  	sample_length = {default={15,nil},value={}},
  	retrig = {default={0,nil},value={}},
  	delay = {default={0,nil},value={}},
  	reverb = {default={0,nil},value={}},
  	probability = {default={12,nil},value={}},
}

local effect_order = {
	"volume",
	"pitch",
	"pan",
	"lpf",
	"resonance",
	"hpf",
	"sample_start",
	"sample_length",
	"retrig",
	"delay",
	"reverb",
	"probability",
}
for i=1,15 do 
	effect_available.volume.value[i]=(i-1)/15
	effect_available.lpf.value[i]=40*math.pow(1.5,i)
	effect_available.resonance.value[i]=(4*i)/15
	effect_available.hpf.value[i]=40*math.pow(1.5,i)
	effect_available.sample_start.value[i]=3*i/15
	effect_available.sample_length.value[i]=3*i/15
	effect_available.retrig.value[i]=i 
	effect_available.delay.value[i]=i
	effect_available.reverb.value[i]=i
	effect_available.probability.value[i]=i/15
end

local function random_float(lower, greater)
    return lower + math.random()  * (greater - lower);
end

local function get_effect(trig,effectname)
	-- index ranges between 0 and 15 
	-- tab.print(trig)
	-- print(effectname,"1",trig.effect[effectname].value[1])
	-- print(effectname,"2",trig.effect[effectname].value[2])
	local effect_value = effect_available[effectname].value[trig.effect[effectname].value[1]]
	if trig.effect[effectname].value[2] ~= nil then 
		-- have range
		if trig.effect[effectname].lfo ~= 0 then 
			-- TODO calcualte and return lfo modulated value 
		else
			-- no LFO? but have range? generate a random value in the range
			effect_value = random_float(effect_value,effect_available[effectname].value[trig.effect[effectname].value[2]])
		end
	end 
	return effect_value
end

--- instantiate a new drummy
-- @tparam[opt] table args optional named attributes are:
-- - "auto" (boolean) turn off "auto" pulses from the norns clock, defaults to true
-- - "meter" (number) of quarter notes per measure, defaults to 4
-- - "ppqn" (number) the number of pulses per quarter note of this superclock, defaults to 96
-- @treturn table a new lattice
function Drummy:new(args)

	-- setup object
  local o = setmetatable({}, { __index = Drummy })
  local args = args == nil and {} or args

  o.meter = args.meter == nil and 4 or args.meter
  o.is_playing = false 
  o.is_recording = false
  o.pressed_trig_area = false 
  o.pressed_row_top = false 
  o.pressed_buttons = {}
  o.pressed_buttons_scale = {}
  o.selected_trig=nil
  o.effect_id_selected=0
  o.effect_last = {}
  for k,e in pairs(effect_available) do
  	o.effect_last[k] = {value=e.default,lfo=0}
  	if #e.value < 15 then 
  		print("UH OH "..k.." DOES NOT HAVE 15 value")
  	end
  end
  o.visual = {}
  for i=1,8 do 
  	o.visual[i] = {} 
  	for j=1,16 do 
  		o.visual[i][j] = 0
  	end
  end
  o.current_pattern = 1 
  o.track_current = 1
  o.track_playing = {false,false,false,false,false,false}
  o.pattern = {}
  for i=1,9 do 
  	o.pattern[i] = {}
  	o.pattern[i].trigs_active=0
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
	  		pos_max={1,16},
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
	  				effect={},
	  			}
	  			for k,v in pairs(o.effect_last) do 
		  			o.pattern[i].track[j].trig[row][col].effect[k]={value={v.value[1],v.value[2]},lfo=v.lfo}
	  			end
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

  -- load the samples
  engine.samplefile(1,"/home/we/dust/code/drummy/samples/kick1.wav")
  engine.samplefile(2,"/home/we/dust/code/drummy/samples/snare1.wav")
  engine.samplefile(3,"/home/we/dust/code/drummy/samples/shaker1.wav")
  engine.samplefile(4,"/home/we/dust/code/drummy/samples/ch1.wav")

  -- debouncing and blinking
  o.blink = 0
  o.blink_countdown = 2
  o.show_graphic = {nil,0}
  o.debouncer = metro.init()
  o.debouncer.time = 0.2
  o.debouncer.event = function()
  	o:debounce()
  end
  o.debouncer:start()

  return o
end

function Drummy:debounce()
	if self.blink_countdown > 0 then 
		self.blink_countdown = self.blink_countdown - 1 
		if self.blink_countdown <= 0 then 
			self.blink_countdown = 2 
			self.blink = 1 - self.blink
		end 
	end
	if self.show_graphic[2] > 0 then 
		 self.show_graphic[2] = self.show_graphic[2] - 1
	end
end

-- sixteenth note is played
function Drummy:sixteenth_note(t)
	self.beat_current = t 
	if self.is_playing then 
		-- print(self.beat_current-self.beat_started)
		for i,_ in ipairs(self.pattern[self.current_pattern].track) do 
			self.track_playing[i] = false 
			self.pattern[self.current_pattern].track[i].pos[2] = self.pattern[self.current_pattern].track[i].pos[2] + 1
			if self.pattern[self.current_pattern].track[i].pos[2] > self.pattern[self.current_pattern].track[i].pos_max[2] then 
				self.pattern[self.current_pattern].track[i].pos[2] = 1
				self.pattern[self.current_pattern].track[i].pos[1] = self.pattern[self.current_pattern].track[i].pos[1] + 1
			end
			if self.pattern[self.current_pattern].track[i].pos[1] > self.pattern[self.current_pattern].track[i].pos_max[1] then 
				self.pattern[self.current_pattern].track[i].pos[1] = 1
			end
			-- TODO emit track if something is there
			trig = self.pattern[self.current_pattern].track[i].trig[self.pattern[self.current_pattern].track[i].pos[1]][self.pattern[self.current_pattern].track[i].pos[2]]
			if trig.active and not self.pattern[self.current_pattern].track[i].muted and math.random() < get_effect(trig,"probability") then 
				-- emit 
				d:play_trig(i,trig)
			end
		end
	end
	-- print("sixteenth_note ",t) 
end

function Drummy:play_trig(i,trig)
	self.track_playing[i]=true
	local volume = get_effect(trig,"volume")
	local pitch = get_effect(trig,"pitch")
	local pan = get_effect(trig,"pan")
	local lpf = get_effect(trig,"lpf")
	local resonance = get_effect(trig,"resonance")
	local hpf = get_effect(trig,"hpf")
	local sample_start = get_effect(trig,"sample_start")
	local sample_length = get_effect(trig,"sample_length")
	engine.play(i,volume,pitch,rate,pan,lpf,resonance,hpf,sample_start,sample_length)
end

-- returns the visualization of the matrix
function Drummy:get_grid()
	local current_pos = self.pattern[self.current_pattern].track[self.track_current].pos
	local trig_selected = nil  
	if self.selected_trig ~= nil then 
		trig_selected = self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]]		
	end

	-- clear visual
	for row=1,8 do 
		for col=1,16 do 
			self.visual[row][col]=0
		end
	end

	-- show graphic, hijacks everything!
	if self.show_graphic[2] > 0 then 
		-- d.show_graphic={"lfo",3}
		pixels = graphic_pixels.pixels(self.show_graphic[1])
		for _,p in ipairs(pixels) do 
			self.visual[p[1]][p[2]]=p[3]
		end
		do return self.visual end
	end

	-- draw bar gradient / scale
	if self.effect_id_selected > 0 then 
		self.visual[6][self.effect_id_selected+1]=15
		for i=0,14 do 
			self.visual[5][i+2]=i
		end
		-- if trig is selected, then show the current value
		local e = self.effect_last[effect_order[self.effect_id_selected]]
		if trig_selected ~= nil then 
			e = trig_selected.effect[effect_order[self.effect_id_selected]]
		end
		local value = e.value
		if value[2] == nil then 
			self.visual[5][value[1]+1]=15
		else
			for j=value[1],value[2] do 
				self.visual[5][j+1]=15
			end
		end
		-- show the lfo
		if e.lfo > 0 then 
			self.visual[5][1] = 15 -- TODO set to the level of the lfo
		end		
	else
		-- show beats along the track
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
			if self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected then 
				self.visual[row][col] = 14 
			elseif self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active then 
				self.visual[row][col] = 3 
			end
		end
	end	

	-- show the effects
	-- if trig selected, illuminate the status of the effects
	-- if no trig, show the last effects set
	for i,k in ipairs(effect_order) do 
		local e = self.effect_last[effect_order[i]]
		if trig_selected ~= nil then 
			e = trig_selected.effect[effect_order[i]]
		end
		self.visual[6][i+1] = e.value[1]
		if e.value[2] ~= nil then 
			self.visual[6][i+1] = self.visual[6][i+1] + self.blink*(e.value[2]-e.value[1])
		end
		if i==self.effect_id_selected then 
			self.visual[6][i+1] = self.visual[6][i+1] * self.blink 
		end
	end

	-- illuminate currently playing trig on currently selected track
	if self.is_playing and self.pattern[self.current_pattern].track[self.track_current].pos[2] > 0 then 
		self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]] = self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]]  + 7
		if self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]] > 15 then 
			self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]] = 15 
		end
	end

	-- illuminate non-muted tracks, show if they are playing, blink if selected
	for i,track in ipairs(self.pattern[self.current_pattern].track) do 
		if not track.muted then 
			self.visual[8][i+1] = 5
			if self.track_playing[i] and self.is_playing then 
				self.visual[8][i+1] = 14
			end
		else
			self.visual[8][i+1] = 1
		end
		if i==self.track_current then 
			self.visual[8][i+1] = self.visual[8][i+1] *self.blink 
		end
	end

	-- illuminate patterns (active and not active)
	for i=1,9 do 
		if self.current_pattern == i then 
			self.visual[8][i+7] = 15 
		elseif self.pattern[i].trigs_active > 0 then 
			self.visual[8][i+7] = 4
		end
	end

	-- illuminate markov probability for next pattern
	for i=1,9 do 
		self.visual[7][i+7] = self.pattern[self.current_pattern].next_pattern[i]*5
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

-- update the state depending on what was pressed
function Drummy:key_press(row,col,on)
	if on then 
		self.pressed_buttons[row..","..col]=true
	else
		self.pressed_buttons[row..","..col]=nil
	end

	if row == 5 and col == 1 and self.effect_id_selected>0 and on then 
		-- TODO toggle lfo setting 
	elseif row == 5 and col > 1 and self.effect_id_selected>0  then 
		self:update_effect(col-1,on)
	elseif row == 5 and self.effect_id_selected==0  then 
		self.selected_trig = nil
	elseif row == 6 and col > 1 and on then 
		self:press_effect(col-1)
	elseif row >= 1 and row <= 4 and on then 
		self:press_trig(row,col)
	elseif row==6 and col==1 then 
		self:press_rec(on)
	elseif row==7 and col==1 then 
		self:press_stop(on)
	elseif row==8 and col==1 then 
		self:press_play(on)
	elseif row==8 and col >= 2 and col <= 7 and on then 
		self:press_track(col-1)
	elseif row==7 and col >= 2 and col <= 7 and on then 
		self:press_mute(col-1)
	elseif row==8 and col >= 8 and on then 
		self:press_pattern(col-7)
	elseif row==7 and col >= 8 and on then 
		self:press_chain_pattern(col-7)
	end
end

function Drummy:press_chain_pattern(pattern_id)
	self.pattern[self.current_pattern].next_pattern[pattern_id] = self.pattern[self.current_pattern].next_pattern[pattern_id] + 1 
	if self.pattern[self.current_pattern].next_pattern[pattern_id] > 3 then 
		self.pattern[self.current_pattern].next_pattern[pattern_id] = 0 
	end
end

function Drummy:press_pattern(pattern_id)
	self.selected_trig = nil
	self.current_pattern = pattern_id
end

function Drummy:update_effect(scale_id,on)
	print("update_effect")
	-- scale_id is between 1 and 15 

	-- update buttons
	if on then 
		self.pressed_buttons_scale[scale_id] = true 
	else
		self.pressed_buttons_scale[scale_id] = nil 
		do return end
	end

	-- determine which buttons are being held
	buttons_held = {}
	for k,_ in pairs(self.pressed_buttons_scale) do
		table.insert(buttons_held,k)
	end
	table.sort(buttons_held)
	if #buttons_held < 1 then 
		print("no buttons?")
		do return end
	end
	local value = {buttons_held[1],nil}
	if #buttons_held > 1 then 
		value = {buttons_held[1],buttons_held[#buttons_held]}
	end
	print(value[1])
	print(value[2])

	if self.selected_trig ~= nil then 
		-- simple case, update selected trig 
		print("updating selected trig effect '"..effect_order[self.effect_id_selected].."' at ("..self.selected_trig[1]..","..self.selected_trig[2]..")")
		tab.print(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]])
		self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]].value = value 
	else
		-- update the cache
		print("updating cache effect")
		self.effect_last[effect_order[self.effect_id_selected]].value = value 
	end
end

function Drummy:press_effect(effect_id)
	print("press_effect "..effect_id)
	self.pressed_buttons_scale = {} -- reset scale
	if self.effect_id_selected == effect_id then 
		self.effect_id_selected = 0
		do return end 
	end
	self.effect_id_selected = effect_id
	self.show_graphic = {effect_order[effect_id],3}
end

function Drummy:press_track(track)
	self.track_current = track 
	self.selected_trig = nil
	if not self.is_playing then 
		engine.play(track,1.0,0)
	end
end

function Drummy:press_mute(track)
		self.pattern[self.current_pattern].track[track].muted = not self.pattern[self.current_pattern].track[track].muted 
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
	if row > self.pattern[self.current_pattern].track[self.track_current].pos_max[1] then 
		do return end 
	end
	if col > self.pattern[self.current_pattern].track[self.track_current].pos_max[2] then 
		do return end 
	end

	self.selected_trig = nil
	if self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected then 
		self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected = false
		self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active = false
		self.pattern[self.current_pattern].trigs_active = self.pattern[self.current_pattern].trigs_active - 1
		do return end
	end

	-- unselect all others and select current
	for r=1,4 do 
		for c=1,16 do 
			self.pattern[self.current_pattern].track[self.track_current].trig[r][c].selected = false 
		end
	end
	self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected = true
	if not self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active then
		self.pattern[self.current_pattern].trigs_active = self.pattern[self.current_pattern].trigs_active + 1
	end
	self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active = true	
	self.selected_trig = {row,col}
	-- the last effect should correspond to this trig 

	self.effect_last = {}
	for k,e in pairs(self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect) do 
		self.effect_last[k] = {value=e.value,lfo=e.lfo}
	end
end


return Drummy