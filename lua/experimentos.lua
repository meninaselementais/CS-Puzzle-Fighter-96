-- Experimentos por quadros, somente entradas do jogo e leitura da memória.
local machine=manager.machine
local cpu=machine.devices[":maincpu"]
local space=cpu.spaces["program"]
local screen=machine.screens[":screen"]
local fields={}
for _,port in pairs(machine.ioport.ports) do
    for name,field in pairs(port.fields) do fields[name]=field end
end
local function set(name,value) assert(fields[name],name):set_value(value) end
local controlled={"P1 Left","P1 Right","P1 Down","P1 Button 1","P1 Button 2",
                  "P2 Left","P2 Right","P2 Down","P2 Button 1","P2 Button 2",
                  "Coin 1","Coin 2","1 Player Start","2 Players Start"}
for _,name in ipairs(controlled) do
    fields[name]:set_input_seq("standard",machine.input:seq_from_tokens(""))
end
local function release() for _,name in ipairs(controlled) do set(name,0) end end
release()
local portslog=assert(io.open(PF_SESSION.."/ports.csv","w"))
portslog:write("frame,in0,in2\n")
local events=assert(io.open(PF_SESSION.."/eventos.csv","w"))
events:write("case,frame,time_us,pc,p1_84f4,p2_88f4,p1_8488,p1_8542,p1_84a6,p1_ptr,p2_ptr,in0\n")
local writes=assert(io.open(PF_SESSION.."/escritas.csv","w"))
writes:write("case,frame,address,data,mask,pc,a6\n")
local debuglog=assert(io.open(PF_SESSION.."/depurador.txt","w"))
local writer_pcs={}
local cases={
 {"controle_a",nil,0,16},{"controle_b",nil,0,16},
 {"direita_a","P1 Right",1,16},{"direita_b","P1 Right",1,16},
 {"esquerda_a","P1 Left",1,16},{"esquerda_b","P1 Left",1,16},
 {"rotacao_1","P1 Button 1",1,16},{"rotacao_1_rep","P1 Button 1",1,16},
 {"rotacao_2","P1 Button 2",1,16},{"baixo_16","P1 Down",16,16},
 {"controle_48",nil,0,48},{"baixo_48","P1 Down",48,48},
 {"direita_48","P1 Right",48,48},{"esquerda_48","P1 Left",48,48},
 {"p2_direita","P2 Right",1,16},{"p2_esquerda","P2 Left",1,16},
 {"p2_rotacao","P2 Button 1",1,16},{"p2_baixo","P2 Down",16,16},
 {"rotacao_180","P1 Button 2",1,16,{5}},
 {"rotacao_completa","P1 Button 2",1,20,{5,9,13}},
 {"p2_rotacao_2","P2 Button 2",1,16},{"p2_baixo_48","P2 Down",48,48},
 {"controle_480",nil,0,480},
 {"coleta_p1","P1 Down",480,480},{"coleta_p2","P2 Down",480,480}
}
local index,step,total,flush_frames=0,0,0,0
local phase="boot"
local pending_picture=nil
local function name() return index==0 and "boot" or cases[index][1] end
local function capture(label,picture)
    local stem=name().."_"..label
    local file=assert(io.open(PF_SESSION.."/captures/"..stem..".bin","wb"))
    local data=space:read_range(0xFF0000,0xFFFFFF,8)
    assert(#data==65536)
    file:write(data);file:close()
    if picture then pending_picture=stem end
end
local function row()
    events:write(string.format("%s,%d,%d,%X,%d,%d,%d,%d,%d,%X,%X,%X\n",name(),step,
       math.floor(machine.time:as_double()*1000000+0.5),cpu.state["PC"].value,
       space:read_u16(0xFF84F4),space:read_u16(0xFF88F4),space:read_u16(0xFF8488),
       space:read_i16(0xFF8542),space:read_u16(0xFF84A6),space:read_u32(0xFF851A),space:read_u32(0xFF891A),machine.ioport.ports[":IN0"]:read()))
end
local taps={}
for _,address in ipairs({0xFF8310,0xFF8314,0xFF8470,0xFF8450,0xFF8452,0xFF8488,0xFF84F4,0xFF8542,0xFF84A6,0xFF851A,0xFF851C,
                        0xFF8710,0xFF8714,0xFF8870,0xFF8850,0xFF8852,0xFF8888,0xFF88F4,0xFF8942,0xFF88A6,0xFF891A,0xFF891C}) do
    taps[#taps+1]=space:install_write_tap(address,address+1,string.format("pf_%X",address),
        function(offset,data,mask)
            if phase=="case" then
                local pc=cpu.state["PC"].value
                writes:write(string.format("%s,%d,%X,%X,%X,%X,%X\n",name(),step,offset,data,mask,pc,cpu.state["A6"].value))
                if offset==0xFF8310 or offset==0xFF8314 or offset==0xFF8470 then writer_pcs[pc]=true end
            end
            -- Sem valor de retorno: observa sem modificar a escrita.
        end)
end
PF_taps=taps
local function next_case()
    release();index=index+1;step=0
    if index>#cases then
        if machine.debugger then
            for pc,_ in pairs(writer_pcs) do
                machine.debugger:command(string.format('dasm "%s/writer_%06X.asm",%x,60',PF_SESSION,pc,pc-0x20))
            end
        end
        events:close();writes:close()
        debuglog:close();portslog:close()
        local done=assert(io.open(PF_SESSION.."/concluido.txt","w"));done:write(tostring(#cases).." casos concluídos\n");done:close()
        machine:exit();phase="done";return
    end
    -- O estado não restaura o cache de entrada: neutralizar os ports antes de carregar.
    phase="flush";flush_frames=0
end
PF_postload=emu.add_machine_post_load_notifier(function()
    if phase~="loading" then return end
    release();step=0;capture("base",true);row()
    if machine.debugger then machine.debugger:command("trackmem 1,maincpu,1") end
    local case=cases[index]
    if case[2] then set(case[2],1) end
    phase="case"
end)
PF_frames=emu.add_machine_frame_notifier(function()
    total=total+1
    if total>=2095 and total<=2750 then portslog:write(string.format("%d,%X,%X\n",total,machine.ioport.ports[":IN0"]:read(),machine.ioport.ports[":IN2"]:read()));portslog:flush() end
    if phase=="case" then
        step=step+1;row();capture(string.format("f%03d",step),step==1 or step==cases[index][4] or (name():find("coleta") and step%32==0))
        if step>=cases[index][3] then release() end
        for _,pulse in ipairs(cases[index][5] or {}) do if step==pulse then set(cases[index][2],1) end end
        if step>=cases[index][4] then
            if machine.debugger then
                debuglog:write("CASE "..name().."\n")
                for _,address in ipairs({0xFF8310,0xFF8314,0xFF8470,0xFF8710,0xFF8714,0xFF8870}) do
                    machine.debugger:command(string.format("pcatmem %x:maincpu",address))
                    local console=machine.debugger.consolelog
                    debuglog:write(string.format("%X: %s\n",address,tostring(console[#console])))
                end
            end
            events:flush();writes:flush();next_case()
        end
    elseif phase=="flush" then
        release();flush_frames=flush_frames+1
        if flush_frames>=3 then phase="loading";machine:load("baseline.sta") end
    elseif phase=="boot" then
        if total==2100 or total==2130 then set("Coin 1",1);set("Coin 2",1) end
        if total==2116 or total==2146 then set("Coin 1",0);set("Coin 2",0) end
        if total==2200 then set("1 Player Start",1) end
        if total==2208 then set("1 Player Start",0) end
        if total==3800 then set("2 Players Start",1) end
        if total==3808 then set("2 Players Start",0) end
        if total==2300 or total==2500 or total==2700 then set("P1 Button 1",1) end
        if total==2308 or total==2508 or total==2708 then release() end
        if total==3950 or total==4150 or total==4350 then set("P1 Button 1",1);set("P2 Button 1",1) end
        if total==3958 or total==4158 or total==4358 then release() end
        if total%150==0 or total==2120 or total==2150 or total==2250 then capture(string.format("f%04d",total),true) end
        if total==5300 then release();machine:save("baseline.sta");phase="saving" end
    elseif phase=="saving" and total>=5303 then next_case() end
    if total>10000 and phase~="done" and phase~="failed" then
        phase="failed";machine:exit();error("Limite de quadros sem conclusão")
    end
end)
emu.register_frame_done(function()
    if pending_picture then
        local stem=pending_picture;pending_picture=nil
        assert(not screen:snapshot(PF_SESSION.."/snap/"..stem..".png"))
        local pixels,width,height=screen:pixels()
        local info=assert(io.open(PF_SESSION.."/video.json","w"))
        info:write(string.format('{"width":%d,"height":%d,"byteorder":"%s"}',width,height,string.pack("I2",1):byte(1)==1 and "little" or "big"));info:close()
        local file=assert(io.open(PF_SESSION.."/snap/"..stem..".argb","wb"))
        file:write(pixels);file:close()
    end
end)
