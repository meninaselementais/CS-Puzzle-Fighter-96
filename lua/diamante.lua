assert(PF_STATE)
local m=manager.machine;local mem=m.devices[':maincpu'].spaces.program
local fields={}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
local controls={'P1 Down','P1 Button 2','P2 Down','P1 Left','P1 Right','P1 Button 1','P2 Left','P2 Right','P2 Button 1','P2 Button 2'}
for _,n in ipairs(controls) do fields[n]:set_input_seq('standard',m.input:seq_from_tokens('')) end
local function release() for _,n in ipairs(controls) do fields[n]:set_value(0) end end
local function encode(base)
 local a={};for y=0,13 do for x=0,5 do a[#a+1]=string.format('%04X',mem:read_u16(base+y*16+2*(x+1))) end end
 return table.concat(a,':')
end
local cases={
 {name='diamond_floor',pivot=1,sat=5,x=2,r=1,cells={}},
 {name='diamond_normal_blue',pivot=1,sat=5,x=4,r=0,cells={{4,13,1},{0,13,1},{1,13,1},{2,13,1},{3,10,1},{5,10,1},{5,8,1},{0,12,2}}},
 {name='diamond_counter_blue',pivot=2,sat=5,x=2,r=2,cells={{2,13,1},{0,13,0x1507},{1,13,0x2507},{4,13,1}}},
 {name='diamond_power_blue',pivot=2,sat=5,x=2,r=2,cells={{0,12,1},{1,12,1},{0,13,1},{1,13,1},{2,13,1}},frames=300},
 {name='diamond_on_counter',pivot=2,sat=5,x=2,r=2,cells={{2,13,0x3507},{0,13,3},{1,13,0x3307},{4,13,2}}},
 {name='diamond_chain',pivot=2,sat=5,x=2,r=2,cells={{2,13,1},{3,13,4},{3,12,1},{3,11,12},{0,13,4},{1,13,4}},frames=300},
}
local log=assert(io.open(PF_SESSION..'/diamond.csv','w'))
log:write('case,frame,state1,turn1,score1,pending2,grid1,aux1\n')
local phase='start';local index=0;local frame=0;local neutral=0;local total=0;local turn0=0
local function next_case()
 release();index=index+1;frame=0;neutral=0
 if index>#cases then
  local rom=assert(io.open(PF_SESSION..'/piece_tables.bin','wb'));rom:write(mem:read_range(0x124B8,0x128B7,8));rom:close()
  local pow=assert(io.open(PF_SESSION..'/power_table.bin','wb'));pow:write(mem:read_range(0xFFF8,0x100DF,8));pow:close()
  log:close();local f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write(tostring(#cases)..' casos diamante');f:close();phase='done';m:exit()
 else phase='neutral' end
end
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~='loading' then return end
 release();local c=cases[index]
 for y=0,13 do for x=0,5 do mem:write_u16(0xFFAB00+y*16+2*(x+1),0);mem:write_u16(0xFFAF00+y*16+2*(x+1),0) end end
 for _,cell in ipairs(c.cells) do mem:write_u16(0xFFAB00+cell[2]*16+2*(cell[1]+1),cell[3]) end
 mem:write_u16(0xFF8310,c.x);mem:write_u16(0xFF8452,c.pivot);mem:write_u16(0xFF8454,c.sat);mem:write_u8(0xFF8470,c.r)
 mem:write_u8(0xFF849E,0);mem:write_u8(0xFF889E,0)
 turn0=mem:read_u16(0xFF84A0);fields['P1 Down']:set_value(1);phase='case'
end)
PF_frame=emu.add_machine_frame_notifier(function()
 total=total+1
 if phase=='start' then next_case()
 elseif phase=='neutral' then release();neutral=neutral+1;if neutral==3 then phase='loading';m:load(PF_STATE) end
 elseif phase=='case' then
  frame=frame+1;local c=cases[index]
  if mem:read_u16(0xFF84A0)~=turn0 then fields['P1 Down']:set_value(0) end
  log:write(string.format('%s,%d,%d,%d,%d,%d,%s,%s\n',c.name,frame,mem:read_u8(0xFF847E),mem:read_u16(0xFF84A0),mem:read_u32(0xFF83AA),mem:read_u8(0xFF849E),encode(0xFFAB00),encode(0xFFAF00)))
  if frame>=(c.frames or 220) then next_case() end
 end
 if total>10000 and phase~='done' then error('Limite de quadros') end
end)
