lattice = include("lib/lattice")
graphic_pixels = include("lib/pixels")
json = include("lib/json")
local Drummy = {}

engine.name="Drummy"

local effect_available = {
  	volume = {default={8,nil},value={}},
  	pitch = {default={12,nil},value={-2,-1.5,-1.25,-1,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1,1.25,1.5,2}},
  	pan = {default={7,9},value={-7/7,-6/7,-5/7,-4/7,-3/7,-2/7,-1/7,0,1/7,2/7,3/7,4/7,5/7,6/7,7/7}},
  	lpf = {default={15,nil},value={}},
  	resonance = {default={8,nil},value={}},
  	hpf = {default={1,nil},value={}},
  	sample_start = {default={1,nil},value={}},
  	sample_length = {default={15,nil},value={}},
  	retrig = {default={1,nil},value={}},
  	delay = {default={1,nil},value={}},
  	reverb = {default={1,nil},value={}},
  	probability = {default={15,nil},value={}},
  	lfolfo = {default={1,nil},value={}},
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
	"probability",
	"lfolfo",
}
for i=1,15 do 
	effect_available.volume.value[i]=(i-1)/14
	effect_available.lpf.value[i]=40*math.pow(1.5,i)
	effect_available.resonance.value[i]=(4*i)/15
	effect_available.hpf.value[i]=40*math.pow(1.5,i)
	effect_available.sample_start.value[i]=(i-1)/14
	effect_available.sample_length.value[i]=(i-1)/14
	effect_available.retrig.value[i]=(i-1)
	effect_available.delay.value[i]=(i-1)/14
	effect_available.reverb.value[i]=(i-1)/14
	effect_available.probability.value[i]=(i-1)/14
	effect_available.lfolfo.value[i]=i
end

local function deepcopy(orig)
	return {table.unpack(orig)}
end

local function current_time()
	return clock.get_beat_sec()*clock.get_beats()
end

local function random_float(lower, greater)
    return lower + math.random()  * (greater - lower);
end


local function lfo_freq(index)
	if index==1 then 
		do return 0 end 
	end
  return 1/((index-1)*clock.get_beat_sec()*2)
end

local function list_files(d,files,recursive)
  -- list files in a flat table
  if d=="." or d=="./" then
    d=""
  end
  if d~="" and string.sub(d,-1)~="/" then
    d=d.."/"
  end
  folders={}
  if recursive then
    local cmd="ls -ad "..d.."*/ 2>/dev/null"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      if not (string.match(s,"ls: ") or s=="../" or s=="./") then
        files=list_files(s,files,recursive)
      end
    end
  end
  do
    local cmd="ls -p "..d.." | grep -v /"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      table.insert(files,d..s)
    end
  end
  return files
end

local function get_effect(effect,effectname)
	-- index ranges between 0 and 15 
	local minval = effect_available[effectname].value[effect[effectname].value[1]]
	local maxval = minval
	if effect[effectname].value[2] ~= nil then 
		maxval = effect_available[effectname].value[effect[effectname].value[2]]
	end
	local minfreq = lfo_freq(effect[effectname].lfo[1])
	local maxfreq = minfreq
	if effect[effectname].lfo[2] ~= nil then 
		maxfreq = lfo_freq(effect[effectname].lfo[2])
	end
	return {minval, maxval, minfreq, maxfreq}
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
  o.pressed_lfo = false
  o.pressed_buttons_bar = false
  o.pressed_buttons = {}
  o.pressed_buttons_scale = {}
  o.selected_trig=nil
  o.effect_id_selected=0
  o.effect_stored = {}
  for k,e in pairs(effect_available) do
  	o.effect_stored[k] = {value=e.default,lfo={1,nil}}
  	-- if #e.value < 15 then 
  	-- 	print("UH OH "..k.." DOES NOT HAVE 15 value")
  	-- end
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
  o.demo_mode = false
  o.track_files_available = {}
  for i=1,6 do 
		local filelist = list_files("/home/we/dust/audio/samples/bank"..i,{},true)
		o.track_files_available[i] = {}
		local row = 1 
		local col = 1 
		for j,f in ipairs(filelist) do 
			print(row,col,f)
			table.insert(o.track_files_available[i], {row=row,col=col,filename=f,loaded=false})
			col = col + 1 
			if col > 16 then 
				row = row + 1 
				col = 1 
			end
			if row == 5 then 
				break
			end 
		end
  end
  o.track_files = {}
  o.pattern = {}
  for i=1,8 do 
  	o.pattern[i] = {}
  	o.pattern[i].next_pattern_queued=i
  	o.pattern[i].next_pattern={}
  	for j=1,8 do 
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
	  		-- pos_max={4,16},
	  		trig={},
	  		longest_track=j==1,
	  		filename="",
	  	}
	  	-- fill in default trigs
	  	for row=1,4 do 
  			o.pattern[i].track[j].trig[row]={}
	  		for col=1,64 do
	  			o.pattern[i].track[j].trig[row][col]={
	  				playing=false,
	  				selected=false,
	  				held=0,
	  				active=false,
	  				pressed=false,
	  				effect={},
	  			}
	  			for k,v in pairs(o.effect_stored) do 
		  			o.pattern[i].track[j].trig[row][col].effect[k]={value={v.value[1],v.value[2]},lfo={v.lfo[1],v.lfo[2]}}
	  			end
	  		end
	  	end
  	end
  end
  o.undo_trig = {} -- used for undo
  o.redo_trig = {} -- used for redo
  -- lattice 
  o.beat_started = 0
  o.beat_current = 0
  o.lattice = lattice:new({
  	ppqn=8
  })
  o.sixteenth_note_pattern = o.lattice:new_pattern{
  	action=function(t)
			o:sixteenth_note(t)
  	end,
  	division=1/16
  }
  o.bottom_beat = true
  o.thirtysecond_note_pattern = o.lattice:new_pattern{
  	action=function(t)
			o:thirtysecond_note(t)
  	end,
  	division=1/32
  }
  o.lattice:start()

  -- TODO: LOAD USER FILE HERE BEFORE LOADING TRACK FILES
  -- if no user file, then load defaults
  for i=1,6 do 
  	o.track_files[i] = o.track_files_available[i][1].filename
  end

  -- load the filenames into each track
  for i=1,6 do 
  	engine.samplefile(i,o.track_files[i])
  end

  -- debouncing and blinking
  o.blink_count = 0
  o.blinky = {}
  for i=1,16 do 
  	o.blinky[i] = 1 -- 1 = fast, 16 = slow
  end
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
	self.blink_count = self.blink_count + 1
	if self.blink_count > 1000 then 
		self.blink_count = 0
	end
	for i,_ in ipairs(self.blinky) do 
		if i==1 then 
			self.blinky[i] = 1 - self.blinky[i]
		else
			if self.blink_count % i == 0 then 
				self.blinky[i] = 0 
			else
				self.blinky[i] = 1 
			end
		end
	end
	if self.show_graphic[2] > 0 then 
		 self.show_graphic[2] = self.show_graphic[2] - 1
	end
end

function Drummy:thirtysecond_note(t)
	if self.is_playing then 
		self.bottom_beat = not self.bottom_beat
		-- print(self.bottom_beat)
	end
end

-- sixteenth note is played
function Drummy:sixteenth_note(t)
	self.beat_current = t 
	if self.is_playing then 
		-- print(t)
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
				if self.pattern[self.current_pattern].track[i].longest_track then
					-- starting over! note: longest track determines when queue next
					self.current_pattern = self.pattern[self.current_pattern].next_pattern_queued
					for j, _ in ipairs(self.pattern[self.current_pattern].track) do 
						self.pattern[self.current_pattern].track[j].pos[1] = 1
						self.pattern[self.current_pattern].track[j].pos[2] = 1
					end
					-- TODO: use markov chains here to determine next queued pattern
				end
			end
			trig = self.pattern[self.current_pattern].track[i].trig[self.pattern[self.current_pattern].track[i].pos[1]][self.pattern[self.current_pattern].track[i].pos[2]]
			local prob = get_effect(trig.effect,"probability")
			-- TODO calculate prob lfo
			if trig.active and not self.pattern[self.current_pattern].track[i].muted and math.random() < prob[1] then 
				-- emit 
				d:play_trig(i,trig.effect)
			end
		end
	end
	-- print("sixteenth_note ",t) 
end

function Drummy:play_trig(i,effect)
	self.track_playing[i]=true
	local volume = get_effect(effect,"volume")
	local pitch = get_effect(effect,"pitch")
	local pan = get_effect(effect,"pan")
	local lpf = get_effect(effect,"lpf")
	local resonance = get_effect(effect,"resonance")
	local hpf = get_effect(effect,"hpf")
	local sample_start = get_effect(effect,"sample_start")
	local sample_length = get_effect(effect,"sample_length")
	local retrig = get_effect(effect,"retrig")
	local lfolfo = get_effect(effect,"lfolfo")
	lfolfo[1] = lfo_freq(lfolfo[1]) -- lfo's lfo
	if pitch[1] < 0 then 
		sample_start[1] = 1 - sample_start[1]
		sample_start[2] = 1 - sample_start[2]
	end
	print(i,current_time(),
		volume[1],volume[2],volume[3],volume[4],
		pitch[1],
		pan[1],
		lpf[1],
		resonance[1],
		hpf[1],
		sample_start[1],
		sample_length[1],
		retrig[1],
		lfolfo[1])
	engine.play(i,current_time(),
		volume[1],volume[2],volume[3],volume[4],
		pitch[1],
		pan[1],
		lpf[1],
		resonance[1],
		hpf[1],
		sample_start[1],
		sample_length[1],
		retrig[1],
		lfolfo[1])
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
		if pixels ~= nil then 
			for _,p in ipairs(pixels) do 
				self.visual[p[1]][p[2]]=p[3]
			end
			do return self.visual end
		end
	end

	-- draw bar gradient / scale / lfo scale
	if self.effect_id_selected > 0 then 
		-- if trig is selected, then show the current value
		local e = self.effect_stored[effect_order[self.effect_id_selected]]
		if trig_selected ~= nil then 
			e = trig_selected.effect[effect_order[self.effect_id_selected]]
		end
		if self.pressed_lfo then 
			-- draw lfo scale
			self.visual[5][1] = 7
			if e.lfo[1] > 1 and e.lfo[2] == nil then 
				self.visual[5][1] = 7*self.blinky[e.lfo[1]]
			elseif e.lfo[1] > 1 and e.lfo[2] ~= nil then 
				self.visual[5][1] = 7 + 7*self.blinky[e.lfo[1]]
			end
			for i=1,15 do 
				self.visual[5][i+1]=i
				if (i==e.lfo[1] and e.lfo[2] == nil) or (e.lfo[2] ~= nil and i>=e.lfo[1] and i<=e.lfo[2]) then
					self.visual[5][i+1]=15
					if i > 1 then  
						self.visual[5][i+1] = self.visual[5][i+1] * self.blinky[i]
					end
				end
			end
		else
			-- draw efect scale
			self.visual[6][self.effect_id_selected+1]=15
			for i=1,15 do 
				self.visual[5][i+1]=i
			end
			local value = e.value
			if value[2] == nil then 
				self.visual[5][value[1]+1]=value[1]*self.blinky[1]
			else
				for j=value[1],value[2] do 
					self.visual[5][j+1]=j*self.blinky[1]
				end
			end
			-- show the lfo
			if e.lfo[1] > 1 or e.lfo[2] ~=nil then 
				self.visual[5][1] = e.lfo[1]
				if e.lfo[2] ~= nil then 
					self.visual[5][1] = self.visual[5][1] + (e.lfo[2]-e.lfo[1])*self.blinky[4]
				end
			end		
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

	if self.demo_mode then 
		-- show demo demo files instead of triggers
		for _, d in ipairs(self.track_files_available[self.track_current]) do 
			self.visual[d.row][d.col] = 4 
			if d.loaded then 
				self.visual[d.row][d.col] = 14 
			end
		end
		self.visual[6][14] = 15 *self.blinky[3]
	elseif self.pressed_buttons_bar then
		-- illuminate the available area for trigs
		for row=1,self.pattern[self.current_pattern].track[self.track_current].pos_max[1] do 
			for col=1,self.pattern[self.current_pattern].track[self.track_current].pos_max[2] do
				self.visual[row][col] = 14 
			end
		end 
	else
		-- illuminate active/selected trigs
		for row=1,4 do 
			for col=1,64 do
				if row <=  self.pattern[self.current_pattern].track[self.track_current].pos_max[1] and col <= self.pattern[self.current_pattern].track[self.track_current].pos_max[2] then
					if self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active then 
						-- determine the current effect and display the effect it
						if self.effect_id_selected > 0 then 
							self.visual[row][col] = self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[effect_order[self.effect_id_selected]].value[1]
						else
							self.visual[row][col] = 3 
						end
						if self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected then 
							self.visual[row][col] = self.visual[row][col] * self.blinky[1]
						end
					end
				end
			end
		end	
	end

	-- show the effects
	-- if trig selected, illuminate the status of the effects
	-- if no trig, show the last effects set
	for i,k in ipairs(effect_order) do 
		local e = self.effect_stored[effect_order[i]]
		if trig_selected ~= nil then 
			e = trig_selected.effect[effect_order[i]]
		end
		self.visual[6][i+1] = e.value[1]
		if e.value[2] ~= nil then 
			self.visual[6][i+1] = self.visual[6][i+1] + self.blinky[4]*(e.value[2]-e.value[1])
		end
		if i==self.effect_id_selected then 
			self.visual[6][i+1] = self.visual[6][i+1] * self.blinky[4] 
		end
	end
	if trig_selected ~= nil then 
		self.visual[6][16] = 14 -- copy ability
	end

	-- undo/redo
	if #self.undo_trig > 0 then 
		self.visual[8][16] = 14
	end
	if #self.redo_trig > 0 then 
		self.visual[7][16] = 14
	end

	-- illuminate currently playing trig on currently selected track
	if not self.demo_mode and self.is_playing and self.pattern[self.current_pattern].track[self.track_current].pos[2] > 0 then 
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
			self.visual[7][i+1] = 14
		end
		if i==self.track_current then 
			self.visual[8][i+1] = self.visual[8][i+1] *self.blinky[6] 
		end
	end

	-- illuminate patterns (active and not active)
	for i=1,8 do 
		if self.current_pattern == i then 
			self.visual[8][i+7] = 15 
		elseif i==self.pattern[self.current_pattern].next_pattern_queued then -- show which is next
			self.visual[8][i+7] = 4
		end
	end

	-- illuminate markov probability for next pattern
	for i=1,8 do 
		self.visual[7][i+7] = self.pattern[self.current_pattern].next_pattern[i]*5
	end

	-- draw buttons
	if self.is_playing then 
		self.visual[8][1] = 15 -- play button
		self.visual[6][1] = 4  -- stop button
	else
		self.visual[8][1] = 4
		self.visual[6][1] = 15 
	end
	if self.is_recording then 
		self.visual[7][1] = 15 -- rec button
	else
		self.visual[7][1] = 4
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
	-- print("key_press",row,col,on)
	if on then 
		self.pressed_buttons[row..","..col]=true
	else
		self.pressed_buttons[row..","..col]=nil
	end

	if row == 5 and col == 1 and self.effect_id_selected>0 and on then 
		self.pressed_lfo = not self.pressed_lfo
		if self.pressed_lfo then self.show_graphic = {"lfo",2} end
	elseif row == 5 and col > 1 and self.effect_id_selected>0  then 
		if self.pressed_lfo then 
			self:update_lfo(col-1,on)
		else
			self:update_effect(col-1,on)
		end
	elseif row == 5 and self.effect_id_selected==0  then 
		self.selected_trig = nil
		self.pressed_buttons_bar = on 
	elseif row == 6 and col >= 2 and col <= 13 and on then 
		self:press_effect(col-1)
	elseif row == 6 and col == 16 and on then 
		self:copy_effect()
	elseif row == 6 and col == 15 and on then 
		self:paste_effect_to_track()
	elseif row == 6 and col == 14 and on then 
		self:toggle_demo()
	elseif row >= 1 and row <= 4 and self.pressed_buttons_bar and on then 
		self:update_posmax(row,col)
	elseif self.demo_mode and row >= 1 and row <= 4 and not self.pressed_buttons_bar and on then 
		self:press_demo_file(row,col)
	elseif row >= 1 and row <= 4 and not self.pressed_buttons_bar and on then 
		self:press_trig(row,col)
	elseif row==7 and col==1 then 
		self:press_rec(on)
	elseif row==6 and col==1 then 
		self:press_stop(on)
	elseif row==8 and col==1 then 
		self:press_play(on)
	elseif row==8 and col >= 2 and col <= 7 and on then 
		self:press_track(col-1)
	elseif row==7 and col >= 2 and col <= 7 and on then 
		self:press_mute(col-1)
	elseif row==8 and col >= 8 and col <= 15 and on then 
		self:press_pattern(col-7)
	elseif row==7 and col >= 8 and col <= 15 and on then 
		self:press_chain_pattern(col-7)
	elseif row==7 and col >= 8 and col <= 15 and on then 
		self:press_chain_pattern(col-7)
	elseif row==7 and col==16 and on then 
		self:redo()
	elseif row==8 and col==16 and on then 
		self:undo()
	end
end


function Drummy:update_lfo(scale_id,on)
	print("update_lfo")
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
	local lfo = {buttons_held[1],nil}
	if #buttons_held > 1 then 
		lfo = {buttons_held[1],buttons_held[#buttons_held]}
	end

	if self.selected_trig ~= nil then 
		-- simple case, update selected trig 
		print("updating selected trig effect '"..effect_order[self.effect_id_selected].."' at ("..self.selected_trig[1]..","..self.selected_trig[2]..")")
		tab.print(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]])
		self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]].lfo = lfo 
	else
		-- update the cache
		print("updating effect_store")
		self.effect_stored[effect_order[self.effect_id_selected]].lfo = lfo
	end
end

function Drummy:copy_effect()
	if self.selected_trig ~= nil then 
				-- copy the effects of the current to the cache
		self.effect_stored = {}
		for k,e in pairs(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect) do 
			self.effect_stored[k] = {value=e.value,lfo=e.lfo}
		end
		self.show_graphic = {"copied",3}
	end
end

function Drummy:paste_effect_to_track()
	-- self.show_graphic = {"pasted",3}
	for row, _ in ipairs(self.pattern[self.current_pattern].track[self.track_current].trig) do 
		for col, _ in ipairs(self.pattern[self.current_pattern].track[self.track_current].trig[row]) do 
			for k,e in pairs(self.effect_stored) do 
				self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[k] = {value=e.value,lfo=e.lfo}
			end
		end
	end
end


function Drummy:update_posmax(row,col)
	self.pattern[self.current_pattern].track[self.track_current].pos_max = {row,col}
	-- find new longest track 
	longest_track = 1 
	longest_track_value = 0
	for i,track in ipairs(self.pattern[self.current_pattern].track) do 
		self.pattern[self.current_pattern].track[i].longest_track = false
		if track.pos_max[1]*track.pos_max[2] > longest_track_value then 
			longest_track = i 
			longest_track_value = track.pos_max[1]*track.pos_max[2] 
		end
	end
	print("longesttrack "..longest_track)
	self.pattern[self.current_pattern].track[longest_track].longest_track = true
end

function Drummy:press_chain_pattern(pattern_id)
	self.pattern[self.current_pattern].next_pattern[pattern_id] = self.pattern[self.current_pattern].next_pattern[pattern_id] + 1 
	if self.pattern[self.current_pattern].next_pattern[pattern_id] > 3 then 
		self.pattern[self.current_pattern].next_pattern[pattern_id] = 0 
	end
end

function Drummy:press_pattern(pattern_id)
	self:deselect()
	if self.is_playing then 
		self.pattern[self.current_pattern].next_pattern_queued = pattern_id
	else
		self.current_pattern = pattern_id
	end
end

function Drummy:deselect()
	if self.selected_trig ~= nil then 
		self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].selected = false
		self.selected_trig = nil
	end
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

	if self.selected_trig ~= nil then 
		-- simple case, update selected trig 
		print("updating selected trig effect '"..effect_order[self.effect_id_selected].."' at ("..self.selected_trig[1]..","..self.selected_trig[2]..")")
		tab.print(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]])
		self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]].value = value 
	else
		-- update the cache
		print("updating effect_store")
		self.effect_stored[effect_order[self.effect_id_selected]].value = value
	end
end

function Drummy:press_effect(effect_id)
	print("press_effect "..effect_id)
	self.pressed_lfo = false
	self.pressed_buttons_scale = {} -- reset scale
	if self.effect_id_selected == effect_id then 
		self.effect_id_selected = 0
		do return end 
	end
	self.effect_id_selected = effect_id
	self.show_graphic = {effect_order[effect_id],2}
end

function Drummy:press_demo_file(row,col)
	print("press_demo_file "..row.." "..col)
	for i, d in ipairs(self.track_files_available[self.track_current]) do 
		if d.row == row and d.col == col then 
			if d.loaded == false then 
				print("loaded "..d.filename)
				engine.samplefile(self.track_current,d.filename)
				for j, _ in ipairs(self.track_files_available[self.track_current]) do 
					self.track_files_available[self.track_current][j].loaded = false 
				end
				self.track_files_available[self.track_current][i].loaded = true
			else
				self:play_trig(self.track_current,self.effect_stored)
			end
			break
		end
	end
end

function Drummy:toggle_demo()
	-- demo track!
	print("demo mode")
	self.demo_mode = not self.demo_mode
	-- determine which of the current tracks is already loaded
	if self.demo_mode then 
		for i=1,6 do 
			for j,d in ipairs(self.track_files_available[i]) do 
				print(i,self.track_files[i],d.filename,self.track_files[i] == d.filename)
				self.track_files_available[i][j].loaded = self.track_files[i] == d.filename
			end
		end
	end
end

function Drummy:press_track(track)
	print("press_track")
	self:deselect()
	self.track_current = track 
	self.selected_trig = nil
	if not self.is_playing then 
		self:play_trig(track,self.effect_stored)
	end
end

function Drummy:press_mute(track)
		self.pattern[self.current_pattern].track[track].muted = not self.pattern[self.current_pattern].track[track].muted 
end

function Drummy:press_rec(on)

end

function Drummy:press_stop(on)
	print("press_stop")
	if self.is_playing then 
		self.is_playing = false 
	end
end

function Drummy:press_play(on)
	print("press_play")
	if not self.is_playing then 
		self.is_playing = true
		self.bottom_beat = false -- initialize state
		self.beat_started = self.beat_current
		-- reset tracks
		for i,_ in ipairs(self.pattern[self.current_pattern].track) do
			self.pattern[self.current_pattern].track[i].pos = {1,0}
		end
	end
end


function Drummy:press_trig(row,col)
	-- print("press_trig",row,col,on)
	if row > self.pattern[self.current_pattern].track[self.track_current].pos_max[1] then 
		do return end 
	end
	if col > self.pattern[self.current_pattern].track[self.track_current].pos_max[2] then 
		do return end 
	end

	if self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected  then
		print("deselecting")
		self.selected_trig = nil
		self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected = false
		self:add_undo(self.current_pattern,self.track_current,row,col)
		self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active = false
		do return end
	end

	self.selected_trig = nil
	-- unselect all others and select current
	for r=1,4 do 
		for c=1,16 do 
			self.pattern[self.current_pattern].track[self.track_current].trig[r][c].selected = false 
		end
	end
	self:add_undo(self.current_pattern,self.track_current,row,col)
	self.pattern[self.current_pattern].track[self.track_current].trig[row][col].selected = true
	if not self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active then
		-- reset the effects to the cached effects
		for k,e in pairs(self.effect_stored) do 
			self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[k] = {value=e.value,lfo=e.lfo} 
		end
	end
	self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active = true	
	self.selected_trig = {row,col}
end


function Drummy:undo()
	-- insert into redo's and load undo
	if #self.undo_trig > 0 then 
		print("undoing")
		self.show_graphic = {"undo",2}
		local d = self.undo_trig[#self.undo_trig]
		table.remove(self.undo_trig,#self.undo_trig)
		table.insert(self.redo_trig,{d[1],d[2],d[3],d[4],json.encode(self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]])})
		self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]]=json.decode(d[5])
	end
end


function Drummy:add_undo(pattern_id,track_id,row,col)
	print("add_undo")
	table.insert(self.undo_trig,{pattern_id,track_id,row,col,json.encode(self.pattern[pattern_id].track[track_id].trig[row][col])})
	if #self.undo_trig > 100 then 
		print("removing from undo")
		table.remove(self.undo_trig,1)
	end
end

function Drummy:redo()
	-- insert into undo's
	if #self.redo_trig > 0 then 
		print("redoing")
		self.show_graphic = {"redo",2}
		local d = self.redo_trig[#self.redo_trig]
		table.remove(self.redo_trig,#self.redo_trig)
		table.insert(self.undo_trig,{d[1],d[2],d[3],d[4],json.encode(self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]])})
		self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]]=json.decode(d[5])
	end
end

return Drummy