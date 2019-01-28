pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- of ineffable nature
-- team spook

ggen = {}

g_player_died = false
g_died_init = false

g_drawing_text = false
twoi = false
g_text_is_diary = false

dbfp = false

mspl = true

camera_x = 0
camera_y = 0

atrs = {}
areas = {}
text_queue = {}
text_displaying = {}

jtel = false
psgfw = false
fade_screen_x = 0
fade_screen_y = 0
fsftm = 0

haxe = false

lightning_chance = 10
lightning_chance_timer = 0

function _init()

    pl = add_atr(24,256,0)
    pl.isplayer = true
    
    sll(g_light_default)

    add_game_maps()
    icts()

    init_flow()

end

function _update()

    update_flow()

    if pl.health <= 0 then
        g_player_died = true
    else
        if mspl then 
            if current_sfx == sfx_enemy_close or current_sfx == sfx_enemy_very_close then
                music(-1, 500, 8)
                mspl = false
            end
        else
            if current_sfx != sfx_enemy_close and current_sfx != sfx_enemy_very_close then
                music(0, 500, 8)
                mspl = true
            end
        end
    end

    if g_player_died then
        if not g_died_init then
            g_died_init = true
            
            sfx(-1, 2)
            stop_sfx()
            music(-1, 300)

            sfx(15)

            wait(15)

            psgfw = true
            fade_screen_x = 0
            fade_screen_y = 0

        end

        if fade_screen_y >= 127 then
            wait(15)
            printh('nointro', '@clip')

            run()
        end
    end

    if not psgfw then
        if not g_drawing_text then 
            foreach(atrs, update_atr)
        else
            text_update()
        end

        local cx = flr((pl.x / 8))
        local cy = flr((pl.y / 8) + 0.75)

        for m in all(areas) do
			foreach(m.entities, update_ent)
			
            if cx >= m.minx and cx <= m.maxx and cy >= m.miny and cy <= m.maxy then
                if(not m.entered) entered_area(m)                
            else
                if(m.entered) left_area(m)
            end
        end
        
        for t in all(teleporters) do
            if cx >= t.minx and cx <= t.maxx and cy >= t.miny and cy <= t.maxy then
                
                if not psgfw then
                    psgfw = true
                    fade_screen_x = 0
                    fade_screen_y = 0

                    teleporter_using = t
                    return
                end
            end
        end
    else
        process_teleporting()
    end
		
	local floor = get_pl_floor()
	g_light_level = ggen[floor]:get_lightlevel()

end

function _draw()

    if not psgfw or jtel then
        cls()
        
        camera(camera_x, camera_y)

        if not can_flow_render() then
            if (g_drawing_text) draw_lightnings() text_draw() 
            return
        end

        if not g_player_died and not g_drawing_text and f2lf then
            lightning_chance_timer += 1
        
            if (cfs == 6) lightning_chance_timer += 4


            if lightning_chance_timer > 120 then
                lightning_chance_timer = 0

                if rnd(100) < lightning_chance then
                    lightning_chance = 5 - rnd(10)
                    do_lightning()
                else
                    lightning_chance += (6 + rnd(10))
                end
            end
        end

        dbfp = true

        local visible_areas = {}
        local drawn_areas = {}

        for m in all(areas) do
            m.linkshow = false
            if m.show then 
                add(visible_areas, m)
                add(drawn_areas, m)
            end
        end
        
        for m in all(visible_areas) do
            draw_map_area(m)

            if #m.links >= 1 then
                for lm=1, #m.links do
                    local draw = true

                    if (m.linkblockers[lm] != nil and not m.linkblockers[lm].triggered) draw = false

                    if draw then
                        m.links[lm].linkshow = true
                        draw_map_area(m.links[lm])
                        add(drawn_areas, m.links[lm])
                    end
                end
            end
        end

        for a in all(atrs) do
            draw_atr(a, drawn_areas, false)
        end

        draw_atr(pl, drawn_areas, true)
        dbfp = false

        for a in all(atrs) do
            draw_atr(a, drawn_areas, false)
        end

        for m in all(visible_areas) do
            draw_map_area(m)
            
            if #m.links >= 1 then
                for lm=1, #m.links do
                    local draw = true
                    if (m.linkblockers[lm] != nil and not m.linkblockers[lm].triggered) draw = false
                        
                    if draw then   
                        m.links[lm].linkshow = true
                        draw_map_area(m.links[lm])
                    end
                end
            end
        end

        if (g_drawing_text) text_draw()
     else
        draw_teleport_warp()
    end

    if g_player_died then
        rectfill(camera_x+44,camera_y+60,camera_x+87,camera_y+72, 0)
        rect(camera_x+44,camera_y+60,camera_x+87,camera_y+72, 6)
        print("game over", camera_x+48, camera_y+64, 7)
    end

	if	g_temp_effect_palette and g_temp_effect_palette:tick() then
		set_pal( g_temp_effect_palette )
	else
		draw_light_level()
		draw_lightnings()
	end
	
end

dark0_pal 		= {0,0,0,1,   2,1,1,13,   2,2,4,3,   1,1,1,14}
dark1_pal 		= {0,0,0,1,   2,1,1,5,      2,2,5,1,   1,1,1,5}
dark2_pal 		= {0,0,0,0,   2,0,1,5,      2,2,5,1,   1,1,2,5}
light2_pal 		= { 5, 6,14, 7,    7, 7, 7, 7,    14, 7, 7, 7,   7, 6, 7,7}

light_lv_pals	= 
{
	dark2_pal, dark2_pal, dark1_pal, dark1_pal, 
	dark0_pal, dark0_pal, nil, nil,
	nil, nil, nil, nil,
	nil, light2_pal, light2_pal, light2_pal
}

g_light_default = 8
g_light_level = 8
gltg = {}

function set_pal(p)
	for i =0,15 do
		local c = (p and p[i+1]) or i
		pal(i,c,1)
	end
end

function sll(lv)
	g_light_level = lv or g_light_default	
end

function draw_light_level()	
	set_pal( light_lv_pals[g_light_level] )
end
function add_lightning(duration, intensity)
	local lightning = {}
	lightning.intensity = intensity
	lightning.time = duration
	lightning.timer = duration	
	
	add(gltg, lightning)
	
	return lightning
end

function do_lightning()
    add_lightning(4, 17)
    add_lightning(6, 6)
    add_lightning(8, 15)
    add_lightning(4, 9)
    add_lightning(5, 13)
    add_lightning(7, 6)
    
    play_lightning_sfx()
end

function do_lightning_long()
    add_lightning(4, 17)
    add_lightning(6, 6)
    add_lightning(8, 15)
    add_lightning(4, 9)
    add_lightning(5, 13)
    add_lightning(7, 6)
    add_lightning(4, 17)
    add_lightning(6, 6)
    
    play_lightning_sfx()
end

function play_lightning_sfx()
    local thunders = {1,5}
    local rnd_idx = flr(rnd(2))+1
    sfx(thunders[rnd_idx],0)
end

function draw_lightnings()
    local intensity = 0
    for lightning in all(gltg) do			
        lightning.timer -= 1
        
        if (lightning.timer < 0) del(gltg, lightning)
        
        intensity += lightning.intensity * lightning.timer / lightning.time
    end
    
    if( intensity > 16) intensity = 16		
    if( intensity <= 0 ) gltg = {}		
            
    if( intensity > g_light_level ) set_pal( light_lv_pals[intensity] );
end

g_temp_effect_palette = nil

function create_temp_pal(t)
	local temp_pal = {}	
	temp_pal.timer = t or 10
	
	function temp_pal:tick()
		if( self.timer>0 ) self.timer -= 1
		return self.timer>0;
	end
	
	return temp_pal
end

function redify_screen()
	local red_cols			= { 0, 2, 8, 14, 4,		0,0,2,2,8,8,8,8,1 }

	local palette = create_temp_pal(5)		
	for i =1,16 do
		palette[i] = red_cols[ flr(rnd(#red_cols))+1]
	end
	
	g_temp_effect_palette = palette		
end

sfx_pool = {}
current_sfx = -1

function add_sfx_to_pool(snd, p)
    local s = {}
    s.snd = snd
    s.pri = p
    s.channel = 1
    add(sfx_pool, s)

    return #sfx_pool
end

function play_sfx(idx, ent)
    if (current_sfx != -1 and sfx_pool[current_sfx].ent and sfx_pool[current_sfx].ent != ent) return

    if current_sfx == -1 or (sfx_pool[idx].pri >= sfx_pool[current_sfx].pri and sfx_pool[idx].snd != sfx_pool[current_sfx].snd) then
        sfx(-1,1)
        sfx(sfx_pool[idx].snd, 1)

        if (ent) sfx_pool[idx].ent = ent
        current_sfx = idx
    end
end

function stop_sfx(idx, ent)

    if (idx and current_sfx != -1 and idx != current_sfx) return
    if (ent and current_sfx != -1 and sfx_pool[idx].ent and sfx_pool[idx].ent != ent) return

    current_sfx = -1
    sfx(-1,1)
end

function icts()
    sfx_enemy_very_close = add_sfx_to_pool(16, 0)
    sfx_enemy_close = add_sfx_to_pool(17, 0)
end

function atr_facing_entity(atr, e)
	local action_dist = 16	
	if( abs(atr.x - e.x) + abs(atr.x - e.x) > action_dist ) return false
	if( atr.x < e.x and atr.dir == 3) return false
	if( atr.x > e.x and atr.dir == 1) return false
	if( atr.y < e.y and atr.dir == 4) return false
	if( atr.y > e.y and atr.dir == 2) return false
	return true
end

function atr_action(atr, attack)
	for m in all(areas) do
		if m.show or m.linkshow then
			for e in all(m.entities) do
				if atr_facing_entity(atr, e) then
					local result = false
					if attack and e.on_attack then
						result = e.on_attack(e)
					elseif e.on_use then
						result = e.on_use(e, atr)
					end
					if(result) return result;
				end
			end
		end
	end

	for e in all(atrs) do
        if atr_facing_entity(atr, e) then
            local result = false
            if attack and e.on_attack then						
                result = e.on_attack(e)
            end
            if(result) return result;
        end
    end
end

function pl_move()
    local x = 0
    local y = 0

    if (btn(0)) x = -1

    if (btn(1)) x = 1

    if (btn(2)) y = -1

    if (btn(3)) y = 1

	pl.attack = btnp(4)
    pl.use = btnp(5)

    if not jtel and can_pl_move() then
        aftat(pl,x,y)
    else
        if (y == 0) jtel = false
    end

    camera_x = pl.x - 64
    camera_y = pl.y - 64

    if not g_drawing_text then
	    if (pl.use or pl.attack) atr_action(pl, pl.attack)
    end
end

function get_pl_floor()
	if pl.x < 376 then 
		if pl.y < 208 then
			return 2
		else 
			return 1
		end		
	else
		if pl.y < 208 then
			return 0
		end
	end
	
	return 0
end

function splan(a)
    
    a.anim_sz = { 4, 4, 4, 4 }

    a.tcol = 0

    for i=1, 8 do
        a.anim[i] = {}
        for y=1, 4 do
            a.anim[i][y] = 0
        end
    end

    for i=1,4 do
        a.anim[1][i] = 39   
        a.anim[3][i] = 7    	
        a.anim[5][i] = -39   
        a.anim[7][i] = 9   	
    end

    a.anim[2][1] = 55
    a.anim[2][2] = 56
    a.anim[2][3] = 55
    a.anim[2][4] = 57
    
    for i=1,4 do
        a.anim[6][i] = -a.anim[2][i]
    end

    a.anim[4][1] = 23
    a.anim[4][2] = 24
    a.anim[4][3] = 23
    a.anim[4][4] = -24

    a.anim[8][1] = 25
    a.anim[8][2] = 26
    a.anim[8][3] = 25
    a.anim[8][4] = -26
end

function smoan(a)
    a.anim_sz = { 4, 4, 4, 4 }
	
    a.tcol = 14
	
    for i=1, 8 do
        a.anim[i] = {}
        for y=1, 4 do
            a.anim[i][y] = 0
        end
    end
    
    for i=1,4 do
        a.anim[1][i] = 33   
        a.anim[3][i] = 1   	
        a.anim[5][i] = 36   
        a.anim[7][i] = 4   	
    end

    a.anim[2][1] = 49
    a.anim[2][2] = 50
    a.anim[2][3] = 49
    a.anim[2][4] = 51
    
    a.anim[6][1] = 52
    a.anim[6][2] = 53
    a.anim[6][3] = 52
    a.anim[6][4] = 54

    a.anim[4][1] = 17
    a.anim[4][2] = 18
    a.anim[4][3] = 17
    a.anim[4][4] = 19

    a.anim[8][1] = 20
    a.anim[8][2] = 21
    a.anim[8][3] = 20
    a.anim[8][4] = 22
end

function add_atr(x,y,at, is_boss)
    local a = {}

    a.x = x
    a.y = y

    a.is_boss = is_boss

    a.attack = false
    a.use = false

    a.health = 100

    a.attacktimer = 0

    a.smp = false

    a.anim = { }

    if at == 0 then
        splan(a)
    elseif at == 1 then
        smoan(a)
    end

    a.dx = 0
    a.dy = 0

    a.dir = 1

    a.moving = false

    a.frame = 1
    a.ft = 0

    a.isplayer = false

    add(atrs, a)

    return a
end

function admo(x,y, dir, is_boss)

    local mon = add_atr(x,y,1,is_boss)


    if (dir) mon.dir = dir
    if (is_boss) mon.health = 250

    function mon:on_attack(atr)
        
        if (#gltg == 0) sfx(-1, 0) sfx(10, 0)
        
        if haxe then
            self.health -= 20
        else
            self.health -= 5
        end
		
		return true
	end

    return mon
end
function aftat(a,x,y)

    a.dx = 0
    a.dy = 0

    a.moving = (x != 0 or y != 0)

    if (not a.moving) a.frame = 1 return

    if x > 0 then       a.dir = 1 
    elseif x < 0 then   a.dir = 3 
    elseif y > 0 then   a.dir = 2 
    else                a.dir = 4 
    end

    local spd = 1

    if (not a.isplayer) spd *= 0.3

    a.dx += spd * x
    a.dy += spd * y


    a.ft+=1
    
    if (a.ft % 5 != 0)  return

    if a.frame == a.anim_sz[a.dir] then
        a.frame = 1
    else
        a.frame += 1
    end

    a.ft = 0

end

function math_lerp(a,b,t)
    return a + t * (b - a)
end

function process_atr_ai(a)
    
    local distance = dist(a.x, a.y, pl.x, pl.y)
    
    if a.is_boss then
        a.smp = true
    end

    if cfs == 6 and f_s[cfs].stage_internal != 2 then
        return
    end

    if not a.smp then
        if abs(a.x - pl.x) > 32 or abs(a.y - pl.y) > 32 then
            a.dx = 0
            a.dy = 0
            stop_sfx(sfx_enemy_very_close, a)
            stop_sfx(sfx_enemy_close, a)
            return
        end
    end

    if not a.attack and (a.smp or (distance >= 0 and distance < 32)) then

        local x = 0
        local y = 0

        if abs(pl.x - a.x) > 0.2 then
            if  pl.x - a.x > 0 then
                x = 1
            elseif pl.x - a.x < 0 then
                x = -1
            end
        end

        if abs(pl.y - a.y) > 0.2 then
            if pl.y - a.y > 0 then
                y = 1
            elseif pl.y - a.y < 0 then
                y = -1
            end
        end

        aftat(a, x, y)
    else
        a.dx = 0
        a.dy = 0
    end
    
    if a.smp and distance < 72 and distance >= 24 then
        play_sfx(sfx_enemy_close, a)
    elseif a.smp and distance < 24 then
        play_sfx(sfx_enemy_very_close, a)
    else
        stop_sfx(sfx_enemy_very_close, a)
        stop_sfx(sfx_enemy_close, a)
    end

    if distance >= 0 and distance < 8 then
        if not a.attack then 
            a.dx = 0
            a.dy = 0
            a.attack = true
            sfx(22, 0)
        end
    end

    if a.attack then
        if (a.attacktimer < 28) a.attacktimer += 1 return
        a.attacktimer = 0

        if distance < 12 then
            pl.health -= 20
            sfx(-1, 0)
            sfx(11, 0)
            
			redify_screen()        
        end

        a.attack = false
    end
end

function update_atr(a)

    if a.isplayer then 
        pl_move(a)
    else
        if a.health <= 0 then

            if (a.attack) sfx(-1, 0)
            sfx(11, 0)

            if a.is_boss then
            
                f_s[cfs].stage_internal = 3
            end

            stop_sfx(sfx_enemy_very_close, a)
            stop_sfx(sfx_enemy_close, a)

            del(atrs, a)
            return
        end

        process_atr_ai(a)
    end
    
    local cx = (a.x / 8)
    local cy = (a.y / 8) + 0.75

    if not a.isplayer or not is_map_solid(cx, cy, a.dx, a.dy) then
        a.x += a.dx
        a.y += a.dy
    end

end

function draw_atr(a, drawn_areas, drawplayer)

    if not a.isplayer then
        if dbfp then
            if(a.y > pl.y) return
        else
            if(a.y <= pl.y) return
        end
        
        local cx = flr((a.x / 8))
        local cy = flr((a.y / 8) + 0.75)

        local invisiblemap = false

        a.smp = false

        for m in all(drawn_areas) do
            if cx >= m.minx and cx <= m.maxx and cy >= m.miny and cy <= m.maxy then
                invisiblemap = true
                local pcx = flr((pl.x / 8))
                local pcy = flr((pl.y / 8) + 0.75)

                if pcx >= m.minx and pcx <= m.maxx and pcy >= m.miny and pcy <= m.maxy then
                    a.smp = true
                end
            end
        end

        if (not invisiblemap) return
        
    elseif not drawplayer then
        return
    end

    local dir = a.dir*2

    if (a.tcol != 0) palt(a.tcol, true)

    local top_offset = 8
    local height = 1.0

    if a.attacktimer > 0 then
        height -= a.attacktimer / 200
        top_offset *= height
    end
    
    local frame = a.anim[dir-1][a.frame]
	local flip = false
	if (frame < 0) frame = -frame   flip = true
    spr(frame,     a.x,    a.y - top_offset,    1.0,    height, flip)
    
	frame = a.anim[dir][a.frame]
	flip = false
	if (frame < 0) frame = -frame    flip = true
    spr(frame,       a.x,    a.y,        1.0,    height, flip)

    if (a.tcol != 0) palt(a.tcol, false)

end

function add_ent_blocker(e, b)
    e.blocker = b
end

function add_ent_alt_sprite(e,s)
    e.spralt = s
end

function disable_ent_collision(e)
    e.coll = false
end

function add_ent_for_draw_order(e, y)
    e.ovr_y_draw_order = y
end

function add_ent(m, x,y,sp,ontop,drawblack,fliph,flipv)
    local e = {}

    e.x = x * 8
    e.y = y * 8
    e.spr = sp

    e.type = 0

    e.coll = not ontop

    e.triggered = false
    e.ontop = ontop
    e.drawblack = drawblack
    e.fliph = fliph
    e.flipv = flipv

    e.ovr_y_draw_order = 0

    add(m.entities,e)

    return e
end

function draw_ent(e)

    if e.type == 1 then
        if (e.triggered) return
    end
    
    local order_y = e.y

    if e.ovr_y_draw_order != 0 then
        order_y = e.ovr_y_draw_order
    end

    if dbfp then
        if(order_y > pl.y) return
        if(e.ontop) return
    else
        if not e.ontop then
            if(order_y <= pl.y) return
        end
    end

    if (e.drawblack) palt(0, false)
	
	if type(e.spr) == "number" then
		spr(e.spr,e.x,e.y, 1,1, e.fliph, e.flipv)
	elseif type(e.spr) == "table" then 
    
		spr(e.spr[1],e.x,e.y, 1,1, e.fliph, e.flipv)
		spr(e.spr[2],e.x,e.y-8, 1,1, e.fliph, e.flipv)
	elseif type(e.spr) == "function" then
		e:spr()
	end

    if (e.drawblack) palt(0, true)
end

function update_ent(e)

	if(e.tick) e:tick()

end

function action_text(text)
	return function(e,a)
		text_add(text)
		return true
	end
end


s_key						= 30
s_axe						= 46
s_chair 					= 109
s_table 					= 77
s_small_table 		= 93
s_shelf_top 			= 108
s_mirror					= 107
s_bookshelf			= 124
s_cupboard				= 125
s_safe						= 125
s_baththub				= 121
s_shower				= 105
s_clock 					= 79
s_gfclock_bot			= 95
s_gfclock					= {s_gfclock_bot,s_clock}
s_door_top 				= 73
s_door_bot				= 89
s_door_boards		= 72
s_generator			= 106
s_door						=	{s_door_bot ,s_door_top}
s_plant					= 127
s_photo1					= 78
s_photo2					= 94
s_sink						= 122
s_toilet_back			= 122
s_switch_on			= 63	
s_switch_off			= 62
s_wall_brown  		= 82
s_wall_bath  			= 67
s_wall_stripe			= 80
s_wall_gray			= 84

function add_door( area, x,y, spwall, boarded)
	local ceil = add_ent(area, x,y-1,  {spwall, 119}, false, true)
    local ceil2 = add_ent(area, x+1,y-1,  {spwall, 119}, true, true)
    disable_ent_collision(ceil)
	disable_ent_collision(ceil2)

	local door = add_ent(area, x,y, s_door)	
    door.type = 2
	
	if boarded then
		door.blocker = add_ent(area, x,y, s_door_boards)
        door.blocker.type = 1
		door.blocker.triggered = false
		door.blocker.boards = true		
		door.blocker.block_text = "bruno boarded this room, he didn't want me going there.______if i had an axe i would be able to get in.";
    end
	
	function door:on_use(atr)
		if self.triggered then
            if (#gltg == 0) sfx(14, 0)
			self.triggered = false
		elseif not self.blocker or self.blocker.triggered then
            if (#gltg == 0) sfx(14, 0)
            self.triggered = true
		else 
			local msg = self.blocker.block_text or 
			"the door appears to be locked. maybe i can find a key."
			text_add(msg)
		end
		
		return true
	end

    function door:on_attack(atr)
        if self.blocker and not self.blocker.triggered then
            if haxe then
                if (#gltg == 0) sfx(10, 0)
                self.blocker.triggered = true
            end
        end
        return true
    end
	
    add_ent_for_draw_order(ceil, door.y)

	return door
end

function draw_door(door)
	pal(1,2)	
	
	if door.triggered then
		pal(2,0)	pal(4,0)	pal(13,0)
	end
	
	spr(s_door_bot, door.x, door.y, 1,1, door.fliph, door.flipv)
	spr(s_door_top, door.x, door.y-8, 1,1, door.fliph, door.flipv)
	
	pal(1,1) pal(2,2) pal(4,4) pal(13,13)	
end

s_door = draw_door

function add_generator(area, floor,	 x, y)
	local min_lights = { }
	min_lights[0] = 2
	min_lights[1] = 4
	min_lights[2] = 3
	
	local generator = add_ent(area, x, y,		s_generator)	
	generator.power_level = 0
	generator.power_leak = true
	generator.min_light = min_lights[floor]
	generator.light = false
	generator.floor = floor	
	
	function generator:tick()
		if(self.power_level > 0 and self.power_leak and self.light ) self.power_level -= 1
	end
	
	function generator:switch()
		if self.triggered and cfs >= 4 then 
			self.power_level = 30 * 30
			self.light = not self.light
		end
	end
	
	function generator:get_lightlevel()
		local power = self.power_level
		
		if not self.light then
			return self.min_light
		end
		
		if power > 0  then
			if power < 50 then
				local rndlv = flr( rnd( g_light_default + power / 20 - 2.5)  + power / 20)
				if( rndlv > g_light_default ) rndlv = g_light_default
				if( rndlv < self.min_light ) rndlv = self.min_light
				return rndlv
			else 
				return g_light_default
			end
		end	
		return self.min_light
	end
	
	ggen[floor] = generator
	
	return generator
end

function draw_switch(switch)
	local generator = ggen[switch.floor]
	local sprite = (switch.on and s_switch_on) or s_switch_off
	spr(sprite, switch.x, switch.y, 1,1, switch.fliph, switch.flipv)
end


function add_lswitch(area, floor,	 x, y)
	local lswitch = add_ent(area, x, y,		draw_switch)
	
	lswitch.floor = floor
	
	function lswitch:on_use(atr)
		local generator = ggen[self.floor]
		
		self.on = not self.on
		
		if	not generator.triggered then
			text_add("lights won't switch. i must power the generator on this floor.")
		end
		
		generator:switch()
	end
	
	return lswitch
end

s_switch = draw_switch

function add_map_area(minx,miny,maxx,maxy,cx,cy,cex,cey)
    local a = {}
    a.minx = minx
    a.miny = miny
    a.maxx = maxx
    a.maxy = maxy
    a.cx = cx
    a.cy = cy
    a.cex = cex + 1
    a.cey = cey + 1
    
    a.entered = false
    a.show = false
    a.linkshow = false

    a.entities = {}
    a.links = {}
    a.linkblockers = {}

    add(areas,a)

    return a
end

function add_map_link(s, t, blocker)
    add(s.links, t)
    add(s.linkblockers, blocker)
end

function entered_area(a)
    a.entered = true
    a.show = true
    
end

function left_area(a)
    a.entered = false
    a.show = false
    
end

function draw_map_area(m)
    if (dbfp) map(m.cx,m.cy, m.cx*8,m.cy*8, m.cex - m.cx,m.cey - m.cy)
    foreach(m.entities, draw_ent)
end


function add_area_f1_main_bedroom()
	local area = add_map_area(   0,27,13,39,     0,27,13,36)	 

    add_ent(area,	3,	31,		s_small_table)

    add_ent(area,	2,	34,		s_chair)
    local e = add_ent(area,	3,	34,		s_table)

	e.on_use = action_text("irene attacked the table and hurt it_._._. emotionally")
	e.on_attack = action_text("irene used the table, but nothing happened")
	
    add_ent(area,	4,	34,		s_chair, false, false, true)
    
    add_ent(area,	6,	30,		s_shelf_top)
    add_ent(area,	7,	29,		s_shelf_top)
    add_ent(area,	12,	30,		s_shelf_top)
	
    add_ent(area,	11, 31,		s_table)
    add_ent(area,	2, 	29, 	s_clock )
	
	return area
end

function add_area_f1_corridor()
	local area = add_map_area(       0,40,46,42,     0,37,46,43)
	
	add_ent(area,	4,	38,		s_photo2)
	add_ent(area,	23,	38,		s_photo2)
	add_ent(area,	36,	38,		s_photo1)
	
	
	return area
end

function add_area_f1_bathroom()
	local area = add_map_area(       6,43,16,51,     6,44,16,51)
	
	add_ent(area,	8,	50,		s_toilet_back)	
	
	add_ent(area,	13,	50,		s_baththub)
	add_ent(area,	14,	50,		s_baththub, false, false, true)
	add_ent(area,	14,	49,		s_shower, true, false, true)
		
	add_ent(area, 12,	45.25,	{s_mirror, s_shelf_top })
	add_ent(area, 14,	45.25,	{s_cupboard, s_shelf_top })
	add_ent(area,	13,	46,			s_sink)
	
	return area
end

function add_area_f1_library()
	local area = add_map_area(        14,30,38,39,    14,30,38,36)
	
	foreach( {15,16,17,  20,21,22,23,24,  27, 28, 29,  31, 32, 33}, 
	function(x)
		add_ent(area,	x,	35,		s_shelf_top, true)
	end )
		
	add_ent(area,	23,	33,	s_plant)
	
	add_ent(area,	37,	34,		s_chair, false, false, true)
	add_ent(area,	37,	33,		s_chair, false, false, true)
	
	add_ent(area,	35,	33,		s_table_back)
	add_ent(area,	36,	33,		s_table_back)
	
	add_ent(area,	35.5,	33.2,	s_plant)
	add_ent(area,	35,	31,		s_clock)
	
    f1_library_safe = add_ent(area,	34,	33,		s_safe)
	
    function f1_library_safe:on_use(atr)
        if not self.triggered then
            sfx(8, 0)
			self.triggered = true
            
            text_add("lucky that the safe was open!___ the code to his office reads:__ 4_9_2_6.")
		end
		
		return true
	end

	return area
end

function add_area_f1_storage()
	local area = add_map_area(        39,30,46,39,    39,30,46,36)
	
	f1_fuse_cupboard = add_ent(area, 45, 33,		s_cupboard)

    function f1_fuse_cupboard:on_use(atr)
        if not self.triggered then
            sfx(8, 0)
			self.triggered = true
            
            text_add("okay, now i can use these fuses on the generators in the house. ____ i need to get the power back up and running__.__.__.__ damn storm!")
		end
		
		return true
	end

    f1_generator = add_generator(area, 1,		41, 33)
    add_ent_blocker(f1_generator, f1_fuse_cupboard)

	f1_generator.light = true
	f1_generator.power_level = 1000
	f1_generator.power_leak = false
	
    function f1_generator:on_use(atr)
		
        if self.blocker then
            if not self.triggered then
                if self.blocker.triggered then
                    if (#gltg == 0) sfx(8, 0)
                    self.triggered = true
					self.power_leak = true
                    if cfs == 4 then
                        text_for_flow_4_generator_fueled()
                        f1_generator.power_level = 1000
                    else
                        text_add("sweet!___ h_m_m_m___ doesn't appear to be working__.__.__._____ ah yes, probably needs some fuel. ____ i think there was some upstairs in the room being constructed.")
                        f1_generator.power_level = 0
                    end
                else
                    text_add("i need the fuses in the cupboard just over there to get this running.")
                end
            end
		end
		
		return true
	end
	
	add_lswitch( area, 1,   43, 32 )

	return area
end

function add_area_f2_construction_a()
    local area = add_map_area(14,4,23,12,    	14,4,23,10)

    f2_construction_fuel_cupboard = add_ent(area, 15, 7, s_cupboard)
    
    function f2_construction_fuel_cupboard:on_use(atr)
        if not self.triggered then
            if (#gltg == 0) sfx(8, 0)
			self.triggered = true
            
            text_add("not where i expected it to be but okay.___ now lets finally get those lights back on_._._.___ i should power this floor and the lower floor first.")
		end
		
		return true
	end

    

    return area
end

function add_area_f2_construction_b()
    local area = add_map_area(24,4,38,10,    	24,4,38,10)

    f2_generator = add_generator(area, 2,	 	37, 7)
    add_ent_blocker(f2_generator, f2_construction_fuel_cupboard)

    function f2_generator:on_use(atr)
		
        if self.blocker then
            if not self.triggered then
                if self.blocker.triggered then
                    if (#gltg == 0) sfx(8, 0)
                    self.triggered = true
                    f2_generator.power_level = 1000
                    f2_generator.light = true
                    f2_generator.power_leak = true
                    text_for_flow_4_generator_fueled()
                else
                    text_add("i need to find the fuel first_._._.___ should be somewhere around here.")
                end
            end
		end
		
		return true
	end

    return area
end


function add_area_f0_garage()
	local area =  add_map_area(72,5,87,14,    	72,5,87,14)
		
	f0_axe = add_ent(area, 86, 10,		s_axe)
	f0_axe.type = 1

	function f0_axe:on_use(atr)
		if not self.triggered then
            if (#gltg == 0) sfx(8, 0)
            haxe = true
            self.triggered = true
            admo(73*8, 10*8, 3)
        end
		return true
	end
		
	return area
end

function add_area_f0_kitchen()
	local area =  add_map_area(49,0,62,5,    		49,0,62,5)
	
	f0_garage_key = add_ent(area, 60, 4,		s_key)	
	f0_garage_key.type = 1

    add_ent_blocker(f0_garage_key, f0_generator)

	function f0_garage_key:on_use(atr)
		if not self.triggered and fb_generator.triggered then
            if (#gltg == 0) sfx(8, 0)
            self.triggered = true
            fb_generator.power_level = 1000
            fb_generator.light = true
            fb_generator.power_leak = true
            
        end
		return true
	end
	
	return area
end

function add_area_f0_livingroom()
	local area =  add_map_area(49,6,62,16,    	49,6,62,14)
	return area
end

function add_area_fb_gen_area()
	local area = add_map_area(49,31,60,39,    49,31,61,39)
	
	fb_generator = add_generator(area,  0,	 56, 34)
	
	function fb_generator:on_use(atr)
		if not self.triggered then
            if (#gltg == 0) sfx(8, 0)
            self.triggered = true
            
            text_add("ok_._._.___ everything should be stable now.___ time to find the source of that glass noise.")
            f0_office_door.blocker.block_text = "brunos office_._._.___ this is where the sound came from.____ it's locked though_._._._ i think he left the code in the library safe.___ the library is boarded so i'll need to get an axe from the garage."
			
			for gen in all(ggen) do
				gen.power_leak = false
				gen.power_level = 10000
			end
        end
		return true
	end
	
	return area
end

function add_game_maps()

    local f1_main_bedroom = add_area_f1_main_bedroom()
    local f1_corridor = add_area_f1_corridor()
    local f1_bathroom = add_area_f1_bathroom()
    local f1_library = add_area_f1_library()
    local f1_storage = add_area_f1_storage()
    local f1_spare_bedroom = add_map_area(  38,43,46,50,    38,44,46,50)
    local f1_stairs = add_map_area(         24,43,33,46,    24,44,33,46)	
	
	f1_bedroom_door 	    = add_door( f1_corridor, 9,39, 		s_wall_brown)
    
	local f1_library_door 		= add_door( f1_corridor, 19,39, 	s_wall_brown, true)
	local f1_storage_door 	= add_door( f1_corridor, 43,39, 	s_wall_brown)
	
	local f1_bathroom_door 		= add_door( f1_bathroom, 9,46, 		s_wall_bath)
	local f1_spareroom_door 	= add_door( f1_spare_bedroom, 43,46,s_wall_stripe)

    add_map_link(f1_main_bedroom, f1_corridor, f1_bedroom_door)
    add_map_link(f1_bathroom, f1_corridor)
    add_map_link(f1_library, f1_corridor)
    add_map_link(f1_storage, f1_corridor)
    add_map_link(f1_spare_bedroom, f1_corridor)
    add_map_link(f1_stairs, f1_corridor)
	
	add_lswitch( f1_corridor, 1,		5, 39)
	add_lswitch( f1_corridor, 1,		30, 39)
	
	local f2_corridor 				= add_map_area(0,11,46,17,    	0,11,46,17)
	local f2_corridor_anex 	= add_map_area(5,0,8,10,    			5,0,8,10)	
	local f2_staircase			= add_map_area(24,18,28,20,   	24,18,28,20)
	local f2_storage 				= add_map_area(0,0,4,4,    			0,0,4,4)
	local f2_toilet 					= add_map_area(9,0,13,4,    			9,0,13,4)
	local f2_bedroom1			= add_map_area(0,6,4,10,    			0,6,4,10)
	local f2_bedroom2			= add_map_area(9,6,13,10,    		9,6,13,10)
	local f2_livingroom			= add_map_area(6,18,16,24,    	6,18,16,24)
	local f2_construction_a	= add_area_f2_construction_a()
	local f2_construction_b	= add_area_f2_construction_b()
	local f2_peaceroom		= add_map_area(39,4,46,10,    	39,4,46,10)
	local f2_office					= add_map_area(38,18,46,24,   	38,18,46,24)	
	
	local f2_construction_door 	= add_door( f2_corridor, 	19,13, 			s_wall_stripe)
	local f2_peace_door 				= add_door( f2_corridor, 	43,13, 			s_wall_stripe)
	
	local f2_office_door 				= add_door( f2_office, 		41,20, 			s_wall_gray)
	local f2_livingroom_door		= add_door( f2_livingroom, 11,20, 		s_wall_brown)
	
	add_map_link(f2_corridor, f2_corridor_anex)
	add_map_link(f2_corridor_anex, f2_corridor)
	add_map_link(f2_staircase, f2_corridor)
	add_map_link(f2_corridor,f2_staircase)
	
	add_map_link(f2_storage, f2_corridor_anex)
	add_map_link(f2_toilet, f2_corridor_anex)
	add_map_link(f2_bedroom1, f2_corridor_anex)	
	add_map_link(f2_bedroom2, f2_corridor_anex)
	add_map_link(f2_bedroom2, f2_corridor)
	
	add_map_link(f2_livingroom, f2_corridor)
	
	add_map_link(f2_construction_a, f2_corridor)
	add_map_link(f2_construction_a, f2_construction_b)
	add_map_link(f2_construction_b, f2_construction_a)
	
	add_map_link(f2_office, f2_corridor)	

	add_lswitch( f2_corridor, 2,		28, 13)
	add_lswitch( f2_corridor, 2,		38, 13)
	add_lswitch( f2_corridor, 2,		3, 13)
	
	local f0_corridor 				= add_map_area(49,13,95,20,    49,13,95,19)
	local f0_entrance			= add_map_area(63,6,71,12,    	63,6,71,12)
	local f0_stairs					= add_map_area(73,20,82,22,    73,20,82,22)
	local f0_kitchen 				= add_area_f0_kitchen()
	local f0_livingroom			= add_area_f0_livingroom()
	local f0_garage				= add_area_f0_garage()
	local f0_bathroom			= add_map_area(88,5,95,14,    	88,5,95,14)
	local f0_office					= add_map_area(49,20,65,28,    49,20,65,28)
	
	local f0_livingroom_door 	= add_door( f0_corridor, 	55,15, 			s_wall_brown)
	f0_garage_door 			= add_door( f0_corridor, 	75,15, 			s_wall_brown)
	local f0_bathroom_door 		= add_door( f0_corridor, 	92,15, 			s_wall_brown)
	f0_office_door 			= add_door( f0_office,			61,22,			s_wall_gray)	
	
    add_ent_blocker(f0_garage_door, f0_garage_key)
    add_ent_blocker(f0_office_door, f1_library_safe)
    f0_office_door.blocker.block_text = "brunos office_._._._"

    
	add_map_link(f0_corridor, f0_entrance)
	add_map_link(f0_entrance, f0_corridor)
	add_map_link(f0_corridor, f0_stairs)

	add_map_link(f0_livingroom, f0_corridor)
	add_map_link(f0_livingroom, f0_kitchen)
	add_map_link(f0_kitchen, f0_livingroom)	
	add_map_link(f0_garage, f0_corridor)
	add_map_link(f0_garage, f0_entrance)
	add_map_link(f0_bathroom, f0_corridor)
	
	
	add_lswitch( f0_livingroom, 	0,		54,  8)
	add_lswitch( f0_corridor, 		0,		89, 15)
	add_lswitch( f0_garage, 		0,		79, 7)
	
	local fb_corridor 				= add_map_area(49,40,70,43,    49,39,70,43)
	local fb_entry 					= add_map_area(61,29,70,39,    60,29,70,39)
	local fb_gen_area 			    = add_area_fb_gen_area()
	
	add_map_link(fb_entry, fb_corridor)
	add_map_link(fb_corridor, fb_entry)
	add_map_link(fb_gen_area, fb_corridor)
	add_map_link(fb_corridor, fb_gen_area)
		
	
	add_lswitch( fb_gen_area, 	0,		58,  33)
end

function text_for_flow_4_generator_fueled()
    if f1_generator.triggered and not f2_generator.triggered then
        text_add("why did i fuel this one first?____ the mind works in mysterious ways_._._._")
    elseif not f1_generator.triggered and f2_generator.triggered then
        text_add("ugh__, this fuel stinks!___ now to fuel the one below.")
    elseif f1_generator.triggered and f2_generator.triggered then
        text_add("now that the generators up here are running, i need to activate the basement one to stabilise these!")
    end
end

flow_blocker_timer = 0

f_s = {}
cfs = 1

function can_flow_render()
    if cfs == 1 then
        return (f_s[cfs].ft > 270)

    end

    return true
end

function can_pl_move()
    if cfs == 1 then
        return (f_s[cfs].ft > 270)
    elseif cfs == 2 then
        return (not f2lf or f_s[cfs].ft > 90)
    elseif cfs == 6 then
        return (f_s[cfs].stage_internal != 1 and f_s[cfs].stage_internal != 4)
    end

    return true
end

function flow_init_common()
    f_s[cfs].ft = 0
    f_s[cfs].stage += 1
    f_s[cfs].stage_internal = 0
end
function flow_update_common()
    if (not g_drawing_text) f_s[cfs].ft += 1
end
function flow_exit_common()
    cfs += 1
end

f2lf = false
f2lf = false

bambi = false
bminit = false
function flow_init_ambience(playmusic)
    if (not bambi) sfx(0, 2) bambi = true
    if (playmusic and not bminit) music(0, 0, 8) bminit = true
end

function f1i()
    flow_init_ambience()
    
end
function f1u()

    if f_s[cfs].ft == 90 then
        sfx(12, 0)
    end
    
    if f_s[cfs].ft == 150 then
        text_add("._._.", false, true, true)
    end

    if f_s[cfs].ft == 180 then
        text_add("was that glass breaking?_____ ugh _____i don't want to get out of bed_._._._", false, true, true)
    end

    if f_s[cfs].ft == 240 then
        text_add("but_._._.____ i suppose i should go check that out_._._._", false, true, true)
    end

    if f_s[cfs].ft > 270 then
        f_s[cfs].stage += 1
    end
end
function flow_1_exit()

end

function f2i()
    flow_init_ambience(true)
    local s = "i should find some fuses to start the generator on this level_._._."
    a_t(30,44, 32,44,  31,42, true, true, s)
    a_t(25,44, 27,44,  26,42, true, true, s)

end
function f2u()

    if not f1_bedroom_door.triggered then
        if (dist(pl.x,pl.y, 72,281) < 16) f1_bedroom_door.triggered = true
    end

    if not f2lf then				
        if (dist(pl.x,pl.y, 72,324) < 8) then
            f2lf = true
            f_s[cfs].ft = 0
            
			f1_generator.power_level = 30
			f1_generator.power_leak = true
		
            do_lightning()
            
            pl.dx = 0
            pl.dy = 0

            pl.frame = 1
        end
    elseif not f2lf then

        if f_s[cfs].ft == 5 then
            text_add("aaaaaaaaaaaggggghhhh!", false, true, true, true)
        end

        if (f_s[cfs].ft == 20) sll(7)
        if (f_s[cfs].ft == 25) sll(6)
        if (f_s[cfs].ft == 30) sll(5)
        if (f_s[cfs].ft == 35) sll(4)

        if (f_s[cfs].ft == 50) then
            text_add("oh just perfect_.__.__._____ of course_._._._lightning just had to go and hit our powerline didn't it.", false, true, true)
        end

        if (f_s[cfs].ft == 60) then
            text_add("well its lucky i still have generators on each floor for that home renovation.", false, true, true)
        end

        if (f_s[cfs].ft == 90) f2lf = true
    end
    if f1_generator.triggered then
        f_s[cfs].stage += 1
    end

end
function flow_2_exit()

    remove_teleporter(25,44)
    remove_teleporter(30,44)

end

flow_3_monster_surprise_done = false

function f3i()
    
    a_t(25,19, 27,19,  31,43, false)
    a_t(30,45, 32,45,  26,17, false)
    a_t(25,44, 27,44,  26,42, true, true, "i needed to find that battery on the floor above_._._.")

    firstmonster = admo(242, 327, 3)

    admo(1*8, 4*8, 3)
    admo(37*8, 8*8, 3)

end
function f3u()
    if f2_construction_fuel_cupboard.triggered then
        f_s[cfs].stage += 1
    end

    if not flow_3_monster_surprise_done then
        if dist(pl.x,pl.y,firstmonster.x,firstmonster.y) < 54 then
            flow_3_monster_surprise_done = true
            
            text_add("what the duck is that?!", false, true, true)

        end
    end

end
function flow_3_exit()
    remove_teleporter(25,44)
end

function f4i()
    a_t(25,44, 27,44,  26,42, true, true, "i have the fuel, need to put it on the generators up here_._._.")

    f1_generator.triggered = false
    f2_generator.triggered = false
end
function f4u()
    if f1_generator.triggered and f2_generator.triggered then
        f_s[cfs].stage += 1
    end
end
function flow_4_exit()
    remove_teleporter(25,44)
end

function f5i()
    a_t(25,44, 27,44,  75,19, false)
    a_t(74,21, 76,21,  26,43, false)
    a_t(79,20, 81,20,  68,32, true)
    a_t(67,30, 69,30,  80,19, false)
    
end
function f5u()
    if f1_library_safe.triggered then
        f_s[cfs].stage += 1
    end
end
function flow_5_exit()
end
function f6i()
end
function f6u()
    if get_pl_floor() == 0 and f_s[cfs].stage_internal == 0 then
        local distancetoboss = dist(pl.x,pl.y,f0_office_door.x, f0_office_door.y+8)
        if distancetoboss > 0 and distancetoboss < 8 then
            f_s[cfs].stage_internal += 1
            do_lightning_long()

            f_s[cfs].ft = 0

            g_boss = admo(57*8,25*8,3, true)

            fset(14, 6, true)
            fset(15, 6, true)
        end
    elseif f_s[cfs].stage_internal == 1 then
        
        if f_s[cfs].ft == 10 then
            text_add("b-__b-__b-__b_lood on the floor?___._._.____._._.____oh no. i remember now___ ... ___why i left___ ... ___and why i came back.", false, true, true)

        elseif f_s[cfs].ft == 20 then
            text_add("bruno.____ my not so loving, abusive husband_._._.______ had broken a wine glass___ ... ___cursed at me to help him pick up the pieces.___ all the while insulting me_._._._", false, true, true)

        elseif f_s[cfs].ft == 30 then
            text_add("a-_after that my vision went red_._._._________ i took some of the glass and defty put it across his throat.____ i'm not sure what came over me__.__.__.", false, true, true)
        
        elseif f_s[cfs].ft == 40 then
            text_add("i left for a while after that__.__.__.______ i came back to put this to rest.", false, true, true)
        
        elseif f_s[cfs].ft >= 50 then
            f_s[cfs].stage_internal += 1
        end
    elseif f_s[cfs].stage_internal == 3 then
        f_s[cfs].ft = 0
        f_s[cfs].stage_internal += 1
    
    elseif f_s[cfs].stage_internal == 4 then
        if f_s[cfs].ft == 15 then
            text_add("finally__.__.__.__._____ i've laid him to rest.________________", false, true, true)
        end

        if f_s[cfs].ft == 20 then
            text_add("made in 48 hours for the global game jam 2019. thanks for playing and completing our game! we hope you enjoyed it... izzo and jimmu, jimmu and izzo :)", true, false, true)
        end

        if f_s[cfs].ft >= 25 then
            run()
        end
    end

end
function flow_6_exit()
end

function a_f_s(init,update,exit)
    local f = {}

    f.stage = 0
    f.stage_internal = 0

    f.func_init = init
    f.func_update = update
    f.func_exit = exit

    f.ft = 0

    add(f_s, f)
end


function init_flow()

    if stat(4) == "nointro" then
        cfs = 2
    end

    a_f_s(f1i, f1u, flow_1_exit)
    a_f_s(f2i, f2u, flow_2_exit)
    a_f_s(f3i, f3u, flow_3_exit)
    a_f_s(f4i, f4u, flow_4_exit)
    a_f_s(f5i, f5u, flow_5_exit)
    a_f_s(f6i, f6u, flow_6_exit)

end

function update_flow()

    if f_s[cfs].stage == 0 then
        f_s[cfs].func_init()
        flow_init_common()
    elseif f_s[cfs].stage == 1 then
        f_s[cfs].func_update()
        flow_update_common()
    else
        f_s[cfs].func_exit()
        flow_exit_common()
    end

end

teleporters = {}

function a_t(minx,miny,maxx,maxy, desx, desy, d, block_warp, block_text)
    local t = {}

    t.minx = minx
    t.miny = miny
    t.maxx = maxx
    t.maxy = maxy
    t.desx = desx
    t.desy = desy
    t.face_down = d

    t.block_warp = block_warp
    t.block_text = block_text

    add(teleporters,t)
end

function remove_teleporter(minx,miny)
    for t in all(teleporters) do
        if t.minx == minx and t.miny == miny then
            del(teleporters, t)
            return
        end
    end
end

function warp_player()
    pl.x = teleporter_using.desx * 8
    pl.y = teleporter_using.desy * 8

    camera_x = pl.x - 64
    camera_y = pl.y - 64

    pl.frame = 1
    if(not teleporter_using.face_down) pl.dir = 4

    jtel = true
    teleporter_using = nil
end

function process_teleporting()
    
    if (not teleporter_using) return

    if teleporter_using.block_warp then
        text_add(teleporter_using.block_text)
        warp_player()
        jtel = false
        psgfw = false

        return
    end

    if fade_screen_y >= 127 and not g_player_died then
        for a in all(atrs) do
            a.dx = 0
            a.dy = 0
        end

        warp_player()

        psgfw = false
    end
end

function draw_teleport_warp()
    if fade_screen_y <= 127 and fade_screen_y >= 0 then
        
        if (fsftm < 1) fsftm+=1 return

        local amount_per_frame = 6
        
        for y=0, fade_screen_y + amount_per_frame do
            
            for x=fade_screen_x, fade_screen_x + 63 do
                pset(camera_x+x,camera_y+y-1,0)
            end
        end

        if (fsftm < 3) fsftm+=1 return
        
        if(fade_screen_y == 0) sfx(21)

        fade_screen_x += 64

        for y=0, fade_screen_y + amount_per_frame do
            
            for x=fade_screen_x, fade_screen_x + 63 do
                pset(camera_x+x,camera_y+y-1,0)
            end
        end

        fade_screen_x = 0
        fsftm = 0

        fade_screen_y += amount_per_frame+1
    end
end

function is_cell_solid(x,y)
    return fget(mget(x,y), 6)
end

function is_map_solid(x,y,dx,dy)
    local mod_x = x % 1
    local mod_y = y % 1

    local cell_x = x - mod_x
    local cell_y = y - mod_y
    
    if dx != 0 and mod_x <= 0.15 then
        cell_x += dx
    end

    if dy == -1 and mod_y <= 0.5 then
        cell_y += dy
    elseif dy == 1 and mod_y >= 0.75 then
        cell_y += dy
    end

    if dx != 0 or dy != 0 then
        for m in all(areas) do
            if m.show or m.linkshow then 
                for e in all(m.entities) do
                    if e.coll and not e.triggered then
                        if e.x / 8 == cell_x and e.y / 8 == cell_y then
                            return true
                        elseif mod_x >= 0.15 and e.x / 8 == cell_x+1 and e.y / 8 == cell_y then
                            return true
                        end
                    end
                end
            end
        end

        if is_cell_solid(cell_x, cell_y) then
            return true
            
        elseif mod_x >= 0.15 then
            return is_cell_solid(cell_x+1, cell_y)
        end
    end
end

function dist(ax, ay, bx, by)
    local x_diff = ax - bx
    local y_diff = ay - by

    return sqrt((x_diff * x_diff) + (y_diff * y_diff))
end

text_displayline = 1
text_displaychar = 1
text_actualchar = 1
text_displaytimer = 0

function text_update()

    if (#text_queue == 0) return

    if text_displaychar > #text_queue[1][text_displayline] then

        if text_displayline >= #text_queue[1] then
            
            twoi = (not btn(4))

            if g_text_wait_at_end and twoi then
                return
            end

            if not g_text_wait_at_end then
                if not g_text_end_delay_started then
                    text_displaytimer = 0
                    g_text_end_delay_started = true
                end

                local delay_amount = 15 + g_text_length * 2

                if (text_displaytimer < delay_amount) then
                    text_displaytimer+=1 

                    if text_displaytimer < (delay_amount) / 2 or not twoi then
                        return
                    end
                end
            end

            text_displaying = {}
            text_queue = {}

            text_displayline = 1
            text_displaychar = 1
            text_actualchar = 1
            text_displaytimer = 0

            g_text_end_delay_started = false
            g_drawing_text = false
            g_text_is_diary = false

            return
        else
            text_displayline += 1
            text_displaychar = 1
            text_actualchar = 1
            text_displaytimer = 0
        end
    end

    if g_text_is_diary then
        for l=1, #text_queue[1] do
            for l=1, #text_queue[1][l] do
                text_displaying[l] = text_queue[1][l]
            end
        end

        text_displayline = #text_queue[1]
        text_displaychar = #text_queue[1][text_displayline]+1
        text_actualchar = #text_displaying[text_displayline]
        return
    end

    if (text_displaytimer < 1) text_displaytimer += 1 return
    text_displaytimer = 1

    if sub(text_queue[1][text_displayline], text_displaychar, text_displaychar) == "_" then
        text_displaytimer = -4
        text_displaychar += 1
        return
    end

    text_displaying[text_displayline] = text_displaying[text_displayline] ..sub(text_queue[1][text_displayline], text_displaychar, text_displaychar)

    text_displaychar += 1
    text_actualchar += 1

    if (not g_text_no_sound and #gltg == 0) sfx(2, 0)
    
end

function text_add(str, diary, dont_wait_at_end, add_flow_frame, mute_sound)

    local textlines = {}

    local char = ""
    local word = ""
    local line = ""

    g_text_length = 0

    local line_limit = 26
    if (d) line_limit = 24

    local addtoline = function()
        
        if #word + #line > line_limit then
            add(textlines, line)
            line = ""
        end

        line = line ..word
        word = ""

    end

    for i=1, #str do
        
        char = sub(str,i,i)
        word = word ..char

        g_text_length += 1
        
        if (char == " ") addtoline()

    end

    addtoline()

    if (line != "") add(textlines, line)

    add(text_queue, textlines)

    for i=1, #textlines do
        add(text_displaying,"")
    end

    g_text_wait_at_end = not dont_wait_at_end
    g_drawing_text = true
    g_text_is_diary = diary
    g_text_no_sound = mute_sound

    text_displaytimer = 0

    if (add_flow_frame) f_s[cfs].ft += 1

    pl.dx = 0
    pl.dy = 0

end

function text_draw()

    if (#text_queue == 0) return

    text_start_x = camera_x
    text_start_y = camera_y
    box_start_x = camera_x
    box_start_y = camera_y
    box_end_x = camera_x
    box_end_y = camera_y
    box_col = 1

    if g_text_is_diary then
        box_start_x += 15
        box_start_y += 5

        box_end_x += 111
        box_end_y += 122

        text_start_x += 19
        text_start_y += 10

        box_col = 7
    else
        box_start_x += 5
        box_start_y += 85

        box_end_x += 122
        box_end_y += 122

        text_start_x += 10
        text_start_y += 110
    end

    rectfill(box_start_x, box_start_y, box_end_x, box_end_y, box_col)

    rect(box_start_x - 1,   box_start_y - 1,    box_end_x + 1,  box_end_y + 1,  0)
    rect(box_start_x,       box_start_y,        box_end_x,      box_end_y,      2)
    rect(box_start_x + 1,   box_start_y + 1,    box_end_x - 1,  box_end_y - 1,  6)

    if (not g_text_is_diary) clip(10, 90, 117, 27)

    for i=1, #text_displaying[1] do
        if i < text_displayline then
            if not g_text_is_diary then
                print(text_displaying[i], text_start_x, text_start_y - (8 * (text_displayline-i)), 7)
            else
                print(text_displaying[i], text_start_x, text_start_y + (8 * (i-1)), 0)
            end
        elseif i == text_displayline then
            if not g_text_is_diary then
                print(sub(text_displaying[i], 1, text_actualchar), text_start_x, text_start_y, 7)
            else
                print(sub(text_displaying[i], 1, text_actualchar), text_start_x, text_start_y + (8 * (i-1)), 0)
            end
        end

    end

    clip()

    if twoi and g_text_wait_at_end then
        text_displaytimer += 1

        if(text_displaytimer >= 0 and text_displaytimer < 30) pal(6, 5)
        spr(123, box_end_x - 12, box_end_y - 10)
        pal()

        if (text_displaytimer > 60) text_displaytimer = 0
    end

end

function wait(a) for i = 1,a do flip() end end

__gfx__
00000000eeeeeeee0000000000000000eeeeeeee0000000000000000000000000ffffff0000000000a9aaaa00000000000000000000000004544545411111111
00000000eedd11ee0000000000000000ee11ddee00000000000000000000000009ffff9000000000099a9a900000000000000000000000004444444422222222
00700700ed00117e0000000000000000e711d1de0000000000000000009999008ee888e8009999008e9a99980000000000000000000000002222222211111111
00077000e01d106e0000000000000000e6117d0e000000000000000009aaaaa0ffeeee8809aaaaa088e99e880000000000000000000000002122221222222222
00077000e1d7177e0000000000000000e7711d1e000000000000000099a99a9aff8ee888aaa99a9a888998880000000000000000000000005445444511111111
00700700e110066e0000000000000000e661101e00000000000000009aff99aa022888ff9a9aa9a9ff8888800000000000000000000000004444444422222222
000000001d17777e0000000000000000e77711de0000000000000000961ff19a0dd22dd09a9aa9a90dd22dd00000000000000000000000002222222211111111
00000000016666ee0000000000000000ee66011d0000000000000000a7cffc7a00000000aa9aa9a9000000000000000000000000000000002212212222122122
00000000e01e7eee101e7eee111e7eeeeee7e10eeee7e101eee7e1110ffffff00ffffff00a9aaaa00a9aa9a00000000000000000000000000000000004000040
00000000e111d6eee111d66ed111d6eeee6d1111e66d111eee6d111d09ffff9009ffff90099a9a9009a9a9900000000000000000000000000000000004dddd40
000000000dd0116eed1111e61011116ee61111106e11111de61111018ee888e80ee88ee88e9a99980e9999e80000000000000000000000000000a99004444440
00000000e00161e71dd06eeee00d1e7e7e11d10eeee101d0e7e1d00e88eeee88888eee8888e99e88888e99880000000000000000000000009999900904000040
00000000e1116eee10d161eee1d16eeeeee61d1eee161101eee61d1e888ee8888288e8ff888998888888e8ff0000000000000000000000009090900904000040
00000000d110e67e11116eeedd106deee76e011deee61111eed601ddff8888fff82882ffff8888fff88882ff0000000000000000000000000000099a04dddd40
000000000d1ee66ee1e177ee0dd11deee66ee010ee761e1eeed11dd00dd22dd00dd221100dd22dd00dd221100000000000000000000000000000000004444440
00000000eeeeeeeeeeee66eee1001eeeeeeeeeeeee66eeeeeee1001e000000000dd00000000000000dd000000000000000000000000000000000000004000040
00000000eeeeeeee0000000000000000eeeeeeee00000000000000000000000099f97cf000000000000000000000000000008000000000000000000022222222
00000000eedd11ee0000000000000000eedd11ee00000000000000000000000099efff0000000000000000000888000000808080000000000000055044444444
00000000ed11d11e0000000000000000ed11711e00000000000000000990999099eeeee000000000000000000880000000808280000000000000555d44444444
00000000e1d1011e0000000000000000e106661e000000000000000099a9aa9990e88ff00000000000000000000000000080888000000000000245d644444444
00000000e1111d1e0000000000000000e177771e00000000000000009aa9a9a900888ff000000000000000000008880008202880000000000022006644444444
00000000e110d11e0000000000000000e066666e00000000000000009aaaa9f9008822000000000000000000000888800820828000000000024000d044444444
000000001d11107e0000000000000000e777771e00000000000000009a9a9ff0008ddd1000000000000000000000000008008080000000004400000044444444
00000000011601ee0000000000000000ee16611d00000000000000009a9961f00000000000000000000000000000000000002000000000004000000044444444
00000000e01111eee11111eee01111eeee117101ee117101ee11710e99f97cf099f97cf099f97cf0000000005dddddd55dddd8d500000000000dd00000000000
00000000e11d11eee1dd11d7711dd1eeeed1611eedd1611eeed161dd99efff0099efff0099efff0000000000d52d2d58d88dd85d000000000046640000444400
00000000110dd01e10d1011eee10dd0eed016011dd101611ed06111d99eeeee0998ee8e09aeeee0000000000d822288dd858d88d0000000000f66f0000ffff00
000000001110011e11001d1ee111001ee11171111e11117de171111190e88e009088ee8fa0e82ee000000000d888888dd882d28d0000000000f66f0000ffff00
00000000e11111eee111111eddd111eeee11610eee116101ed11610e008ffe0000ff2e2f0088ffe000000000d8d8828dd8d2888d0000000000f44f0000fddf00
00000000d1dd11dee01dd11dd11d11eeed17611de7661011d111176d008ff20001ff22dd00d8ff1000000000dd88288ddd82d28d0000000000ffff0000f66f00
000000001111d11e11111d11111d111ee1766111e1761e1ee1e17611008ddd1000110ddd00dd011000000000d5d8285dd58dd88d0000000000ffff0000f66f00
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000005dd88dd55ddddd25000000000000000000066000
8888888b3333333366d66d6666d666d666d666d6555555555444444500000500242002200000000055555555010101011d11d1d1444444440000000000000000
8888888b333333336dd6dd6d66d666d666d666d655511115445555440111511024422442000000005000d5051d11d1111d11d111444444440222222000000000
8888888b33333333dddddddd66d666d666d666d655551555455445540dddddd002244542000000005000500d1d11dd1d1d11d1d1444444440266dd2000222200
8888888b33333333d6666d66dddddddddddddddd51111155454554540d7506d02445445000000000d000500d11111d1d1d11d1d1444444440264932002444420
888b888b33333333d6d6dd6d66d666d666d666d655155515454554540d0776d024445520555555555ddd5dd51d111d1d1d11d1d12222222202ed8b200446d440
888b888b33333333dddddddd66d666d666d666d651111155455445540d6070d0245544425112222550005005dd11d11d1d11d1112000000202b333200465d640
888b888b3333333366d6666d66d666d6dddddddd55555555445555440dddddd025005542511224255000d00d1d11d11d1000d0012000000202222220044d6440
888b888b333333336dd6d6dd66d666d6dddddddd55555555544444450000000000000055511224255ddd5ddd1dd111d1555d5d55000000000000000000444400
22221111222211114442444433323343555555555515551555555555555555555555555551122425555555551d11d1d18e88e8e8044664400000000002422420
2222111122251111444244444332334455555555111111115dddddddddddddddddddddd5511444255555dd551d11d1118e88e888044764500222222004222240
2222111122555111444244444432344455555555155515555d00000000000000000000d5511222d5555555551d10d0158e88ee8e044444400244f42004242240
2222111122555111444244444432444455555555111111115d00000000000000000000d5511222d55155d5551d11d0158e88e08e0222222002654f2004299240
2222111122555111444244444442444455555555551555155d00000000000000000000d551122425515555555d1155118e885588020000200264f52004299240
2222111122155111444244444442444455555555111111115d00000000000000000000d551222425555555555d1050118e8050880200002002f4552004222240
2222111122115111444244444442444455555555155515555d00000000000000000000d551244425555555555500d0018500d008000000000222222004444440
2222111122121111444244444442444455555555111111115d00000000000000000000d552222225111111115d5d5d515d5d5d58000000000000000000444400
2222111122201111444244444442344455555555555555555d00000000000000000000d505500000555555554444444400000000000000004444444402422420
2222111122005111444244444442334455555555555555555d00000000000000000000d5505500005555595546ddd55400000000002000004040040404222240
dddddddddddddddddddddddddddddddd55555555555535555d00000000000000000000d550055000555595554d6ddd5422555555002000004666666404942240
1111111111111111444444444444444455555555553535555d00000000000000000000d5500ddd00515999554d66ddd42555555500244440466666d404992240
1111111111111111422222d4422222d455555555533333355d00000000000000000000d550000000515559554dd66dd455555255002444402dddddd204222240
111111111111111142ddddd442d3d33455555555533135355d00000000000000000000d550000000555595554ddd66d444444444000222206666666604222240
1111111111111110444444444444444455555555313331335d00000000000000000000d550000000555555554444444445555524000200206333333604444440
0000000000000000222222222222222211111111511511515d00000000000000000000d550000000111111111111111145555524000000003333333300444400
2222222222222222ddd60000666600005dddddd5111151115d00000000000000000000d556666666000000000000000045222224422222243333333300330000
5222445442424444d666000166660000d5dddd5d151111515d00000000000000000000d56ddddddd066666600000000042222224444444443333333300333000
45224545242244446666000166660000dd5dd5dd511111115d00000000000000000000d56dcccccc6dddddd60000000044444444452222243333333300bbb000
52224452422244446666001166660000ddd55ddd115111115d00000000000000000000d56ccccccc6dccccd66666666640401554422222243333333305242500
22222222222222220000dddd00006666ddd55ddd111115115d00000000000000000000d566666666d666666d0666666042913154452229243333333305555500
42554225244442240000d66600006666dd5dd5dd511111115d00000000000000000000d5666666660d6666d000666600429133244222222422222222055dd500
24544254444442420001d66600006666d5dddd5d111511515dddddddddddddddddddddd56666666600000000000660004291232445222224222222220055d000
422542222444422201116666000066665dddddd5151111115555555555555555555555550dd00000000000000000000044444444444444442000000200000000
86e7e7575757575757575757576686c7c7b5c4a4c7c7c7c4a4b5c7c7c7a4a4b5c7c7160616066686b4b4555555c6660000000000000086555555a455668615a4
050515e0e0e066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
865757575757575757575757576686c7c7071707c7c7c7171707c7c7c7171707c7c7d7d4d447668646a6170747d7660000000000000086b4b4b4555566861606
c6160647474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
865757d457575757575757575766861707170717170717070717070717170717474747d4d4476686170707174747660000767777777787a5a6a547d46686d447
d7474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86575757575757571707175757668600000017070000000000170700000017000000474747476686071707071707660000865555a45555474747474766864747
47474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7675757575757575851765757576767575758507657575757575757575757575757575757575767675758517657576000086c65555555547474747476686d647
4747f2f2f24766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
767777777777777777177777777777777777770777777777777777777777777777777777777777777777771777777600008626d4474747474747474766864747
4747d4d4d44766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86253525252525252517253525252525252525073525252525352525252525252525352525252525252525172525660000864747474747474747474767874747
47474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86262626262636262617262626262626262626572626262626362626262626362626262626262626262626572626660000867777777777774747777755554747
47677777777766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8664646464646464575757646464646464645757576464646464646464646464646464646464646464645757576466000086a4a4a4a4a4a44747a4a455554747
47a4a4a4a4a466000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8657575757575757575757575757575757575757575757575757575757575757575757575757575757575757575766000086a4a4a4a4a4a44747a4a447474747
47a4a4a4a4a466000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86646464646464645757576464646464646464646464646457575757575757575757646464646464646457575764660000864747474747474747474747474747
47474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76757575757575758557657575757575757575757575757585f0f0f06585e0e0e065757575757575757585576575760000767575757575757575757575757575
75757575757576000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000076777757777777777777760000000000000086f0f0f06686e0e0e066000000007677777777577777760000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086343427343455b655556600000000000000860000006686e0e0e06600000000860505e505471505660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086444427444455555555660000000000000086000000668600000066000000008606160606470606660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000862727272737272727d4660000000000000000000000000000000000000000008647474747474747660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086272737373737373737660000000000000000000000000000000000000000008647474747474747660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086273737753737373737660000000000000000000000000000000000000000008647474747474747660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086373737762727272727660000000000000000000000000000000000000000007675757575757575760000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000076757575767575757575760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404040404000004000404040404000404040404040404040404040404040404040404040404040400040400040004000000000000040404040400040404040
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6777777777777777777777777767000000000000000000000000000000000000000000000000000000000000000000000067777777777777777777777777670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6854544a5452525252434a4343660000000000000000000000000000000000000000000000000000000000000000000000684343434c434f434a43434343660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
686c6c555562626262444444446600000000000000000000000000000000000000000000000000000000000000000000006844446c4444444444446c6c44660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
687d7d7575464646467373737a660000000000000000000000000000000000000000000000000000000000000000000000684d725a726d4d4d6d7f7d7d2f660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
687575754d58464656727272726667777777777777777767677777777777777777777777777767677777777777776700006872727373737272727272724d660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6767676767684646666767676767686c6c554a4a545555666855554a5445544a4a54555445546668424e425e424e66000068727356575757575757575757670000000000000000006777777777777777777777777777776767777777670000000000000000000000000000000000000000000000000000000000000000000000
684f4242427846467650504e5066687d7d454a4a555555767855644a6464644a4a5555644b4b666842424242426c660000687373767777777777777777776767777777777777776768554f5555555555554343434355556668434444660000000000000000000000000000000000000000000000000000000000000000000000
6842427f6c524646526c60606066687d7d4d7474707170455470717170717070742f2f74646a666875757575757c6600006875755050515e5050505050516668535b5249524b53666855556c6c4b4b555544444444556c6668694444767777670000000000000000000000000000000000000000000000000000000000000000
686e754d7d624646627c755d6e666874747474717170716464707071717071746d4d4d7474746668756d4d6d7575660000687575614f60606060476c616c6668624a6359625b6366687f716b7d64647074747474744d7d66687979726c6b5b660000000000000000000000000000000000000000000000000000000000000000
687e757575464646467575757e666874747470707170717070717070717174747474747474746668757575757575660000687575755f7575755d4d6b757c66687f46757575467f6668707071707170717474747474747466687272727d7a44660000000000000000000000000000000000000000000000000000000000000000
67575757575846465657575757676757575758705657575757575757575757575757575757576767575758755657670000687575757575757575757575756668464675757546466668717170717171707474747474742f6668727373727272660000000000000000000000000000000000000000000000000000000000000000
67777777777846467677777777777777777777707777777777777777777777777777777777777777777777757777670000684d4d7f757575757e7e7e7f7566687e4675757546466668707071707070717474747474744d6668727273737272660000000000000000000000000000000000000000000000000000000000000000
685050505150464650505050505051505050504650505050505150505050505051505050505050505150504650506600006757575757587556575757575767687e467575754646666757587056575757575757575757576767575758725657670000000000000000000000000000000000000000000000000000000000000000
6860616060604646606061606060606060606046606061606060606060606060616060606060606060606046606166000067777777777775777777777777777846467575754646767777777077777777777777777777777777777777727777670000000000000000000000000000000000000000000000000000000000000000
68464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646660000685353535252755253525e525353526d757575757575525252537552524e525253535e525252534e535252755252660000000000000000000000000000000000000000000000000000000000000000
684646464646464646464646464646464646464646464646464646464646464646464646464646464646464646466600006863626362627563626263626362637575757575757562634f6275626c636263626362626c6c6263626362756262660000000000000000000000000000000000000000000000000000000000000000
68464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646660000684675757575757575757575755d757575757575757546465f7575757d4646467f4646467d6b4646464675757546660000000000000000000000000000000000000000000000000000000000000000
675757575757575757575846565757575757575757575757580e0e0e56575757575757575757575758465657575767000068464675757575757575757575757575757575757575757575757575757575757575757575757575757575757546660000000000000000000000000000000000000000000000000000000000000000
000000000000677777777746777777776700000000000000680e0e0e66000000000000000000677777467777777767000068464646467575757575757575757575757575757575757575757575757575757575757575757575757575757546660000000000000000000000000000000000000000000000000000000000000000
00000000000068524e52527552526c6c6600000000000000680e0e0e6600000000000000000068544572544f5454660000675757575757575757575758755657575757575757575757580e0e0e56580f0f0f56575757575757587556575757670000000000000000000000000000000000000000000000000000000000000000
000000000000684f6262627562477d7c66000000000000006800000066000000000000000000686564726464656c660000677777777777777777777777757777776700000000000000680e0e0e66680f0f0f66000000006777777777777777670000000000000000000000000000000000000000000000000000000000000000
000000000000685f75757575754d7c6b6600000000000000000000000000000000000000000068727272725d727c660000686c555555545e5454546b547454456c6600000000000000680e0e0e666800000066000000006840404940404040660000000000000000000000000000000000000000000000000000000000000000
00000000000068756d2f2f6d7575757566000000000000000000000000000000000000000000686d4d7273737373660000687c6c6c6c6464476564646474656c7c660000000000000068000000666800000066000000006840405940404040660000000000000000000000000000000000000000000000000000000000000000
00000000000068756d4d4d6d757e7e7f6600000000000000000000000000000000000000000068724d6d7373737f660000687c7c7d7d7f744d3c7474747474627d660000000000000000000000000000000000000000006841414141414141660000000000000000000000000000000000000000000000000000000000000000
00000000000067575757575757575757670000000000000000000000000000000000000000006757575757575757670000687474747474743b7474747474747474660000000000000000000000000000000000000000006841414141414141660000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068746d2f747474747474746d5d6d7474660000000000000000000000000000000000000000006841414141414141660000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068744d4d74747474747474747474747f660000000000000000000000000000000000000000006757575757575757670000000000000000000000000000000000000000000000000000000000000000
0000000077770000777700000000000000000000000000000000000000000000000000000000000000000000000000000067575757575757575757575757575757670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
677777784b4b76784b4b7677776700000000000000000000000000000000000000000000000000000000000000000000000000004a0000004a00000000004a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
685050504c4c50505b4c50505066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006800000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
686060607575607d7575616b606667777777777777777777777777777777777777777777777767677777777777776700000000000000000000000000000000000000680e0e0e66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
686e6e7575757c7c7575754d7d66686c6c4b4b5b6c6c6c4b4a4b6c6c6c5b4a4b6c6c505051506668554a55554a456600000000000000677777777777676777777777780e0e0e66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400070361003610026100261001610016100261002610066000560005600056000560004600046000360003600036000260002600026000360003600036000360005600056000560006600066000860008604
00050000176630e66011666146501663400000126541665416640116331763014650136431264011630106330e6300f6300e620106200f6200e6100c6100b6100961007610056100461002610006100061000610
01040000217160001513000130001300000000025000c500100001000010000000000550010500130001300013000000000560006600000000000000000000000000000000000000000000000000000000000000
013c00201350013500135001350013500135001350013500185001850018500185001850018500185001850017500175001750017500175001750017500175001150011500115001150011500115001150011500
013c00200705407045000000000011054100420e0420e0450c0440c0350000000000100540e0420c0420c0450b0440b03500000000000b0540904207042070450504405035000000000004054040450804408045
00090000086100c61011620166201a6401e66025670226701e6701e6701767014660126601165010650106500e6500d6400b6400a640086300663006630066200662005610036100261002610016100161001610
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001a44600035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108002018146101450000000000000000000000000000000c300000000000000000000000000000000000000e146001450000000000000000000000000000000c30000000000000000000000000000000000000
010600002164600635000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001027403571102710e5710c27503100101000f100100000f000100000f000100000f000100000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800003465635643356273561135611356150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003462437632376222f61530600356003560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000063600643006350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000010252000000e1520c15200000000000015200002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000201171413711116241372111721137211161413731157441363415741137511575113751156141376111764137611176113614117511362411741137411061411731107311172110721116141071111711
011d0008007320073200732007320073200732007320c736000000000000000000000000000000000000000000000000000000000000000000e00010000120000f000307002f4002130013400392001510000000
011a00200415300000000000000000000001330000000000000000214300000000000000000000000000312300000051330000000000001130000000000000000000000000031430000000000000000013300000
012000100071400711007110071100711007110071100711027110271102711027110271102711027110c7010c7010c7010c7000c1020c1020c1000e1000e1000e10013100141001410013100131000000000000
01100008007150060502715006000071500600027150000009700000000a700000000b700000000a7000000015700000000000000000000000000000000000000000000000000000000000000000000000000000
010800001705500005160550000515055000051405500005130550000512055000051105500005100550d0050f0550f0050e055110050c0550d0050b0550f0050a05511005090551300508055150050705207055
010800000c5340d5340e5440f54410554115541256413564145741557416574175741700018666186630000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 43444304
02 43424344

