-- Tabuleiros sintéticos somente na RAM da cópia de laboratório; nenhuma ROM é alterada.
assert(PF_STATE,"Informe --state com o estado reproduzível já coletado")
local m=manager.machine
local cpu=m.devices[":maincpu"]
local mem=cpu.spaces.program
local screen=m.screens[":screen"]
local fields={}
for _,port in pairs(m.ioport.ports) do for name,field in pairs(port.fields) do fields[name]=field end end
local names={"P1 Left","P1 Right","P1 Down","P1 Button 1","P1 Button 2","P2 Left","P2 Right","P2 Down","P2 Button 1","P2 Button 2"}
for _,name in ipairs(names) do fields[name]:set_input_seq("standard",m.input:seq_from_tokens("")) end
local function release() for _,name in ipairs(names) do fields[name]:set_value(0) end end
release()
local function rectangle(x,y,w,h,color)
    local result={}
    for row=y,y+h-1 do for col=x,x+w-1 do result[#result+1]={col,row,color} end end
    return result
end
local cases={
 {name="control",cells={}},
 {name="power_2x2",cells=rectangle(0,12,2,2,3)},
 {name="power_3x2",cells=rectangle(0,12,3,2,3)},
 {name="power_2x3",cells=rectangle(0,11,2,3,3)},
 {name="power_4x2",cells=rectangle(0,12,4,2,3),drop_x=5},
 {name="line_1x4",cells=rectangle(0,10,1,4,3)},
 {name="power_L",cells={{0,13,3},{1,13,3},{0,12,3},{0,11,3}}},
 {name="crash_red4",cells=rectangle(4,10,1,4,4)},
 {name="crash_pair",cells={{4,10,12},{4,11,3},{4,12,3},{4,13,3}}},
 {name="crash_diagonal",cells={{4,9,4},{4,10,1},{4,11,1},{4,12,1},{4,13,1}}},
 {name="power_crash4",cells=rectangle(4,12,2,2,4),rotate=true},
 {name="power_crash6",cells=rectangle(4,11,2,3,4),rotate=true},
 {name="attack_red8",cells=rectangle(4,6,1,8,4),rotate=true,frames=480},
 {name="attack_red12",cells=rectangle(4,8,2,6,4),rotate=true,frames=480},
 {name="topout_center",cells=rectangle(3,2,1,10,1),drop_x=0},
 {name="topout_side",cells=rectangle(0,2,1,12,1),drop_x=5},
 {name="power_growth",cells=rectangle(0,12,2,2,3),stage2={{0,11,3},{1,11,3}},frames=360},
 {name="power_union",cells={{0,12,3},{1,12,3},{0,13,3},{1,13,3},{3,12,3},{4,12,3},{3,13,3},{4,13,3}},drop_x=5,stage2={{2,12,3},{2,13,3}},frames=360},
 {name="gravity_after_clear",cells={{4,9,1},{4,10,4},{4,11,4},{4,12,4},{4,13,4}}},
 {name="chain_2",cells={{4,9,1},{4,10,4},{4,11,4},{4,12,4},{4,13,4},{5,13,9}},frames=480},
 {name="combo_two_colors",cells={{4,10,4},{4,11,4},{4,12,4},{4,13,4},{0,13,1},{1,13,9}},frames=480},
 {name="counter_adjacent_same",cells={{4,10,4},{4,11,4},{4,12,4},{4,13,4},{5,12,0x4507},{5,13,1}}},
 {name="counter_adjacent_other",cells={{4,10,4},{4,11,4},{4,12,4},{4,13,4},{5,12,0x1507},{5,13,1}}},
 {name="counter_countdown",cells={{0,13,0x2507}},drop_x=2,cycles=true,frames=900},
 {name="attack_cancel",cells=rectangle(4,10,1,4,4),cells2=rectangle(4,10,1,4,4),both=true,frames=480},
 {name="counter_spread",cells={{4,10,4},{4,11,4},{4,12,4},{4,13,4},{2,13,0x2507},{1,13,0x3507}}},
 {name="counter_diagonal",cells={{4,10,4},{4,11,4},{4,12,4},{4,13,4},{2,12,0x2507},{2,13,1}}},
 {name="power_rigid_gravity",cells={{0,10,3},{1,10,3},{0,11,3},{1,11,3},{0,12,12},{0,13,4},{1,12,1},{1,13,1}},drop_x=5},
 {name="attack_p2_red12",cells={},cells2=rectangle(4,8,2,6,4),both=true,rotate2=true,frames=480},
 {name="holdout_blue_power4",cells={{0,12,1},{1,12,1},{0,13,1},{1,13,1},{2,13,9}}},
 {name="holdout_green_power6",cells={{0,11,3},{1,11,3},{0,12,3},{1,12,3},{0,13,3},{1,13,3},{2,13,11}}},
}
for n=1,8 do cases[#cases+1]={name="score_normal_"..n,cells=rectangle(4,14-n,1,n,4),rotate=true,frames=300} end
for _,size in ipairs({{2,4},{2,5},{3,3},{3,4},{4,4},{5,2},{3,5},{4,5},{4,6},{5,5},{5,6},{6,6}}) do
 cases[#cases+1]={name="calibrate_power_"..size[1].."x"..size[2],cells=rectangle(6-size[1],14-size[2],size[1],size[2],4),rotate=true}
end
for _,size in ipairs({{3,6},{3,7},{3,8},{3,9},{4,7},{3,10},{4,8},{5,7},{4,10},{6,7},{6,8}}) do
 cases[#cases+1]={name="holdout_power_"..size[1].."x"..size[2],cells=rectangle(6-size[1],14-size[2],size[1],size[2],4),rotate=true}
end
for _,incoming in ipairs({3,6,10}) do
 cases[#cases+1]={name="cancel_pending_"..incoming,cells=rectangle(4,10,1,4,4),pending=incoming,frames=300}
end
for _,size in ipairs({{2,7},{2,8},{5,8},{6,4}}) do
 cases[#cases+1]={name="area_check_"..size[1].."x"..size[2],cells=rectangle(6-size[1],14-size[2],size[1],size[2],4),rotate=true}
end
for _,incoming in ipairs({3,6,10}) do
 cases[#cases+1]={name="cancel_late_"..incoming,cells=rectangle(4,10,1,4,4),late_pending=incoming,frames=300}
end
for _,sizes in ipairs({{1,4},{4,8},{1,8},{8,4},{4,4},{8,8},{4,3},{4,5},{8,6}}) do
 cases[#cases+1]={name="counterattack_"..sizes[1].."_"..sizes[2],cells=rectangle(4,14-sizes[1],1,sizes[1],4),cells2=rectangle(4,14-sizes[2],1,sizes[2],4),both=true,delay2=30,frames=360}
end
local log=assert(io.open(PF_SESSION.."/mechanics.csv","w"))
log:write("case,frame,state1,state2,turn1,turn2,rotation1,score1,score2,pending1,pending2,grid1,grid2,aux1,aux2\n")
local injected=assert(io.open(PF_SESSION.."/injection.csv","w"))
injected:write("case,address,before,after\n")
local taps,pc_seen={},{}
local writers=assert(io.open(PF_SESSION.."/board_writers.csv","w"))
writers:write("case,frame,address,data,mask,pc,a6\n")
local scorelog=assert(io.open(PF_SESSION.."/score_writers.csv","w"))
scorelog:write("case,frame,before,low_word,pc,a6,d0,d1,d2,d3,return1,return2\n")
local score_pcs={}
local index,frame,total,neutral=0,0,0,0
local phase="start"
local turn0=0
local turn2=0
local pending=nil
local function title() return cases[index] and cases[index].name or "boot" end
local function encode(base)
    local values={}
    for y=0,13 do for x=0,5 do values[#values+1]=string.format("%04X",mem:read_u16(base+y*16+2*(x+1))) end end
    return table.concat(values,":")
end
local function snap(suffix,picture)
    local stem=title().."_"..suffix
    local f=assert(io.open(PF_SESSION.."/captures/"..stem..".bin","wb"))
    f:write(mem:read_range(0xFF0000,0xFFFFFF,8));f:close()
    if picture then pending=stem end
end
local function write_word(address,value)
    injected:write(string.format("%s,%X,%X,%X\n",title(),address,mem:read_u16(address),value))
    mem:write_u16(address,value)
end
local function seed()
    local case=cases[index]
    for _,cell in ipairs(case.cells) do
        assert(cell[1]>=0 and cell[1]<6 and cell[2]>=0 and cell[2]<14)
        write_word(0xFFAB00+cell[2]*16+2*(cell[1]+1),cell[3])
    end
    for _,cell in ipairs(case.cells2 or {}) do write_word(0xFFAD00+cell[2]*16+2*(cell[1]+1),cell[3]) end
    if case.drop_x then write_word(0xFF8310,case.drop_x) end
    if case.pending then write_word(0xFF857A,case.pending) end
end
PF_taps=taps
taps[2]=mem:install_write_tap(0xFF83AA,0xFF83AD,"pf_scores",function(address,data,mask)
    if phase~="case" then return end
    local pc=cpu.state.PC.value
    local sp=cpu.state.A7.value
    score_pcs[pc]=true
    score_pcs[mem:read_u32(sp)]=true
    scorelog:write(string.format("%s,%d,%d,%d,%X,%X,%X,%X,%X,%X,%X,%X\n",title(),frame,mem:read_u32(0xFF83AA),data,
      pc,cpu.state.A6.value,cpu.state.D0.value,cpu.state.D1.value,cpu.state.D2.value,cpu.state.D3.value,mem:read_u32(sp),mem:read_u32(sp+4)))
end)
taps[1]=mem:install_write_tap(0xFFAB00,0xFFB2FF,"pf_mechanics",function(address,data,mask)
    if phase~="case" then return end
    local pc=cpu.state.PC.value
    local key=string.format("%X:%X:%X",pc,address,data)
    if not pc_seen[key] then
        pc_seen[key]=true
        writers:write(string.format("%s,%d,%X,%X,%X,%X,%X\n",title(),frame,address,data,mask,pc,cpu.state.A6.value))
    end
end)
local function next_case()
    release();index=index+1;frame=0;neutral=0
    if index>#cases then
        phase="done"
        if m.debugger then
            for pc,_ in pairs(score_pcs) do if pc>0x100 and pc<0x400000 then
                m.debugger:command(string.format('dasm "%s/score_%06X.asm",%x,100',PF_SESSION,pc,pc-0x40))
            end end
        end
        log:close();writers:close();injected:close();scorelog:close()
        local done=assert(io.open(PF_SESSION.."/concluido.txt","w"));done:write(tostring(#cases).." cenários de mecânicas\n");done:close()
        m:exit();return
    end
    phase="neutral"
end
PF_loaded=emu.add_machine_post_load_notifier(function()
    if phase~="loading" then return end
    for _,tap in pairs(taps) do tap:reinstall() end
    release();snap("source",false);seed();snap("seed",true)
    turn0=mem:read_u16(0xFF84A0)
    turn2=mem:read_u16(0xFF88A0)
    if cases[index].rotate then fields["P1 Button 2"]:set_value(1) end
    if cases[index].rotate2 then fields["P2 Button 2"]:set_value(1) end
    fields["P1 Down"]:set_value(1)
    if cases[index].both and not cases[index].delay2 then fields["P2 Down"]:set_value(1) end
    phase="case"
end)
PF_frames=emu.add_machine_frame_notifier(function()
    total=total+1
    if phase=="start" and total>=5 then next_case()
    elseif phase=="neutral" then
        release();neutral=neutral+1
        if neutral>=3 then phase="loading";m:load(PF_STATE) end
    elseif phase=="case" then
        frame=frame+1
        if frame>=1 then fields["P1 Button 2"]:set_value(0);fields["P2 Button 2"]:set_value(0) end
        if frame==105 and cases[index].late_pending then write_word(0xFF857A,cases[index].late_pending) end
        if frame==cases[index].delay2 then fields["P2 Down"]:set_value(1) end
        if mem:read_u16(0xFF84A0)~=turn0 then fields["P1 Down"]:set_value(0) end
        if mem:read_u16(0xFF88A0)~=turn2 then fields["P2 Down"]:set_value(0) end
        if cases[index].stage2 and frame==120 then
            phase="inject"
            for _,cell in ipairs(cases[index].stage2) do write_word(0xFFAB00+cell[2]*16+2*(cell[1]+1),cell[3]) end
            write_word(0xFF8310,5);turn0=mem:read_u16(0xFF84A0)
            fields["P1 Down"]:set_value(1);phase="case";snap("stage2",true)
        end
        if cases[index].cycles and frame%180==0 and frame<800 then
            phase="inject"
            local columns={4,1,5,3}
            write_word(0xFF8310,columns[frame//180]);turn0=mem:read_u16(0xFF84A0)
            fields["P1 Down"]:set_value(1);phase="case"
        end
        log:write(string.format("%s,%d,%X,%X,%d,%d,%d,%d,%d,%d,%d,%s,%s,%s,%s\n",title(),frame,
            mem:read_u16(0xFF8300),mem:read_u16(0xFF8700),mem:read_u16(0xFF84A0),mem:read_u16(0xFF88A0),
            mem:read_u8(0xFF8470),mem:read_u32(0xFF83AA),mem:read_u32(0xFF87AA),mem:read_u16(0xFF857A),mem:read_u16(0xFF897A),encode(0xFFAB00),encode(0xFFAD00),encode(0xFFAF00),encode(0xFFB100)))
        local last=cases[index].frames or 240
        if frame==1 or frame%6==0 or frame==last then snap(string.format("f%04d",frame),frame%30==0 or frame==1 or frame==last) end
        if frame>=last then log:flush();writers:flush();injected:flush();next_case() end
    end
    if total>40000 and phase~="done" and phase~="failed" then phase="failed";m:exit();error("Limite de quadros") end
end)
emu.register_frame_done(function()
    if pending then
        local stem=pending;pending=nil
        assert(not screen:snapshot(PF_SESSION.."/snap/"..stem..".png"))
    end
end)
