-- kolor v0.0.3
-- every light sequences samples
--
-- llllllll.co/t/kolor
--
-- this script mirrors the grid
--
--    ▼ instructions below ▼
--
-- E2 changes row
-- E3 changes column
-- K2 is left finger 
-- K3 is right finger

kolor = include("kolor/lib/kolor")

if util.file_exists("/home/we/dust/code/tmi") then
  tmi = include("tmi/lib/tmi")
  m = tmi:new()
  -- m:load(1,"/home/we/dust/code/tmi/chords2.tmi","chords")
  -- m:load(2,"/home/we/dust/code/tmi/lead2.tmi","lead")
end
d = nil 
position={1,1}
press_positions={{0,0},{0,0}}

engine.name="Kolor"


function init()
  d = kolor:new()
  -- d:demo()

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
      -- if util.file_exists("/home/we/dust/code/tmi") then
      --   if k==3 then 
      --     m:toggle_play()
      --   end
      -- end
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

  local gd = d:get_visual()
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
