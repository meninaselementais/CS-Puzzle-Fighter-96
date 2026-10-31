assert(PF_STATE)
local m=manager.machine;local mem=m.devices[':maincpu'].spaces.program
local phase=0;local frame=0
PF_loaded=emu.add_machine_post_load_notifier(function()
 if phase~=1 then return end
 m.devices[':maincpu'].debug:bpset(0x2DB6A,'1','logerror "GLOBAL_IN,%X,%X,%X",a5,a6,w@(a5+ae);g')
 m.devices[':maincpu'].debug:bpset(0x2DB82,'1','logerror "GLOBAL_OUT,%X,%X,%X",a5,a6,w@(a5+ae);g')
 m.devices[':maincpu'].debug:bpset(0x122EC,'1','logerror "PIECE_IN,%X,%X",a6,w@(a6+144);g')
 m.devices[':maincpu'].debug:bpset(0x12312,'1','logerror "PIECE_OUT,%X,%X",a6,w@(a6+144);g')
 phase=2
end)
PF_frame=emu.add_machine_frame_notifier(function()
 if phase==0 then phase=1;m:load(PF_STATE)
 elseif phase==2 then
  frame=frame+1
  if frame==450 then
   local f=assert(io.open(PF_SESSION..'/rng_native.txt','w'))
   for _,line in ipairs(m.debugger.errorlog) do f:write(line,'\n') end
   f:close();f=assert(io.open(PF_SESSION..'/concluido.txt','w'));f:write('rng');f:close();phase=3;m:exit()
  end
 end
end)
