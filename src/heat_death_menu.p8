pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--heat death
--by john williams

cartdata("gate88_heat_death")

debug, bitwise_index = false, 0
--menuitem(1,"debug",function() debug = not debug end)

function to_table(s,do_not_strip)
 if (not do_not_strip) s = strip_whitespace(s)
 local j,depth,key,table = 1, 0, nil, {}
 for i=1,#s do
  local ss = sub(s,i,i)
  if ss == "," and depth == 0 then
   local v = num_or_str_value(sub(s,j,i-1))
   if key then
    table[key]=v
   else
    add(table,v)
   end
   j = i+1
   key = nil
  elseif ss == ":" and depth == 0 then
   key = num_or_str_value(sub(s,j,i-1))
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

function num_or_str_value(v)
 local l,v1 = sub(v,#v,#v), sub(v,0,#v > 1 and #v-1 or #v)
 if (l == "}") return to_table(v1)
 if (l == "|") return v1
 if (v == "true") return true
 if (v == "false") return false
 return v+0
end

whitespace_symbols = to_table(" |:1,\n|:1,\r|:1,\t|:1",true)

function strip_whitespace(s)
 local output,j = "", 1
 for i=1,#s do
  if whitespace_symbols[sub(s,i,i)] then
   output = output..sub(s,j,i-1)
   j = i+1
  end
 end
 return output..sub(s,j,#s)
end

function _init()
 bitwise_set(false,0)

 frame, menu_colors, camx, camy, py, hold_down = to_unpack("0,{8,9,10,7,6,5,},0,0,0,0,")
 pcolor_choice, eb_choice, particles, p_choice, effects, texts, fade = to_unpack("{8,12,9,11,14,4,},{-1,8,9,10,11,12,14,4,15,},{},{6,7,9,10,13,1,2,5,},{},{},{1,5,13,13,6,7,},")
 update_frame()

 defaults_set, n_play, shuffle_mode, slime_world, easy_mode = bitwise_get(1), bitwise_get(2,2), bitwise_get(4), bitwise_get(5), bitwise_get(6)

 menu = init_menu()
 go_menu(true)
 local load_message = to_table(stat(6))
 if load_message[1] and sub(load_message[1],1,1) == "s" then
  stats_title = get_stats_title(load_message[1])
  stats = load_message[2]
  go_highscore(nil,load_message[1])
 else
  if load_message[1] and sub(load_message[1],1,1) == "c" then
   dset(5,1)
  end
  go_intro()
 end

end

function go_menu(f)
 state_update, state_draw = update_main, draw_main
 if not f and dget(5) ~= 1 then
  go_first_time_tutorial()
 end
end

function _update60()
 tween_update(1/60)
 state_update()
end

function _draw()
 state_draw()
end

function update_frame()
 frame += 1
  --2 24 30 32 48 60
 frame %= 960 --lcd
 frame30 = frame % 30
 frame48 = frame % 48
 multicolor = frame%24/4+8
end

-->8
--help

function bitwise_get(lowest_bit,size,index)
 size, index = size or 1, index or bitwise_index
 local op = lowest_bit > 16 and lshr or shl
 local returnvalue = op(band(dget(index),get_mask(lowest_bit,size)),abs(16-lowest_bit))
 if (size == 1) return returnvalue == 1
 return returnvalue
end

function bitwise_set(value,lowest_bit,size,index)
 size, index = size or 1, index or bitwise_index
 local v, mask = dget(index), get_mask(lowest_bit,size)
 dset(index,bor(band(v,bnot(mask)),band(shl(lshr(size == 1 and (value and 1 or 0) or value,16),lowest_bit),mask)))
end

function get_mask(lowest_bit,size)
 return shl(lshr(0xffff.ffff,32-size),lowest_bit)
end

function round(num, snap)
  local snap = snap or 1
  return flr(num * snap + 0.5) / snap
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

function sort(a,cmp)
  for i=1,#a do
    local j = i
    while j > 1 and cmp(a[j-1],a[j]) do
        a[j],a[j-1] = a[j-1],a[j]
    j = j - 1
    end
  end
end

function str_to_array(str)
 local output = {}
 for i=1,#str do
  output[i] = sub(str,i,i)
 end
 return output
end

function array_to_str(array)
 local output = ""
 for i=1,#array do
  output = output..array[i]
 end
 return output
end

function rndint(max_i,min_i)
 min_i = min_i or 0
 return flr(rnd(max_i+1-min_i))+min_i
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

-->8
--draw

function b(n)
 return n/7*6
end

function go_intro()
 state_draw, state_update, effects, texts, added_sprout, playing_music = draw_intro, update_intro, {}, {}, false, false

 for i=1,1500 do
  local d = rnd(min(i/2,55))+1.5+rnd(min(i/2,6))
  add(particles,{
    d = d,
    a = rnd(1),
    ad = min(1/d^2,0.015),
    c = p_choice[rndint(#p_choice,1)],
   })
 end
 t_offset = b(3)
 t_start = t() + t_offset
 intro_state = {particles = #particles+1}
 tween(intro_state, {particles = 1},b(11),"quad_out").delay = b(3)+t_offset

 fit("the year is",30,8,3,true)
 fit("20000000000000000000000000000",94,7,4)
 fit("00000000000000000000000000000",100,6,5)
 fit("00000000000000000000000000000",106,5,6)
 fit("000000000000000000000000000xx",112,4,7)
 fit("a.d.",120,3,8)

 fit("the universe is",30,6,12)
 fit("dark",61,4,14)

 fit("cyber benjamin",50,6,19)
 fit("owns all",58,5,20)
 fit("remaining energy",66,4,21)

 fit("cb's mega computer",54,5,26,true)
 fit("runs the internet",62,4,27,true)

 fit("take back virtual space",50,8,32)
 fit("liberate the energy",58,6,34)
 fit("and free the universe",66,4,36)

end

function add_sprout(x,y,dur,a)
 local x1, y1 = x, y
 add(effects,{
   draw = function(e)
    local c = e.t < 1/15 and 1 or 3
    line(x,y,x1,y1,c)
    if (c == 3) pset(x1,y1,11)
    x1 += cos(a)
    y1 += sin(a)
    if rnd(100)<2.75 and #effects < 700 then
     local na = a + 0.25
     if (flr(rnd(2))==0) na -= 0.5
     na %= 1
     add_sprout(x1,y1,e.t+1/60,na)
    end
   end,
   t = dur,
  })
end

function update_intro()
 if (btnp(🅾️) or btnp(❎)) go_menu() music(-1)
 update_frame()
end

function draw_cb(x,y)
 pal(5,multicolor)
 sspr(48,0,23,31,x,y)
end

function draw_intro()
 cls(0)

 local tdiff = t()-t_start

 if (tdiff >= 0 and not playing_music) music(0) playing_music = true

 if tdiff >= b(22) and tdiff < b(23) then
  draw_cb(1,1)
  draw_cb(105,1)
  draw_cb(1,95)
  draw_cb(105,95)
  pal()
 end

 for p in all(particles) do
  p.a += p.ad
  if (tdiff > 3) p.ad += rnd(0.000062)
  p.a %= 1
  p.x,p.y = 64+cos(p.a)*p.d, 64+sin(p.a)*p.d/min(max(1,tdiff/3+1),2.5)
  pset(p.x,p.y,p.c)
 end

 for i=flr(intro_state.particles), #particles do
  particles[i] = nil
 end

 if tdiff >= b(26) and not added_sprout then
  for i=0,11 do
   add_sprout(64,64,b(5)+rnd(1/15),.25*i%1)
  end
  added_sprout = true
 end
 if (tdiff >= b(40.25)) create_title()
 if (tdiff >= b(46.25)) go_menu()

 draw_title()

 draw_l(effects)

 draw_l(texts)

 draw_debug()
end

function draw_l(effects)
 local elength = #effects

 for i=1,elength do
  local e = effects[i]
  if e then
   if (e.draw) e.draw(e)
   if e.t then e.t -= 1/60 if e.t <= 0 then effects[i] = nil end end
  end
 end

 remove_nil(effects,elength)
end

function fit(text,y,dur,start,bg)
 local x = 64-#text*2
 dur, start = b(dur), b(start) + t_offset
 local e = {
  x = x,
  y = y,
  draw = function(e)
   local diff = dur-e.t
   if diff > 0 then
    local ft = flr(min(diff*4,1)*(#fade-1))+1
    if (e.t < 0.125) ft = flr(e.t*8*(#fade-1)+1)
    local c = fade[ft]
    if (bg) rectfill(e.x-1,e.y-1,e.x+#text*4-1,e.y+5,0)
    print(text,e.x,e.y,c)
   end
  end,
  t = dur+start,
 }
 add(texts, e)
 return e
end

function draw_main()
 cls()
 camera()

 draw_title()
 draw_menu()
 draw_debug()

end

function draw_title()
 pal()
 if title then
  if title.ndraw >= 6 then
   pal(8,5)
   sspr(0,47,50,14,32,title.death_y)
   sspr(54,47,10,14,title.h_x,40)
  end
  for i=min(flr(title.ndraw),5),1,-1 do
   pal(8,menu_colors[i])
   sspr(0,32,50,14,26+i,18+i)
  end
 end
end

function draw_colors()
 cls()

 --print mode at top
 local s = get_difficulty_string().." "..get_mode_string()
 color(7)
 if is_picking() then
  s = "p1 double tap ⬇️ to cancel"
  color(7)
 end
 cursor((128-#s*4)/2,1)
 print(s)

 local schm, scvm = 64, 42
 --print player colors
 local players = n_play+1
 for i=1,players do
  local x, y = players <= 1 and schm-6 or schm-30 + (i-1)%2*50,
             players <= 2 and scvm-6 or scvm-20 + flr((i-1)/2)*35
  pal(5,pcolor_choice[color_indexes[i]])
  sspr(0,0,10,10,x,y)
  print("p"..i,x+2,y-8,6)
  if player_picking[i] then
   print("⬅️",x-10, y+3)
   print("➡️",x+13, y+3)
   if other_player_has_color(i) then
    palt(0,false)
    sspr(16,0,10,10,x,y)
    palt(0,true)
   end
  end
  pal()
 end

 draw_menu()

 if (bullet_color_index == 1) then
  print("rainbow",80,100)
 else
  rectfill(80,100,84,104,eb_choice[bullet_color_index])
 end

 draw_debug()
end

function draw_highscore()
 cls()
 draw_hs_table(1,1,"standard",hs_standard)
 draw_hs_table(44,1,"shuffle",hs_shuffle)
 draw_hs_table(87,1,"slime",hs_slime,"world",39)
 if entering_highscore then
  local s = "new high score!"
  local x, y = 64-#s*2, 63
  rectfill(x-1,y,x+#s*4+1,y+7,2)
  print(s,x+1,y+2,0)
  print(s,x,y+1,7)

  x, y = 64-#hs_initials*2.5, 76
  rect(x-2,y-2,x+14,y+6,2)
  for i=0,2 do
   if (i+1 == enter_index) rectfill(x+i*5-1,y-1,x+i*5+3,y+5,1)
   print(hs_initials[i+1],x+i*5,y,7)
  end

  x, y = 64-9*3, 88

  for i=0,#hs_alphabet-1 do
   local ox, oy = i%9*6, flr(i/9)*10
   if (i == initial_index) rect(x+ox-2,y+oy-2,x+ox+4,y+oy+6,2)
   print(sub(hs_alphabet,i+1,i+1),x+ox,y+oy,7)
  end

  if (initial_index >= 30) then
   local ox = (initial_index-30)*12
   rect(53+ox,y+28,59+ox,y+36,2)
  end

  print("<", 55, y+30,7)
  print(">", 67, y+30,7)
 else
  draw_menu()
 end

 draw_debug()
end

function draw_hs_table(x,y,title,table,title_2,w)
 title_2 = title_2 or ""
 local h,w = #table * 9 + 14, w or 40
 rectfill(x,y,x+w,y+h,1)
 t1x, t1y, t2x, t2y = x+(w-#title*4)/2, y+1, x+(w-#title_2*4)/2, y+7
 color(0)
 print(title,t1x+1,t1y+1)
 print(title_2,t2x+1,t2y+1)
 color(7)
 print(title,t1x,t1y)
 print(title_2,t2x,t2y)
 for i=1,#table do
  local item = table[i]
  local l = y+18+(i-1)*9
  if (item.new) rectfill(x,l-1,x+w,l+5,2)
  print(item.initials,x+w-11,l,7)
  print(item.score,x+1,l)
  print(item.zeros,x+1,l,5)
  print(":",x+22,l,7)
 end
end

function draw_menu()
 color(7)
 for i=1,#menu do
  local menui = menu[i]
  local t = 
   ((i == m_sel and not is_picking() and not entering_highscore) and "> " or "  ")
   ..menui.t
  if (menui.a) t = t..menui.a()
  print(t,mx,my+(i-1)*6)
 end
 camera(0,0)
end

function draw_debug()
 if debug then
  cursor(0,0)
  color(7)
  print(stat(1))
  print(#effects)
 end
end

function draw_stats()
 cls(1)
 camy = min(py-128,camy)
 camy = max(0,camy)
 camera(camx, camy)
 py, printsc = 1, 7
 local death_debt = -stats[17]*10
 prints(stats_title)
 prints""
 prints("level: ",stats[4])
 prints""
 prints"heat"
 prints(" starting   + ",100)
 prints(" enemies    + ",round(stats[1]-stats[2]+stats[3]-100+death_debt,10))
 prints(" gems       + ",round(stats[2],10))
 prints(" time       - ",round(stats[3],10)," "..round(stats[3]*3,10).." sec",5)
 if stats[17] < 0 then
 prints(" death debt - ",death_debt)
 end
 prints(" total      = ",flr(stats[1])," joules",5)
 prints""
 local total_gems = stats[7] + stats[9]
 prints"power gems"
 prints(" gems collected  : ",stats[7])
 prints(" gems lost       : ",stats[9])
 prints(" gems chained    : ",stats[8])
 prints(" longest chain   : ",stats[6])
 prints(" chain ratio     : ",total_gems == 0 and 0 or round(stats[8]/stats[7]*100,10),"%")
 prints(" avg pts per gem : ",total_gems == 0 and 0 or round(stats[2]/total_gems,100))
 prints""
 prints"power"
 prints(" power used   : ",stats[10]+stats[12]*2+stats[13]*3)
 prints(" power wasted : ",stats[14])
 prints""
 prints"abilities"
 prints(" 1. defrag        : ",stats[10])
 prints("     efficiency   : ",stats[10] == 0 and 0 or round(stats[11]/stats[10]*100,10),"%")
 prints(" 2. cloak         : ",stats[12])
 prints(" 3. remote backup : ",stats[13])
 prints""
 prints"lives"
 prints(" start  : ",stats[16]+sub(stats_title,1,1))
 prints(" extra  : ",stats[5])
 prints(" deaths : ",stats[15])
 prints""
 prints"deaths per level"
 local largest, death_list = 0, stats[18]
 for k,v in pairs(death_list) do
  if (k > largest) largest = k
 end
 for i=1,largest do
  local v = death_list[i]
  if (v) prints(" lvl "..i..": ",v)
 end
 prints""
 prints"press button for menu"

 if (camy <= 0) color(5)
 print("⬆️",120,camy+1)
 color(7)
 if (camy >= py-128) color(5)
 print("⬇️",120,camy+122)
 color(7)

 rectfill(120,camy+7,126,camy+120,5)
 local sh, sy = min(128/py,1)*113, 7 + camy*(114/py)
 rectfill(120,camy+sy,126,camy+sh+sy,7)
end

function prints(string, value, suffix, c)
 value, suffix, c = value or "", suffix or "", c or 7
 print(string..value,1,py,printsc)
 print(suffix,#(string..value)*4+1,py,c)
 py+=6
end

functions={
["linear"]=function(t) return t end,
["quad_out"]=function(t) return -t*(t-2) end,
["quad_in"]=function(t) return t*t end,
["quad_in_out"]=function(t) t=t*2 if(t<1) return 0.5*t*t
    return -0.5*((t-1)*(t-3)-1) end
}

local tasks = {}

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
--menu

function init_menu()
 menu, m_sel, mx, my = {}, 1, 12, 70
 add(menu,
  menu_item("play",go_colors))
 add(menu,menu_item(""))
 add(menu,
  menu_item("difficulty - ",difficulty_menu,get_difficulty_string))
 add(menu,
  menu_item("mode       - ",mode_menu,get_mode_string))
 add(menu,
  menu_item("players    - ",p_menu,function() return n_play + 1 end))
 add(menu,menu_item(""))
 add(menu,menu_item("tutorial",go_tutorial))
 add(menu,menu_item("help and info",go_controls))
 add(menu,
  menu_item("high scores",function(b) if not b then music(16) end go_highscore(b) end))
 return menu
end

function go_first_time_tutorial()
 local back_function = sub_menu(1,70,draw_first_time,update_first_time)
 m_sel = 2
 add(menu,menu_item("play tutorial (recommended)",go_tutorial))
 add(menu,menu_item(""))
 add(menu,menu_item("skip tutorial for now",function() dset(5,1) back_function() end))
end

function draw_first_time()
 cls()
 camera()
 draw_title()
 draw_menu()
 rectfill(8,103,92,115,1)
 print("  controls: ",1,107,7)
 print("             ❎",1,110,7)
 print("                   ⬆️",1,104,7)
 print("                 ⬅️⬇️➡️",1,110,7)
end

function update_first_time()
 create_title()
 update_frame()
 menu_input()
end

function go_tutorial(b)
 if not b then
  music(16)
  local back_function = sub_menu(1, 19, draw_tutorial, update_tutorial)
  m_sel = 1
  add(menu,
   menu_item("keyboard",function() start_tutorial(2) end))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,
   menu_item("classic",function() start_tutorial(0) end))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,
   menu_item("dual stick",function() start_tutorial(1) end))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,menu_item(""))
  add(menu,
   menu_item("back",back_function))
 end
end

function start_tutorial(c)
 load("heat_death_tutorial",nil,"t|,"..c..",")
end

function draw_tutorial()
 cls()
 camera()
 local title = "choose input device for tutorial"
 print(title,64-#title*2,1,7)
 print("z c",75,22,12)
 print(" x",75,22,8)
 print("      ⬆️",75,16,11)
 print("    ⬅️⬇️➡️",75,22,11)
 sspr(0,112,49,16,70,43)
 sspr(0,64,64,43,63,70)
 draw_menu()
end

function update_tutorial()
  update_frame()
  menu_input()
end

function go_colors(b)
 if not b then
  music(15)
  player_picking = {false,false,false,false}
  color_storage_index = n_play < 1 and 1 or 2

  bitwise_index = color_storage_index

  color_indexes = {}
  for i=1,n_play+1 do
   add(color_indexes,get_color_index(bitwise_get(i*4-4,4),i))
  end

  player_shots_match = bitwise_get(16)
  if bitwise_get(0,4) == 0 and n_play > 0 then
   player_shots_match = true
  end

  bitwise_set(player_shots_match,16)

  local bullet_color = bitwise_get(17,5)-1
  bullet_color_index = get_color_index(bullet_color,1,eb_choice)

  save_colors()

  bitwise_index = 0

  local back_function = sub_menu(12, 76, draw_colors, update_colors)
  add(menu,
   menu_item("",start_game,function() return player_colors_match() and "colors must be unique" or "start" end))
  add(menu,menu_item(""))
  add(menu,
   menu_item("player colors",pick_colors))
  add(menu,
   menu_item("player shots - ",toggle_player_shots,player_shots_string))
  add(menu,
   menu_item("enemy  shots -   ",cycle_enemy_bullet_color))
  add(menu,menu_item(""))
  add(menu,
   menu_item("back", back_function))
  m_sel = 1
 end
end

function go_controls(b)
 if not b then
  music(16)
  if not page then
   page = 0
   total_pages = 4
  end
  local back_function = sub_menu(87,2, draw_controls, update_controls)
  add(menu,
   menu_item("page ",change_page,function() return (page+1).."/"..total_pages end))
  add(menu,
   menu_item("back", back_function))
 end
end

function draw_controls()
 cls()
 camera()
 rectfill(86,1,126,13,1)
 if page == 0 then
  rectfill(1,48,126,82,1)
  rectfill(1,87,126,121,1)
  print("simple controls",65,26,7)
  sspr(0,112,49,16,10,15)
  print("default controller",2,49,7)
  sspr(3,116,9,9,2,55)
  print(" - move",12,59)
  print("❎",3,65,8)
  print(" - shoot",12,65,7)
  print("🅾️",3,71,12)
  print(" - use power",12,71,7)
  print("-",5,77,9)
  print(" - pause",12,77,7)
  print("default keyboard",2,88)
  print("⬆️⬇️⬅️➡️",2,98,11)
  print(" - move",34,98,7)
  print("       x",2,104,8)
  print(" - shoot",34,104,7)
  print("  z or c",2,110,12)
  print(" - use power",34,110,7)
  print("       p",2,116,9)
  print(" - pause",34,116,7)
 elseif page == 1 then
  rectfill(1,48,126,82,1)
  rectfill(1,87,126,121,1)
  print("   dual stick\n    controls",65,20,7)
  print("(gate.itch.io)",71,38,5)
  sspr(0,64,64,43,4,1)
  print("default controller",2,49,7)
  sspr(7,76,9,9,2,57)
  print(" - move",12,61)
  sspr(34,88,9,9,66,57)
  print(" - shoot",76,61,7)
  print("🅾️",3,69,12)
  print(" - use power",12,69,7)
  print("-",5,77,9)
  print(" - pause",12,77,7)
  print("default keyboard",2,88)
  print("    edsf",2,98,11)
  print(" - move",34,98,7)
  print("    ikjl",2,104,8)
  print(" - shoot",34,104,7)
  print("spacebar",2,110,12)
  print(" - use power",34,110,7)
  print("       p",2,116,9)
  print(" - pause",34,116,7)
 elseif page == 2 then
  py, printsc = 1, 7
  color(7)
  rectfill(0,51,127,51,1)

  prints"objective: gain heat"
  prints"by shooting enemies"
  prints""
  prints"collect power gems to"
  prints"fill the power bar"
  prints""
  prints"hold power button to"
  prints"charge ability (123)"
  prints""
  prints"release power button to spend"
  prints"power on numbered ability:"
  prints""
  printsc = 8
  prints"1 power - defrag"
  printsc = 7
  prints" collects debris in an area"
  prints" and converts it to firepower"
  printsc = 8
  prints"2 power - cloak"
  printsc = 7
  prints" briefly prevent enemies from"
  prints" chasing and aiming at you"
  printsc = 8
  prints"3 power - remote backup"
  printsc = 7
  prints" creates backups on field which"
  prints" each prevent one death"
  camera(0,0)
  
  pal(14,8)
  if frame48 < 8 then pal(15,8) else pal(15,15) end
  sspr(88+flr(frame48/8)*3,0,3,3,87,23)

  sspr(102,11,12,7,97,21)
  sspr(120,0,6,25,116,17)
  spr(14,86,37)
  local n = flr(frame%120/30)
  if (n > 0) print(n,87,43,8)

 elseif page == 3 then
  py, printsc = 24,7

  prints"         credits"
  py+=12
  prints"programming, music, sfx,"
  prints"graphics, and game design by"
  printsc = 8
  prints" john m. williams\n @gateeightyeight"
  py += 12
  prints("      gate.itch.io")
  printsc = 7
  py -= 6
  prints"visit              for full"
  prints"instructions, info, and tips"
  py+=6
  prints"pico-8 fantasy console by"
  printsc = 8
  prints" joseph white\n @lexaloffle"
  prints""
 end
 draw_menu()
end

function update_controls()
  update_frame()
  menu_input()
end

function change_page(b)
 sfx(6,1)
 b = b or 1

 page += b
 page %= total_pages
end

function go_highscore(b,string)
 if not b then
  if not string then
   hs_easymode, hs_players = easy_mode, n_play+1
  else
   hs_easymode, hs_players = extract_hs_data(string)
  end

  resetting_scores = 0

  local back_function = sub_menu(12, 76, draw_highscore, update_highscore)
  m_sel = 6
  if stats then
   add(menu,
    menu_item("view game stats: ",go_stats,function() return flr(stats[1]).."j" end))
   add(menu,menu_item(""))
   m_sel += 2
  end
  add(menu,
   menu_item("players    - ",cycle_hs_players,function() return hs_players end))
  add(menu,
   menu_item("difficulty - ",toggle_hs_difficulty,function() return get_difficulty_string(hs_easymode) end))
  add(menu,menu_item(""))
  add(menu,menu_item("",reset_visible_scores,reset_string))
  add(menu,menu_item(""))
  add(menu,
   menu_item("main menu",back_function))

  if stats and string and dget(3) ~= stats[1] then
   local score = stats[1]
   dset(3,score)
   new_hs_index = get_hs_index(string,score)
   if new_hs_index then
    dset(new_hs_index,flr(score))
    entering_highscore = true
    music(12)
   end
  end

  initial_index = 31
  enter_index = 1

  hs_initials = str_to_array(get_initials(4))

  refresh_hs_tables()
  
 end
end

function reset_visible_scores(b)
 if (resetting_scores < 0) return
 if not b and resetting_scores < 2 then
  sfx(6,1)
  resetting_scores += 1
 elseif resetting_scores == 2 or resetting_scores == 3 then
  if b == -1 then
   sfx(6,1)
   resetting_scores += 1
  else
   resetting_scores = -1
  end
 elseif resetting_scores == 4 then
  if b == 1 then
   sfx(6,1)
   resetting_scores += 1
  else
   resetting_scores = -1
  end
 elseif resetting_scores == 5 then
  if not b then
   sfx(6,1)
   resetting_scores = -2
   wipe_table(hs_standard)
   wipe_table(hs_shuffle)
   wipe_table(hs_slime)
   refresh_hs_tables()
  else
   resetting_scores = -1
  end
 end
end

function wipe_table(table)
 for e in all(table) do
  dset(e.index,0)
 end
end

function reset_string()
 if resetting_scores == -2 then
  return "above tables cleared"
 elseif resetting_scores == -1 then
  return "bad input: delete cancelled"
 elseif resetting_scores == 1 then
  return "are you sure?"
 elseif resetting_scores == 2 then
  return "press ⬅️"
 elseif resetting_scores == 3 then
  return "press ⬅️ again"
 elseif resetting_scores == 4 then
  return "press ➡️"
 elseif resetting_scores == 5 then
  return "press final ❎ to delete"
 else
  return "delete tables above"
 end
end

function toggle_hs_difficulty(b)
 sfx(6,1)
 hs_easymode = not hs_easymode
 refresh_hs_tables()
end

function cycle_hs_players(b)
 sfx(6,1)
 b = b or 1
 hs_players += b
 hs_players = (hs_players-1) % 4 + 1
 refresh_hs_tables()
end

function extract_hs_data(string)
 local p = sub(string,3,3)
 p = p or 1
 if p == "" then p = 1 end
 return sub(string,2,2) == "e", p + 0, sub(string,4,4)
end

function get_stats_title(string)
 local easy, players, mode = extract_hs_data(string)
 return players.."p "..(easy and "easier " or "normal ") .. short_mode_value(mode)
end

function short_mode_value(m)
 if (m == "w") return "slime world", 2
 if (m == "s") return "shuffle", 1
 return "standard", 0
end

normal_offset = to_table("0,15,24,33,")
easy_offset = to_table("42,45,48,51,")
hs_alphabet = "abcdefghijklmnopqrstuvwxyz_"

function refresh_hs_tables()
 local offset, scores_per_table = score_data(hs_players,hs_easymode)
 hs_standard = get_table(scores_per_table, offset)
 hs_shuffle = get_table(scores_per_table,offset+scores_per_table)
 hs_slime = get_table(scores_per_table,offset+scores_per_table*2)
end

function score_data(players,easy_mode)
 local scores_per_table, offset_lookup = 3, normal_offset
 if (players <= 1) scores_per_table = 5
 if (easy_mode) scores_per_table = 1 offset_lookup = easy_offset

 return offset_lookup[hs_players], scores_per_table
end

function get_hs_index(string,score)
 local easy_mode, players, mode = extract_hs_data(string)
 local offset, scores_per_table = score_data(players, easy_mode)
 local _, v = short_mode_value(mode)
 local mode_offset = scores_per_table*v

 local e = 63 - offset - mode_offset
 local smallest_v, smallest_i = 0x7fff, nil
 for i=e-scores_per_table+1,e do
  if bitwise_get(16,16,i) < smallest_v then
   smallest_v = bitwise_get(16,16,i)
   smallest_i = i
  end
 end

 return smallest_v < flr(score) and smallest_i or nil
end

function save_initials(index)
 local i1, i2, i3 = encode_initials(hs_initials)
 bitwise_set(i1,0,5,index)
 bitwise_set(i2,5,5,index)
 bitwise_set(i3,10,5,index)
 if (index == new_hs_index) save_initials(4)
end

function get_table(num,offset)
 local table = {}
 for i=1,num do
  local index = 64-offset-i
  local score = bitwise_get(16,16,index)
  local ss,zeros = score.."", ""
  while #ss < 5 do
   ss = "0"..ss
   zeros = "0"..zeros
  end
  add(table,{score=ss,zeros=zeros,initials=get_initials(index),new=index==new_hs_index,index=index})
 end

 --sort descending
 sort(table,function(a,b) return a.score < b.score end)

 return table
end

function encode_initials(initials)
 local out = {}
 for i=1,3 do
  local letter, j = initials[i], 1
  while j <= #hs_alphabet do
   if (sub(hs_alphabet,j,j) == letter) break
   j += 1
  end
  out[i] = j
 end
 return unpack(out)
end

function get_initials(index)
 local i1, i2, i3 = bitwise_get(0,5,index), bitwise_get(5,5,index), bitwise_get(10,5,index)
 local r = sub(hs_alphabet,i1,i1) .. sub(hs_alphabet,i2,i2) .. sub(hs_alphabet,i3,i3)
 while #r < 3 do
  r = r.."_"
 end
 return r
end

function pick_colors(b)
 if not b then
  for i=1,n_play+1 do
   color_backup = merge_into({},color_indexes)
   player_picking[i] = true
  end
 end
end

function toggle_player_shots(b)
 sfx(6,1)
 player_shots_match = not player_shots_match
 bitwise_set(player_shots_match,16,1,color_storage_index)
end

function cycle_enemy_bullet_color(b)
 sfx(6,1)
 b = b or 1
 bullet_color_index += b
 bullet_color_index = (bullet_color_index-1) % #eb_choice + 1
 bitwise_set(eb_choice[bullet_color_index]+1,17,5,color_storage_index)
end

function player_shots_string()
 return player_shots_match and "matching" or "rainbow"
end

function save_colors()
 for i=1,n_play+1 do
  bitwise_set(pcolor_choice[color_indexes[i]],i*4-4,4)
 end
end

function cycle_color(player,direction)
 color_indexes[player] += direction
 color_indexes[player] = (color_indexes[player]-1) % #pcolor_choice + 1
end

function is_picking()
 if not player_picking then return false end
 for v in all(player_picking) do
  if v then return true end
 end
 return false
end

function other_player_has_color(s)
 for i=1,#color_indexes do
  if i ~= s and not player_picking[i] and color_indexes[i] == color_indexes[s] then return true end
 end
 return false
end

function get_color_index(c,default,choice)
 choice = choice or pcolor_choice
 for i=1,#choice do
  if choice[i] == c then return i end
 end
 return default
end

function player_colors_match()
 for i=1,n_play+1 do
  for j=i+1,n_play+1 do
   if color_indexes[i] == color_indexes[j] then return true end
  end
 end
 return false
end

function sub_menu(x,y,draw,update)
 local p_menu, p_m_sel, p_mx, p_my, p_draw, p_update = menu, m_sel, mx, my, state_draw, state_update
 menu, m_sel, mx, my, state_draw, state_update = {}, 1, x, y, draw, update
 return function(b)
  if not b then
   sfx(6,1)
   camera() 
   menu, m_sel, mx, my, state_draw, state_update = p_menu, p_m_sel, p_mx, p_my, p_draw, p_update
  end
 end
end

function menu_item(t,f,a)
 return {t=t, f=f, a=a}
end

function update_main()
 create_title()
 update_frame()
 menu_input()
end

function create_title()
 if not title then
  title = {
   ndraw  = 1,
   death_y = 24,
   h_x = 140,
  }
  local t = tween(title,{ndraw = 6},b(5),"linear")
  t.onend = function()
   tween(title,{death_y = 40, h_x = 86},b(0.5),"quad_in").delay = b(0.5)
  end
 end
end

function update_colors()
 update_frame()
 if not is_picking() then
  if not_saved_colors then
   bitwise_index = color_storage_index
   save_colors()
   bitwise_index = 0
   not_saved_colors = false
  end
  menu_input()
  down_time = 0
 else
  not_saved_colors = true
  for i=1,n_play+1 do
   local bp = i-1
   if player_picking[i] then
    if (btnp(⬅️,bp)) sfx(7,1) cycle_color(i,-1)
    if (btnp(➡️,bp)) sfx(7,1) cycle_color(i,1)
    if ((btnp(🅾️,bp) or btnp(❎,bp)) and not other_player_has_color(i)) player_picking[i] = false sfx(6,1)
   end
  end
  if btn(⬇️) and down_let_go then
   if (t() - down_time < 0.75) then
    player_picking = {false,false,false,false}
    color_indexes = color_backup
   end
   down_time = t()
   down_let_go = false
  end
  if not btn(⬇️) then
   down_let_go = true
  end
 end
end

function update_highscore()
 if entering_highscore then
  if (btnp(⬆️) and initial_index >= 9) initial_index -= 9 sfx(7,1)
  if (btnp(⬇️)) initial_index += 9 sfx(7,1)
  if (btnp(⬅️)) initial_index -= 1 sfx(7,1)
  if (btnp(➡️)) initial_index += 1 sfx(7,1)
  initial_index = max(initial_index,0)
  if initial_index >= 31 then initial_index = 31
  elseif initial_index > 26 then initial_index = 30 end
  if btnp(🅾️) or btnp(❎) then
   sfx(6,1)
   if initial_index <= 26 and enter_index <= 3 then
    local ii = initial_index+1
    hs_initials[enter_index] = sub(hs_alphabet,ii,ii)
    enter_index += 1
    if (enter_index > 3) initial_index = 31
   elseif initial_index == 30 and enter_index > 1 then
    enter_index -= 1
   elseif initial_index == 31 then
    if enter_index <= 3 then
     enter_index += 1
    else
     save_initials(new_hs_index)
     refresh_hs_tables()
     entering_highscore = false
    end
   end
  end
 else
  if (btnp(⬆️) or btnp(⬇️)) resetting_scores = 0
  menu_input()
 end
end

function menu_input()
 if (btnp(⬆️)) repeat m_sel -= 1 until menu[wrap_m_sel()].f sfx(7,1)
 if (btnp(⬇️)) repeat m_sel += 1 until menu[wrap_m_sel()].f sfx(7,1)
 m_sel = wrap_m_sel()
 
 if menu[m_sel] and menu[m_sel].f then
 if (btnp(🅾️) or btnp(❎)) menu[m_sel].f() 
 if (btnp(⬅️)) menu[m_sel].f(-1)
 if (btnp(➡️)) menu[m_sel].f(1)
 end
end

function wrap_m_sel()
 return (m_sel-1) % #menu + 1
end

function update_stats()
 if (btn(⬆️)) camy -= 2
 if (btn(⬇️)) camy += 2
 if (btnp(🅾️) or btnp(❎)) stats_back() sfx(6,1)
end

function start_game(b)
 if not b and not player_colors_match() then
  load("heat_death_game",nil,"t|,"..tostr(dget(0),true)..","..tostr(dget(color_storage_index),true)..",")
 elseif not b and player_colors_match() then
  pick_colors(b)
 end
end

function go_stats(b)
 if not b then
  sfx(6,1)
  stats_back = sub_menu(0,0,draw_stats,update_stats)
 end
end

function p_menu(b)
 sfx(6,1)
 b = b or 1
 n_play += b
 n_play %= 4
 bitwise_set(n_play,2,2)
end

function mode_menu(b)
 sfx(6,1)
 local r = b == -1 and 2 or 1
 for i=1,r do
  if not shuffle_mode and not slime_world then shuffle_mode = true
  elseif shuffle_mode then shuffle_mode, slime_world = false, true
  elseif slime_world then slime_world = false end
 end
 bitwise_set(shuffle_mode,4)
 bitwise_set(slime_world,5)
end

function difficulty_menu()
 sfx(6,1)
 easy_mode = not easy_mode
 bitwise_set(easy_mode,6)
end

function get_difficulty_string(b)
 b = (b==nil) and easy_mode or b
 if (b) return "easier"
 return "normal"
end

function get_mode_string()
 if (shuffle_mode) return "shuffle"
 if (slime_world) return "slime world"
 return "standard"
end

__gfx__
0077777700000000007777770000000000000000000000000000000000000055555500000000000000000000fffffffffefffefffe0000000777000000000000
0077777700000000007777770000000000000000000000000000000000055555555550000000000000000000fffffffffefffefffe0000008888800005555000
5555555555000000550000005500000000000000000000000000000005555555500055000000000000000000fffffffffefffefffe0000008888800005555000
55555555550000005500000055000000000000000000000000000005550005000000550000000000000000000000000000000000000000008888800005555000
5555555555000000550000005500000000000000000000000000005500000005500055000000000000000000d080d8d080d8d080080000000888000005555000
55555555550000005500000055000000000000000000000000000555050005555555550000000000000000000000000000000000000000000000000000000000
55555555550000005500000055000000000000000000000000005500055555050500000000000000000000000000000000000000000000000000000005555000
55555555550000005500000055000000000000000000000000055005555000050500000000000000000000000000000000000000000000000000000005555000
00555555000000000055555500000000000000000000000000555055500000050500000000000000000000000000000000000000000000000000000005555000
00555555000000000055555500000000000000000000000000555055000555555555000000000000000000000000000000000000000000000000000005555000
00000000000000000000000000000000000000000000000005555055000555555555500000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005550055000005500000550000000000000000000000000000000000000000800000000008888000
00000000000000000000000000000000000000000000000055550550000005500000550000000000000000000000000000000000000000080000000008888000
00000000000000000000000000000000000000000000000055550550000005500000500000000000000000000000000000000000000000008000000008888000
00000000000000000000000000000000000000000000000050050550000005555555000000000000000000000000000000000088888888888800000008888000
00000000000000000000000000000000000000000000000050000550000005555555000000000000000000000000000000000000000000008000000000000000
00000000000000000000000000000000000000000000000050050550000005500000500000000000000000000000000000000000000000080000000008888000
00000000000000000000000000000000000000000000000055550550000005500000550000000000000000000000000000000000000000800000000008888000
00000000000000000000000000000000000000000000000055550050000005500000550000000000000000000000000000000000000000000000000008888000
00000000000000000000000000000000000000000000000005555055000555555555500000000000000000000000000000000000000000000000000008888000
00000000000000000000000000000000000000000000000005555055000555555555000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000555055000000050500000000000000000000000000000000000000000000000000000008888000
00000000000000000000000000000000000000000000000000555055500000050500000000000000000000000000000000000000000000000000000008888000
00000000000000000000000000000000000000000000000000055005555000050500000000000000000000000000000000000000000000000000000008888000
00000000000000000000000000000000000000000000000000005500055555050500000077000000777000007770000000000000000000000000000008888000
00000000000000000000000000000000000000000000000000000555050005555555550007000000007000000070000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000055000000055000550007000000777000000770000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000005550005000000550007000000700000000070000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000055555555000550077700000777000007770000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000555555555500000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000555555000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888888880000008888880000008888888888000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000088000088000000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888880000888880000000888888888800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888880000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
88800008880000888888880000888000088800000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888800000000888888880000008888880000008888888888000088800008880000000000000000000000000000000000000000000000000000000000000000
88800088000000888000000000088000088000000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008800000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888880000000888888888800000008880000000088888888880000000000000000000000000000000000000000000000000000000000000000
88800008880000888880000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008880000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800008800000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88800088000000888000000000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
88888800000000888888880000888000088800000008880000000088800008880000000000000000000000000000000000000000000000000000000000000000
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
__label__
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
00000000000000000000000000000000000000000000000000000000000500006000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000a0000000000006000000000000000000000000000000000000000000000
000000000000000000000000000000000000000610d0a0005000000000000000100000d00000000d000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000070500000005000000d0056000000600000a00000900000000000000000000000000000000000000000000
00000000000000000000000000000000000000100000000000000060a00000000000000000000000000090009900090000000000000000000000000000000000
000000000000000000000000000000000000000000000000000090000000000000000000000000a0000000000aa0050010500000000000000000000000000000
000000000000000000000000000000050000000000000000010000000000000500000070765000000000000000a0000000060000000000000000000000000000
0000000000000000000000000000000000000001005100000000000005d000000007000000970900000000000000000000060000000000000000000000000000
0000000000000000000000000000200000000060a000000000005009000000000000000075000000000000002050000000000000000000000000000000000000
00000000000000000000000000000000000000000107000050000000d60000000000010000000000000000000000000000000009000000000000000000000000
00000000000000000000000000a00700000000000000000a000000050d00d000005a000006000000000000000050100010000000000000000000000000000000
00000000000000000000000000000000000d0000000000001a000000d10000070000000000000000000000700000000000050000000000000000000000000000
00000000000000000000000000000000000000000006200000700000000000000000097000000000702000000000000000900000000000000000000000000000
00000000000000059d01000000000000d00000000000000000000a00000000010000501000000700000700000060600000000000000000010000000000000000
0000000000000000a00000000000007000000a0000002000000000050000007000000000000002d0000000000000000000000900000000000060000000000000
00000000000000002000000a0000000259a000010009000000000d00000000500000000000000600000000a07910000d0000000000d010000000000000000000
00000000000a0000000000000000000000000000000000000009000000000070000000000000a0000000000000000070000000a0029000000000000000000000
0000000000020000000000000000000000000000020000da0000000d0000000000000000700001000000100000000000a00090000006000d00000d0000000000
000000000000000000000000600000000009000000700090000007000009a0000000000006700000200000000000002000000600006070000100910000000000
0000000000000005000000000000000060d09000000090d070000000000000000000000000001000000000000000070000000000007000000000d09000000000
0000000000001000000000000000000000000000600060000d0000277000000000006d70009000000000050a0000009000001000000000000000000000000000
0000000000000000000000000009000000000000000700000000002000d000000000060060002000000000007100000d000000000100000000000001a6000000
00000000000000010000900000000006000060600000000000000090d60010000000070000000000d0005000d000000d00000000000000060000000075000000
000000000000500000600000000600000000d00002000007700a00000059a200006100706600206000000000500001d000000000000d0d000000000010000000
000000000000000000100000000100100000207000000000009000000500710002000d9009002000000a000190000a00d9050100000000002000000000000000
00001000000190000002000000000000700000000000000000070000000020050050002a60009500700100050000000020000000000000009000000000000000
00000000070000000000000a000000000000000000750000000a000060000a7020000170a0000061000020000100000d00000000000000000000000000020000
00600000000000000000000000000000000d6000000050500a0000000700000000000000000d05700000100a0d02000000607000000900090500000000000000
00000000000000000100002050000900a000a100000002000000720050000006000050050000a000005000000000000000000000d60500000000000000000000
00000000020106006000000a0050700000100000000907900d090070061090d00000200000000005000000000017000006000005000000000000000000000900
000000007000902000000000001000090000090000009000001000060770d010010ad10000007200000001a0000000000090000000d000000007d09000000000
0d0002900d0000000007000000000000000d00007d0007009d0100920010070090000700aa0090000a0000600001000000000000009000000000000000000000
00000000000a0000000050a000d00050000000001006000d0007000001000d001000570070000070000d0900000000a006000000000000200000010000000a00
000000000000000000090100000050a00500000002002000d0709107025a05090500025000009000516000000029200000002020000000000000020000000007
00000000000000000000005000000000000000000000a00000079000700a9070d050d9009a000d00005005000000700000100000000000000000000000000200
0000000000000060002000000000000000190050000000050700060602a590a201020d600010050600000000090000000000d0100000d0006000000000000000
00000050007a000d0000000000000a7000000000000200900da0772090600a552d0679909a000090700000a00050000a00000000000000000010000000000006
000000000060000000000000000000000000090090062d060a70ad7a00a055a576d61050d902000005500070005000000000000a000000005000005000070000
000060000000000010000000000090000a0000000700005a000d000126991d99906dd609620000000d00009a00d000500007a000000000000002000000200000
009000000000000000000060000d050000000a0050a0000099da000050065965079a500a560000700000620d260000100520170000050000000a000000000001
0000000000000010000000a0000207000200d07d0010a0000000100a006adad91960d70a65760000100000000000000000000000060000000000000000000000
00000000000000600000000009000a00d0000000020009009000d00d90517a900d922002150d000209000a000000000060600000000a00000000000090000006
00000000a009d0000000000000000d02060a00002900506090d00522700170106d651006d020961109000005000200000200600607000d007010000000205000
00000000000000000000000000000000000010d000920a000151215a052000001000090760000207000000900000002020002000000000000005000000000000
0d0600000a00000d000000000020000000000000000000000a0a0600001206192000560000012050a00001a0005000000000000000001000000d0000a0000000
000000000000000a000a00a000000a0050a020a02a00000d005a02006000d60960d0000700a1611109000060099a000000070000000000000000000000009a00
000000000000000a00000007000000090060dd0000d000000001000009d009000001000a002500a0000900020000000000060000000000000000000000005000
00000000000000020000000000000000102007000200000006000000000000056020a9500a0d20079a0000000001200000000000000902000000000a00050000
00000000000000000a000000006000000a000000000700070000100006007000dd0000270d0000a0a6a000000000a0000000d070000000070001002000200000
00000000d000000d000000000000000000d010000201000000000100007d59000000000000907170000d00000010000000005000000000009200000000000000
0000000d000000000070000d01000000900002000000000000500201d5100010d000570d0050000002000900590000075d000000000000060000000000000000
0000000700000000000aa00000000100000050500007a00100600009000000000700000000100000010000000000000000000010000000600000000000000000
000000000000000002000000009d06060000100000000900090100000010100000001600000005000000000000060000006000d0000000000000000000050000
0000000090062000000200000000700070000500050009000000070000127007901a006000d00060000000000a0700000000000000000000000002000d000000
00000000000000000000000000000000010000020000710000009000000000107a000000000000100a0000500000000100010000007000000a02000000000000
00000000000000000000000000006000100000000000a00000000000010000000000000001002000000000090000090000000000700000600000000000000000
00000000000000000000000052000000000000600d00d006770090079601000000000000000000000a0000500000700020006005000000000097000000000000
00000000000000000d00090000000d00000000000d0900d000000000000000000200a00000000000000000007000000000000000000000050000000000000000
000000000060070600200a0000000000020a0000000000000190000000000020001050d02900000100000070090020000a00006006d000000000000000000000
000000000000000000000000d00000000000000700000000000000000090000000d0000000000000000000000000000000010000000100000000000000000000
000000000000000000000000000900000000000a000000200200000900600009009a000000000000000a05000000600000070000000000000000000000000000
00000000000000062060000507000000100000000000000000a00007000600200900000000000000000000010000000000000007000000000000000000000000
000000000000000010000000000a000a000000000000000000000000200020000000900000000000d00000000000000000000500000000000000000000000000
000000000000000000000000000100001000000090000000000000007000a0000020000000000005000000000000000000000d00000200000700000000000000
00000000000000070000005000010000000000000000000000000000250000000000005000000000000000000900000000000002000000000000000000000000
00000000000000000da000000000000000000000000a9000006000000000a000000000000000000000000002000000000000d000050000000000000000000000
0000000000000000000000000000000000000d0000000000700000000055000050700d000000000002000000000000000d0000d7000000000000000000000000
00000000000000000000020000000000000000200000a00070000000076000d0000000000000200000000000000000a000000d00006a00000000000000000000
0000000000000000000000000020700000909000000000000000000000000000000000000500000000000a000000000005000000000000000000000000000000
000000000000000000000001000016700d5000000aa000000000000000a0000090000002000000000000000a0000000000000000000000000000000000000000
000000000000000000000000000000000010000000000000000000000000070000dd00000700000d000000000000000000600000000000000000000000000000
0000000000000000000000000000000000000d000000000000000000000000000000000000010000000000000000000070000000000000000000000000000000
00000000000000000000000000000000000000002000000000a00000000000000000000050000000000000000700600000000000000000000000000000000000
00000000000000000000000000000000000000a0000000000a00000000020006000a000000000000000200600000000000000000000000000000000000000000
0000000000000000000000000000000000000000000700000001000d000000000000000050000600000000060000000000000000000000000000000000000000
0000000000000000000000000000000000000000010000000000000060000000000000070000006a000005000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000200000000010a0000000000000000000000000000000000000000000000000000000000000000000
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

__sfx__
010100010c130320002d00028000240001f0001c0001700014000120000f0000c0000a0000600003000000000a0050600503005000051c0051900518005150051300511005100050e0050d0050b0050500500005
0101000100760320002d00028000240001f0001c0001700014000120000f0000c0000a0000600003000000000a0050600503005000051c0051900518005150051300511005100050e0050d0050b0050500500005
0101000100560320002d00028000240001f0001c0001700014000120000f0000c0000a0000600003000000000a0050600503005000051c0051900518005150051300511005100050e0050d0050b0050500500005
000116172d64021630176300e6200c6200a6200962008620076200562004620036200262002610016100161001610006100061000610006100061000610006100061000610006100c6000c6000c6000c6000d600
0101000118040320002d00028000240001f0001c0001700014000120000f0000c0000a0000600003000000000a0050600503005000051c0051900518005150051300511005100050e0050d0050b0050500500005
017900000c5200c5000c5000c5000c5000c5000c5000c500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010100001d3101d3101d3100530005300053000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100002131021310213100030015300153001530015300003000030015300153001530015300153001530015300113001430000300003001530015300153001530015300153001530015300003001530015300
010d00000c04325600216001e6002660025600216001e60018b2018b2018b1018b152660025600216001e6000c04325600216001e6002660025600216001e60018b2018b2018b1018b152660025600216001e600
010d000009a5009a5009a6009a7009762097620976209750097500975509755097450475004750027500274002750027400976109765091350975509750097400c75100552005620055218730005500c76000540
010d000009760097600975009750097450970009700097000f0001000011000100000c0000e0000f000110000c0000c0000d0000f00015000170000c0000e000170001500009400094000b4000b4000b40000000
010d00000e75002550025400e7200e7600e7500255002540025500e7500e7400e74010761107550e7500254000550005500c7400c7300c7600c7500055000540005500c7500c7400c73000550005400c7400c730
010d00001375013740075401373513755075401374013730075551374513740075301375213742075421373013750075401374013730075501374013740075301575015740157421573015750157421574215730
010d00001575415754157401573009552095520955009540157521575215740157340955409550095500954009550095500954209532157501575015755157451575515750157401573209552095520955209542
010d0000180330c03318b200c033180330c03318b200c033180430c03318b200c033180330c03318b200c0331803318b2017b2018b201803318b2017b2018b201803318b2517b2518b25180330c03318b2518033
010d00001803317b2018b2017b201803317b2018b2017b201803317b2018b3017b2018b3017b3018b3017b4018b5018b5018b5500000000000000000000000000000000000000000000000000000000000000000
010d00001586015850158641585015850158651585515855158601585013854138601c8501c850158601585015852158621585415850188601885515855158651085009740047500974010850158601074015850
010d00001086410860138511585209752158460410000100095000450009500005000950004500095000050009536045460953600546095360454609536005460c20004200132000c2000b4000b4000b40000000
010d00000e8550e8550e8550e8500e8500e8550e8550e8550e8550e8550e8550e8550e8550e8550e8550e8550e8550e8550e8650e86510870108700e8750e8750c8620c8620c8520c8550c8550c8550c8550c855
010d00000c8550c8550c8550c8520c8520c8550c8650c865138721387213875138751386513865138551385513855138551385513855138551385513855138551385513855138551385513855138551385513855
010d00001587515875158751587515860158601586515865158551585515855158551585515850158501585515855158551585515855158551585515855158551585515852158521585515855158551585515835
010d00001574009530157420953209542157300954415730157440953015742095320954215732095421573218b00157001570015700157001570015700157001570015700157001570015700157001570015700
010d0000098302d825098302d825098302d825098302d825098302d825098302d825098302d825098302d82515800158001580015800158001580015800158001580015800158001580015800158001580015800
010d000021c252131021c351fc3021c3521c3024c241fc312bc3028c3526c2226c2521c302131523c3021c3124c352412524c352412524c2526c3430c342bc2118c2218c351a3121ac351cc201cc351fc301fc25
010d00002bc452bc4528c4228c4526c3226c3524c3124c3121c3121c4021c4021c4221c3221c3221c3221c3021c3221c2221c2221c1221c0021000210002d0001500015000150001500015000150001500015000
010600001dd701dd701dd751dd001fd701fd701fd751fd0021d4021d4021d4021d4521d2021d2021d2021d2521d1021d1021d1021d1521d0021d0021d0000d0021d0021d0021d0021d0021d0021d0021d0000000
0106000024d7024d7024d7524d0523d7023d7023d7523d0526d4026d4026d4526d0526d2026d2026d2526d0526d1026d1026d1526d0521d0021d0021d0021d0000d0021d0021d0021d0021d0021d0021d0000000
010600001ad701ad701ad751dd001ad701ad701ad751fd001ad401ad401ad401ad451ad201ad201ad201ad251ad101ad101ad101ad1521d0021d0021d0000d0021d0021d0021d0021d0021d0021d0021d0000000
010600001dd701dd701dd751dd001fd701fd701fd751fd0013d4013d4013d4513d0013d2013d2013d2513d0013d1013d1013d1513d002dd002dd0021d0000d0021d0021d0021d0021d0021d0021d0021d0000000
0107000016d7016d4016d7000d0016d7016d7516d7000d002ed702ed702ed7000d0029d7029d4029d7500d0029d4029d4029d451f00029d1029d1029d1500d0029d1529d1529d1529d001dd001dd001dd0029d00
010700001fd701fd701fd601fd551fd401fd401fd301fd251fd701fd701fd601fd5524d4024d4024d3024d2524d2024d2224d2224d2224d2224d2024d2024d2024d2524d2524d2524d2524d2524d2524d2524d25
010700002cd722cd722cd622cd622cd522cd522bd0024d002bd702bd702bd7024d0029d7029d7029d7027d0027d7027d7027d6027d6027d6027d5027d5024d0029d7229d7229d6229d6229d5229d5529d0029d00
0107000029d4229d4229d3229d3229d2229d25000000000029d2229d2229d2229d1229d1229d15000000000029d1229d1229d1229d1229d1229d1529d0029d000000000000000000000000000000000000000000
0107000024d5024d5024d5024d4024d4024d3024d3024d3016d5022d5016d5022d401fd501fd501fd401fd4022d5022d5022d5022d4022d4022d4022d3022d3024d5024d5024d5024d4024d4024d4024d3024d30
__music__
01 08094344
00 080a4344
00 08094044
00 080a4344
00 08104344
00 08114344
00 08105144
00 08114344
00 080b1257
00 080c1344
00 0e0d1417
04 0f151618
00 5d5e1d1e
00 5e5f1f21
04 52602044
04 484c191a
04 4e4d1b1c
04 4f424344

