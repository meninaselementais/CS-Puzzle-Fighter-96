assert(PF_STATE)
local m=manager.machine
local mem=m.devices[':maincpu'].spaces.program
local fields={}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
local controls={'P1 Left','P1 Right','P1 Down','P1 Button 1','P1 Button 2','P2 Left','P2 Right','P2 Down','P2 Button 1','P2 Button 2'}
for _,name in ipairs(controls) do fields[name]:set_input_seq('standard',m.input:seq_from_tokens('')) end
local function release() for _,name in ipairs(controls) do fields[name]:set_value(0) end end
local cases={{name='neutral',frames=240},{name='right_held',key='P1 Right',frames=80},{name='left_held',key='P1 Left',frames=80},{name='down_held',key='P1 Down',frames=80},
 {name='right_release',key='P1 Right',release=8,frames=30},{name='right_pulses',key='P1 Right',pulses=true,frames=60}}
for x=0,5,5 do for r=0,3 do for d=1,2 do
 cases[#cases+1]={name=string.format('wall_%d_%d_%d',x,r,d),x=x,r=r,key='P1 Button '..d,release=2,frames=20}
end end end
for r=0,3 do for d=1,2 do
 cases[#cases+1]={name=string.format('corridor_%d_%d',r,d),x=3,r=r,key='P1 Button '..d,release=2,frames=20,corridor=true}
end end
for r=0,3 do for d=1,2 do cases[#cases+1]={name=string.format('floor_%d_%d',r,d),x=3,r=r,key='P1 Button '..d,release=2,frames=20,floor=true} end end
for d=1,2 do cases[#cases+1]={name='quickturn_'..d,x=3,r=0,key='P1 Button '..d,release=2,frames=20,corridor=true,repeat_press=true} end
local log=assert(io.open(PF_SESSION..'/timing.csv','w'))
log:write('case,frame,key,x,y,offset,rotation,turn,seed,perm,held_timer,drop_timer,fall_interval,fall_timer,pivot_color,satellite_color,rotation_lock,input,previous_input\n')
local phase='start';local index=0;local frame=0;local neutral=0;local total=0
local function next_case()
 release();index=index+1;frame=0;neutral=0
 if index>#cases then log:close();local f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write('timing');f:close();phase='done';m:exit()
 else phase='neutral' end
end
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~='loading' then return end
 release();local c=cases[index]
 if c.floor then for y=0,13 do for x=0,5 do mem:write_u16(0xFFAB00+y*16+2*(x+1),0) end end end
 if c.x then mem:write_u16(0xFF8310,c.x);mem:write_u16(0xFF8314,c.floor and 14 or 6);mem:write_u16(0xFF8542,c.floor and 0xFFF0 or 0);mem:write_u8(0xFF8470,c.r) end
 if c.corridor then for y=3,9 do for _,x in ipairs({2,4}) do mem:write_u16(0xFFAB00+y*16+2*(x+1),1) end end end
 if c.key then fields[c.key]:set_value(1) end
 phase='case'
end)
PF_frame=emu.add_machine_frame_notifier(function()
 total=total+1
 if phase=='start' then next_case()
 elseif phase=='neutral' then release();neutral=neutral+1;if neutral==3 then phase='loading';m:load(PF_STATE) end
 elseif phase=='case' then
  frame=frame+1;local c=cases[index]
  local down=c.key and (not c.release or frame<c.release) and (not c.pulses or frame%8<4)
  if c.repeat_press and frame==10 then down=true end
  if c.key then fields[c.key]:set_value(down and 1 or 0) end
  log:write(string.format('%s,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',c.name,frame,down and c.key or '',mem:read_u16(0xFF8310),mem:read_u16(0xFF8314),mem:read_i16(0xFF8542),mem:read_u8(0xFF8470),mem:read_u16(0xFF84A0),mem:read_u16(0xFF8444),mem:read_u8(0xFF867B),mem:read_u16(0xFF8488),mem:read_u16(0xFF8620),mem:read_u16(0xFF84A6),mem:read_u8(0xFF845E),mem:read_u16(0xFF8452),mem:read_u16(0xFF8454),mem:read_u8(0xFF8476),mem:read_u16(0xFF8440),mem:read_u16(0xFF8442)))
  if frame>=c.frames then next_case() end
 end
 if total>5000 and phase~='done' then phase='failed';error('Limite de quadros') end
end)
