assert(PF_STATE)
local m=manager.machine;local mem=m.devices[':maincpu'].spaces.program
local fields={}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
local controls={'P1 Down','P1 Button 2','P2 Down','P1 Left','P1 Right','P1 Button 1','P2 Left','P2 Right','P2 Button 1','P2 Button 2'}
for _,n in ipairs(controls) do fields[n]:set_input_seq('standard',m.input:seq_from_tokens('')) end
local function release() for _,n in ipairs(controls) do fields[n]:set_value(0) end end
local cases={}
for perm=0,7 do for amount=1,17 do cases[#cases+1]={name='residual_'..perm..'_'..amount,perm=perm,amount=amount,char=2} end end
for char=0,10 do cases[#cases+1]={name='character_'..char,perm=3,amount=33,char=char} end
local log=assert(io.open(PF_SESSION..'/delivery.csv','w'))
log:write('case,amount,permutation,character,row_before,row_after,before,after\n')
local function grid()
 local result={};for y=0,13 do for x=0,5 do result[#result+1]=string.format('%04X',mem:read_u16(0xFFAD00+y*16+2*(x+1))) end end
 return table.concat(result,':')
end
local phase='start';local index=0;local frame=0;local neutral=0;local total=0;local turn=0
local before='';local row_before=0
local function next_case()
 release();index=index+1;frame=0;neutral=0
 if index>#cases then
  local f=assert(io.open(PF_SESSION..'/attack_tables.bin','wb'));f:write(mem:read_range(0xFF98,0x10A87,8));f:close()
  log:close();f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write(tostring(#cases)..' casos');f:close();phase='done';m:exit()
 else phase='neutral' end
end
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~='loading' then return end
 release();local c=cases[index]
 for y=6,13 do mem:write_u16(0xFFAB00+y*16+10,4) end
 mem:write_u8(0xFF8382,c.char)
 turn=mem:read_u16(0xFF84A0)
 fields['P1 Down']:set_value(1);fields['P1 Button 2']:set_value(1);phase='case'
end)
PF_frame=emu.add_machine_frame_notifier(function()
 total=total+1
 if phase=='start' then next_case()
 elseif phase=='neutral' then release();neutral=neutral+1;if neutral==3 then phase='loading';m:load(PF_STATE) end
 elseif phase=='case' then
  frame=frame+1;local c=cases[index]
  fields['P1 Button 2']:set_value(0)
  if mem:read_u16(0xFF84A0)~=turn then fields['P1 Down']:set_value(0) end
  if frame==150 then mem:write_u8(0xFF849E,c.amount) end
  if frame==235 then mem:write_u8(0xFF8A7B,c.perm) end
  if frame==240 then before=grid();row_before=mem:read_u16(0xFF8A06);assert(mem:read_u8(0xFF8A7B)==c.perm) end
  if frame==310 then
   log:write(string.format('%s,%d,%d,%d,%d,%d,%s,%s\n',c.name,c.amount,c.perm,c.char,row_before,mem:read_u16(0xFF8A06),before,grid()))
   next_case()
  end
 end
 if total>60000 and phase~='done' then error('Limite de quadros') end
end)
