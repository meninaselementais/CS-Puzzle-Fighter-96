-- Ensaio visual isolado: injeta somente RAM de laboratório, preserva ROM e configurações originais.
assert(PF_STATE)
local m=manager.machine
local mem=m.devices[':maincpu'].spaces.program
local screen=m.screens[':screen']
local fields={}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
local controls={'P1 Left','P1 Right','P1 Down','P1 Button 1','P1 Button 2','P2 Left','P2 Right','P2 Down','P2 Button 1','P2 Button 2'}
for _,n in ipairs(controls) do fields[n]:set_input_seq('standard',m.input:seq_from_tokens('')) end
local function release() for _,n in ipairs(controls) do fields[n]:set_value(0) end end
local cases={
 {name='crash_chain',x=5,pivot=2,sat=12,r=0,cells={{4,9,1},{4,10,4},{4,11,4},{4,12,4},{4,13,4},{5,13,9}}},
 {name='power',x=4,pivot=2,sat=12,r=1,cells={{4,12,4},{5,12,4},{4,13,4},{5,13,4}}},
 {name='diamond',x=2,pivot=2,sat=5,r=2,cells={{0,12,1},{1,12,1},{0,13,1},{1,13,1},{2,13,1}}}
}
local index=0;local phase='start';local frame=0;local total=0;local neutral=0;local turn=0;local picture=nil
local log=assert(io.open(PF_SESSION..'/visual.csv','w'));log:write('case,frame,phase1,score1\n')
local function next_case()
 release();index=index+1;frame=0;neutral=0
 if index>#cases then
  log:close();local f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write('3 referencias visuais CPS2');f:close();phase='done';m:exit()
 else phase='neutral' end
end
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~='loading' then return end
 release();local c=cases[index]
 for y=0,13 do for x=0,5 do mem:write_u16(0xFFAB00+y*16+2*(x+1),0);mem:write_u16(0xFFAF00+y*16+2*(x+1),0) end end
 for _,cell in ipairs(c.cells) do mem:write_u16(0xFFAB00+cell[2]*16+2*(cell[1]+1),cell[3]) end
 mem:write_u16(0xFF8310,c.x);mem:write_u16(0xFF8452,c.pivot);mem:write_u16(0xFF8454,c.sat);mem:write_u8(0xFF8470,c.r)
 turn=mem:read_u16(0xFF84A0);fields['P1 Down']:set_value(1);phase='case'
end)
PF_frame=emu.add_machine_frame_notifier(function()
 total=total+1
 if phase=='start' then next_case()
 elseif phase=='neutral' then release();neutral=neutral+1;if neutral==3 then phase='loading';m:load(PF_STATE) end
 elseif phase=='case' then
  frame=frame+1
  if mem:read_u16(0xFF84A0)~=turn then fields['P1 Down']:set_value(0) end
  log:write(string.format('%s,%d,%d,%d\n',cases[index].name,frame,mem:read_u8(0xFF847E),mem:read_u32(0xFF83AA)))
  picture=string.format('%s_%04d.png',cases[index].name,frame)
  if frame>=240 then assert(mem:read_u32(0xFF83AA)>100, 'Cenario sem limpeza');next_case() end
 end
 if total>1500 and phase~='done' then error('Limite de quadros') end
end)
emu.register_frame_done(function()
 if picture then assert(not screen:snapshot(PF_SESSION..'/snap/'..picture));picture=nil end
end)
