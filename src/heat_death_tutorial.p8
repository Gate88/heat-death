pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--heat death
--by john williams

cartdata("gate88_heat_death")

function to_table(s,do_not_strip)
 if (not do_not_strip) s = strip_whitespace(s)
 local j,depth,key,table = 1, 0, nil, {}
 for i=1,#s do
  local ss = sub(s,i,i)
  if ss == "," and depth == 0 then
   local v = value(sub(s,j,i-1))
   if key then
    table[key]=v
   else
    add(table,v)
   end
   j = i+1
   key = nil
  elseif ss == ":" and depth == 0 then
   key = value(sub(s,j,i-1))
   j = i+1
  elseif ss == "{" then
   if (depth == 0) j = i+1
   depth += 1
  elseif ss == "}" then
   depth -= 1
  end
 end

 return table
end

function value(v)
 local l,v1 = sub(v,#v,#v), sub(v,0,#v > 1 and #v-1 or #v)
 if (l == "}") return to_table(v1)
 if (l == "|") return v1
 if (v == "true") return true
 if (v == "false") return false
 return v+0
end

wss = to_table(" |:1,\n|:1,\r|:1,\t|:1",true)

function strip_whitespace(s)
 local output,j = "", 1
 for i=1,#s do
  if wss[sub(s,i,i)] then
   output = output..sub(s,j,i-1)
   j = i+1
  end
 end
 return output..sub(s,j,#s)
end

function _init()

 menuitem(1,"go back a step",function() if (tut.step > 0) then tut.step -= 1 tut.progress = 0 end end)
 menuitem(2,"end tutorial",function() go_to_menu("c|,") end)
 menuitem(3,"change input",function() controller += 1 controller %= 3 end)
 menuitem(4,"skip to practice",function() tut.step = 13 tut.progress = 0 end)

 frame = 0
 update_frame()
 palette, fade, g, bitwise_index, n_play = to_unpack("{8,},{1,5,13,13,6,6,},{8,8,13,8,18,8,8,13,13,13,18,13,8,18,13,18,},0,0,")

 local t = to_table(stat(6))
 if not t[1] or t[1] ~= "t" or bitwise_get(0) then
  go_to_menu("r|,")
 end
 controller = 2
 if t[2] then 
  controller = t[2]
 end
 dset(0,t[2])
 dset(3,0)
 bitwise_set(true,0)

 init_game()
end

function go_to_menu(s)
 load("heat_death_menu",nil,s)
end

function init_game()
 tasks, players, p_spawns, alive_players, particles, circles, ct, levels, sc = to_unpack([[{},{},{},{},{},{},{},{1,2,3,4,5,6,7,8,9,10,},{t|:1,b|:79,l|:1,r|:120,},]])
 drew, g_over, score, lives, next_extra_life, extra_life_delta, extra_life_increment, life_gained, plus_lives, invisible_time, invisible_flash_time, pickup_scale, n_pickups, level = to_unpack(
 "0,      -30,   100,      1,            200,               50,                 100,           0,          0,            240,                   90,           1,         0,     0,"
 )

 _sc = sc

 -- 0 = pico8 controller, 1 = dual stick,  2 = keyboard
 tut = {
  progress = 0,
  step = 0,
  transitioning = false,
 }

 palette = {8}

 clear_memory()
 reset_enemy_collections()

 c_players()

 lives += #players

 state_update, state_draw = update_game, draw_game
 
end

function reset_enemy_collections()
 enemies, bullets, e_bullets, spawners, pickups, effects 
  = to_unpack("{},{},{},{},{},{},")
end

function _update60()
 tween_update(1/60)
 state_update()
end

function _draw()
 state_draw()
end

function update_slam()
 update_frame()
end

function sum(enemies,f)
 f, c = f or function(e) return e.value > 0 and 1 or 0 end, 0
 for e in all(enemies) do
  c += f(e)
 end
 return c
end

function notblank(x1,y1)
 for i=0,2 do
  for j=0,2 do
   if (pget(x1+i,y1+j) != 0) return true
  end
 end
end

function update_frame()
 frame += 1
  --2 24 30 32 48 60
 frame %= 960 --lcd
 frame30, frame48, mcolor = frame % 30, frame % 48, frame%24/4+8

end

function btnds(b,p1)
 return btn(b,p1) or (#players == 1 and btn(b,1))
end

function update_game()

 if controller == 1 then
  tut_x, tut_w, tut_y, tut_h = 66, 54, 84, 42
 elseif controller == 0 then
  tut_x, tut_w, tut_y, tut_h = 53, 69, 84, 42
 elseif controller == 2 then
  tut_x, tut_w, tut_y, tut_h = 41, 79, 84, 42
 end

 if tut.step == 7 and not tut.transitioning then
  tut.progress = players[1].power * 20
 end

 if tut.progress >= 100 and not tut.transitioning and not (tut.step == 10 and players[1].invisible > 0) then
  tut.transitioning = true
  tween(tut,{progress=0},1).onend = function()
   tut.step += 1
   tut.transitioning = false
  end
 end

 if tut.step >= 7 then
  local target, always = 5, false
  if (tut.step >= 9) target = 0 always = true
  while #p_spawns == 0 and (#pickups + #enemies + #spawners + players[1].power < target or (#enemies + #spawners < 4 and always)) do
   add_spawn(c_enemy,1)
  end
 end

 for p in all(players) do
  if (p.invincible > 0) p.invincible -= 1
 end

 update_frame()
 if drew < 2 then
 local bullets, enemies, all_players, players,       spawners = 
       bullets, enemies, players,     alive_players, spawners

 --collision
 ct = {}
 c_ct()
 e_b_collide({enemies},bullets)

 --p_spawns
 
 local psl = #p_spawns
 if psl > 0 then
  for i=1,psl do
   local p = p_spawns[i]
   p.frame += 1
   if p.frame >= 80 then
    p_spawns[i] = nil
    add(alive_players,p)
   end
  end
  remove_nil(p_spawns,psl)
 end

 if (#players > 0) score -= 0.005

 --players
 for p in all(players) do
  local pi = p.i-1
  
  p.vx, p.vy = 0, 0
  local smv = p.mv - p.slime_count*p.slime_slow
  --movement
  if (btn(⬆️,pi)) p.vy -= smv
  if (btn(⬇️,pi)) p.vy += smv
  if (btn(⬅️,pi)) p.vx -= smv
  if (btn(➡️,pi)) p.vx += smv
  
  if (p.vx != 0 or p.vy != 0) and not btn(❎,pi) then
   p.face = atan2(-p.vx,-p.vy)
  end
  
 if (p.last_shot > 0) p.last_shot -= 1
 if p.invisible > 0 then 
  p.invisible -= 1
  if (p.invisible == 30) then sfx(21,3) end
 end

  if btn(🅾️,pi) and p.charge < 3 then
   p.charge += 1/30
  elseif p.charge > 0 and p.charge < 3 then
   for i=1,3 do
    if p.charge < i then
     powers[i](p,i)
     break
    end
   end
   p.charge = 0
  elseif not btn(🅾️,pi) and p.charge > 0 then
   p.charge = 0
  end
  
 --dual stick
 local dss, dsy, dsx, pi2 = false, 0, 0, pi+4
 if (btnds(⬆️,pi2)) dsy, dss = -1, true 
 if (btnds(⬇️,pi2)) dsy, dss = 1, true
 if (btnds(⬅️,pi2)) dsx, dss = -1, true
 if (btnds(➡️,pi2)) dsx, dss = 1, true
 if (dss) p.face = atan2(dsx,dsy)

  --fire
  if (btn(❎,pi) or dss) and p.last_shot <= 0 then
   add_progress(1,5)
   if p.face == 0.25 then add_progress(2,10)
   elseif p.face == 0.75 then add_progress(3,10)
   elseif p.face == 0.5 then add_progress(4,10)
   elseif p.face == 0 then add_progress(5,10)
   else add_progress(6,10) end

   sfx(8,0)
   local n_bul = p.n_bul + flr(level / 10)/(4*#players)
   p.shoot_extra += n_bul % 1
   local nb = flr(n_bul-1)
   nb += flr(p.shoot_extra)
   p.shoot_extra %= 1
   if p.pixels > 0 then
    p.pixels -= 1
    nb += 1
   end
   for i=-nb,nb,2 do
    local sx, sy = sign(cos(p.face)), sign(sin(p.face))
    if (sx ~= 0 and sy ~= 0) sx/=2 sy/=2
    add (bullets,bullet(
     flr(p.x+2+i*sy),
     flr(p.y+2-i*sx),
     p.face,
     b_match and palette[p.i] or -1
    ))
   end
   
   p.last_shot = p.bcd
  end
  local x1, y1 = p.x, p.y
  move({p})
  screen_clamp(p)
  if (x1 != p.x or y1 != p.y) add_progress(0,0.45)
 end
 
 move(particles)
 
 local pl = #particles
 for i=1,pl do
  local p = particles[i]
  p.vx -= p.fx
  p.vy -= p.fy
  if abs(p.vx) < 0.01 and abs(p.vy) < 0.01 then
   particles[i] = nil
   set_memory(flr(p.x),flr(p.y),p.c)
  end
 end
 
 remove_nil(particles,pl)

--move enemies
 if #players > 0 then
  --update enemies
  for i=1,#enemies do
   local e = enemies[i]
   local ex, ey = e.x, e.y
   if e.chase or e.last_move <= 0 then
    local p,d = closest(e,players)

    if not p then
     e.chase = false
     p,d = get_target(e)
    else e.target = nil end

    local px, py = p.x, p.y
    if d < 12 and not e.target then
     e.chase = true
    end
    if e.chase then
     --chase
     e.vx, e.vy = 0,0
     if abs(px-ex) > 2 then
      e.vx = sgn(px-ex)*e.mv
     end
     if abs(py-ey) > 2 then
      e.vy = sgn(py-ey)*e.mv
     end
     if d > 12 then
      e.chase = false
     end
    else
     --not chase
     if abs(px-ex) > abs(py-ey) then
      e.vx = sgn(px-ex)*e.mv
      if coinflip() then
       e.vy = 0
      end
     else
      e.vy = sgn(py-ey)*e.mv
      if coinflip() then
       e.vx = 0
      end
     end
     e.last_move = 10+rnd(e.mcd)
     --if (not e.target) e.mv += e.vg
    end
   else
    e.last_move -= 1
   end
   move({e})
   screen_clamp(e)
  end
  local mid_h, mid_v = 
   sc.l+(sc.r - sc.l-3)/2, sc.t+(sc.b - sc.t-3)/2

  move(bullets)
  move(e_bullets)

  for p in all(pickups) do
   screen_clamp(p)
  end
 end

 for e in all(effects) do
  if (e.update) e.update(e)
 end
 drew += 1
 end
end

powers = {
--p_vacuum
function(p, cost)
 if p.power >= cost and tut.step >= 8 then
  add_progress(8,50)
  sfx(18,3)
  local c, x, y, vi,
        np, die, off, done = 
        palette[p.i], flr(p.x-8), flr(p.y-8), 0,
        0, 120, rndint(440), false
  local v = {
   ni = 0,
   draw = function(v)
    color(c)
    if (not done) rect(x,y,x+21,y+21)
    local ns = tostr(np)
    if (die % 15 < 7) print(ns,x+11-#ns*2,y+8)
   end,
   update = function(v)
    if not done then
     local ni = v.ni
     for i=vi,flr(min(440,ni)) do
      --multiplier must be relatively prime to cycle
      local n = (i*29+off)%441
      local x1,y1 = x+n%21, y+flr(n/21)
      if get_memory(x1,y1) ~= 0 then
       np+=1
       add_progress(9,0.75)
       if (p.pixels < 500) p.pixels += .25
      end
      set_memory(x1,y1)
     end
     vi = flr(ni+1)
     if ni >= 440 then
      done = true
      sfx(19,3)
     end
    else
     die -= 1
     if (die <= 0) del(effects, v)
    end
   end
  }
  add(effects, v)
  tween(v,{ni = 441},8,"quad_in_out")
  p.power -= cost
 end
end,

--p_cloak
function(p, cost)
 if p.power >= cost and tut.step >= 10 then
  add_progress(10,50)
  sfx(20,3)
  p.invisible = invisible_time
  p.power -= cost
 end
end,

--p_teleport
function(p, cost, trigger)
 local sw, sh , scl, sct = sc.r - sc.l, sc.b - sc.t, sc.l, sc.t
 if trigger and #p.target > 0 then
  add_progress(12,50)
  sfx(23,3)
  local target = p.target[#p.target]
  local l = {x = target.mx*sw/target.sw+scl, y = target.my*sh/target.sh+sct, x2 = p.x, y2 = p.y}
  screen_clamp(l,5)
  l.draw = function(l)
   line(l.x+2,l.y+2,l.x2+2,l.y2+2,palette[p.i])
  end
  p.x, p.y = l.x, l.y
  p.invincible += 90
  add(effects,l)
  tween(l,{x2 = l.x, y2 = l.y},0.5,"quad_in").onend = function()
   del(effects,l)
  end
  del(p.target,target)
 elseif p.power >= cost and #p.target < 5 and tut.step >= 11 then
  add_progress(11,100)
  sfx(22,3)
  add(p.target,{mx=p.x-scl,sw = sw,my=p.y-sct,sh = sh})
  p.power -= cost
 end
end,

}

function draw_game()
 local scl, scr, sct, scb, all_players, players  = 
   sc.l-1, sc.r, sc.t-1, sc.b, players, alive_players
 
 drew = 0
 cls(0)
 
 draw_l(enemies)
 draw_p(e_bullets)
 --player enemy collision

 local screen_smush,               chain,         died = 
       scr-scl < 5 or scb-sct < 5, (frame48 < 8), false
 for p in all(players) do
  local x1,y1 = flr(p.x+1), flr(p.y+1)
  if screen_smush or p.invincible <= 0 and notblank(x1,y1) then
   if not screen_smush and #p.target>0 then
    powers[3](p,0,true)
   else
    local c = palette[p.i]
    sfx(1,1)
    explode(p,6,c,c)
    del(players,p)
    enemies = {}
    spawners = {}
    died = true
   end
  end
  if not died then
   for u in all(pickups) do
    if u.pi == p.i then
     local h = abs(flr(u.x)-x1)
     if h <= 3 then
      local v = abs(flr(u.y)-y1)
      if v <= 3 and (h ~= 3 or v ~= 3) then
       local pickup_points, t = 1, 45
       if chain then
        p.chain = p.chain+1
        pickup_points = min(5,p.chain+1)
        add(effects,{
          draw = function(e)
           print(pickup_points,u.x,u.y-1,mcolor)
           t -= 1
           if (t <= 0) del(effects,e)
          end
         })
       else p.chain = 0 end
       add_score(pickup_points,true)
       add_power(1)
       sfx(8+pickup_points,1)
       del(pickups,u)
      end
     end
    end
   end
  end
 end

 draw_memory()

 for p in all(players) do
  local x, y, sl = 
   flr(p.x), flr(p.y), 0
  for i=0,4 do
   for j=0,4 do
    sl += (pget(x+i,y+j) == 3 and 1 or 0)
   end
  end
  if (sl > 20) sl = 20
  if (p.slime_count > sl) p.slime_count *= 0.985
  if (p.slime_count < sl) p.slime_count = min(sl,p.slime_count+1)
 end

 draw_p(particles)
 draw_circles(circles)
 
 draw_spawners()
 for p in all(all_players) do
  local sw, sh, scl, sct, c = sc.r - sc.l, sc.b - sc.t, sc.l, sc.t, palette[p.i]
  pal(8,c)
  pal(14,c)
  if (frame30 < 15) pal(14,0)
  for target in all(p.target) do
   local t = {x = target.mx*sw/target.sw+scl,y = target.my*sh/target.sh+sct}
   screen_clamp(t,5)
   spr(36,t.x,t.y)
  end
 end
 draw_l(pickups)
 
 if (frame30<15) pal(1,5)
 draw_l(enemies)
 for e in all(enemies) do
   if e.target and tut.step == 10 then
    line(e.x+2,e.y+2,e.target.x+2,e.target.y+2,2)
   elseif not e.target and tut.step == 10 then
    line(e.x+2,e.y+2,players[1].x+2,players[1].y+2,2)
   end
 end

 draw_p(bullets)
 draw_l(players)
 draw_p(e_bullets)

 draw_l(effects)

 --draw scren borders
 rectfill(0,0,127,sct,0)
 rectfill(0,0,scl,127)
 rectfill(scr,0,127,127)
 rectfill(0,scb,127,127)
 rect(scl,sct,scr,scb,5)

 draw_tutorial()

 --draw hud

 for p in all(all_players) do
  draw_power(122,1+(p.i-1)*31,p)
 end
 
 for p in all(p_spawns) do
  local f = p.frame < 20 and 1 or flr((p.frame-20)/60*5)*2+1
  pal(8, palette[p.i])
  sspr(g[f]+32,g[f+1],5,5,p.x,p.y)
 end
 pal()
 
 if #players+#particles+#p_spawns <= 0 then
   respawn_players(sc)
 end
end

function draw_tutorial()
 draw_progress()
 
 local step = tut.step

 if step == 7 then
  sspr(96,11,10,7,109,11)
 end

 if controller == 1 then
  sspr(0,64,64,43,1,84)
  print("p = pause",15,121,9)
  if step == 0 then
   draw_tutbox("move with",12)
   sspr(7,76,9,9,88,105)
  elseif step == 1 then
   draw_tutbox({"aim and","shoot with"},12)
   sspr(34,88,9,9,88,108)
  elseif step == 2 then
   draw_tutbox("shoot up",12)
   sspr(34,88,9,9,88,105)
  elseif step == 3 then
   draw_tutbox("shoot down",12)
   sspr(34,88,9,9,88,105)
  elseif step == 4 then
   draw_tutbox("shoot left",12)
   sspr(34,88,9,9,88,105)
  elseif step == 5 then
   draw_tutbox("shoot right",12)
   sspr(34,88,9,9,88,105)
  elseif step == 6 then
   draw_tutbox("shoot diagonal",12)
   sspr(34,88,9,9,88,105)
  elseif step == 7 then
   draw_tutbox({"shoot enemies","to create gems","","collect gems to","gain power"})
  elseif step == 8 then
   draw_tutbox({"hold","🅾️ ","and release on","1 power", "to use defrag",},0,{7,12,7,8})
  elseif step == 9 then
   draw_tutbox({"use defrag to","collect debris","and gain","extra shots"})
  elseif step == 10 then
   draw_tutbox({"hold","🅾️ ","and release on","2", "to use cloak",},0,{7,12,7,8})
  elseif step == 11 then
   draw_tutbox({"hold","🅾️ ","and release on","3 power", "to place","remote backup",},0,{7,12,7,8})
  elseif step == 12 then
   draw_tutbox({"touch enemy when","remote backup","on field to","teleport"})
  else
   draw_tutbox({"finished!","","you can","practice or","pause and","end tutorial"})
  end 
 elseif controller == 0 then
  print("p =",3,119,9)
  print("    pause",3,116,9)
  print("    menu",5,122,9)
  sspr(0,112,49,16,1,97)
  if step == 0 then
   draw_tutbox({"move with","","","you aim opposite","your movement"})
   sspr(3,116,9,9,81,98)
  elseif step == 1 then
   draw_tutbox({"hold to shoot","❎ "},0,{7,8})
  elseif step == 2 then
   draw_tutbox({"shoot up","","aim by moving","down then hold","❎ "},0,{7,7,7,7,8})
  elseif step == 3 then
   draw_tutbox({"shoot down","","aim by moving","up then hold","❎ "},0,{7,7,7,7,8})
  elseif step == 4 then
   draw_tutbox({"shoot left","","aim by moving","right then hold","❎ "},0,{7,7,7,7,8})
  elseif step == 5 then
   draw_tutbox({"shoot right","","aim by moving","left then hold","❎ "},0,{7,7,7,7,8})
  elseif step == 6 then
   draw_tutbox({"shoot diagonal","","aim by moving","then hold","❎ "},0,{7,7,7,7,8})
  elseif step == 7 then
   draw_tutbox({"shoot enemies","to create gems","","collect gems to","gain power"})
  elseif step == 8 then
   draw_tutbox({"hold","🅾️ ","and release on","1 power", "to use defrag",},0,{7,12,7,8})
  elseif step == 9 then
   draw_tutbox({"use defrag to","collect debris","and gain","extra shots"})
  elseif step == 10 then
   draw_tutbox({"hold","🅾️ ","and release on","2 power", "to use cloak",},0,{7,12,7,8})
  elseif step == 11 then
   draw_tutbox({"hold","🅾️ ","and release on","3 power", "to place","remote backup",},0,{7,12,7,8})
  elseif step == 12 then
   draw_tutbox({"touch enemy when","remote backup","on field to","teleport"})
  else
   draw_tutbox({"finished!","","you can","practice or","pause and","end tutorial"})
  end 
 elseif controller == 2 then
  print("z c",1,104,12)
  print(" x",1,104,8)
  print("      ⬆️",1,98,11)
  print("    ⬅️⬇️➡️",1,104,11)
  print("p =",3,119,9)
  print("    pause",3,116,9)
  print("    menu",5,122,9)
  if step == 0 then
   draw_tutbox({"move with","⬆️ ","⬅️⬇️➡️   ","you aim opposite","your movement"},0,{7,11,11})
  elseif step == 1 then
   draw_tutbox({"hold to shoot","[x]"},0,{7,8})
  elseif step == 2 then
   draw_tutbox({"shoot up","","aim by moving","down then hold","[x]"},0,{7,7,7,7,8})
  elseif step == 3 then
   draw_tutbox({"shoot down","","aim by moving","up then hold","[x]"},0,{7,7,7,7,8})
  elseif step == 4 then
   draw_tutbox({"shoot left","","aim by moving","right then hold","[x]"},0,{7,7,7,7,8})
  elseif step == 5 then
   draw_tutbox({"shoot right","","aim by moving","left then hold","[x]"},0,{7,7,7,7,8})
  elseif step == 6 then
   draw_tutbox({"shoot diagonal","","aim by moving","then hold","[x]"},0,{7,7,7,7,8})
  elseif step == 7 then
   draw_tutbox({"shoot enemies","to create gems","","collect gems to","gain power"})
  elseif step == 8 then
   draw_tutbox({"hold","[z] or [c]","and release on","1 power", "to use defrag",},0,{7,12,7,8})
  elseif step == 9 then
   draw_tutbox({"use defrag to","collect debris","and gain","extra shots"})
  elseif step == 10 then
   draw_tutbox({"hold","[z] or [c]","and release on","2 power", "to use cloak",},0,{7,12,7,8})
  elseif step == 11 then
   draw_tutbox({"hold","[z] or [c]","and release on","3 power", "to place","remote backup",},0,{7,12,7,8})
  elseif step == 12 then
   draw_tutbox({"touch enemy when","remote backup","on field to","teleport"})
  else
   draw_tutbox({"finished!","","you can","practice or","pause and","end tutorial"})
  end
 end
end

function draw_tutbox(strings,extra_h,colors)
 extra_h = extra_h or 0
 colors = colors or {}
 if type(strings) == "string" then strings = {strings} end

 local len = 0
 for s in all(strings) do
  if (#s > len) len = #s
 end

 len *= 4
 hei = #strings*6+extra_h

 local tx = tut_x+(tut_w - len)/2
 local ty = tut_y+(tut_h - hei)/2

 local dx, dy = 1,1

 rectfill(tx,ty,tx+len,ty+hei,1)

 local index = 1
 
 for s in all(strings) do
  c = colors[index] or 7
  print(s,tx+(len-#s*4)/2+dx,ty+dy,c)
  dy += 6
  index += 1
 end
end

function add_progress(s,p)
 if (tut.step == s and not tut.transitioning) tut.progress += p
end

function draw_progress()
 rectfill(0,81,120,82,1)
 local col = (tut.progress >= 100 or tut.transitioning) and 11 or 8 
 rectfill(0,81,min(120*(tut.progress/100),120),82,col)
end

function update_gover()
 if g_over >= 90 and (btnp(🅾️) or btnp(❎)) then
  if (lives < 0) score += lives * 10
  local output = (easy and "se" or "sn") .. #players .. get_mode_str() .. "|,{"
  output = output.."},"
  go_to_menu(output)
 end
 update_frame()
end

function get_mode_str()
 return "d"
end

function to_string(obj)
 if type(obj) == "number" then
  return obj;
 elseif type(obj) == "table" then
  local output = "{"
  for k,v in pairs(obj) do
   output = output..to_string(k)..":"..to_string(v)..","
  end
  return output.."}"
 else
  return obj.."|"
 end 
end

function draw_gover()
 if g_over >= 0 then
  local x,y,m = 
   1+rndint(2)*41.5,
   8+rndint(19)*6,
   "game over"
  print(m,x+1,y+1,1)
  print(m,x,y,rndint(13,8))
 end
 if g_over < 90 then 
  g_over += 1
  if (g_over == 0) sfx(16,2) sfx(17,3)
 else
  rectfill(6,59,113,68,0)
  print("press button to save score",9,62,1)
  print("press button to save score",8,61,7)
 end
end
-->8
--objs
function bullet(x,y,face,c)
 local dx, dy = sign(cos(face)), sign(sin(face))
 local v = (dx == 0 or dy == 0) and 7 or 5
 local vm1 = v-1
 local p = particle(x,y,v,dx * v,dy * v,c,"line")
 p.dx, p.dy = dx*vm1, dy*vm1
 return p
end

function bullet_at_player(x,y,v,delay,ease)
 local p,d = closest({x=x,y=y},alive_players)
 if (not p) p,d = random_point({x=x, y=y, size=2})
 if p then
  local a = atan2(p.x+2-x-rnd(1),p.y+2-y-rnd(1))
  bullet_at_angle(x,y,a,v,delay,ease)
  return a
 end
end

function bullet_at_angle(x,y,a,v,delay,ease)
 local p = particle(x,y,v,cos(a)*v,sin(a)*v,enemy_bc,1)
 if (delay or ease) then
  delay, ease = delay or 0, ease or 1
  local np = {v = p.v, vx = p.vx, vy = p.vy}
  p.v, p.vx, p.vy = 0,0,0
  tween(p,np,ease,"quad_in").delay = delay
 end
 add(e_bullets, p)
end

function particle(x,y,v,vx,vy,c,ptype)
 local t = rndint(30,1)
 return {x=x,y=y,v=v,vx=vx,vy=vy,fx=vx/t,fy=vy/t,
         c=c,ptype=ptype,size=type(ptype) == "number" and ptype+1 or 1}
end

function c_circle(x,y,r,mr,vr,c)
 return add(circles,{x=x,y=y,r=r,mr=mr,vr=vr,c=c})
end

local default_player = to_table(
[[x|:64,y|:64,vx|:0,vy|:0,mv|:0.5,last_shot|:0,bcd|:7,face|:0.25,
 size|:5,shoot_extra|:0,slime_count|:0,slime_slow|:.017,value|:1,
 power|:0,n_bul|:1,invisible|:0,invincible|:0,charge|:0,pixels|:0,chain|:0,
]])

function c_players()
 pickup_order, p_o = {}, 0
 for i=1,n_play+1 do
  pickup_order[i] = i
  add(players, merge_into({
   i = i,  --player index
   draw = draw_player,
   target = {}, --need to be here, otherwise all players share same target object
  },default_player))
 end
end

function c_pickup(x,y,pi)
 if (p_o == 0) shuffle(pickup_order)
 add(pickups, {
   x = x+rnd(4)-2,
   y = y+rnd(4)-2,
   pi = pickup_order[p_o+1],
   size = 3,
   draw = draw_pickup
  })

 p_o += 1
 p_o %= #pickup_order
end



player_reset_values = to_table("frame|:0,face|:0.25,invisible|:0,pixels|:0,chain|:0,slime_count|:0,")

function respawn_players(sc)
 for i=1,#players do
  local p = players[i]
  if not contains(alive_players,p) then
  	add(p_spawns,p)
  end
 end
 local schm, scvm = sc.l + (sc.r-sc.l)/2, sc.t + (sc.b-sc.t)/2
 for i=1,#p_spawns do
  local p = p_spawns[i]
  merge_into(p,player_reset_values)
  p.x, p.y = #p_spawns <= 1 and schm-3 or schm-6 + (i-1)%2*7,
             #p_spawns <= 2 and scvm-3 or scvm-6 + flr((i-1)/2)*7
 end
end

default_enemy = to_table([[
  size|:5,
  bd|:0,
  be|:0.4,
  chase|:false,]])
--variation, rv, vgm, health, value
enemy_variation = to_table([[
 0:{false, 0.2, 1.5, 2, 1,},
 4:{3, 0.2, 1.5, 2, 1,},
 8:{2, 0.05, 3, 2, 1,},
 10:{1, 0.1, 3, 4, 2,},]])
function c_enemy(value)
 local variation, rv, vgm, health, val = unpack(enemy_variation[lvl_type] or enemy_variation[0],5)
 value = value or val
 if (value <= 0 and level < 10) health /= 2
 local mv, a = 0.1, round(rnd(1),8)
 return merge_into({
   list = enemies,
   value = value,
   vx = mv*cos(a),
   vy = mv*sin(a), --velocity
   mv = mv, --max velocity
   vg = (rnd(0.008)+0.002)/vgm, --gain velocity on cooldown
   last_move = 20+rnd(60),
   mcd = rnd(5), --move cooldown
   collision = c_3x3,
   health = health,
   draw = draw_enemy,
   variation = variation,
   bv = 0.1+rnd(0.4), --bullet velocity
  },default_enemy)
end

function c_spawners(regular_spawn,sc)
 --brief invincible when enemies spawn
 -- for p in all(players) do
 --  p.invincible = 90
 -- end
 -- local level, spawns, scale = level, {}, level
 -- scale = scale/(scale+20)*25*(1+flr(scale/10)*0.1)*(0.9+#players*0.1)+4
 -- if regular_spawn then
 --  n_e, n_p, n_t, n_b, n_c = e_nums({8+scale*4, (scale)*0.75, 0, 0, scale > 2 and 1+scale*0.5 or 0},scale)
 -- end
 -- --create new spawners
 -- _sc = sc
 -- add_spawn(c_enemy, n_e)
 -- add_spawn(c_turret, n_t)
 -- if regular_spawn then add_spawn(c_bouncer, n_b) else add_bouncers() end
 -- add_spawn(c_chaser, n_c)

end

function add_spawn(create, n, v)
 for i=1,n do
  local e = spawn_enemy(create,nil,v)
  e.spawn_frame = 0
  add(spawners,e)
 end
end

function spawn_enemy(create,sc,value,add_to_list)
 local e, sc = create(value), sc or _sc
 e.x, e.y = spawn_coords(sc,e.size)
 if (add_to_list) add(e.list,e)
 return e
end

function spawn_coords(sc, size)
 return round(sc.l+rnd(sc.r-sc.l-size)),
   round(sc.t+rnd(sc.b-sc.t-size))
end

function explode(e,col1,col2,col3)
 if (not col3) col3 = col1
 if e.value > 0 then
  for k=1,col1 == 5 and 50 or 10 do
   local a, v = 
    rnd(1), 0.2+rnd(1)
   local xv, yv =
     v*cos(a), v*sin(a)
   add(particles,
    particle(e.x+rndint(3,1),
             e.y+rndint(3,1),
             v,
             xv,yv,
             coinflip(5) and col1 or col2,"pixel"))
   set_memory(flr(1+e.x+rnd(3)),flr(1+e.y+rnd(3)),col3)
  end
 end

 c_circle(e.x+2, e.y+2, 1, 5, 0.625, -1)
end
-->8
--update
function move(list)
 for i=1,#list do
  local b = list[i]
  b.x += b.vx
  b.y += b.vy
 end
end

function add_score(n,counts_towards_pickup,x,y)
 if (n == 0) return
 score += n
 if (counts_towards_pickup) n_pickups += n/pickup_scale
 if n_pickups >= 1 and #pickups+players[1].power < 5 and x then
  c_pickup(x,y)
  n_pickups -= 1
  --pickup_scale += 0.5
 end
 while score >= next_extra_life do
  sfx(24,3)
  lives += 1
  extra_life_delta += extra_life_increment
  next_extra_life += extra_life_delta
  life_gained = 240
  plus_lives += 1
 end
end

function add_power(pow)
 for p in all(players) do
  p.power += pow
  if (p.power > 5) p.power = 5
 end
end

function screen_clamp(p,s,bounce,scale)
 local scl, scr, sct, scb, size, shouldscale =
      sc.l, sc.r, sc.t, sc.b, s or p.size, false
 scale = scale or 1
 if p.x < scl then
  p.x = scl
  if bounce and p.vx < 0 then 
   p.vx = -p.vx
   shouldscale = true
  end
 end
 if p.y < sct then 
  p.y = sct
  if bounce and p.vy < 0 then
   p.vy = -p.vy
   shouldscale = true
  end
 end
 if p.x > scr-size then
  p.x = scr-size
  if bounce and p.vx > 0 then
   p.vx = -p.vx
   shouldscale = true
  end
 end
 if p.y > scb-size then 
  p.y = scb-size
  if bounce and p.vy > 0 then
   p.vy = -p.vy
   shouldscale = true
  end
 end
 if shouldscale then
  p.vx *= scale
  p.vy *= scale
 end
end

function is_off_screen(p)
  return p.x <= sc.l or p.y <= sc.t
   or p.x >= sc.r-p.size or p.y >= sc.b-p.size
end

-->8
--help
function round(num, snap)
  local snap = snap or 1
  return flr(num * snap + 0.5) / snap
end

function contains(tbl,v)
 for i=1,#tbl do
  if (tbl[i] == v) return true
 end
end

function distance(x1,y1,x2,y2)
 local x, y = abs(x2-x1), abs(y2-y1)
 local d = max(x,y)
 local n = min(x,y) / d
 return sqrt(n^2 + 1) * d
end

function closest(e,list)
 local min_d, obj = 32767.99
 for o in all(list) do
  if not o.invisible or o.invisible <= 0 then
   local dist = distance(e.x,e.y,
                      o.x,o.y)
   if dist < min_d then
    min_d, obj = dist, o
   end
  end
 end
 return obj,min_d
end

function random_point(e)
 local x, y = spawn_coords(sc, e.size)
 return {x=x, y=y}, distance(e.x,e.y,x,y)
end

function get_target(e)
 if e.target then
  local t = e.target
  screen_clamp(t,e.size)
  local d = distance(e.x,e.y,t.x,t.y)
  if (d > 3) return t, d
 end
 local t,d = random_point(e)
 e.target = t
 return t,d
end

function remove_nil(list,n)
 return remove(list,n,function(i) return not i end)
end

function remove(list,n,test)
 local j=0
 for i=1,n do
  if not test(list[i]) then
   j=j+1
   list[j]=list[i]
  end
 end
 
 for i=j+1,n do
  list[i]=nil
 end
end

function sign(n)
 if (n == 0) return n
 return sgn(n)
end

function rndint(max_i,min_i)
 min_i = min_i or 0
 return flr(rnd(max_i+1-min_i))+min_i
end

function coinflip(n)
 return rndint(n or 1)==0
end

function shuffle(t)
  for i = #t, 1, -1 do
    local j = flr(rnd(i)) + 1
    t[i], t[j] = t[j], t[i]
  end
end

function to_unpack(s)
 return unpack(to_table(s))
end

function unpack(y, m, i)
 i, m = i or 1, m or 0
 local g = y[i]
 if (g or i <= m) return g, unpack(y, m, i+1)
end

function merge_into(t1,t2,do_not_override)
 for k,v in pairs(t2) do if(not do_not_override or not t1[k])t1[k] = v end
 return t1
end

function bitwise_get(lowest_bit,size,index)
 size, index = size or 1, index or bitwise_index
 local op = lowest_bit > 16 and lshr or shl
 local r = op(band(dget(index),get_mask(lowest_bit,size)),abs(16-lowest_bit))
 if (size == 1) return r == 1
 return r
end

function bitwise_set(value,lowest_bit,size,index)
 size, index = size or 1, index or bitwise_index
 local v, mask = dget(index), get_mask(lowest_bit,size)
 dset(index,bor(band(v,bnot(mask)),band(shl(lshr(size == 1 and (value and 1 or 0) or value,16),lowest_bit),mask)))
end

function get_mask(lowest_bit,size)
 return shl(lshr(0xffff.ffff,32-size),lowest_bit)
end

-->8
--draw
function draw_p(list)
 local size = #list
 for i=1,size do
  local b = list[i]
  local c, x, y, ptype= 
   b.c, b.x, b.y, b.ptype
  if (c == -1) c = mcolor
  if ptype == "line" then
   line(x,y,x-b.dx,y-b.dy,c)
  elseif type(ptype) == "number" then
   rectfill(x,y,x+ptype,y+ptype,c)
  else
   pset(x,y,c)
  end
  if x < -10 or x > 137
  or y < -10 or y > 137 then
   list[i] = nil
  end
 end
 
 remove_nil(list,size)
end

function draw_circles(list)
 local size = #list
 for i=1,size do
  local c = list[i]
  local col = c.c
  if (col == -1) col = mcolor
  circfill(c.x,c.y,c.r,col)
  c.r += c.vr
  if c.r > c.mr then
   list[i] = nil
  end
 end

 remove_nil(list,size)
end

function draw_l(list)
 for obj in all(list) do
  obj.draw(obj)
 end
 pal()
end

function draw_player(p)
 local f, px, py, c = p.face*#g, p.x, p.y, palette[p.i]
 pal(8, c)
 pal(14, c)
 if (p.invisible > 0 and (p.invisible > invisible_flash_time or p.invisible % 15 < 7)) pal(14,0)
 sspr(g[f+1],g[f+2],5,5,px,py)
 if p.invincible > 0 and p.invincible % 10 >= 5 then
  spr(19,px-1,py-1)
 end
 if p.charge > 0 and p.charge < 3 then
  local yoff = sc.b - py < 12 and -6 or 6
  if (p.charge > flr(p.power) or (p.charge > 2 and #p.target >= 5) or tut.step < 8) c = 5
  if ((tut.step == 8 or tut.step == 9) and p.charge >= 1) c = 5
  if (tut.step == 10 and p.charge >= 2) c = 5
  print(flr(p.charge)+1,px+1,py+yoff,c)
 end
end

function draw_pickup(p)
 local px, py, c = p.x, p.y, palette[p.pi]
 pal(14,c)
 if frame48 < 8 then pal(15,c) else pal(15,15) end
 sspr(72+flr(frame48/8)*3,8,3,3,px,py)
end

function draw_enemy(e,col)
 local c, ex, ey = col or e.variation, e.x, e.y
 if (c) pal(6,c)
 if (col) pal(7,c)
 if (not c) pal(6,7)
 sspr(24,0,e.size,e.size,ex,ey)
end

function draw_spawners()
 local fade, n = fade, #spawners
 for i=1,n do
  local s = spawners[i]
  local f = s.spawn_frame - 100
  if f >= 0 then
   local p = fade[flr(f*0.05)+1]
   if f < 120 then
    s.draw(s,p,true)
   else
    add(s.list,s)
    spawners[i] = nil
   end
  end
  s.spawn_frame += 1
 end
 remove_nil(spawners,n)
end

function draw_power(x,y,p)
 rectfill(x,y,x+5,y+25,5)

 local yoff = 25 - flr(p.power * 4 + flr(p.power))

 rectfill(x,y+yoff,x+5,y+25,palette[p.i])
 if (p.power % 0.25 ~= 0) rectfill(x,y+yoff-1,x+2,y+25)

 palt(0,false)
 palt(14,true)

 sspr(120,0,6,26,x,y)

 palt()

 for i=1,#p.target do
  spr(30,x,y+25-i*5)
 end
 if p.pixels > 0 then
  local ratio = 1-min(p.pixels / 45,1)
  line(x-1,y+1+23*ratio,x-1,y+24,palette[p.i])
 end
end

functions={
["linear"]=function(t) return t end,
["quad_out"]=function(t) return -t*(t-2) end,
["quad_in"]=function(t) return t*t end,
["quad_in_out"]=function(t) t=t*2 if(t<1) return 0.5*t*t
    return -0.5*((t-1)*(t-3)-1) end
}

function tween(o,vl,t,fn)
 local task={
  vl={},
  time=t or 1,
  o=o,
  progress=0,
  delay=0,
  fn=functions[fn or "quad_out"]
 }

 for k,v in pairs(vl) do
  local x=o[k]
  task.vl[k]={start=x,diff=v-x}
 end

 add(tasks,task)
 return task
end

function tween_update(dt)
 for t in all(tasks) do
  if t.delay>0 then
   t.delay-=dt
  else
   t.progress+=dt/t.time
   local p=t.progress
   local x=t.fn(p>=1 and 1 or p)
   for k,v in pairs(t.vl) do
    t.o[k]=v.start+v.diff*x
   end

   if p>=1 then
    del(tasks,t)
    if (t.onend) t.onend(t)
   end 
  end
 end
end
-->8
--memory

function clear_memory()
 memset(0x2000,0,0x1000)
 memset(0x4300,0,0x1000)
end

function draw_memory()
 memcpy(0x6000,0x2000,0x1000)
 memcpy(0x7000,0x4300,0x1000)
end

function set_memory(x,y,c)
 c = c or 0
 if (oob(x,y)) return
 local not_fraction, adr, mask, colr = get_address(x,y)
 --0x4300 - 0x1000 = 0x3300
 if not_fraction then
  mask, colr = 0xf0, c
 else
  mask, colr = 0x0f, c*0x10
 end
 poke(adr,bor(band(peek(adr),mask),colr))
end

function get_memory(x,y)
 if (oob(x,y)) return 0
 local not_fraction, adr = get_address(x,y)
 local t = band(peek(adr),not_fraction and 0x0f or 0xf0)
 return not_fraction and t or t/0x10
end

function get_address(x,y)
 local i = (x+y*128)/2
 return i % 1 == 0, (i < 0x1000 and 0x2000 or 0x3300) + flr(i)
end

function oob(x,y)
 return x < 0 or x >= 128 or y < 0 or y >= 128
end
-->8
--ct

function c_ct()
 for b in all(bullets) do
  for j=0,b.v-1 do
   set_ct(b.x-sign(b.dx)*j, b.y-sign(b.dy)*j, b)
  end
 end
end

function e_b_collide(els, bullets)
 local deaths = {}
 for enemies in all(els) do
  local length = #enemies
  if (#bullets == 0) goto collision_done
  for i=1,length do
   local e = enemies[i]
   ::next_bullet::
   local b = e.collision(e.x,e.y)
   if b then
    del(bullets,b)
    e.health -= 1
    ct = {}
    c_ct()
    if e.health <= 0 then
     sfx(2,2)
     enemies[i] = nil
     local vr = e.variation
     if (vr == 2) bullet_at_player(e.x+1+rnd(1),e.y+1+rnd(1),e.bv,e.bd,e.be)
     explode(e,vr or 5,vr == 3 and vr or 1)
     if (e.on_death) add(deaths,e)
     add_score(e.value,true,e.x+1,e.y+1)
 				if (#bullets == 0) goto collision_done
     goto next_enemy
 			else
  			if not e.off and not e.no_push then
    		local a = atan2(b.vx,b.vy)
    		e.x += cos(a)*2
    		e.y += sin(a)*2
   		end
   		if (#bullets == 0) goto collision_done
     goto next_bullet
    end
   end
   ::next_enemy::
  end
  ::collision_done::
  remove_nil(enemies,length)
 end
 for e in all(deaths) do
  e.on_death(e)
 end
end

function c_1x1(ex,ey)
 return ct[flr(ex)+flr(ey)*128]
end

function c_3x3(ex,ey)
 --obfuscated now by optimization
 local ct, ex1,        ey1 = 
       ct, flr(ex+1), flr(ey+1)*128
 local ex2, ex3, ey2, ey3 = 
  ex1+1, ex1+2, ey1+128, ey1+256

 return ct[ex1+ey1] or ct[ex1+ey2] or ct[ex1+ey3] or ct[ex2+ey1] or ct[ex2+ey3] or ct[ex3+ey1] or ct[ex3+ey2] or ct[ex3+ey3] or ct[ex2+ey2]
end

function c_4x4_0_0(ex,ey)
 return c_4x4(ex-2,ey-2)
end

function c_4x4(ex,ey)
 local ct, ex1,        ey1 =
       ct, flr(ex+2), flr(ey+2)*128
 local ex2, ex3, ex4, ey2, ey3, ey4 =
  ex1+1, ex1+2, ex1+3, ey1+128, ey1+256, ey1+384

 return ct[ex1+ey1] or ct[ex2+ey1] or ct[ex3+ey1] or ct[ex4+ey1] or ct[ex1+ey2] or ct[ex4+ey2] or ct[ex1+ey3] or ct[ex4+ey3] or ct[ex1+ey4] or ct[ex2+ey4] or ct[ex3+ey4] or ct[ex4+ey4]
end

function c_8x8(ex,ey)
 local ex1, ey1, ex2, ey2 = ex-2, ey-2, ex+2, ey+2
 return c_4x4(ex1,ey1) or c_4x4(ex2,ey1) or c_4x4(ex1,ey2) or c_4x4(ex2,ey2)
end

function set_ct(x,y,v)
 local ct = ct
 if (oob(x,y)) return
 ct[flr(x)+flr(y)*128] = v
end

__gfx__
00000000088008700880088007770000001111000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088878887788888887777700000055000000110000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
0070070088878888788878887767700010111101505555050000000000000000000000000000000000000000000000000000000000000000000000000eeee000
0007700008800880088007807777700015155151515115150005500000000000000000000000000000000000000000000000000000000000000000000eeee000
0007700007700780088008800777000015155151515115150005500000000000000000000000000000000000000000000000000000000000000000000eeee000
00700700888878888888888800000000101111015055550500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888888888870000000000055000000110000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
0000000008800880077008700000000000111100005555000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
000880000888008870077700000000000777000000700007000070000000000000000000fffffffffefffefffe0000000000000000000000777777000eeee000
088888808eee78ee778eee80000000007777700008880088800888000000000000000000fffffffffefffefffe0000000000000000000000700007000eeee000
088888808eee78eee88eee80000600007777700000800088808888800000000000000000fffffffffefffefffe00000000000000000000007000070000000000
888888778eee78eee88eee800066600077777000080800808008880000000000000000000000000000000000000000000000008000000000700007000eeee000
888888770888008880088800000600000777000000000000000000000000000000000000d080d8d080d8d080080000000000000800000000700007000eeee000
0888888007880088800888000000000000000000007000878000000000000000000000000000000000000000000000000000000080000000777777000eeee000
0888888077ee87eee88eee800000000000000000088808888800000000000000000000000000000000000000000000008888888888000000000000000eeee000
000880008eee87eee88eee8000000000000000008888888888000000000000000000000000000000000000000000000000000000800000000000000000000000
088800008eee87eee877ee80ddd0000088888000888888888800000000000000000000000000000000000000000000000000000800000000000000000eeee000
800080000888008880078800ddd0000080008000088800888000000000000000000000000000000000000000000000000000008000000000000000000eeee000
800080000888008880000000ddd0000080e08000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
800080008eee88eee80000000000000080008000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
088800008eee88eee800000000000000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008eee88ee770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
0000000007770088700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
0000000000000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000
07770777707777077707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07070070707070070707070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07770777707777077707770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000007777700000000000000000000000000000000ccccc000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007707077000000000000000000000000000000cc000cc00000000000000000000000000000000000000000000000000000000000000000000000000
00000000007770777000000000000000000000000000000cc0c0cc00000000000000000000000000000000000000000000000000000000000000000000000000
00000000007707077000000000000000000000000000000cc000cc00000000000000000000000000000000000000000000000000000000000000000000000000
000000000007777700000777777777777777777777700000ccccc000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777700000000000000000000007777777777777000000000000000000000000000000000000000000000000000000000000000000000000
00000007000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000007000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000007000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000070000000000000000000000000000000000000777770000000070000000000000000000000000000000000000000000000000000000000000000000000
00000070000000000000000000000000000000000007707077000000070000000000000000000000000000000000000000000000000000000000000000000000
00000070000000000000000000000000000000000007770777000000070000000000000000000000000000000000000000000000000000000000000000000000
00000700007770000000000000000000000000000007707077000000007000000000000000000000000000000000000000000000000000000000000000000000
00000700070007000000000000000000000000000000777770000000007000000000000000000000000000000000000000000000000000000000000000000000
0000070070b000700000000000000000000007777700000000077777007000000000000000000000000000000000000000000000000000000000000000000000
0000700700b000070000000000000000000077000770000000770007700700000000000000000000000000000000000000000000000000000000000000000000
0000700700b000070000000000000000000077070770000000770707700700000000000000000000000000000000000000000000000000000000000000000000
0000700700b000070000077700000999000077000770000000770007700700000000000000000000000000000000000000000000000000000000000000000000
0007000070bbb0700000000000000000000007777700000000077777000070000000000000000000000000000000000000000000000000000000000000000000
00070000070007000000000000000000000000000000777770000000000070000000000000000000000000000000000000000000000000000000000000000000
00070000007770000000000000000000000000000007707077000000000070000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000007770777000000000007000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000007707077000000000007000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000777770000000000007000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000777000000000000007770000000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000000707000000000000070007000000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000000707000000000000708880700000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000777707777000000007008080070000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000700000007000000007008800070000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000777707777000000007008080070000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000000707000000000000708080700000000000000000000700000000000000000000000000000000000000000000000000000000000000000
07000000000000000000707000000000000070007000000000000000000000700000000000000000000000000000000000000000000000000000000000000000
70000000000000000000777000000000000007770000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
70000000007777777777777777777777777777777777777777777700000000070000000000000000000000000000000000000000000000000000000000000000
70000000070000000000000000000000000000000000000000000070000000070000000000000000000000000000000000000000000000000000000000000000
70000000070000000000000000000000000000000000000000000070000000070000000000000000000000000000000000000000000000000000000000000000
70000000070000000000000000000000000000000000000000000070000000070000000000000000000000000000000000000000000000000000000000000000
70000000700000000000000000000000000000000000000000000007000000070000000000000000000000000000000000000000000000000000000000000000
70000000700000000000000000000000000000000000000000000007000000070000000000000000000000000000000000000000000000000000000000000000
70000000700000000000000000000000000000000000000000000007000000070000000000000000000000000000000000000000000000000000000000000000
07000007000000000000000000000000000000000000000000000000700000700000000000000000000000000000000000000000000000000000000000000000
00777770000000000000000000000000000000000000000000000000077777000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
700000bbb00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
700000b0b00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
700000b0b00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
700bbbb0bbbb0000000000000000000ccccc00008888800070000000000000000000000000000000000000000000000000000000000000000000000000000000
700b0000000b000000000000000000cc000cc0088080880070000000000000000000000000000000000000000000000000000000000000000000000000000000
700bbbb0bbbb000000000000000000cc0c0cc0088808880070000000000000000000000000000000000000000000000000000000000000000000000000000000
700000b0b000000077700009990000cc000cc0088080880070000000000000000000000000000000000000000000000000000000000000000000000000000000
700000b0b0000000000000000000000ccccc00008888800070000000000000000000000000000000000000000000000000000000000000000000000000000000
700000bbb00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01010001180202a00025000210001e0001a0001700013000100000e0000e000120000800000001150011400113005130051300513005130051400515005150051200512005120051200512005120051200512005
000600002f5352c5352953525535225251f5251c525185251552513515105150d5150a51508515055150451502515015250150500505005050050500505005010050300501005000050000500005000050000500
01070000206250d110113150631505315053003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01070000206000e100103000630005300021003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01070000206000e100123000630005300021003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000400002932529411293212941129321294122932229410293222941229321294112832126411223201d410183120e4110431101411032020220002200022000220002200012000120001200012000120001200
010b00001d315114111550015500185001850018500185001a5001a5001a5001a5001850018500175001750015500155001550015500155001550015500155000060018600176001340015400004000040000400
011f00000c1040011104111071110b1110e11111111151110c01300100001010010102101041010510107101091010b1010010100101001010010100101001010010100101001010010100101001000010000100
000200002e8122a81225810218101e8101a8101782013820108200e8200e810128000880500801158011480113805138051380513805138051480515805158051280512805128051280512805128051280512805
010800001572410125157140f1200f1252a7003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0108000015724101251071415120151152a7003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0108000015724101251071418120181152a7003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010800001572410125107141a1201a1151a1003270032700397003970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010800001572410125107141c12521714211202111021725007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000000000000
010b000015530150151553015535185401801218542185451a5301a5321a0121a0121854018545175401753615530155321552215522155201551015510155150060018600176001340015400004000040000400
010b000018120187101811018725151211571215112157251a1201a7101a1101a7201812118715171101712615110157101511015710151101571015110157151511515715151151571521100157001510015700
010b00001554015012155321553518540180151a5411a5461a5301a5351c5401c53021541215402153221532215341850021534185002152418500215242150021514185001a5001c50021500005000000000000
010b000018124187141812418700151241570018124187141a1241a7001c1211c7002112421714211242171421124005041c7240050421114005041c71421504211141a5001a5001c50021500005000000000000
010e0000152341521415234152340c2310c2350c20000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
011200000c2340c2340c2340c2350c2000c2000c20000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
010a00000003005121090310e1211403119121220112e121006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
010600002e1202201119121140310e1210903105121000110000005100090000e1001400019100220002e10000600006000060000600006000060000600006000060000600006000060000600006000060000600
010500001c2200c3100c3100c4150c4000c2000c20000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
011800001c2220c3110c425152000c2000c2000c20000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
010800002154415015280221c01521534150152b0121301521524150151a5001c5002150021500000000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
__music__
04 0e0f4344
04 10114344
00 4e4f4344

