-- Entradas lógicas e observação; nenhuma escrita direta na RAM/ROM.
local machine = manager.machine
local space = machine.devices[":maincpu"].spaces["program"]
local screen = machine.screens[":screen"]
local fields = {}
local inputs = assert(io.open(PF_SESSION .. "/inputs.txt", "w"))
for tag,port in pairs(machine.ioport.ports) do
    for name,field in pairs(port.fields) do
        inputs:write(string.format("%s\t%s\t%X\n",tag,name,field.mask))
        fields[name]=field
    end
end
inputs:close()
local log=assert(io.open(PF_SESSION .. "/frames.csv","w"))
log:write("frame,time,pc,p1_84f4,p2_88f4,p1_8488,p1_8542,p1_84a6,p1_ptr,p2_ptr\n")
local n=0
local function press(name,on)
    assert(fields[name],"Campo ausente: "..name):set_value(on and 1 or 0)
end
local function capture()
    local stem=string.format("frame_%04d",n)
    local file=assert(io.open(PF_SESSION.."/captures/"..stem..".bin","wb"))
    file:write(space:read_range(0xFF0000,0xFFFFFF,8)); file:close()
    assert(not screen:snapshot(PF_SESSION.."/snap/"..stem..".png"))
end
PF_frame_subscription=emu.add_machine_frame_notifier(function()
    n=n+1
    if n==600 or n==630 then press("Coin 1",true) end
    if n==602 or n==632 then press("Coin 1",false) end
    if n==700 or n==900 or n==1100 then press("1 Player Start",true) end
    if n==702 or n==902 or n==1102 then press("1 Player Start",false) end
    if n==800 or n==1000 or n==1200 then press("P1 Button 1",true) end
    if n==802 or n==1002 or n==1202 then press("P1 Button 1",false) end
    log:write(string.format("%d,%.9f,%X,%d,%d,%d,%d,%d,%X,%X\n",n,machine.time:as_double(),
        machine.devices[":maincpu"].state["PC"].value,space:read_u16(0xFF84F4),space:read_u16(0xFF88F4),
        space:read_u16(0xFF8488),space:read_i16(0xFF8542),space:read_u16(0xFF84A6),
        space:read_u32(0xFF851A),space:read_u32(0xFF891A)))
    if n%150==0 then capture();log:flush() end
    if n==1800 then
        log:close()
        local done=assert(io.open(PF_SESSION.."/concluido.txt","w"));done:write("piloto concluído\n");done:close()
        machine:exit()
    end
end)
