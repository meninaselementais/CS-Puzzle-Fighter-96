assert(PF_STATE)
local m=manager.machine
local phase=0
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~=1 then return end
 for _,range in ipairs({{0,0x30000}}) do
  m.debugger:command(string.format('dasm "%s/code_%X.asm",%x,%x',PF_SESSION,range[1],range[1],range[2]))
 end
 local mem=m.devices[':maincpu'].spaces.program
 local f=assert(io.open(PF_SESSION..'/tables.bin','wb'));f:write(mem:read_range(0xFF98,0x10097,8));f:close()
 phase=2
end)
PF_frame=emu.add_machine_frame_notifier(function()
 if phase==0 then phase=1;m:load(PF_STATE)
 elseif phase==2 then
  local f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write('inspecao');f:close();m:exit();phase=3
 end
end)
