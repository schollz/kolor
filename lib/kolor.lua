print(_VERSION)
print(package.cpath)
if not string.find(package.cpath,"/home/we/dust/code/kolor/lib/") then 
  package.cpath = package.cpath .. ";/home/we/dust/code/kolor/lib/?.so"
end
local json=require("cjson")
local lattice=include("kolor/lib/lattice")
--graphic_pixels=include("kolor/lib/pixels")
local graphic_pixels=include("kolor/lib/glyphs")
--json=include("kolor/lib/json")

local Kolor={}

local total_tracks=12
local effect_available={
  volume={default={8,nil},value={}},
  rate={default={12,nil},value={-2,-1.5,-1.25,-1,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1,1.25,1.5,2},lights={15,13,11,9,7,5,3,1,3,5,7,9,11,13,15}},
  pan={default={7,9},value={-7/7,-6/7,-5/7,-4/7,-3/7,-2/7,-1/7,0,1/7,2/7,3/7,4/7,5/7,6/7,7/7},lights={15,13,11,9,7,5,3,1,3,5,7,9,11,13,15}},
  lpf={default={15,nil},value={}},
  resonance={default={8,nil},value={}},
  hpf={default={1,nil},value={}},
  sample_start={default={1,nil},value={}},
  sample_end={default={15,nil},value={}},
  retrig={default={1,nil},value={}},
  probability={default={15,nil},value={}},
  lfolfo={default={1,nil},value={}},
  delay={default={1,nil},value={}},
  feedback={default={14,nil},value={}},
}

local effect_order={
  "volume",
  "rate",
  "pan",
  "lpf",
  "resonance",
  "hpf",
  "sample_start",
  "sample_end",
  "retrig",
  "probability",
  "lfolfo",
  "delay",
  "feedback",
}
local effect_name={
  "volume",
  "rate",
  "pan",
  "LPF",
  "resonance",
  "HPF",
  "strt",
  "end",
  "retrig",
  "probability",
  "LFO2",
  "dly",
  "fdbk",
}
for i=1,15 do
  effect_available.volume.value[i]=(i-1)/14
  effect_available.lpf.value[i]=40*math.pow(1.5,i)
  effect_available.resonance.value[i]=(4*i)/15
  effect_available.hpf.value[i]=40*math.pow(1.5,i)
  effect_available.sample_start.value[i]=(i-1)/16
  effect_available.sample_end.value[i]=(i)/16
  effect_available.retrig.value[i]=(i-1)
  effect_available.probability.value[i]=(i-1)/14
  effect_available.lfolfo.value[i]=i
  effect_available.delay.value[i]=(i-1)/14
  effect_available.feedback.value[i]=(i-1)/14*128
end

local function current_ms()
  cmd="date +%s%3N 2>&1"
  local handle=io.popen(cmd)
  local result=handle:read("*a")
  handle:close()
  return tonumber(result)
end

local function deepcopy(orig)
  return {table.unpack(orig)}
end

local function current_time()
  return clock.get_beat_sec()*clock.get_beats()
end

local function random_float(lower,greater)
  return lower+math.random()*(greater-lower);
end

local function average(t)
  local sum=0
  local count=0

  for k,v in pairs(t) do
    if type(v)=='number' then
      sum=sum+v
      count=count+1
    end
  end

  return (sum/count)
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

local function wrap_position(rowcol,rowcolmax)
  if rowcol[2]>rowcolmax[2] then
    rowcol[1]=rowcol[1]+1
    rowcol[2]=1
  end
  if rowcol[1]>rowcolmax[1] then
    rowcol[1]=1
  end
  return rowcol
end

local function calculate_lfo(minval,maxval,minfreq,maxfreq,lfolfofreq)
  local freq=(math.sin(current_time()*2*3.14159*lfolfofreq))*(maxfreq-minfreq)/2+(maxfreq+minfreq)/2
  return (math.sin(current_time()*2*3.14159*freq))*(maxval-minval)/2+(maxval+minval)/2
end

local function current_ms()
  os.execute("date +%s%3N")

end

local function get_effect(effect,effectname)
  -- index ranges between 0 and 15
  if effect==nil or effect[effectname]==nil then
    do return end
  end

  local minval=effect_available[effectname].value[effect[effectname].value[1]]
  local maxval=minval
  if effect[effectname].value[2]~=nil then
    maxval=effect_available[effectname].value[effect[effectname].value[2]]
  end
  local minfreq=lfo_freq(effect[effectname].lfo[1])
  local maxfreq=minfreq
  if effect[effectname].lfo[2]~=nil then
    maxfreq=lfo_freq(effect[effectname].lfo[2])
  end
  return {minval,maxval,minfreq,maxfreq}
end

--- instantiate a new kolor
function Kolor:new(args)
  -- setup sample folders
  os.execute("mkdir -p ".._path.audio.."kolor/")
  -- copy all the samples over
  for i=1,total_tracks do
    if not util.file_exists(_path.audio.."kolor/bank"..i) then
      local cmd = "cp -r ".._path.code.."kolor/samples/bank"..i.." ".._path.audio.."kolor/"
      print(cmd)
      os.execute(cmd)
    end
  end

  -- setup object
  local o=setmetatable({},{__index=Kolor})
  local args=args==nil and {} or args

  -- initiate the grid
  -- grid specific
  o.g=grid.connect()
  o.g.key=function(x,y,z)
    o:grid_key(x,y,z)
  end
  print("grid columns: "..o.g.cols)
  -- grid refreshing
  o.grid_refresh=metro.init()
  o.grid_refresh.time=0.05
  o.grid_refresh.event=function()
    o:grid_redraw()
  end

  -- setup state
  o.grid64=o.g.cols==8
  o.grid64_page_default=true
  o.is_playing=false
  o.is_recording=false
  o.pressed_trig_area=false
  o.pressed_lfo=false
  o.pressed_buttons_bar=false
  o.pressed_buttons={}
  o.pressed_buttons_scale={}
  o.choosing_division=false
  o.show_quarter_note=1-4
  o.selected_trig=nil
  o.effect_id_selected=0
  o.effect_stored={}
  for i=1,total_tracks do
    o.effect_stored[i]={}
    for k,e in pairs(effect_available) do
      o.effect_stored[i][k]={value=e.default,lfo={1,nil}}
    end
  end
  o.visual={}
  for i=1,8 do
    o.visual[i]={}
    for j=1,16 do
      o.visual[i][j]=0
    end
  end
  o.current_pattern=1
  o.track_current=1
  o.track_playing={false,false,false,false,false,false,false,false,false,false,false,false}
  o.demo_mode=false
  o.track_files_available={}
  for i=1,total_tracks do
    local filelist=list_files(_path.audio.."kolor/bank"..i,{},true)
    o.track_files_available[i]={}
    local row=1
    local col=1
    for j,f in ipairs(filelist) do
      table.insert(o.track_files_available[i],{row=row,col=col,filename=f,loaded=false})
      col=col+1
      if col>16 then
        row=row+1
        col=1
      end
      if row==5 then
        break
      end
    end
  end
  o.track_files={}
  o.choke={}
  o.muted={}
  for i=1,total_tracks do
    table.insert(o.choke,i)
    table.insert(o.muted,false)
  end
  o.pattern={}
  local default_columns=16
  if o.grid64 then
    default_columns=8
  end
  for i=1,8 do
    o.pattern[i]={}
    o.pattern[i].next_pattern_queued=i
    o.pattern[i].next_pattern={}
    for j=1,8 do
      o.pattern[i].next_pattern[j]=0
      if i==j then
        o.pattern[i].next_pattern[j]=1
      end
    end
    o.pattern[i].track={}
    for j=1,total_tracks do
      o.pattern[i].track[j]={
        pos={1,1},
        pos_max={4,default_columns},
        -- pos_max={4,16},
        trig={},
        longest_track=j==1,
        division=16,-- which clock division (1-16)
      }
      -- fill in default trigs
      for row=1,4 do
        o.pattern[i].track[j].trig[row]={}
        for col=1,16 do
          o.pattern[i].track[j].trig[row][col]={
            playing=false,
            selected=false,
            held=0,
            active=false,
            pressed=false,
            effect={},
          }
          for k,v in pairs(o.effect_stored[j]) do
            o.pattern[i].track[j].trig[row][col].effect[k]={value={v.value[1],v.value[2]},lfo={v.lfo[1],v.lfo[2]}}
          end
        end
      end
    end
  end
  o.undo_trig={} -- used for undo
  o.redo_trig={} -- used for redo


  -- lattice
  -- for keeping time of all the divisions
  o.lattice=lattice:new({
    ppqn=8
  })
  o.timers={}
  for division=1,16 do
    o.timers[division]={time_last_beat=0,time_next_beat=0}
    o.timers[division].lattice=o.lattice:new_pattern{
      action=function(t)
        o:emit_note(division)
      end,
      division=1/division
    }
  end
  o.lattice:start()

  -- TODO: LOAD USER FILE HERE BEFORE LOADING TRACK FILES
  -- if no user file, then load defaults
  for i=1,total_tracks do
    o.track_files[i]=Kolor.get_filename_and_rate(o.track_files_available[i][1].filename)
  end

  -- load the filenames into each track
  for i=1,total_tracks do
    engine.kolorsample(i,o.track_files[i].filename)
  end

  -- debouncing and blinking
  o.blink_count=0
  o.blinky={}
  for i=1,16 do
    o.blinky[i]=1 -- 1 = fast, 16 = slow
  end
  o.show_graphic={nil,0}
  o.debouncer=metro.init()
  o.debouncer.time=0.2
  o.debouncer.event=function()
    o:debounce()
  end
  o.debouncer:start()


  -- start grid
  o.grid_refresh:start()

  -- setup the parameter window
  params:add_group("KOLOR",3)
  params:add_text('save_name_d',"save as...","")
  local name_folder=_path.data.."kolor/"
  params:set_action("save_name_d",function(y)
    -- prevent banging
    local x=y
    params:set("save_name_d","")
    if x=="" then
      do return end
    end
    -- save
    o:save(name_folder..x)
    params:set("save_message_d","saved as "..x)
  end)
  print("name_folder: "..name_folder)
  params:add_file("load_name_d","load",name_folder)
  params:set_action("load_name_d",function(y)
    -- prevent banging
    local x=y
    params:set("load_name_d",name_folder)
    if #x<=#name_folder then
      do return end
    end
    -- load
    print("load_name: "..x)
    pathname,filename,ext=string.match(x,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    print("loading "..filename)
    o:load(x)
    params:set("save_message_d","loaded "..filename..".")
  end)
  params:add_text('save_message_d',">","")


  return o
end

function Kolor:show_text(text,time)
  if time==nil then
    time=4
  end
  self.show_graphic={text,time}
end

function Kolor:save(filename)
  print("saving to "..filename)
  local data=json.encode({
    pattern=self.pattern,
    effect_stored=self.effect_stored,
    track_files=self.track_files,
  })
  file=io.open(filename,"w+")
  io.output(file)
  io.write(data)
  io.close(file)
end

function Kolor:load(filename)
  print("opening "..filename)
  local f=io.open(filename,"rb")
  local content=f:read("*all")
  f:close()

  local data=json.decode(content)
  -- how kosher is this?
  for k,v in pairs(data) do
    self[k]=v
  end
  for i=1,total_tracks do
    engine.kolorsample(i,self.track_files[i].filename)
  end
end

function Kolor:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function Kolor:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  rows=#gd
  cols=#gd[1]
  for row=1,rows do
    for col=1,cols do
      if gd[row][col]~=0 then
        self.g:led(col,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function Kolor:debounce()
  self.blink_count=self.blink_count+1
  if self.blink_count>1000 then
    self.blink_count=0
  end
  for i,_ in ipairs(self.blinky) do
    if i==1 then
      self.blinky[i]=1-self.blinky[i]
    else
      if self.blink_count%i==0 then
        self.blinky[i]=0
      else
        self.blinky[i]=1
      end
    end
  end
  if self.show_graphic[2]>0 then
    self.show_graphic[2]=self.show_graphic[2]-1
  end
end

-- emit a note note is played
function Kolor:emit_note(division)
  if not self.is_playing then
    do return end
  end
  if division==4 then
    self.show_quarter_note=self.show_quarter_note+4
    if self.show_quarter_note==17 then
      self.show_quarter_note=1
    end
  end
  -- calculate the start and end of current and next
  -- beat for use with quantization
  self.timers[division].time_last_beat=current_time()
  self.timers[division].time_next_beat=current_time()+(1/division)*clock.get_beat_sec()*4

  -- check to see which tracks need to emit
  local pattern_switched=false
  for i,t in ipairs(self.pattern[self.current_pattern].track) do
    -- make sure this track is in the right division
    if t.division~=division then goto continue end
    -- if i== 1 then
    -- print(clock.get_beats())
    -- end
    self.track_playing[i]=false
    self.pattern[self.current_pattern].track[i].pos[2]=self.pattern[self.current_pattern].track[i].pos[2]+1
    if self.pattern[self.current_pattern].track[i].pos[2]>self.pattern[self.current_pattern].track[i].pos_max[2] then
      self.pattern[self.current_pattern].track[i].pos[2]=1
      self.pattern[self.current_pattern].track[i].pos[1]=self.pattern[self.current_pattern].track[i].pos[1]+1
    end
    if self.pattern[self.current_pattern].track[i].pos[1]>self.pattern[self.current_pattern].track[i].pos_max[1] then
      self.pattern[self.current_pattern].track[i].pos[1]=1
      if self.pattern[self.current_pattern].track[i].longest_track then
        -- starting over! note: longest track determines when queue next

        for j,_ in ipairs(self.pattern[self.current_pattern].track) do
          self.pattern[self.current_pattern].track[j].pos[1]=1
          self.pattern[self.current_pattern].track[j].pos[2]=1
        end
        if self.pattern[self.current_pattern].next_pattern_queued>0 then
          -- use manually cued
          local current_pattern=self.current_pattern
          self.current_pattern=self.pattern[current_pattern].next_pattern_queued
          self.pattern[current_pattern].next_pattern_queued=0
        else
          -- use markov chains here to determine next queued pattern
          local total_prob=0
          for j=1,8 do
            total_prob=total_prob+self.pattern[self.current_pattern].next_pattern[j]
          end
          if total_prob>0 then
            local r=math.random(1,total_prob)
            local r0=0
            for j=1,8 do
              r0=r0+self.pattern[self.current_pattern].next_pattern[j]
              if r<=r0 then
                self.current_pattern=j
                break
              end
            end
          end
        end
        print("switched to pattern "..self.current_pattern)
        pattern_switched=true
      end
    end
    if pattern_switched then
      break
    end
    ::continue::
  end
  -- play the new note
  for i,t in ipairs(self.pattern[self.current_pattern].track) do
    -- make sure this track is in the right division
    if t.division~=division then goto continue end

    trig=self.pattern[self.current_pattern].track[i].trig[self.pattern[self.current_pattern].track[i].pos[1]][self.pattern[self.current_pattern].track[i].pos[2]]
    if trig.active then
      if self.is_recording and self.effect_id_selected>0 and i==self.track_current then
        -- copy current selected effect to the current trig on currently selected track
        local e=self.effect_stored[i][effect_order[self.effect_id_selected]]
        self.pattern[self.current_pattern].track[i].trig[self.pattern[self.current_pattern].track[i].pos[1]][self.pattern[self.current_pattern].track[i].pos[2]].effect[effect_order[self.effect_id_selected]]={value=e.value,lfo=e.lfo}
      end
      local prob=get_effect(trig.effect,"probability")
      local lfolfo=get_effect(trig.effect,"lfolfo")
      local probability=calculate_lfo(prob[1],prob[2],prob[3],prob[4],lfolfo[1])
      if self.choke[i]>0 and not self.muted[i] and math.random()<probability then
        -- emit
        self:play_trig(i,trig.effect,self.choke[i])
      end
    end
    ::continue::
  end
end

function Kolor:play_trig(i,effect,choke,off)
  self.track_playing[i]=true
  local volume=get_effect(effect,"volume")
  if off~=nil and off then
    volume[1]=0
    volume[2]=0
  end
  local rate=get_effect(effect,"rate")
  if self.track_files[i].bpm~=nil then
    rate[1]=rate[1]*(clock.get_tempo()/self.track_files[i].bpm)
    rate[2]=rate[2]*(clock.get_tempo()/self.track_files[i].bpm)
  end
  local pan=get_effect(effect,"pan")
  local lpf=get_effect(effect,"lpf")
  local resonance=get_effect(effect,"resonance")
  local hpf=get_effect(effect,"hpf")
  local sample_start=get_effect(effect,"sample_start")
  local sample_end=get_effect(effect,"sample_end")
  local retrig=get_effect(effect,"retrig")
  local delay=get_effect(effect,"delay")
  local feedback=get_effect(effect,"feedback")
  local lfolfo=get_effect(effect,"lfolfo")
  lfolfo[1]=lfo_freq(lfolfo[1]) -- lfo's lfo
  -- if rate[1] < 0 then
  -- sample_start[1] = 1 - sample_start[1]
  -- sample_start[2] = 1 - sample_start[2]
  -- end
  -- print(i,current_time(),
  -- volume[1],volume[2],volume[3],volume[4],
  -- rate[1],rate[2],rate[3],rate[4],
  -- pan[1],pan[2],pan[3],pan[4],
  -- lpf[1],lpf[2],lpf[3],lpf[4],
  -- resonance[1],resonance[2],resonance[3],resonance[4],
  -- hpf[1],hpf[2],hpf[3],hpf[4],
  -- sample_start[1],sample_start[2],sample_start[3],sample_start[4],
  -- sample_end[1],sample_end[2],sample_end[3],sample_end[4],
  -- retrig[1],
  -- lfolfo[1])
  engine.kolorplay(choke,current_time(),
    volume[1],volume[2],volume[3],volume[4],
    rate[1],rate[2],rate[3],rate[4],
    pan[1],pan[2],pan[3],pan[4],
    lpf[1],lpf[2],lpf[3],lpf[4],
    resonance[1],resonance[2],resonance[3],resonance[4],
    hpf[1],hpf[2],hpf[3],hpf[4],
    sample_start[1],sample_start[2],sample_start[3],sample_start[4],
    sample_end[1],sample_end[2],sample_end[3],sample_end[4],
    retrig[1],retrig[2],retrig[3],retrig[4],
    delay[1],delay[2],delay[3],delay[4],
    feedback[1],feedback[2],feedback[3],feedback[4],
  lfolfo[1],i,clock.get_beat_sec())
end

-- returns the visualization of the matrix
function Kolor:get_visual()
  local current_pos=self.pattern[self.current_pattern].track[self.track_current].pos
  local trig_selected=nil
  if self.selected_trig~=nil then
    trig_selected=self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]]
  end

  -- clear visual
  for row=1,8 do
    for col=1,16 do
      self.visual[row][col]=0
    end
  end

  -- draw bar gradient / scale / lfo scale
  if self.effect_id_selected>0 then
    -- if trig is selected, then show the current value
    e=self.effect_stored[self.track_current][effect_order[self.effect_id_selected]]
    if trig_selected~=nil then
      e=trig_selected.effect[effect_order[self.effect_id_selected]]
    end
    if self.pressed_lfo then
      -- draw lfo scale
      self.visual[5][1]=15*self.blinky[1]
      -- if e.lfo[1] > 1 and e.lfo[2] == nil then
      -- self.visual[5][1] = 7*self.blinky[e.lfo[1]]
      -- elseif e.lfo[1] > 1 and e.lfo[2] ~= nil then
      -- self.visual[5][1] = 7 + 7*self.blinky[e.lfo[1]]
      -- end
      for i=1,15 do
        self.visual[5][i+1]=i
        if (i==e.lfo[1] and e.lfo[2]==nil) or (e.lfo[2]~=nil and i>=e.lfo[1] and i<=e.lfo[2]) then
          self.visual[5][i+1]=15
          if i>1 then
            self.visual[5][i+1]=self.visual[5][i+1]*self.blinky[2]
          end
        end
      end
    else
      -- draw effect scale
      self.visual[6][self.effect_id_selected+1]=15
      for i=1,15 do
        if effect_available[effect_order[self.effect_id_selected]].lights~=nil then
          self.visual[5][i+1]=effect_available[effect_order[self.effect_id_selected]].lights[i]
        else
          self.visual[5][i+1]=i
        end
      end
      local value=e.value
      if value[2]==nil then
        self.visual[5][value[1]+1]=value[1]*self.blinky[1]
      else
        for j=value[1],value[2] do
          self.visual[5][j+1]=j*self.blinky[1]
        end
      end
      -- show the lfo
      if e.lfo[1]>1 or e.lfo[2]~=nil then
        self.visual[5][1]=e.lfo[1]
        if e.lfo[2]~=nil then
          self.visual[5][1]=self.visual[5][1]+(e.lfo[2]-e.lfo[1])*self.blinky[4]
        end
      end
    end
  else
    -- show beats along the track
    for i=1,16 do
      if self.visual[5][i]==0 then
        if (i-1)%4==0 then
          self.visual[5][i]=10
          -- show main beat
          if self.show_quarter_note==i and self.is_playing then
            self.visual[5][i]=15
            self.visual[5][i+1]=15
            self.visual[5][i+2]=15
            self.visual[5][i+3]=15
          end
          -- elseif (i-1)%4==2 then
          --   self.visual[5][i]=4
        else
          self.visual[5][i]=2
        end
      end
    end
  end

  -- show graphic, hijacks everything!
  if self.show_graphic[2]>0 then
    -- d.show_graphic={"lfo",3}
    for row=1,5 do
      for col=1,16 do
        self.visual[row][col]=2
      end
    end
    pixels=graphic_pixels.pixels(self.show_graphic[1])
    if pixels~=nil then
      for _,p in ipairs(pixels) do
        self.visual[p[1]][p[2]]=12
      end
    end
  elseif self.demo_mode then
    -- show demo demo files instead of triggers
    for _,d in ipairs(self.track_files_available[self.track_current]) do
      self.visual[d.row][d.col]=4
      if d.loaded then
        self.visual[d.row][d.col]=14
      end
    end
    self.visual[8][16]=15*self.blinky[1]
  elseif self.pressed_buttons_bar then
    -- illuminate the available area for trigs
    for row=1,self.pattern[self.current_pattern].track[self.track_current].pos_max[1] do
      for col=1,self.pattern[self.current_pattern].track[self.track_current].pos_max[2] do
        self.visual[row][col]=14
      end
    end
  else
    -- illuminate active/selected trigs
    for row=1,4 do
      for col=1,16 do
        if row<=self.pattern[self.current_pattern].track[self.track_current].pos_max[1] and col<=self.pattern[self.current_pattern].track[self.track_current].pos_max[2] then
          self.visual[row][col]=2
          if self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active then
            -- determine the current effect and display the effect it
            if self.effect_id_selected>0 and self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[effect_order[self.effect_id_selected]]~=nil then
              self.visual[row][col]=self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[effect_order[self.effect_id_selected]].value[1]
              if self.visual[row][col]<5 then
                self.visual[row][col]=5
              end
            else
              self.visual[row][col]=7
            end
            if self.selected_trig~=nil and row==self.selected_trig[1] and col==self.selected_trig[2] then
              self.visual[row][col]=self.visual[row][col]*self.blinky[1]
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
    local e=self.effect_stored[self.track_current][effect_order[i]]
    if trig_selected~=nil then
      e=trig_selected.effect[effect_order[i]]
    end
    self.visual[6][i+1]=e.value[1]
    if i==self.effect_id_selected then
      self.visual[6][i+1]=self.visual[6][i+1]*self.blinky[4]
    end
  end
  if trig_selected~=nil then
    self.visual[6][16]=14 -- copy ability
  end
  -- show transfer button if effect selected
  if self.effect_id_selected>0 then
    self.visual[6][15]=14
  end

  -- show division
  self.visual[7][16]=self.pattern[self.current_pattern].track[self.track_current].division-1
  if self.choosing_division then
    self.visual[7][16]=self.blinky[2]*self.visual[7][16]
    -- show scale bar for division
    for i=1,16 do
      self.visual[5][i]=i-1
      if i==self.pattern[self.current_pattern].track[self.track_current].division then
        self.visual[5][i]=15*self.blinky[2]
      end
    end
  end

  -- -- undo/redo
  -- if #self.undo_trig > 0 then
  -- self.visual[8][16] = 14
  -- end
  -- if #self.redo_trig > 0 then
  -- self.visual[7][16] = 14
  -- end

  -- illuminate currently playing trig on currently selected track
  if not self.demo_mode and self.is_playing and self.pattern[self.current_pattern].track[self.track_current].pos[2]>0 then
    self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]]=self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]]+7
    if self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]]>15 then
      self.visual[self.pattern[self.current_pattern].track[self.track_current].pos[1]][self.pattern[self.current_pattern].track[self.track_current].pos[2]]=15
    end
  end

  -- illuminate tracks
  -- or show choke groups if holding stop
  -- or show mute groups if holding play
  if self.pressed_buttons["7,1"]~=nil then
    if self.choke[self.track_current]>0 then
      local row=8
      local col=1+self.choke[self.track_current]
      if self.choke[self.track_current]>6 then
        row=7
        col=1+self.choke[self.track_current]-6
      end
      self.visual[row][col]=7
    end
  else
    for i,track in ipairs(self.pattern[self.current_pattern].track) do
      local row=8
      local col=1+i
      if i>6 then
        row=7
        col=1+i-6
      end
      local brightness=1
      if self.pressed_buttons["8,1"]~=nil then
        if self.muted[i] then
          brightness=7
        else
          brightness=0
        end
      else
        if i==self.track_current then
          brightness=4
        end
        if self.track_playing[i] and self.is_playing then
          brightness=15
        end
        self.visual[row][col]=brightness
        if i==self.track_current then
          brightness=brightness*self.blinky[6]
        end
      end
      self.visual[row][col]=brightness
    end
  end

  -- illuminate patterns (active and not active)
  for i=1,8 do
    if self.current_pattern==i then
      self.visual[8][i+7]=15
    elseif i==self.pattern[self.current_pattern].next_pattern_queued then -- show which is next
      self.visual[8][i+7]=4
    end
  end

  -- illuminate markov probability for next pattern
  for i=1,8 do
    self.visual[7][i+7]=self.pattern[self.current_pattern].next_pattern[i]*5
  end

  -- draw buttons
  if self.is_playing then
    self.visual[8][1]=15 -- play button
    self.visual[7][1]=1 -- stop button
  else
    self.visual[8][1]=1
    self.visual[7][1]=15
  end
  if self.is_recording then
    self.visual[6][1]=15 -- rec button
  else
    self.visual[6][1]=1
  end

  -- illuminate currently pressed button
  for k,_ in pairs(self.pressed_buttons) do
    row,col=k:match("(%d+),(%d+)")
    self.visual[tonumber(row)][tonumber(col)]=15
  end

  -- change up the display if for 64-grid
  if self.grid64 then
    if not self.grid64_page_default then
      -- move everything from the right side to the left
      for row,_ in ipairs(self.visual) do
        for col,_ in ipairs(self.visual[row]) do
          if col>8 then
            self.visual[row][col-8]=self.visual[row][col]
          end
        end
      end
    end
    -- remove all the columsn > 8
    for row,_ in ipairs(self.visual) do
      for i=0,7 do
        self.visual[row][16-i]=nil
      end
    end
  end

  return self.visual
end

-- update the state depending on what was pressed
function Kolor:key_press(row,col,on)
  -- print("key_press",row,col,on/
  if self.grid64 and not self.grid64_page_default then
    col=col+8
  end
  if on then
    self.pressed_buttons[row..","..col]=true
  else
    self.pressed_buttons[row..","..col]=nil
  end

  if row==5 and col==1 and self.effect_id_selected>0 and on then
    self.pressed_lfo=not self.pressed_lfo
    if self.pressed_lfo then self:show_text("LFO") end
    if not self.pressed_lfo then self:show_text(effect_name[self.effect_id_selected]) end
  elseif row==7 and (col==8 or col==16) and self.grid64 then
    if on then
      self.grid64_page_default=not self.grid64_page_default
    end
  elseif row==5 and self.choosing_division then
    if on then
      self:update_division(col)
    end
  elseif row==5 and col>1 and self.effect_id_selected>0 then
    if self.pressed_lfo then
      self:update_lfo(col-1,on)
    else
      self:update_effect(col-1,on)
    end
  elseif row==5 and self.effect_id_selected==0 then
    self.selected_trig=nil
    self.pressed_buttons_bar=on
    self:deselect()
  elseif row==6 and col>=2 and col<=14 and on then
    self:press_effect(col-1)
  elseif row==8 and col==16 and on then
    self:toggle_demo()
  elseif row==7 and col==16 and on then
    self:choose_division()
  elseif row==6 and col==15 and on then
    self:paste_effect_to_track()
  elseif row==6 and col==16 and on then
    self:copy_effect()
  elseif row>=1 and row<=4 and self.pressed_buttons_bar and on then
    self:update_posmax(row,col)
  elseif self.demo_mode and row>=1 and row<=4 and not self.pressed_buttons_bar and on then
    self:press_demo_file(row,col)
  elseif row>=1 and row<=4 and not self.pressed_buttons_bar and on then
    self:press_trig(row,col)
  elseif row==6 and col==1 and on then
    self:press_rec()
  elseif row==7 and col==1 and on then
    self:press_stop()
  elseif row==8 and col==1 and on then
    self:press_play()
  elseif (row==8 or row==7) and col>=2 and col<=7 and on then
    local tracknum=col-1
    if row==7 then
      tracknum=tracknum+6
    end
    self:press_track(tracknum)
  elseif row==8 and col>=8 and col<=15 and on then
    self:press_pattern(col-7)
  elseif row==7 and col>=8 and col<=15 and on then
    self:press_chain_pattern(col-7)
  elseif row==7 and col>=8 and col<=15 and on then
    self:press_chain_pattern(col-7)
    -- elseif row==7 and col==16 and on then
    -- self:redo()
    -- elseif row==8 and col==16 and on then
    -- self:undo()
  end
end

function Kolor:update_division(division)
  self.pattern[self.current_pattern].track[self.track_current].division=division
end

function Kolor:choose_division()
  self.choosing_division=not self.choosing_division
  if self.choosing_division then
    self:show_text("clock")
  end
end

function Kolor:copy_effect()
  if self.selected_trig~=nil then
    -- copy the effects of the current to the cache
    if self.effect_id_selected>0 then
      print("copying active effect from trig")
      -- copy only the active effect
      local e=self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]]
      self.effect_stored[self.track_current][effect_order[self.effect_id_selected]]={value=e.value,lfo=e.lfo}
    else
      print("copying all effects from trig")
      self.effect_stored[self.track_current]={}
      for k,e in pairs(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect) do
        self.effect_stored[self.track_current][k]={value=e.value,lfo=e.lfo}
      end
    end
    self:show_text("copied")
  end
end

function Kolor:paste_effect_to_track()
  if self.effect_id_selected==0 then
    print("no effect selected")
    do return end
  end
  local k=effect_order[self.effect_id_selected]
  local e=self.effect_stored[self.track_current][k]
  for row,_ in ipairs(self.pattern[self.current_pattern].track[self.track_current].trig) do
    for col,_ in ipairs(self.pattern[self.current_pattern].track[self.track_current].trig[row]) do
      self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[k]={value=e.value,lfo=e.lfo}
    end
  end
end


function Kolor:update_posmax(row,col)
  self.pattern[self.current_pattern].track[self.track_current].pos_max={row,col}
  self:determine_longest_track()
end

function Kolor:determine_longest_track()
  -- find new longest track
  longest_track=1
  longest_track_value=0
  for i,track in ipairs(self.pattern[self.current_pattern].track) do
    local is_active=i==self.track_current
    if not is_active then
      for row,_ in ipairs(track.trig) do
        for col,_ in ipairs(track.trig[row]) do
          if track.trig[row][col].active then
            is_active=true
            break
          end
        end
        if is_active then
          break
        end
      end
    end
    self.pattern[self.current_pattern].track[i].longest_track=false
    if track.pos_max[1]*track.pos_max[2]>longest_track_value and is_active then
      longest_track=i
      longest_track_value=track.pos_max[1]*track.pos_max[2]
    end
  end
  print("longesttrack "..longest_track)
  self.pattern[self.current_pattern].track[longest_track].longest_track=true
end

function Kolor:press_chain_pattern(pattern_id)
  self.pattern[self.current_pattern].next_pattern[pattern_id]=self.pattern[self.current_pattern].next_pattern[pattern_id]+1
  if self.pattern[self.current_pattern].next_pattern[pattern_id]>3 then
    self.pattern[self.current_pattern].next_pattern[pattern_id]=0
  end
end

function Kolor:press_pattern(pattern_id)
  -- check if another pattern is being pressed (for copying)
  for col=8,15 do
    if col~=pattern_id+7 then
      if self.pressed_buttons["8,"..col]==true then
        -- copy pattern
        other_id=col-7
        self:show_text("copied",5)
        t1=current_ms()
        -- self.pattern[pattern_id].track[self.track_current]=json.decode(json.encode(self.pattern[other_id].track[self.track_current]))
        -- copy entire pattern
        self.pattern[pattern_id]=json.decode(json.encode(self.pattern[other_id]))
        print("copied pattern "..other_id.." to "..pattern_id)
        do return end
      end
    end
  end
  self:deselect()
  if self.is_playing then
    self.pattern[self.current_pattern].next_pattern_queued=pattern_id
  else
    self.current_pattern=pattern_id
  end
  self:determine_longest_track()
end

function Kolor:deselect()
  if self.selected_trig~=nil then
    self.selected_trig=nil
  end
end

function Kolor:update_effect(scale_id,on)
  print("update_effect")
  -- scale_id is between 1 and 15

  -- update buttons
  if on then
    self.pressed_buttons_scale[scale_id]=true
  else
    self.pressed_buttons_scale[scale_id]=nil
    do return end
  end

  -- determine which buttons are being held
  buttons_held={}
  for k,_ in pairs(self.pressed_buttons_scale) do
    table.insert(buttons_held,k)
  end
  table.sort(buttons_held)
  if #buttons_held<1 then
    print("no buttons?")
    do return end
  end
  local value={buttons_held[1],nil}
  if #buttons_held>1 then
    value={buttons_held[1],buttons_held[#buttons_held]}
  end

  if self.selected_trig~=nil then
    -- simple case, update selected trig
    print("updating selected trig effect '"..effect_order[self.effect_id_selected].."' at ("..self.selected_trig[1]..","..self.selected_trig[2]..")")
    tab.print(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]])
    self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]].value=value
  else
    -- update the cache
    print("updating effect_store")
    self.effect_stored[self.track_current][effect_order[self.effect_id_selected]].value={value[1],value[2]}
  end
end


function Kolor:update_lfo(scale_id,on)
  print("update_lfo")
  -- scale_id is between 1 and 15

  -- update buttons
  if on then
    self.pressed_buttons_scale[scale_id]=true
  else
    self.pressed_buttons_scale[scale_id]=nil
    do return end
  end

  -- determine which buttons are being held
  buttons_held={}
  for k,_ in pairs(self.pressed_buttons_scale) do
    table.insert(buttons_held,k)
  end
  table.sort(buttons_held)
  if #buttons_held<1 then
    print("no buttons?")
    do return end
  end
  local lfo={buttons_held[1],nil}
  if #buttons_held>1 then
    lfo={buttons_held[1],buttons_held[#buttons_held]}
  end

  if self.selected_trig~=nil then
    -- simple case, update selected trig
    print("updating selected trig effect '"..effect_order[self.effect_id_selected].."' at ("..self.selected_trig[1]..","..self.selected_trig[2]..")")
    tab.print(self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]])
    self.pattern[self.current_pattern].track[self.track_current].trig[self.selected_trig[1]][self.selected_trig[2]].effect[effect_order[self.effect_id_selected]].lfo=lfo
  else
    -- update the cache
    print("updating effect_store")
    self.effect_stored[self.track_current][effect_order[self.effect_id_selected]].lfo={lfo[1],lfo[2]}
  end
end

function Kolor:press_effect(effect_id)
  print("press_effect "..effect_id)
  self.pressed_lfo=false
  self.pressed_buttons_scale={} -- reset scale
  if self.effect_id_selected==effect_id then
    self.effect_id_selected=0
    do return end
  end
  self.effect_id_selected=effect_id
  self:show_text(effect_name[effect_id])
end

function Kolor.get_filename_and_rate(filename)
  return {filename=filename,bpm=tonumber(string.match(filename,'bpm(%d*)'))}
end

function Kolor:press_demo_file(row,col)
  print("press_demo_file "..row.." "..col)
  for i,d in ipairs(self.track_files_available[self.track_current]) do
    if d.row==row and d.col==col then
      if d.loaded==false then
        self.track_files[self.track_current]=Kolor.get_filename_and_rate(d.filename)
        print("loaded track: "..json.encode(self.track_files[self.track_current]))
        engine.kolorsample(self.track_current,d.filename)
        for j,_ in ipairs(self.track_files_available[self.track_current]) do
          self.track_files_available[self.track_current][j].loaded=false
        end
        self.track_files_available[self.track_current][i].loaded=true
      else
        self:play_trig(self.track_current,self.effect_stored[self.track_current],self.choke[self.track_current])
      end
      break
    end
  end
end

function Kolor:toggle_demo()
  -- demo track!
  print("demo mode")
  self.demo_mode=not self.demo_mode
  -- determine which of the current tracks is already loaded
  if self.demo_mode then
    self:show_text("BANK")
    for i=1,total_tracks do
      for j,d in ipairs(self.track_files_available[i]) do
        -- print(i,self.track_files[i],d.filename,self.track_files[i].filename==d.filename)
        self.track_files_available[i][j].loaded=self.track_files[i].filename==d.filename
      end
    end
  end
end

function Kolor:press_track(track)
  print("press_track")
  -- WORK
  -- change choke group if holding down stop
  if self.pressed_buttons["7,1"] then
    if self.track_current==track then
      self.choke[self.track_current]=track-self.choke[self.track_current]
    else
      self.choke[self.track_current]=track
    end
    print("updating choke of track "..self.track_current.." to "..self.choke[self.track_current])
    do return end
  end
  -- change mute if holding down play
  if self.pressed_buttons["8,1"] then
    self.muted[track]=not self.muted[track]
    do return end
  end


  if not self.is_recording then
    self:deselect()
  end
  self.track_current=track
  self:play_trig(track,self.effect_stored[self.track_current],self.choke[track])
  if self.is_playing and self.is_recording then
    -- add sample to track in quantized position
    local t=current_time()
    local division=self.pattern[self.current_pattern].track[track].division
    local pos=self.pattern[self.current_pattern].track[track].pos
    local next_pos=wrap_position({pos[1],pos[2]+1},self.pattern[self.current_pattern].track[track].pos_max)
    if math.abs(t-self.timers[division].time_last_beat)>math.abs(t-self.timers[division].time_next_beat) then
      -- add to next position
      pos=next_pos
    end
    if not self.pattern[self.current_pattern].track[track].trig[pos[1]][pos[2]].active then
      -- add it
      self:press_trig(pos[1],pos[2],true)
    end
  end
  clock.run(function()
    self:determine_longest_track()
  end)
end


function Kolor:press_rec()
  print("press_rec")
  self:deselect()
  self.is_recording=not self.is_recording
end

function Kolor:press_stop()
  print("press_stop")
  self.is_playing=false
end

function Kolor:press_play()
  print("press_play")
  -- WORK
  if not self.is_playing then
    -- reset tracks
    for i,_ in ipairs(self.pattern[self.current_pattern].track) do
      self.pattern[self.current_pattern].track[i].pos={1,0}
    end
    self.is_playing=true
    self.show_quarter_note=1-4
    self.lattice:hard_sync()
  end
end


function Kolor:press_trig(row,col,noselect)
  -- print("press_trig",row,col,on)
  if row>self.pattern[self.current_pattern].track[self.track_current].pos_max[1] then
    do return end
  end
  if col>self.pattern[self.current_pattern].track[self.track_current].pos_max[2] then
    do return end
  end

  if self.selected_trig~=nil and self.selected_trig[1]==row and self.selected_trig[2]==col then
    print("deactivating")
    self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active=false
    self:deselect()
    do return end
  end

  self.selected_trig=nil
  if not self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active then
    -- reset the effects to the cached effects
    for k,e in pairs(self.effect_stored[self.track_current]) do
      self.pattern[self.current_pattern].track[self.track_current].trig[row][col].effect[k]={value=e.value,lfo=e.lfo}
    end
  end
  self.pattern[self.current_pattern].track[self.track_current].trig[row][col].active=true
  if noselect==nil or noselect==false then
    self.selected_trig={row,col}
  end
  self:determine_longest_track()
end


function Kolor:undo()
  -- insert into redo's and load undo
  if #self.undo_trig>0 then
    print("undoing")
    self:show_text("undo")
    local d=self.undo_trig[#self.undo_trig]
    table.remove(self.undo_trig,#self.undo_trig)
    table.insert(self.redo_trig,{d[1],d[2],d[3],d[4],json.encode(self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]])})
    self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]]=json.decode(d[5])
  end
end


function Kolor:add_undo(pattern_id,track_id,row,col)
  print("add_undo")
  table.insert(self.undo_trig,{pattern_id,track_id,row,col,json.encode(self.pattern[pattern_id].track[track_id].trig[row][col])})
  if #self.undo_trig>100 then
    print("removing from undo")
    table.remove(self.undo_trig,1)
  end
end

function Kolor:redo()
  -- insert into undo's
  if #self.redo_trig>0 then
    print("redoing")
    self:show_text("redo")
    local d=self.redo_trig[#self.redo_trig]
    table.remove(self.redo_trig,#self.redo_trig)
    table.insert(self.undo_trig,{d[1],d[2],d[3],d[4],json.encode(self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]])})
    self.pattern[d[1]].track[d[2]].trig[d[3]][d[4]]=json.decode(d[5])
  end
end

function Kolor:demo()
  local f=assert(io.open("/home/we/dust/code/kolor/samples/demo1.json","rb"))
  local content=f:read("*all")
  self.pattern[8]=json.decode(content)
  f:close()
  self:press_pattern(8)
end

return Kolor
