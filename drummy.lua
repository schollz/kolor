-- d

drummy = include("lib/drummy")
d = nil 
position={1,1}
press_positions={{0,0},{0,0}}

function init()
  d = drummy:new()
  
  pattern=1
  patterns = {
    {
      {},
      {},
      {},
      {1},
    },
    -- {
    --   {1,4,7,10,15},
    --   {5,11},
    --   {},
    --   {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
    -- },
    -- {
    --   {1,4,6,9,12},
    --   {5,10,13,16},
    --   {8,11},
    --   {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
    -- },
    -- {
    --   {1,4,8,9,11,15},
    --   {5,10,13},
    --   {10,12},
    --   {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
    -- },
    -- {
    --   {1,4,9,11,12,14,15},
    --   {5,8,10,13,16},
    --   {8,11},
    --   {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
    -- },
  }
  for row,p in ipairs(patterns) do 
    for i,track in ipairs(p) do
      d:press_track(i)
      for _, v in ipairs(track) do 
        d:key_press(row,v,true)
        d:key_press(row,v,false)
      end
    end
  end
  d:key_press(6,1,true)
  d:key_press(8,2,true)
  d:key_press(6,1,false)
  d:key_press(8,2,false)
  -- d:key_press(6,2,true)
  -- d:key_press(6,2,false)
  -- d:key_press(8,1,true)
  -- d:key_press(8,1,false)

  -- d:press_trig(1,1)
  -- d:press_trig(1,2)
  -- d:press_trig(2,1)
  -- d:press_trig(1,3)
  -- d:press_trig(2,3)
  -- pattern=2
  -- bd={1,4,7,10,15}
  -- sd={5,11}



  clock.run(grid_redraw_clock) -- start the grid redraw clock
end

function enc(k,d)
  if k==2 then 
    position[1] = position[1]+d 
    if position[1] > 8 then 
      position[1]=8 
    elseif position[1] < 1 then 
      position[1]=1
    end
  elseif k==3 then 
    position[2] = position[2]+d 
    if position[2] > 16 then 
      position[2]=16
    elseif position[2] < 1 then 
      position[2]=1
    end
  end
end

function key(k,z)
  if k>1 then 
    if z==1 then 
      press_positions[k-1] = {position[1],position[2]}
    end
    d:key_press(press_positions[k-1][1],press_positions[k-1][2],z==1)
  end
end

function grid_redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/30) -- refresh 
    redraw()
  end
end

function redraw()
  screen.clear()
  screen.level(0)
  screen.rect(1,1,128,64)
  screen.fill()

  local gd = d:get_grid()
  rows = #gd 
  cols = #gd[1]
  for row=1,rows do 
    for col=1,cols do 
      if gd[row][col] ~= 0 then 
        screen.level(gd[row][col])
        screen.rect(col*8-7,row*8-8+1,6,6)
        screen.fill()
      end
    end
  end
  screen.level(15)
  screen.rect(position[2]*8-7,position[1]*8-8+1,7,7)
  screen.stroke()
  -- screen.aa(0)
  -- screen.font_size(8)
  -- screen.font_face(0)
  -- screen.move(110, 8)
  -- screen.text("("..position[1]..","..position[2]..")")
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end