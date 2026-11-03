-- Suplemento V10.3.1: somente aproximação, contato e recuperação.
-- Referência vazia é controle de fundo para subtração de pixels, não caso de física.
-- Nenhum dump de RAM/ROM é gravado; somente campos numéricos observados e PNGs.
assert(PF_STATE, 'Informe o save state validado de jogo')
local m=manager.machine
local mem=m.devices[':maincpu'].spaces.program
local screen=m.screens[':screen']
local base=0xFF8300
local fields={}
local names={'P1 Left','P1 Right','P1 Down','P1 Button 1','P1 Button 2','P2 Left','P2 Right','P2 Down','P2 Button 1','P2 Button 2'}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
for _,name in ipairs(names) do fields[name]:set_input_seq('standard',m.input:seq_from_tokens('')) end
local function release() for _,name in ipairs(names) do fields[name]:set_value(0) end end
local function u8(a) return mem:read_u8(a) end
local function u16(a) return mem:read_u16(a) end
local function s16(a) return mem:read_i16(a) end
local function u32(a) return mem:read_u32(a) end
local cases={
 {id='isolated_approach',y=14,support=false},
 {id='same_color_approach',y=13,support=true},
 {id='empty_background_reference',y=0,support=false,empty=true}
}
local case_index,frame,total,neutral,preturn=0,0,0,0,0
local stage='boot'
local pending=nil
local function title() return cases[case_index] and cases[case_index].id or 'boot' end
local function open(name,header)
 local f=assert(io.open(PF_SESSION..'/'..name,'w'));f:write(header..'\n');return f
end
local states=open('states.csv','scenario,frame,clock,phase,x,y,offset,orientation,contact,contact_count,input,previous_input,pivot,satellite,pair_age,fall_countdown,fall_interval,fall_increment,board_shake')
local sprites=open('sprites.csv','scenario,frame,clock,kind,index,col,row,address,state,previous_state,script_pointer,anim_timer,layout_flag,dx,dy,tile,attr,width_minus_one,height_minus_one,previous_width_minus_one,previous_height_minus_one,local_x,local_y,board_word,power_word')
local injected=open('injections.csv','scenario,frame,stage,address,width,before,after')
local function write(a,v,width)
 injected:write(string.format('%s,%d,%s,%06X,%d,%d,%d\n',title(),frame,stage,a,width,width==8 and u8(a) or u16(a),v))
 if width==8 then mem:write_u8(a,v&255) else mem:write_u16(a,v&65535) end
end
local function board_addr(c,r) return 0xFFAB00+r*16+2*(c+1) end
local function power_addr(c,r) return 0xFFAF00+r*16+2*(c+1) end
local function setup()
 stage='setup';release();frame=0
 -- Preserve row 14 sentinel and all pre-existing files; only synthetic emulated RAM.
 for r=0,13 do for c=0,5 do write(board_addr(c,r),0,16);write(power_addr(c,r),0,16) end end
 for i=0,77 do for off=0,30,2 do write(0xFFB400+i*32+off,0,16) end end
 write(base+0x17E,0,8)
 write(base+0x10,2,16);write(base+0x14,cases[case_index].y,16)
 write(base+0x242,-8,16);write(base+0x170,0,8);write(base+0x176,0,8)
 write(base+0x152,cases[case_index].empty and 0 or 1,16)
 write(base+0x154,cases[case_index].empty and 0 or 3,16)
 write(base+0x140,0,16);write(base+0x142,0,16);write(base+0x188,0,16)
 write(base+0x1A6,32,16);write(base+0x1A8,0,8);write(base+0x15E,0,8)
 write(base+0x27E,0,8);write(base+0x247,0,8);write(base+0x248,0,16)
 write(base+0x24A,0,16);write(base+0x24C,0,16);write(base+0x314,0,16)
 write(base+0x316,0,8);write(base+0x175,0,8);write(base+0x252,0,8)
 write(base+0x32A,0,16);write(base+0x19E,0,8);write(0xFF889E,0,8)
 if cases[case_index].support then write(board_addr(2,13),1,16) end
 -- Native speed after the same pre-turn as the validated collector, no speed rewrite.
 assert(u8(base+0x18A)==1 and s16(base+0x27C)==1,'Unexpected native fall speed')
 injected:flush();stage='running'
end
local function sprite(clock,kind,index,c,r,a)
 local values={title(),frame,clock,kind,index,c,r,string.format('%06X',a),u16(a),u16(a+2),u32(a+4),s16(a+8),u16(a+10),s16(a+12),s16(a+14),u16(a+16),u16(a+18),u8(a+20),u8(a+21),u8(a+22),u8(a+23),u8(a+24),u8(a+25),kind=='cell' and u16(board_addr(c,r)) or 0,kind=='cell' and u16(power_addr(c,r)) or 0}
 for i,v in ipairs(values) do values[i]=tostring(v) end
 sprites:write(table.concat(values,',')..'\n')
end
local function record(clock)
 local values={title(),frame,clock,u8(base+0x17E),u16(base+0x10),u16(base+0x14),s16(base+0x242),u8(base+0x170),u8(base+0x176),u8(base+0x1A8),u16(base+0x140),u16(base+0x142),u16(base+0x152),u16(base+0x154),u16(base+0x1A6),u8(base+0x15E),u8(base+0x18A),s16(base+0x27C),s16(base+0x32A)}
 for i,v in ipairs(values) do values[i]=tostring(v) end
 states:write(table.concat(values,',')..'\n')
 -- P1 active pivot/satellite and NEXT pivot/satellite, all four descriptors.
 for i=0,3 do sprite(clock,'active_next',i,-1,-1,0xFFB300+i*32) end
 for r=8,13 do for c=0,5 do sprite(clock,'cell',(r-1)*6+c,c,r,0xFFB400+((r-1)*6+c)*32) end end
 states:flush();sprites:flush()
end
local function next_case()
 case_index=case_index+1;frame=0;neutral=0;release()
 if case_index>#cases then
  states:close();sprites:close();injected:close()
  local f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write('3 supplementary cases; 96 CPU/video samples each; all final snapshots completed\n');f:close()
  stage='done';m:exit()
 else stage='neutral' end
end
PF_loaded=emu.add_machine_post_load_notifier(function()
 if stage~='loading' then return end
 release();preturn=u16(base+0x1A0);fields['P1 Down']:set_value(1);stage='precondition'
end)
PF_frames=emu.add_machine_frame_notifier(function()
 total=total+1
 if stage=='boot' then next_case()
 elseif stage=='neutral' then
  release();neutral=neutral+1;if neutral>=3 then stage='loading';m:load(PF_STATE) end
 elseif stage=='precondition' then
  if u16(base+0x1A0)>preturn and u8(base+0x17E)==0 and u16(base+0x14)>=2 then release();neutral=0;stage='settle_input' end
 elseif stage=='settle_input' then
  release();neutral=neutral+1;if neutral>=4 then setup() end
 elseif stage=='running' then
  release();frame=frame+1;record('cpu');pending=title()..string.format('_f%03d',frame)
  stage='await_video'
 elseif stage=='advance' then next_case()
 end
 if total>10000 and stage~='done' then error('Supplement timeout: '..stage) end
end)
emu.register_frame_done(function()
 if stage~='await_video' then return end
 record('video')
 assert(not screen:snapshot(PF_SESSION..'/snap/'..pending..'.png'))
 pending=nil
 stage=frame>=96 and 'advance' or 'running'
end)
