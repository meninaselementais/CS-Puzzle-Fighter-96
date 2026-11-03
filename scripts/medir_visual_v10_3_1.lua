-- v10_3_1_mame_probe.lua
-- Medições Visuais Reprodutíveis no MAME 0.289 para V10.3.1
-- Extrai tabelas de ROM ($12D00, $12DA0, $040000) e mede quadro a quadro os descritores
-- visuais de hardware ($FFB300, $FFB400, $FFAB00, $FFAF00) em cenários controlados.

assert(PF_STATE, "Informe --state com o estado reproduzivel")
local m = manager.machine
local cpu = m.devices[":maincpu"]
local mem = cpu.spaces.program
local screen = m.screens[":screen"]
local out_dir = PF_SESSION or "."

local fields = {}
for _, port in pairs(m.ioport.ports) do
    for name, field in pairs(port.fields) do
        fields[name] = field
    end
end
local input_names = {
    "P1 Left", "P1 Right", "P1 Down", "P1 Button 1", "P1 Button 2",
    "P2 Left", "P2 Right", "P2 Down", "P2 Button 1", "P2 Button 2"
}
for _, name in ipairs(input_names) do
    fields[name]:set_input_seq("standard", m.input:seq_from_tokens(""))
end
local function release()
    for _, name in ipairs(input_names) do
        fields[name]:set_value(0)
    end
end
release()

local P1 = 0xFF8300
local P1_BOARD = 0xFFAB00
local P1_PGEM  = 0xFFAF00
local P1_PAIR_SPR = 0xFFB300
local P1_CELL_SPR = 0xFFB400

local function u8(addr) return mem:read_u8(addr) end
local function s8(addr) return mem:read_i8(addr) end
local function u16(addr) return mem:read_u16(addr) end
local function s16(addr) return mem:read_i16(addr) end
local function u32(addr) return mem:read_u32(addr) end
local function s32(addr) return mem:read_i32(addr) end

local injections = assert(io.open(out_dir.."/injections.csv","w"))
injections:write("address,width,before,after\n")
local function logwrite(a,width,v)
 injections:write(string.format("%06X,%d,%d,%d\n",a,width,width==8 and u8(a) or (width==16 and u16(a) or u32(a)),v));injections:flush()
end
local function w8(addr, val) logwrite(addr,8,val);mem:write_u8(addr, val & 0xFF) end
local function w16(addr, val) logwrite(addr,16,val);mem:write_u16(addr, val & 0xFFFF) end
local function w32(addr, val) logwrite(addr,32,val);mem:write_u32(addr, val & 0xFFFFFFFF) end

local function board_addr(col, row)
    return P1_BOARD + (row * 0x10) + 2 + (col * 2)
end

local function pgem_addr(col, row)
    return P1_PGEM + (row * 0x10) + 2 + (col * 2)
end

local function cell_spr_addr(col, row)
    return P1_CELL_SPR + ((row - 1) * 6 + col) * 0x20
end

local function clear_board()
    for r = 0, 13 do
        for c = 0, 5 do
            w16(board_addr(c, r), 0)
            w16(pgem_addr(c, r), 0)
        end
    end
    for idx = 0, 77 do
        local a = P1_CELL_SPR + idx * 0x20
        for off = 0, 0x1E, 2 do
            w16(a + off, 0)
        end
    end
end

local function read_cell_spr(col, row)
    local a = cell_spr_addr(col, row)
    return {
        state_id = u16(a + 0x00),
        prev_state_id = u16(a + 0x02),
        script_ptr = u32(a + 0x04),
        anim_timer = s16(a + 0x08),
        layout_flag = u16(a + 0x0A),
        dx = s16(a + 0x0C),
        dy = s16(a + 0x0E),
        tile = u16(a + 0x10),
        attr = u16(a + 0x12),
        pw_cur_w = u8(a + 0x14),
        pw_cur_h = u8(a + 0x15),
        pw_prev_w = u8(a + 0x16),
        pw_prev_h = u8(a + 0x17),
        pw_cell_x = u8(a + 0x18),
        pw_cell_y = u8(a + 0x19),
        board_word = u16(board_addr(col, row)),
        pgem_word = u16(pgem_addr(col, row))
    }
end

local function dump_rotation_tables()
    local f = assert(io.open(out_dir .. "/rotation_tables_12D00_12DA0.csv", "w"))
    f:write("table_name,table_addr,d1_index,t_index,frame_step,dx,dy,dx_hex,dy_hex\n")
    local tables = {
        {name = "12D00_CCW_AND_CORRIDOR", addr = 0x012D00, count = 5},
        {name = "12DA0_CW", addr = 0x012DA0, count = 4}
    }
    for _, tb in ipairs(tables) do
        for d1 = 0, tb.count - 1 do
            local group_base = tb.addr + (d1 * 32)
            for t = 7, 0, -1 do
                local step = 8 - t
                local dx_addr = group_base + (t * 2)
                local dy_addr = group_base + 16 + (t * 2)
                local dx = s16(dx_addr)
                local dy = s16(dy_addr)
                local dx_u = u16(dx_addr)
                local dy_u = u16(dy_addr)
                f:write(string.format("%s,0x%05X,%d,%d,%d,%d,%d,0x%04X,0x%04X\n",
                    tb.name, tb.addr, d1, t, step, dx, dy, dx_u, dy_u))
            end
        end
    end
    f:close()
end

local trace_log = assert(io.open(out_dir .. "/visual_trace_v10_3_1.csv", "w"))
trace_log:write("scenario,frame,note,phase,x,y,offset,rot,contact,clear_timer,rot_dir,rot_dx,rot_dy,rot_timer,shake_y,c1,c2,input,previous_input,ai_flag,cells_detail\n")
local video_trace=assert(io.open(out_dir.."/video_trace.csv","w"))
video_trace:write("scenario,frame,note,phase,x,y,offset,rot,contact,clear_timer,rot_dir,rot_dx,rot_dy,rot_timer,shake_y,c1,c2,input,previous_input,ai_flag,cells_detail\n")


local video = assert(io.open(out_dir.."/video_clock.csv","w"))
video:write("stem,phase,contact,rot,rot_timer,rot_dx,rot_dy,clear_timer\n")
local pending_snap = nil
local function request_snap(stem)
    pending_snap = stem
end

local function record_frame(scenario_id, sub_step, note, watched_cells, output_log)
    local p1_phase = u8(P1 + 0x17E)
    local p1_x = s16(P1 + 0x010)
    local p1_y = s16(P1 + 0x014)
    local p1_off = s16(P1 + 0x242)
    local p1_rot = u8(P1 + 0x170)
    local p1_contact = u8(P1 + 0x176)
    local p1_clear_timer = u8(P1 + 0x175)
    local p1_rot_dir = u8(P1 + 0x247)
    local p1_rot_dx = s16(P1 + 0x248)
    local p1_rot_dy = s16(P1 + 0x24A)
    local p1_rot_timer = s16(P1 + 0x24C)
    local p1_shake_y = s16(P1 + 0x32A)
    local p1_c1 = u16(P1 + 0x152)
    local p1_c2 = u16(P1 + 0x154)

    local cell_parts = {}
    for _, coord in ipairs(watched_cells or {}) do
        local c, r = coord[1], coord[2]
        local cs = read_cell_spr(c, r)
        cell_parts[#cell_parts + 1] = string.format(
            "(%d,%d):bw=%04X|pg=%04X|st=%02X/%02X|ptr=%06X|tm=%d|fl=%04X|d=(%d,%d)|tl=%04X|at=%04X|pw=%dx%d<-%dx%d@(%d,%d)",
            c, r, cs.board_word, cs.pgem_word, cs.state_id, cs.prev_state_id,
            cs.script_ptr, cs.anim_timer, cs.layout_flag, cs.dx, cs.dy,
            cs.tile, cs.attr, cs.pw_cur_w, cs.pw_cur_h, cs.pw_prev_w, cs.pw_prev_h,
            cs.pw_cell_x, cs.pw_cell_y
        )
    end
    (output_log or trace_log):write(string.format(
        "%s,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,0x%04X,0x%04X,%d,%d,%d,\"%s\"\n",
        scenario_id, sub_step, note, p1_phase, p1_x, p1_y, p1_off, p1_rot,
        p1_contact, p1_clear_timer, p1_rot_dir, p1_rot_dx, p1_rot_dy,
        p1_rot_timer, p1_shake_y, p1_c1, p1_c2, u16(P1+0x140),u16(P1+0x142),u8(P1+0x9E),table.concat(cell_parts, "; ")
    ))
end

local function reset_p1_falling(x, y, rot, c1, c2)
    w8(P1 + 0x17E, 0)
    w16(P1 + 0x010, x)
    w16(P1 + 0x014, y)
    w16(P1 + 0x242, 0)
    w8(P1 + 0x170, rot)
    w8(P1 + 0x176, 0)
    w16(P1 + 0x152, c1)
    w16(P1 + 0x154, c2)
    w8(P1 + 0x247, 0)
    w16(P1 + 0x248, 0)
    w16(P1 + 0x24A, 0)
    w16(P1 + 0x24C, 0)
    w16(P1 + 0x32A, 0)
end

local scenarios = {}
local watched = {}
for r=8,13 do for c=0,5 do watched[#watched+1]={c,r} end end
local function put(c,r,v) w16(board_addr(c,r),v) end
local function base(x,y,r,c1,c2)
 clear_board(); reset_p1_falling(x,y,r,c1,c2)
 w16(P1+0x140,0);w16(P1+0x142,0);w16(P1+0x188,0)
 w8(P1+0x15E,100);w16(P1+0x1A6,32);w8(P1+0x1A8,0)
 w16(P1+0x314,0);w8(P1+0x316,0);w8(P1+0x175,0)
 w8(P1+0x252,0);w8(P1+0x19E,0);w8(0xFF889E,0)
end
local function add(name,init,frames,step)
 scenarios[#scenarios+1]={name=name,init=init,step=function(f)
  if step then step(f) end
  record_frame(name,f,"corrected_probe",watched)
  request_snap(name..string.format("_f%03d",f))
  return f>=frames
 end}
end
for r=0,3 do
 for _,button in ipairs({1,2}) do
  local rr,bb=r,button
  add("rotation_r"..rr.."_b"..bb,function() base(2,7,rr,1,2) end,18,function(f)
   fields["P1 Button "..bb]:set_value(f==2 and 1 or 0)
  end)
 end
end
for _,button in ipairs({1,2}) do
 local bb=button
 add("corridor_b"..bb,function()
  base(2,7,0,1,2)
  for r=4,13 do put(1,r,3);put(3,r,4) end
 end,18,function(f) fields["P1 Button "..bb]:set_value(f==2 and 1 or 0) end)
end
add("landing_contact",function()
 base(2,14,0,1,3); w8(P1+0x15E,0)
end,85)
add("landing_same_color",function()
 base(2,13,0,1,3);put(2,13,1);w8(P1+0x15E,0)
end,85)
add("split_fall",function()
 base(2,11,1,1,2)
 for r=11,13 do put(2,r,4) end
 put(3,13,2);w8(P1+0x176,2)
end,65)
local function power_base()
 base(5,14,0,3,4)
 put(0,12,1);put(1,12,1);put(0,13,1);put(1,13,1)
 w8(P1+0x17E,3)
end
add("power_2x2",power_base,65)
add("power_2x3",power_base,100,function(f)
 if f==35 then put(0,11,1);put(1,11,1);w8(P1+0x17E,3) end
end)
add("power_union_5x2",function()
 power_base();put(3,12,1);put(4,12,1);put(3,13,1);put(4,13,1)
end,100,function(f)
 if f==35 then put(2,12,1);put(2,13,1);w8(P1+0x17E,3) end
end)
add("explosion_simple",function()
 base(3,6,0,2,12)
 put(3,13,2);put(2,13,2);put(1,13,2);put(0,13,10)
 w8(P1+0x17E,3)
end,130)
add("explosion_chain_2",function()
 base(3,6,0,2,12)
 put(4,9,1);put(4,10,4);put(4,11,4);put(3,12,2)
 put(4,12,4);put(3,13,4);put(4,13,4);put(5,13,9)
 w8(P1+0x15E,0)
end,290,function(f) fields["P1 Down"]:set_value(f<30 and 1 or 0) end)
-- Original scenario block omitted; preserved byte-for-byte in gemini_probe_preservado.lua.
local unused_scenarios = {}

local scen_idx = 0
local scen_frame = 0
local total_frames = 0
local state_phase = "boot"
local neutral_ticks = 0
local preturn = 0

local function next_scenario()
    release()
    scen_idx = scen_idx + 1
    scen_frame = 0
    neutral_ticks = 0
    if scen_idx > #scenarios then
        state_phase = "done"
        trace_log:close()
        local done = assert(io.open(out_dir .. "/concluido.txt", "w"))
        done:write(string.format("%d cenarios visuais V10.3.1 concluidos\n", #scenarios))
        done:close()
        m:exit()
        return
    end
    state_phase = "neutral"
end

PF_loaded = emu.add_machine_post_load_notifier(function()
    if state_phase ~= "loading" then return end
    release()
    preturn = u16(P1+0x1A0)
    fields["P1 Down"]:set_value(1)
    state_phase = "precondition"
end)

PF_frames = emu.add_machine_frame_notifier(function()
    total_frames = total_frames + 1
    if state_phase == "boot" and total_frames >= 5 then
        dump_rotation_tables()
        next_scenario()
    elseif state_phase == "neutral" then
        release()
        neutral_ticks = neutral_ticks + 1
        if neutral_ticks >= 3 then
            state_phase = "loading"
            m:load(PF_STATE)
        end
    elseif state_phase == "precondition" then
        if u16(P1+0x1A0)>preturn and u8(P1+0x17E)==0 and u16(P1+0x14)>=2 then
            release();scenarios[scen_idx].init();state_phase="running"
        end
    elseif state_phase == "running" then
        scen_frame = scen_frame + 1
        local finished = scenarios[scen_idx].step(scen_frame)
        if finished then
            trace_log:flush()
            next_scenario()
        end
    end
    if total_frames > 10000 and state_phase ~= "done" then
        state_phase = "done"
        trace_log:close()
        m:exit()
    end
end)

emu.register_frame_done(function()
    if pending_snap then
        local stem = pending_snap
        pending_snap = nil
        video:write(string.format("%s,%d,%d,%d,%d,%d,%d,%d\n",stem,u8(P1+0x17E),u8(P1+0x176),u8(P1+0x170),s16(P1+0x24C),s16(P1+0x248),s16(P1+0x24A),u8(P1+0x175)))
        video:flush()
        record_frame(stem:match("^(.*)_f%d+$"),tonumber(stem:match("_f(%d+)$")),"video",watched,video_trace);video_trace:flush()
        screen:snapshot(out_dir .. "/snap/" .. stem .. ".png")
    end
end)
