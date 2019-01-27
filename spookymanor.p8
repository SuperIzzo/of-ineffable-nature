pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- of ineffable nature
-- team spook

flag_collision = 6
flag_anim_end = 0
flag_sprite_map_bottom_layer = 6
flag_sprite_map_top_layer = 7

-- base speed for actors to move at
g_speed_accel = 1

-- how many frames between updating character frames
g_anim_update_interval = 5

-- global frame count 
g_frame = 0

g_player_died = false
g_died_init = false

g_drawing_text = false
g_text_waiting_on_input = false
g_text_is_diary = false

g_draw_before_player = false

camera_x = 0
camera_y = 0

-- the global pools
actors = {}
areas = {}
text_queue = {}
text_displaying = {}

just_teleported = false
pause_game_for_warp = false
fade_screen_x = 0
fade_screen_y = 0
fade_screen_frame_time = 0

-- main entry points
function _init()
    --pl = add_actor(188,54,0)
    pl = add_actor(24,256,0) --pixels
    pl.isplayer = true

    add_game_maps()
    add_teleporters()

    mon = add_actor(38,328,1)

    -- play rain loop
    sfx(0, 3)

    -- music has the two middle channels
    music(0, 0, 12)
end

function _update()

    if pl.health <= 0 then
        g_player_died = true
    end

    if g_player_died then
        if not g_died_init then
            g_died_init = true
            
            -- stop the rain, start the dead sound
            sfx(-1, 3)
            music(-1, 300)

            sfx(15)

            wait(15)

            pause_game_for_warp = true
            fade_screen_x = 0
            fade_screen_y = 0

        end

        if fade_screen_y >= 127 then
            wait(15)
            run()
        end
    end

    if not pause_game_for_warp then
        if not g_drawing_text then 
            foreach(actors, update_actor)
        else
            text_update()
        end

        local cx = flr((pl.x / 8))
        local cy = flr((pl.y / 8) + 0.75)

        -- loop through areas and show them if need be
        for m in all(areas) do
            if cx >= m.minx and cx <= m.maxx and cy >= m.miny and cy <= m.maxy then
                if(not m.entered) entered_area(m)

                foreach(m.entities, update_ent)
            else
                if(m.entered) left_area(m)
            end
        end
        
        for t in all(teleporters) do
            if cx >= t.minx and cx <= t.maxx and cy >= t.miny and cy <= t.maxy then
                
                -- we want a nice 'fade out' to happen, so pause everything to do this before warping
                if not pause_game_for_warp then
                    pause_game_for_warp = true
                    fade_screen_x = 0
                    fade_screen_y = 0

                    teleporter_using = t
                end
            end
        end
    else
        process_teleporting()
    end

    g_frame += 1
end

function _draw()

    --clear the screen first
    if not pause_game_for_warp or just_teleported then
        cls()
        
        camera(camera_x, camera_y)

        g_draw_before_player = true

        local visible_areas = {}
        local drawn_areas = {}

        -- loop through areas, if they can show, draw the map
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

        for a in all(actors) do
            draw_actor(a, drawn_areas, false)
        end

        draw_actor(pl, drawn_areas, true)
        g_draw_before_player = false

        for a in all(actors) do
            draw_actor(a, drawn_areas, false)
        end

        -- draw this a second time, but because we're drawing after the player now, only entities 
        --  on a lower y axis to the player will be drawing
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
        --
        -- map(0,0,0,0,16,16,flag_sprite_map_top_layer)
        
        if (g_drawing_text) text_draw()
     else
        draw_teleport_warp()
    end

    if g_player_died then
        rectfill(camera_x+44,camera_y+60,camera_x+87,camera_y+72, 0)
        rect(camera_x+44,camera_y+60,camera_x+87,camera_y+72, 6)
        print("game over", camera_x+48, camera_y+64, 7)
    end

    local cx = (pl.x / 8)
    local cy = (pl.y / 8) + 0.75
   -- print("world x "..pl.x  ..","..pl.y,camera_x,camera_y+100,7)
    --print("map x "..cx  ..","..cy,camera_x,camera_y+110,7)

   --print("fps "..stat(7) ,camera_x + 100,camera_y,7)
end

-- ########################################################################
--                          player functions     start
-- ########################################################################

function pl_move()

    local x = 0
    local y = 0

    -- left
    if (btn(0)) x = -1

    -- right
    if (btn(1)) x = 1

    -- up
    if (btn(2)) y = -1

    -- down
    if (btn(3)) y = 1

    pl.attack = btnp(5)
    pl.use = btnp(5)


    if not just_teleported then
        add_force_to_actor(pl,x,y)
    else
        if (y == 0) just_teleported = false
    end

    camera_x = pl.x - 64
    camera_y = pl.y - 64

end

--- ########################################################################
--                          actor functions     start
-- ########################################################################

function setup_pl_anims(a)
    -- right, down, left, and up consist of 4 frames
    a.anim_sz = { 4, 4, 4, 4 }

    -- the actor transparent colour
    a.tcol = 0

    for i=1, 8 do
        a.anim[i] = {}
        for y=1, 4 do
            a.anim[i][y] = 0
        end
    end
    
    -- walk loop frames alternate so save disk space: frame 1, frame 2, frame 1, frame 3
    -- 1 = upper right
    -- 2 = lower right
    -- 3 = upper down
    -- 4 = lower down
    -- 5 = upper left
    -- 6 = lower left
    -- 7 = upper top
    -- 8 = lower top

    -- upper frames - since they're all the same right now
    for i=1,4 do
        a.anim[1][i] = 39   --right
        a.anim[3][i] = 7    	--down
        a.anim[5][i] = -39   --left
        a.anim[7][i] = 9   	--up
    end

    -- right and left lower frames
    a.anim[2][1] = 55
    a.anim[2][2] = 56
    a.anim[2][3] = 55
    a.anim[2][4] = 57
    
    -- left is the same as right
    for i=1,4 do
        a.anim[6][i] = -a.anim[2][i]
    end

    -- down lower frames
    a.anim[4][1] = 23
    a.anim[4][2] = 24
    a.anim[4][3] = 23
    a.anim[4][4] = -24

    -- up lower frames
    a.anim[8][1] = 25
    a.anim[8][2] = 26
    a.anim[8][3] = 25
    a.anim[8][4] = -26
end

function setup_mon_anims(a)
    -- right, down, left, and up consist of 4 frames
    a.anim_sz = { 4, 4, 4, 4 }
	
	-- the actor transparent colour
    a.tcol = 14
	
    for i=1, 8 do
        a.anim[i] = {}
        for y=1, 4 do
            a.anim[i][y] = 0
        end
    end
    
    -- walk loop frames alternate so save disk space: frame 1, frame 2, frame 1, frame 3
    -- 1 = upper right
    -- 2 = lower right
    -- 3 = upper down
    -- 4 = lower down
    -- 5 = upper left
    -- 6 = lower left
    -- 7 = upper top
    -- 8 = lower top

    -- upper frames - since they're all the same right now
    for i=1,4 do
        a.anim[1][i] = 33   --right
        a.anim[3][i] = 1   	--down
        a.anim[5][i] = 36   --left
        a.anim[7][i] = 4   	--up
    end

    -- right lower frames
    a.anim[2][1] = 49
    a.anim[2][2] = 50
    a.anim[2][3] = 49
    a.anim[2][4] = 51
    
     -- left lower frames
    a.anim[6][1] = 52
    a.anim[6][2] = 53
    a.anim[6][3] = 52
    a.anim[6][4] = 54

    -- down lower frames
    a.anim[4][1] = 17
    a.anim[4][2] = 18
    a.anim[4][3] = 17
    a.anim[4][4] = 19

    -- up lower frames
    a.anim[8][1] = 20
    a.anim[8][2] = 21
    a.anim[8][3] = 20
    a.anim[8][4] = 22
end

-- add an actor to the pool: 
-- x pos
-- y pos
-- actor type: 0 = player
function add_actor(x,y,at)
    local a = {}

    -- this x and y is world position, in pixels
    a.x = x
    a.y = y

    a.attack = false
    a.use = false

    a.health = 100

    a.insamemapasplayer = false

    a.anim = { }

    -- if this is a player, setup the player anims
    if at == 0 then
        setup_pl_anims(a)
    elseif at == 1 then
        setup_mon_anims(a)
    end

    -- physics delta speed variables.
    a.dx = 0
    a.dy = 0

    -- facing direction. 1 = right, 2 = down, 3 = left, 4 = up
    a.dir = 1

    -- is the actor moving
    a.moving = false

    -- current frame displaying; for upper and lower body
    a.frame = 1
    -- current animation frame timer
    a.frametime = 0

    a.isplayer = false

    add(actors, a)

    return a
end

-- add movement force to the actor:
-- the actor to add to
-- desired x direction - 0 is still, -1 is left, 1 is right
-- desired y direction - 0 is still, -1 is up, 1 is down
function add_force_to_actor(a,x,y)

    -- todo do we want this here? need to degrade it somehow rather than straight 0?
    a.dx = 0
    a.dy = 0

    -- any movement at all? set the actor moving
    a.moving = (x != 0 or y != 0)

    -- if not moving, set frame as 1 then exit out
    if (not a.moving) a.frame = 1 return

    if x > 0 then       a.dir = 1 --going right
    elseif x < 0 then   a.dir = 3 --going left
    elseif y > 0 then   a.dir = 2 --going down
    else                a.dir = 4 --going up
    end


    -- movement physics below

    local speed = g_speed_accel

    if (not a.isplayer) speed *= 0.3

    -- apply global acceleration depending on desired x/y
    a.dx += speed * x
    a.dy += speed * y


    -- animation selection below

    a.frametime+=1
    
    -- exit out if we haven't reached the frame update time
    if (a.frametime % g_anim_update_interval != 0)  return

    -- if we've reached the end, reloop
    if a.frame == a.anim_sz[a.dir] then
        a.frame = 1
    else
        a.frame += 1
    end

    a.frametime = 0

end

function math_lerp(a,b,t)
    return a + t * (b - a)
end

function update_actor(a)

    if a.isplayer then 
        pl_move(a)
    else
        -- very simple follow because ghost - maybe change the dist to a los check
        if a.insamemapasplayer or dist(a.x, a.y, pl.x, pl.y) < 32 then

            local x = 0
            local y = 0

            -- send in the direction to move to get to the player. gate behind
            --  abs 0.2 check to fix flickering when on the same axis
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

            add_force_to_actor(a, x, y)

        end
    end

    -- convert to world from cell, divide by 8 (due to 1 map cell being 8x8)
    local cx = (a.x / 8)
    local cy = (a.y / 8) + 0.75

    if not a.isplayer or not is_map_solid(cx, cy, a.dx, a.dy) then
        a.x += a.dx
        a.y += a.dy
    end

end

function draw_actor(a, drawn_areas, drawplayer)

    if not a.isplayer then

        -- wait until after the player has drawn if this entity would be on top
        --  or always drawing on top, don't draw before
        if g_draw_before_player then
            if(a.y > pl.y) return
        else
            -- then if we drew on bottom don't draw on top
            if(a.y <= pl.y) return
        end
        
        local cx = flr((a.x / 8))
        local cy = flr((a.y / 8) + 0.75)

        local invisiblemap = false

        a.insamemapasplayer = false

        for m in all(drawn_areas) do
            if cx >= m.minx and cx <= m.maxx and cy >= m.miny and cy <= m.maxy then
                invisiblemap = true

                -- hacky and lazy way but easy
                local pcx = flr((pl.x / 8))
                local pcy = flr((pl.y / 8) + 0.75)

                if pcx >= m.minx and pcx <= m.maxx and pcy >= m.miny and pcy <= m.maxy then
                    a.insamemapasplayer = true
                end
            end
        end

        if (not invisiblemap) return
        
    elseif not drawplayer then
        return
    end

    local dir = a.dir*2

    -- if we have a custom bg colour, stop it drawing
    if (a.tcol != 0) palt(a.tcol, true)

    -- upper
    local frame = a.anim[dir-1][a.frame]
	local flip = false
	if (frame < 0) frame = -frame   flip = true
    spr(frame,     a.x,    a.y - 8,    1.0,    1.0, flip)
    
    -- lower
	frame = a.anim[dir][a.frame]
	flip = false
	if (frame < 0) frame = -frame    flip = true
    spr(frame,       a.x,    a.y,        1.0,    1.0, flip)

    -- then reenable it to draw
    if (a.tcol != 0) palt(a.tcol, false)

end

-- ########################################################################
--                          entity functions     start
-- ########################################################################

function add_ent_blocker(e, b)
    e.bl = b
end

function add_ent_alt_sprite(e,s)
    e.spralt = s
end

function disable_ent_collision(e)
    e.coll = false
end

-- xy is in cell coords. su and sl are upper and lower sprites, su is optional
--  m = the map to tie this to. 
function add_ent(m, x,y,sp,ontop,drawblack,fliph,flipv)
    local e = {}

    e.x = x * 8
    e.y = y * 8
    e.spr = sp

    -- 0 = none, 1 = collectable, 2 = openable door
    e.type = 0

	-- enable collision for all entities by default
    e.coll = not ontop -- fget(sp, flag_collision)

    e.triggered = false
    e.ontop = ontop
    e.drawblack = drawblack
    e.fliph = fliph
    e.flipv = flipv

    add(m.entities,e)

    return e
end

function draw_ent(e)
    -- once we've "collected" the key, don't want to draw it
    if e.type == 1 then
        if (e.triggered) return
    end
    
    -- wait until after the player has drawn if this entity would be on top
    --  or always drawing on top, don't draw before
    if g_draw_before_player then
        if(e.y > pl.y) return
        if(e.ontop) return
    elseif not e.ontop then
        -- then if we drew on bottom don't draw on top
        if(e.y <= pl.y) return
    end

    if (e.drawblack) palt(0, false)
	
	if type(e.spr) == "number" then
		spr(e.spr,e.x,e.y, 1,1, e.fliph, e.flipv)
	elseif type(e.spr) == "table" then 
		-- can make this a loop instead
		spr(e.spr[1],e.x,e.y, 1,1, e.fliph, e.flipv)
		spr(e.spr[2],e.x,e.y-8, 1,1, e.fliph, e.flipv)
	elseif type(e.spr) == "function" then
		e:spr()
	end

    if (e.drawblack) palt(0, true)
end

function update_ent(e)

    if (e.triggered) return

    -- collectable - static and drawing until player picks it up
    if e.type == 1 then
        if dist(pl.x,pl.y,e.x,e.y) < 7.5 then 
            e.triggered = true
            --text_add("collected a key! __it must be my lucky day, __better put on a lottery ticket then i think!_!_!", true)
            --text_add("this is a journal entry, be kind to me, for as i am a fickle beast that should be handled with responsibility.",true)
            -- todo sound effect, maybe ptfx?
        end
    
    -- openable door - locked and has collision while blocker is active
    elseif e.type == 2 then
        if e.bl and e.bl.triggered then
            if dist(pl.x,pl.y,e.x,e.y) < 16 then 
                e.triggered = true
                e.spr = e.spralt
            end
        end
    end
end

-- ########################################################################
--                          area mapping functions     start
-- ########################################################################


-- adds a map area that'll reveal upon the player entering the area
-- minx,miny,maxx,maxy = area the player must be in to show this area.
-- cx,cy = map cell start for this area.
-- cex,cey = end cell x and y to draw to
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
    if (g_draw_before_player) map(m.cx,m.cy, m.cx*8,m.cy*8, m.cex - m.cx,m.cey - m.cy)
    foreach(m.entities, draw_ent)
end


s_chair 			= 109
s_table 			= 77
s_small_table = 93
s_shelf_top 	= 108
s_mirror			= 107
s_bookshelf	= 124
s_cupboard		= 125
s_safe				= 125
s_baththub		= 121
s_shower		= 105
s_clock 			= 79
s_gfclock_bot	= 95
s_gfclock			= {s_gfclock_bot,s_clock}
s_door_top 		= 73
s_door_bot		= 89
s_door				=	{s_door_bot ,s_door_top}
s_plant			= 127
s_photo1			= 78
s_photo2			= 94
s_sink				= 122
s_toilet_back	= 122

function add_area_f1_main_bedroom()
	local area = add_map_area(   0,27,13,39,     0,27,13,36)	 

    add_ent(area,	3,	31,		s_small_table)

    add_ent(area,	2,	34,		s_chair)
    add_ent(area,	3,	34,		s_table)
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
	
	add_ent(area,	12,	40,		s_gfclock)
	
	add_ent(area,	13,	40,		s_plant)
	add_ent(area,	17,	40,		s_plant)
	add_ent(area,	21,	40,		s_plant)
	add_ent(area,	26,	40,		s_plant)
	add_ent(area,	31,	40,		s_plant)
	
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
	add_ent(area,	34,	33,		s_safe)
	
	return area
end

function add_game_maps()

    -- first floor placement

    --    rooms                             player xy       cell xy
    local f1_main_bedroom = add_area_f1_main_bedroom()
    local f1_corridor = add_area_f1_corridor()
    local f1_bathroom = add_area_f1_bathroom()
    local f1_library = add_area_f1_library()
    local f1_storage = add_map_area(        39,30,46,39,    39,30,46,36)
    local f1_spare_bedroom = add_map_area(  38,43,46,50,    38,44,46,50)
    local f1_stairs = add_map_area(         24,43,33,46,    24,44,33,46)	
	
	-- corridor props	
	local f1_ceil_one = add_ent(f1_corridor, 9,38,  {82, 119}, false, true)
    disable_ent_collision(f1_ceil_one)
	
	local f1_bedroom_door = add_ent(f1_corridor, 9,39, s_door)
    f1_bedroom_door.type = 2
    f1_bedroom_door.triggered = true --todo remove	

    --add_map_link(f1_main_bedroom, f1_corridor, f1_bedroom_door)
    add_map_link(f1_bathroom, f1_corridor)
    add_map_link(f1_library, f1_corridor)
    add_map_link(f1_storage, f1_corridor)
    add_map_link(f1_spare_bedroom, f1_corridor)
    add_map_link(f1_stairs, f1_corridor)
    
    add_map_link(f1_corridor, f1_bathroom)
    add_map_link(f1_corridor, f1_library)
    add_map_link(f1_corridor, f1_storage)
    add_map_link(f1_corridor, f1_spare_bedroom)
    add_map_link(f1_corridor, f1_stairs)
    add_map_link(f1_corridor, f1_main_bedroom)
		
	
	-- second floor
	local f2_corridor 				= add_map_area(0,11,46,17,    	0,11,46,17)
	local f2_corridor_anex 	= add_map_area(5,0,8,10,    			5,0,8,10)	
	local f2_storage 				= add_map_area(0,0,4,4,    			0,0,4,4)
	local f2_toilet 					= add_map_area(9,0,13,4,    			9,0,13,4)
	local f2_bedroom1			= add_map_area(0,6,4,10,    			0,6,4,10)
	local f2_bedroom2			= add_map_area(9,6,13,10,    		9,6,13,10)
	local f2_livingroom			= add_map_area(6,18,16,24,    	6,18,16,24)
	local f2_construction_a	= add_map_area(14,4,23,10,    	14,4,23,10)
	local f2_construction_b	= add_map_area(24,4,38,10,    	24,4,38,10)
	local f2_peaceroom		= add_map_area(39,4,46,10,    	39,4,46,10)
	local f2_office					= add_map_area(38,18,46,24,   	38,18,46,24)
	
	add_map_link(f2_corridor, f2_corridor_anex)
	add_map_link(f2_corridor_anex, f2_corridor)
	
	-- anex rooms
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
	

    -- this ceiling needs to be added to the corrider, otherwise it shows up in the first flow section
    --local ff_ceil_two = add_ent(10,0, 119, ff_corridor, true, true)
    --disable_ent_collision(ff_ceil_two)

    -- ground floor placement
end

-- ########################################################################
--                          teleporter functions     start
-- ########################################################################

teleporters = {}

-- adds a teleporter to be looking out to teleport the player
--  min/max of the activation area, destination xy, and if facing down. in cell coords
function add_teleporter(minx,miny,maxx,maxy, desx, desy, d)
    local t = {}

    t.minx = minx
    t.miny = miny
    t.maxx = maxx
    t.maxy = maxy
    t.desx = desx
    t.desy = desy
    t.face_down = d

    add(teleporters,t)
end

function add_teleporters()
    
    -- 2nd to 1st floor
    add_teleporter(25,19, 27,19,  31,43, false)

    -- 1st to 2nd floor
    add_teleporter(30,45, 32,45,  75,19, false)
	
    -- 1st to ground floor
    add_teleporter(25,44, 27,44,  26,17, false)

    -- ground to 1st floor
    add_teleporter(74,21, 76,21,  26,43, false)
	
    -- ground to basement floor
    add_teleporter(79,20, 81,20,  68,32, true)

    -- basement to ground floor
    add_teleporter(67,30, 69,30,  80,19, false)
end

function process_teleporting()
    if fade_screen_y >= 127 and not g_player_died then

        pl.x = teleporter_using.desx * 8
        pl.y = teleporter_using.desy * 8
        camera_x = pl.x - 64
        camera_y = pl.y - 64

        pl.dx = 0
        pl.dy = 0

        pl.frame = 1
        
        if(not teleporter_using.face_down) pl.dir = 4

        just_teleported = true
        pause_game_for_warp = false

    end
end

function draw_teleport_warp()
    if fade_screen_y <= 127 and fade_screen_y >= 0 then
        
        
        if (fade_screen_frame_time < 1) fade_screen_frame_time+=1 return

        local amount_per_frame = 6
        
        for y=0, fade_screen_y + amount_per_frame do
            
            for x=fade_screen_x, fade_screen_x + 63 do
                pset(camera_x+x,camera_y+y-1,0)
            end
        end

        if (fade_screen_frame_time < 3) fade_screen_frame_time+=1 return
        
        if(fade_screen_y == 0) sfx(21)

        fade_screen_x += 64

        for y=0, fade_screen_y + amount_per_frame do
            
            for x=fade_screen_x, fade_screen_x + 63 do
                pset(camera_x+x,camera_y+y-1,0)
            end
        end

        fade_screen_x = 0
        fade_screen_frame_time = 0

        fade_screen_y += amount_per_frame+1
    end
end

-- ########################################################################
--                          physics functions     start
-- ########################################################################

function is_cell_solid(x,y)
    return fget(mget(x,y), flag_collision)
end

-- current position x,y, then direction x,y
function is_map_solid(x,y,dx,dy)

    -- get the remainder
    local mod_x = x % 1
    local mod_y = y % 1

    -- and the absolute cell position
    local cell_x = x - mod_x
    local cell_y = y - mod_y
    
    -- radius to the walls

    -- when within a radius to a wall, add the direction to the cell check
    --  to check the next one we would run into
    if dx != 0 and mod_x <= 0.15 then
        cell_x += dx
    end

    -- like above but the y needs slightly different values
    if dy == -1 and mod_y <= 0.5 then
        cell_y += dy
    elseif dy == 1 and mod_y >= 0.75 then
        cell_y += dy
    end

    -- debug only
    -- pl.cx = cell_x
    -- pl.cy = cell_y
    -- pl.mx = mod_x
    -- pl.my = mod_y
    
    -- if we're not moving, we don't need to check
    if dx != 0 or dy != 0 then

        -- super hacky, surely a better way?
        -- list through the active area entities, see if one is a door and if it's on the cell
        --  we're checking, we've got collision
        for m in all(areas) do
            if m.show or m.linkshow then 
                for e in all(m.entities) do
                    if e.coll and not e.triggered then
                        if e.x / 8 == cell_x and e.y / 8 == cell_y then
                            return true
                        
                        -- annoying issue with clipping into a right side wall and being able to still move upwards
                        --  doing this will check for the next block over from the current if overhanging into that
                        --  column by more than a distance of 0.3
                        elseif mod_x >= 0.15 and e.x / 8 == cell_x+1 and e.y / 8 == cell_y then
                            return true
                        end
                    end
                end
            end
        end

        -- if the cell we're moving to is solid, cannot move
        if is_cell_solid(cell_x, cell_y) then
            return true
        
        -- annoying issue with clipping into a right side wall and being able to still move upwards
        --  doing this will check for the next block over from the current if overhanging into that
        --  column by more than a distance of 0.3
        elseif mod_x >= 0.15 then
            return is_cell_solid(cell_x+1, cell_y)
        end
    end
end

function dist(ax, ay, bx, by)
    local x_diff = ax - bx
    local y_diff = ay - by

    return sqrt(x_diff * x_diff + y_diff * y_diff)
end

-- ########################################################################
--                          popup text functions     start
-- ########################################################################

text_displayline = 1
text_displaychar = 1
text_actualchar = 1
text_displaytimer = 0

function text_update()

    if (#text_queue == 0) return

    -- if we've above the character count for this line, either go to the next or delete everything
    if text_displaychar > #text_queue[1][text_displayline] then

        if text_displayline >= #text_queue[1] then
            
            -- wait for button input before we unpause the game
            g_text_waiting_on_input = (not btn(4))

            if g_text_waiting_on_input then
                return
            end

            --then del all the queued text and reset
            for i=1, #text_queue[1] do
                del(text_queue, text_queue[1][i])
            end

            text_displayline = 1
            text_displaychar = 1
            text_actualchar = 1
            text_displaytimer = 0

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

    -- if a diary, then add everything straight away
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

    -- every two frames display the next char
    if (text_displaytimer < 1) text_displaytimer += 1 return
    text_displaytimer = 0

    if sub(text_queue[1][text_displayline], text_displaychar, text_displaychar) == "_" then
        text_displaytimer = -4
        text_displaychar += 1
        return
    end

   -- log(""..text_displaying[text_displayline].." <- "..sub(text_queue[1][text_displayline], text_displaychar, text_displaychar))

    text_displaying[text_displayline] = text_displaying[text_displayline] ..sub(text_queue[1][text_displayline], text_displaychar, text_displaychar)

    text_displaychar += 1
    text_actualchar += 1
    
end

function text_add(str, d)

    local textlines = {}

    local char = ""
    local word = ""
    local line = ""

    local line_limit = 26
    if (d) line_limit = 24

    local addtoline = function()
        
        -- if we're over the textbox width, lets add to the lines and move on
        if #word + #line > line_limit then
            add(textlines, line)
            line = ""
        end

        -- append the rest of the word before continuing
        line = line ..word
        word = ""

    end

    for i=1, #str do
        
        char = sub(str,i,i)
        word = word ..char
        
        --if we've encountered a space
        if (char == " ") addtoline()

    end

    -- add anything left over into the text (if it's over the width)
    addtoline()

    -- add the rest of the line if haven't already
    if (line != "") add(textlines, line)

    add(text_queue, textlines)

    for i=1, #textlines do
        add(text_displaying,"")
    end

    g_drawing_text = true
    g_text_is_diary = d

    text_displaytimer = 0

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

    if g_text_waiting_on_input then
        text_displaytimer += 1

        -- blinking text prompt display
        if(text_displaytimer >= 0 and text_displaytimer < 30) pal(6, 5)
        spr(123, box_end_x - 12, box_end_y - 10)
        pal()

        if (text_displaytimer > 60) text_displaytimer = 0
    end

end

-- ########################################################################
--                          debug/misc functions     start
-- ########################################################################

function wait(a) for i = 1,a do flip() end end

function log(msg)
    printh(g_frame..": "..msg, "log.txt")
end



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
00000000eeeeeeee0000000000000000eeeeeeee00000000000000000000000099f97cf000000000000000000000000000000000000000000000000000000000
00000000eedd11ee0000000000000000eedd11ee00000000000000000000000099efff0000000000000000000000000000000000000000000000000000000000
00000000ed11d11e0000000000000000ed11711e00000000000000000990999099eeeee000000000000000000000000000000000000000000000000000000000
00000000e1d1011e0000000000000000e106661e000000000000000099a9aa9990e88ff000000000000000000000000000000000000000000000000000000000
00000000e1111d1e0000000000000000e177771e00000000000000009aa9a9a900888ff000000000000000000000000000000000000000000000000000000000
00000000e110d11e0000000000000000e066666e00000000000000009aaaa9f90088220000000000000000000000000000000000000000000000000000000000
000000001d11107e0000000000000000e777771e00000000000000009a9a9ff0008ddd1000000000000000000000000000000000000000000000000000000000
00000000011601ee0000000000000000ee16611d00000000000000009a9961f00000000000000000000000000000000000000000000000000000000000000000
00000000e01111eee11111eee01111eeee117101ee117101ee11710e99f97cf099f97cf099f97cf0000000000000000000000000000000000000000000000000
00000000e11d11eee1dd11d7711dd1eeeed1611eedd1611eeed161dd99efff0099efff0099efff00000000000000000000000000000000000000000000000000
00000000110dd01e10d1011eee10dd0eed016011dd101611ed06111d99eeeee0998ee8e09aeeee00000000000000000000000000000000000000000000000000
000000001110011e11001d1ee111001ee11171111e11117de171111190e88e009088ee8fa0e82ee0000000000000000000000000000000000000000000000000
00000000e11111eee111111eddd111eeee11610eee116101ed11610e008ffe0000ff2e2f0088ffe0000000000000000000000000000000000000000000000000
00000000d1dd11dee01dd11dd11d11eeed17611de7661011d111176d008ff20001ff22dd00d8ff10000000000000000000000000000000000000000000000000
000000001111d11e11111d11111d111ee1766111e1761e1ee1e17611008ddd1000110ddd00dd0110000000000000000000000000000000000000000000000000
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
8888888b3333333366d66d6666d666d666d666d6555555555444444500000500242002200000000055555555010101011d11d1d1444444440000000000000000
8888888b333333336dd6dd6d66d666d666d666d655511115445555440111511024422442000000005000d5051d11d1111d11d111444444440222222000000000
8888888b33333333dddddddd66d666d666d666d655551555455445540dddddd002244542000000005000500d1d11dd1d1d11d1d1444444440266dd2000222200
8888888b33333333d6666d66dddddddddddddddd51111155454554540d7506d02445445000000000d000500d11111d1d1d11d1d1444444440264932002444420
888b888b33333333d6d6dd6d66d666d666d666d655155515454554540d0776d024445520555555555ddd5dd51d111d1d1d11d1d12222222202ed8b200446d440
888b888b33333333dddddddd66d666d666d666d651111155455445540d6070d0245544425112222550005005dd11d11d1d11d1112000000202b333200465d640
888b888b3333333366d6666d66d666d6dddddddd55555555445555440dddddd025005542511224255000d00d1d11d11d1000d0012000000202222220044d6440
888b888b333333336dd6d6dd66d666d6dddddddd55555555544444450000000000000055511224255ddd5ddd1dd111d1555d5d55000000000000000000444400
22221111222211114442444433323343555555555515551555555555555555555555555551122425111111111d11d1d18e88e8e8044664400000000002422420
2222111122251111444244444332334455555555111111115dddddddddddddddddddddd551144425222222221d11d1118e88e888044764500222222004222240
2222111122555111444244444432344455555555155515555d00000000000000000000d5511222d5111111111d10d0158e88ee8e044444400244f42004242240
2222111122555111444244444432444455555555111111115d00000000000000000000d5511222d5222222221d11d0158e88e08e0222222002654f2004299240
2222111122555111444244444442444455555555551555155d00000000000000000000d551122425111111115d1155118e885588020000200264f52004299240
2222111122155111444244444442444455555555111111115d00000000000000000000d551222425222222225d1050118e8050880200002002f4552004222240
2222111122115111444244444442444455555555155515555d00000000000000000000d551244425111111115500d0018500d008000000000222222004444440
2222111122121111444244444442444455555555111111115d00000000000000000000d552222225111111115d5d5d515d5d5d58000000000000000000444400
2222111122201111444244444442344455555555555555555d00000000000000000000d505500000555555554444444400000000000000004444444402422420
2222111122005111444244444442334455555555555555555d0000000dddddd0000000d5505500005555595546ddd55400000000002000004040040404222240
dddddddddddddddddddddddddddddddd55555555555535555d0000000d0000d0000000d550055000555595554d6ddd5422555555002000004666666404942240
1111111111111111444444444444444455555555553535555d0000000d0000d0000000d5500ddd00515999554d66ddd42555555500244440466666d404992240
1111111111111111422222d4422222d455555555533333355d0000000d0000d0000000d550000000515559554dd66dd455555255002444402dddddd204222240
111111111111111142ddddd442d3d33455555555533135355d0000000d0000d0000000d550000000555595554ddd66d444444444000222206666666604222240
1111111111111110444444444444444455555555313331335d0000000dddddd0000000d550000000555555554444444445555524000200206333333604444440
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
865757d457575757575757575766861707170717170717070717070717170717474747d4d4476686170707174747660000767777777787a646a647d46686d447
d7474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86575757575757571707175757668600000017070000000000170700000017000000474747476686071707071707660000865555a45555474747474766864747
47474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7675757575757575851765757576767575758507657575757575757575757575757575757575767675758517657576000086c65555555547474747476686d647
4747d4d4d44766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
767777777777777777177777777777777777777777777777777777777777777777777777777777777777777777777600008626d4474747474747474766864747
4747d4d4d44766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86253525252525252517253525252525252525943525252525352525252525252525352525252525252525942525660000864747474747474747474767874747
47474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86262626262636262617262626262626262626842626262626362626262626362626262626262626262626952626660000867777777777774747777755554747
47677777777766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8664646464646464575757646464646464645757576464646464646464646464646464646464646464645757576466000086a4a4a4a4a4a44747a4a455554747
47a4a4a4a4a466000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8657575757575757575757575757575757575757575757575757575757575757575757575757575757575757575766000086a4a4a4a4a4a44747a4a447474747
47a4a4a4a4a466000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
86646464646464645757576464646464646464646464646457575757575757575757646464646464646457575764660000864747474747474747474747474747
47474747474766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76757575757575758557657575757575757575757575757585f0f0f06585e0e0e065757575757575757585576575760000767575757575757575757575757575
75757575757576000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000076777777777777777777760000000000000086f0f0f06686e0e0e066000000007677777777777777760000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086343494343455b655556600000000000000860000006686e0e0e06600000000860505e505941505660000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000086444495444455555555660000000000000086000000668600000066000000008606160606950606660000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040404040404000004000404040404000404040404040404040400040404040404040404040404040400040400040004000000000000040404040400040404040
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6777777777777777777777777767000000000000000000000000000000000000000000000000000000000000000000000067777777777777777777777777670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6854544a5452525252434a4343660000000000000000000000000000000000000000000000000000000000000000000000684343434c434f434a43434343660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
686c6c555562626262444444446600000000000000000000000000000000000000000000000000000000000000000000006844446c4444444444446c6c44660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
687d7d7575464646467373737a660000000000000000000000000000000000000000000000000000000000000000000000684d726a726d4d4d6d7f7d7d4d660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
687575754d58464656727272726667777777777777777767677777777777777777777777777767677777777777776700006872727373737272727272724d660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6767676767684646666767676767686c6c554a4a545555666855554a5445544a4a54555445546668424e425e424e66000068727356575757575757575757670000000000000000006777777777777777777777777777776767777777670000000000000000000000000000000000000000000000000000000000000000000000
684f4242427846467650504e5066687d7d454a4a555555767855644a6464644a4a5555644b4b666842424242426c660000687373767777777777777777776767777777777777776768554f5555555555554343434355556668434444660000000000000000000000000000000000000000000000000000000000000000000000
6842427f6c524646526c60606066687d7d4d7474707170455470717170717070744d4d74646a666875757575757c6600006875755050515e5050505050516668535b5249524b53666855556c6c4b4b555544444444556c6668694444767777670000000000000000000000000000000000000000000000000000000000000000
686e754d7d624646627c755d6e666874747474717170716464707071717071746d4d4d7474746668756d4d6d7575660000687575614f60606060476c616c6668624a6359625b6366687f716b7d64647074747474744d7d66687979726c6b5b660000000000000000000000000000000000000000000000000000000000000000
687e757575464646467575757e666874747470707170717070717070717174747474747474746668757575757575660000687575755f7575755d4d6b757c66687f46757575467f6668707071707170717474747474747466687272727d7a44660000000000000000000000000000000000000000000000000000000000000000
67575757575846465657575757676757575758705657575757575757575757575757575757576767575758755657670000687575757575757575757575756668464675757546466668717170717171707474747474744d6668727373727272660000000000000000000000000000000000000000000000000000000000000000
67777777777846467677777777777777777777777777777777777777777777777777777777777777777777777777670000684d4d7f757575757e7e7e7f7566687e4675757546466668707071707070717474747474744d6668727273737272660000000000000000000000000000000000000000000000000000000000000000
685050505150464650505050505051505050505050505050505150505050505051505050505050505150504950506600006757575757587556575757575767687e467575754646666757587056575757575757575757576767575758725657670000000000000000000000000000000000000000000000000000000000000000
6860616060604646606061606060606060606060606061606060606060606060616060606060606060606059606166000067777777777777777777777777777846467575754646767777777777777777777777777777777777777777777777670000000000000000000000000000000000000000000000000000000000000000
68464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646660000685353535252495253525e525353526d757575757575525252534952524e525253535e525252534e535252495252660000000000000000000000000000000000000000000000000000000000000000
684646464646464646464646464646464646464646464646464646464646464646464646464646464646464646466600006863626362625963626263626362637575757575757562634f6259626c636263626362626c6c6263626362596262660000000000000000000000000000000000000000000000000000000000000000
68464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646660000684675757575757575757575755d757575757575757546465f7575757d4646467f4646467d6b4646464675757546660000000000000000000000000000000000000000000000000000000000000000
675757575757575757575846565757575757575757575757580e0e0e56575757575757575757575758465657575767000068464675757575757575757575757575757575757575757575757575757575757575757575757575757575757546660000000000000000000000000000000000000000000000000000000000000000
000000000000677777777777777777776700000000000000680e0e0e66000000000000000000677777777777777767000068464646467575757575757575757575757575757575757575757575757575757575757575757575757575757546660000000000000000000000000000000000000000000000000000000000000000
00000000000068524e52524952526c6c6600000000000000680e0e0e6600000000000000000068544549544f5454660000675757575757575757575758755657575757575757575757580e0e0e56580f0f0f56575757575757587556575757670000000000000000000000000000000000000000000000000000000000000000
000000000000684f6262625962477d7c66000000000000006800000066000000000000000000686564596464656c660000677777777777777777777777777777776700000000000000680e0e0e66680f0f0f66000000006777777777777777670000000000000000000000000000000000000000000000000000000000000000
000000000000685f75757575754d7c6b6600000000000000000000000000000000000000000068727272725d727c660000686c555555545e5454546b544954456c6600000000000000680e0e0e666800000066000000006840404940404040660000000000000000000000000000000000000000000000000000000000000000
00000000000068756d4d4d6d7575757566000000000000000000000000000000000000000000686d4d7273737373660000687c6c6c6c6464476564646459656c7c660000000000000068000000666800000066000000006840405940404040660000000000000000000000000000000000000000000000000000000000000000
00000000000068756d4d4d6d757e7e7f6600000000000000000000000000000000000000000068724d6d7373737f660000687c7c7d7d7f744d747474747474627d660000000000000000000000000000000000000000006841414141414141660000000000000000000000000000000000000000000000000000000000000000
0000000000006757575757575757575767000000000000000000000000000000000000000000675757575757575767000068747474747474747474747474747474660000000000000000000000000000000000000000006841414141414141660000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068746d4d747474747474746d5d6d7474660000000000000000000000000000000000000000006841414141414141660000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068744d4d74747474747474747474747f660000000000000000000000000000000000000000006757575757575757670000000000000000000000000000000000000000000000000000000000000000
0000000077770000777700000000000000000000000000000000000000000000000000000000000000000000000000000067575757575757575757575757575757670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
677777784b4b76784b4b7677776700000000000000000000000000000000000000000000000000000000000000000000000000004a0000004a00000000004a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
685050504c4c50505b4c50505066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006800000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
686060607575607d7575616b606667777777777777777777777777777777777777777777777767677777777777776700000000000000000000000000000000000000680e0e0e66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
686e6e7575757c7c7575754d7d66686c6c4b4b5b6c6c6c4b4a4b6c6c6c5b4a4b6c6c505051506668554a55554a456600000000000000677777777777676777777777780e0e0e66000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010400070361003610026100261001610016100261002610066000560005600056000560004600046000360003600036000260002600026000360003600036000360005600056000560006600066000860008604
01050020176430e63011626146201662400000126341663416630116331762014620136331263011620106230e6100f6100e610106100f6100e6100c6100b6100961007610056100461002610006100061000610
01040000217160001513000130001300000000025000c500100001000010000000000550010500130001300013000000000560006600000000000000000000000000000000000000000000000000000000000000
013c00201353413521135111351113511135111351113515185341852118511185111851118511185111851517534175211751117511175111751117511175151153411521115111151111511115111151111515
013c00200705407045000000000011054100420e0420e0450c0440c0350000000000100540e0420c0420c0450b0440b03500000000000b0540904207042070450504405035000000000004054040450804408045
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001a41600015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108002018116101150000000000000000000000000000000c300000000000000000000000000000000000000e116001150000000000000000000000000000000c30000000000000000000000000000000000000
010600002161600615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001021403511102110e5110c21503100101000f100100000f000100000f000100000f000100000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800003465635643356273561135611356150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003462437632376222f61530600356003560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000063600643006350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000010252000000e1520c15200000000000015200002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000201171413711116241372111721137211161413731157441363415741137511575113751156141376111764137611176113614117511362411741137411061411731107311172110721116141071111711
011d0008007120071200712007120071200712007120c716000000000000000000000000000000000000000000000000000000000000000000e00010000120000f000307002f4002130013400392001510000000
011a00200415300000000000000000000001330000000000000000214300000000000000000000000000312300000051330000000000001130000000000000000000000000031430000000000000000013300000
012000100071400711007110071100711007110071100711027110271102711027110271102711027110c7010c7010c7010c7000c1020c1020c1000e1000e1000e10013100141001410013100131000000000000
01100008007150060502715006000071500600027150000009700000000a700000000b700000000a7000000015700000000000000000000000000000000000000000000000000000000000000000000000000000
010800001705500005160550000515055000051405500005130550000512055000051105500005100550d0050f0550f0050e055110050c0550d0050b0550f0050a05511005090551300508055150050705207055
__music__
02 43040343
02 43424344

