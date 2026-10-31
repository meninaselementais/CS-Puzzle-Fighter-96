-- Partidas com entradas lógicas; nenhuma célula ou contador é injetado.
assert(PF_STATE)
local m=manager.machine;local mem=m.devices[':maincpu'].spaces.program
local fields={}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
local controls={}
for p=1,2 do for _,n in ipairs({'Left','Right','Down','Button 1','Button 2'}) do
 local name='P'..p..' '..n;controls[#controls+1]=name;fields[name]:set_input_seq('standard',m.input:seq_from_tokens(''))
end end
local function release() for _,n in ipairs(controls) do fields[n]:set_value(0) end end
local function encode(base)
 local a={};for y=0,13 do for x=0,5 do a[#a+1]=string.format('%04X',mem:read_u16(base+y*16+2*(x+1))) end end
 return table.concat(a,':')
end
local log=assert(io.open(PF_SESSION..'/natural.csv','w'))
local incomplete=assert(io.open(PF_SESSION..'/incomplete.csv','w'))
incomplete:write('episode,player,turn,frame,state\n')
log:write('episode,player,turn,source_frame,target_frame,score_before,score_after,incoming,outgoing,permutation,source_character,first_bonus,opponent_first_bonus,input,aux_input,expected,aux_expected\n')
local episode=0;local frame=0;local neutral=0;local phase='start';local total=0
local last={0,0};local waiting={};local rotated={false,false}
local function snap(name)
 local f=assert(io.open(PF_SESSION..'/captures/'..name..'_f'..frame..'.bin','wb'));f:write(mem:read_range(0xFF0000,0xFFFFFF,8));f:close()
end
local function next_episode()
 release();episode=episode+1;neutral=0;frame=0;waiting={};rotated={false,false}
 if episode>3 then log:close();incomplete:close();local f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write('3 partidas');f:close();phase='done';m:exit()
 else phase='neutral' end
end
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~='loading' then return end
 release();last={mem:read_u16(0xFF84A0),mem:read_u16(0xFF88A0)};phase='match'
end)
PF_frame=emu.add_machine_frame_notifier(function()
 total=total+1
 if phase=='start' then next_episode()
 elseif phase=='neutral' then release();neutral=neutral+1;if neutral==3 then phase='loading';m:load(PF_STATE) end
 elseif phase=='match' then
  frame=frame+1
  for p=1,2 do
   local base=0xFF8300+(p-1)*0x400;local other=0xFF8300+(2-p)*0x400
   local grid=0xFFAB00+(p-1)*0x200;local aux=0xFFAF00+(p-1)*0x200
   local turn=mem:read_u16(base+0x1A0);local state=mem:read_u8(base+0x17E)
   if turn~=last[p] then
    if waiting[p] then incomplete:write(string.format('%d,%d,%d,%d,%d\n',episode,p,waiting[p].turn,frame,state)) end
    waiting[p]={turn=turn,frame=frame,score=mem:read_u32(base+0xAA),incoming=mem:read_u8(other+0x19E),outgoing=mem:read_u8(base+0x19E),
     perm=mem:read_u8(base+0x37B),character=mem:read_u8(other+0x82),first=mem:read_u8(0xFF8691),opp_first=0,
     received0=mem:read_u8(base+0x37D),opp_received0=mem:read_u8(other+0x37D),cells=encode(grid),aux=encode(aux)}
    snap(string.format('e%d_p%d_t%d_before',episode,p,turn));last[p]=turn;rotated[p]=false
   end
   if waiting[p] and (state==11 or state==17 or state==18) then
    local q=mem:read_u8(other+0x19E)
    if q>waiting[p].incoming then waiting[p].incoming=q end
    if state==17 or state==18 then waiting[p].perm=mem:read_u8(base+0x37B) end
   end
   if waiting[p] and state==0 then
    local w=waiting[p]
    local delivered=(mem:read_u8(base+0x37D)-w.received0)&0xFF
    if delivered>w.incoming then w.incoming=delivered end
    local opp_rec=mem:read_u8(other+0x37D)
    if w.first==0 and mem:read_u8(0xFF8691)==1 and opp_rec~=w.opp_received0 then w.opp_first=1 end
    log:write(string.format('%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%s,%s,%s\n',episode,p,w.turn,w.frame,frame,w.score,mem:read_u32(base+0xAA),w.incoming,w.outgoing,w.perm,w.character,w.first,w.opp_first,w.cells,w.aux,encode(grid),encode(aux)))
    snap(string.format('e%d_p%d_t%d_after',episode,p,turn));waiting[p]=nil
   end
   local target=(turn*3+p*2+episode*5)%6
   if episode==2 then target=(turn+p)%6 end
   if episode==3 then target=(turn*turn+p)%6 end
   local x=mem:read_u16(base+0x10)
   fields['P'..p..' Left']:set_value(state==0 and x>target and 1 or 0)
   fields['P'..p..' Right']:set_value(state==0 and x<target and 1 or 0)
   fields['P'..p..' Down']:set_value(state==0 and 1 or 0)
   local rotate=state==0 and not rotated[p] and mem:read_u16(base+0x1A6)>18 and turn%3~=0
   fields['P'..p..' Button 2']:set_value(rotate and 1 or 0)
   if rotate then rotated[p]=true end
  end
  if frame==2400 then next_episode() end
 end
 if total>8000 and phase~='done' then error('Limite de quadros') end
end)
