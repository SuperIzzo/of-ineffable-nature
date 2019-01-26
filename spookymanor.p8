pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- spookymanor
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

g_drawing_text = false
g_text_waiting_on_input = false
g_text_is_diary = false

camera_x = 0
camera_y = 0

-- the global pools
actors = {}
areas = {}
text_queue = {}
text_displaying = {}

-- main entry points
function _init()
    --pl = add_actor(188,54,0)
    pl = add_actor(25,25,0)
    pl.isplayer = true

    add_game_maps()
end

function _update()
    if not g_drawing_text then 
        foreach(actors, update_actor)
    else
        text_update()
    end

    local cx = (pl.x / 8)
    local cy = (pl.y / 8) + 0.75

    -- loop through areas and show them if need be
    for m in all(areas) do
        if cx >= m.minx and cx < m.maxx and cy >= m.miny and cy < m.maxy then
            if(not m.entered) entered_area(m)

            foreach(m.entities, update_ent)
        else
            if(m.entered) left_area(m)
        end
    end

    g_frame += 1
end

function _draw()

    --clear the screen first
    cls()
    camera(camera_x, camera_y)

    -- loop through areas, if they can show, draw the map and its entities
    for m in all(areas) do
        if m.show then 
            map(m.cx,m.cy, m.cx*8,m.cy*8, m.cex - m.cx,m.cey - m.cy)
            foreach(m.entities, draw_ent)
        end
    end

    -- map(0,0,0,0,16,16,flag_sprite_map_bottom_layer)

    foreach(actors, draw_actor)

    -- map(0,0,0,0,16,16,flag_sprite_map_top_layer)
    
    if (g_drawing_text) text_draw()
    
    local cx = (pl.x / 8)
    local cy = (pl.y / 8) + 0.75
    --print("world x "..pl.x  ..","..pl.y,camera_x,camera_y+100,7)
    --print("map x "..cx  ..","..cy,camera_x,camera_y+110,7)
    --print("cxy "..pl.cx ..","..pl.cy.." mxy "..pl.mx..","..pl.my,camera_x,120,7)
    --print("d: "..dist(pl.x,pl.y,areas[4].entities[1].x,areas[4].entities[1].y), camera_x,camera_y+120,7)
    
   print("fps "..stat(7) ,camera_x + 100,camera_y,7)

   

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

    add_force_to_actor(pl,x,y)

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

    --a.cx = 0
    --a.cy = 0
    --a.mx = 0
    --a.my = 0

    a.anim = { }

    -- if this is a player, setup the player anims
    if at == 0 then
       setup_pl_anims(a)
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


    -- apply global acceleration depending on desired x/y
    a.dx += g_speed_accel * x
    a.dy += g_speed_accel * y


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

function update_actor(a)

    if (a.isplayer) pl_move(a)

    -- convert to world from cell, divide by 8 (due to 1 map cell being 8x8)
    local cx = (a.x / 8)
    local cy = (a.y / 8) + 0.75

    if not is_map_solid(cx, cy, a.dx, a.dy) then
        a.x += a.dx
        a.y += a.dy
    end

end

function draw_actor(a)

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

function add_ent(x,y,s,m)
    local e = {}
    e.x = (m.cx + x) * 8
    e.y = (m.cy + y) * 8
    e.spr = s

    -- 0 = none, 1 = collectable, 2 = openable door
    e.type = 0

    e.triggered = false

    add(m.entities,e)

    return e
end

function draw_ent(e)
    -- once we've "collected" the key, don't want to draw it
    if e.type == 1 then
        if (e.triggered) return
    end

    spr(e.spr,e.x,e.y)
end

function update_ent(e)

    if (e.triggered) return

    -- collectable - static and drawing until player picks it up
    if e.type == 1 then
        if dist(pl.x,pl.y,e.x,e.y) < 7.5 then 
            e.triggered = true
            --text_add("collected a key! __it must be my lucky day, __better put on a lottery ticket then i think!_!_!", true)
            text_add("this is a journal entry, be kind to me, for as i am a fickle beast that should be handled with responsibility.",true)
            -- todo sound effect, maybe ptfx?
        end
    
    -- openable door - locked and has collision while blocker is active
    elseif e.type == 2 then
        if e.bl.triggered then
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

    a.entities = {}

    add(areas,a)

    return a
end

function entered_area(a)
    a.entered = true
    a.show = true

end

function left_area(a)
    a.entered = false
    a.show = false

end

function add_game_maps()
    -- initialise areas that'll show up when you near them
    local firstmap = add_map_area(0,0, 18,18, 0,0, 15,15)

    -- bottom right, and keeping a portion when going top right
    local secondmap = add_map_area(12,09, 32,32, 10,9, 32,29)
    add_map_area(20,02, 29,09, 16,9, 32,16)
    
    -- top right
    local thirdmap = add_map_area(20,02, 29,11, 20,02, 28,09)
    local key = add_ent(3,2,16,thirdmap)
    
    key.type = 1 --make this a collectable

    -- add a door and add the key as a blocker
    local door = add_ent(13,8,126,secondmap)
    door.type = 2
    add_ent_alt_sprite(door,125)
    add_ent_blocker(door,key)

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
            if m.show then 
                for e in all(m.entities) do
                    if e.type == 2 and not e.triggered 
                    and e.x / 8 == cell_x and e.y / 8 == cell_y then
                        return true
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
        elseif mod_x >= 0.3 then
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
            
            -- Wait for button input before we unpause the game
            g_text_waiting_on_input = (not btn(4))

            if g_text_waiting_on_input then
                return
            end

            --Then del all the queued text and reset
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

    -- If a diary, then add everything straight away
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

    -- Every two frames display the next char
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

        -- Blinking text prompt display
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
00000000eeeeeeee0000000000000000eeeeeeee0000000000000000000000000ffffff0000000000a9aaaa00000000000000000000000004544545400000000
00000000eedd11ee0000000000000000ee11ddee00000000000000000000000009ffff9000000000099a9a900000000000000000000000004444444400044000
00700700ed00117e0000000000000000e711d1de0000000000000000009999008ee888e8009999008e9a99980000000000000000000000002222222200044000
00077000e01d106e0000000000000000e6117d0e000000000000000009aaaaa0ffeeee8809aaaaa088e99e880000000000000000000000002122221200022000
00077000e1d7177e0000000000000000e7711d1e000000000000000099a99a9aff8ee888aaa99a9a888998880000000000000000000000005445444544422244
00700700e110066e0000000000000000e661101e00000000000000009aff99aa022888ff9a9aa9a9ff8888800000000000000000000000004444444422222552
000000001d17777e0000000000000000e77711de0000000000000000961ff19a0dd22dd09a9aa9a90dd22dd00000000000000000000000002222222200022000
00000000016666ee0000000000000000ee66011d0000000000000000a7cffc7a00000000aa9aa9a9000000000000000000000000000000002212212200022000
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
22221111222211113332334366d666d666d666d65555555554444445444444445555555555555555555555550101010101080808000000000000000000222200
22221111222211114332334466d666d666d666d655511115445555444000000450000005522222255000d5051d11d1118e88e888044444400222222002444420
22221111222211114432344466d666d666d666d655551555455445544000000450000005524442255000500d1d11dd1d8e88ee8e044444400266dd200446d440
222211112222111144324444dddddddddddddddd5111115545455454400000045000000552444425d000500d11111d1d88888e8e04444440026493200465d640
22221111222211114442444466d666d666d666d655155515454554544000000450000005524445255ddd5dd51d111d1d8e888e8e0222222002ed8b20044d6440
22221111222211114442444466d666d666d666d6511111554554455440000004500000055222252550005005dd11d11dee88e88e0200002002b3332000444400
22221111222211114442444466d666d6dddddddd55555555445555444000000450000005524422255000d00d1d11d11d8e88e88e020000200222222002422420
22221111222211114442444466d666d6dddddddd55555555544444454000000450000005522222255ddd5ddd1dd111d18ee888e8000000000000000004222240
22221111222211114442444466d66d66555555555515551555555555555555555555555555555555d77701101d11d1d18e88e8e8000000000000000004242240
2222111122251111444244446dd6dd6d55555555111111115dddddddddddddddddddddd550005505d77701111d11d1118e88e888044664400222222004299240
222211112255511144424444dddddddd55555555155515555d00000000000000000000d550005005666600011d11d0158e88ee8e044764500244f42004299240
222211112255511144424444d6666d6655555555111111115d00000000000000000000d550005005677701111d11d0158e88e08e0444444002654f2004222240
222211112255511144424444d6d6dd6d55555555551555155d00000000000000000000d5555555550111d66d5d1155118e885588022222200264f52004444440
222211112215511144424444dddddddd55555555111111115d00000000000000000000d5500050050111d7765d1050118e8050880200002002f4552000444400
22221111221151114442444466d6666d55555555155515555d00000000000000000000d5500050050001d6665500d0018500d008020000200222222000000000
2222111122121111444244446dd6d6dd55555555111111115d00000000000000000000d555555555011166665d5d5d515d5d5d58000000000000000000000000
2222111122201111444244444442344455555555555555555d00000000000000000000d500000000000000000000000000000000000000004444444404942240
2222111122005111444244444442334455555555555555555d00000000000000000000d505500000000088000000000000080000002000004222422404992240
dddddddddddddddddddddddddddddddd55553555555555555d00000000000000000000d550550000088888880880080000088000002000004244242404222240
1111111111111111444444444444444455353555555555555d00000000000000000000d550055000888882880880000008888000002444404444444404222240
1111111111111111422222d4422222d453333335555555555d00000000000000000000d5500ddd00088088800000000008808080002444402222222204444440
111111111111111142ddddd442d3d33453313535555555555d00000000000000000000d550000000888088000000888008888880000222202422422200444400
1111111111111110444444444444444431333133555555555d00000000000000000000d550000000008808000000880008088888000200202224224200000000
0000000000000000222222222222222251151151111111115d00000000000000000000d550000000000888000000000088888888000000002242444200000000
2222222222222222ddd600006666000054444445111151115d00000000000000000000d550000000500000000000000000000000444000004444444400000000
5222445442424444d66600016666000045444454151111515d00000000000000000000d556666660566666600000000000000000414000004111111400000000
4522454524224444666600016666000044544544511111115d00000000000000000000d55dddddd65dddddd60000000000000000414000004444444400000000
5222445242224444666600116666000044455444115111115d00000000000000000000d56cccccc6688888866666666600000000444000004555d45400000000
22222222222222220000dddd0000666644455444111115115d00000000000000000000d5d666666dd666666d0666666000000000454a00004545d45400000000
42554225244442240000d6660000666644544544511111115d00000000000000000000d50d6666d00d6666d0006666000000000045400000454505a400000000
24544254444442420001d6660000666645444454111511515dddddddddddddddddddddd50d0000d00d0000d00006600000000000454000004555055400000000
42254222244442220111666600006666544444451511111155555555555555555555555500000000000000000000000000000000444000004444444400000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3030303030303031303030303030303100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3130000000000031003000000030003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000031000000300000003100000000303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3130000000000031003030303030003100000000312020000020203100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000031000000000000003100000000310000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000031003000300030003100000000310000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003100000000310000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000030003000300030003100000000312121000021213100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000030000000000000003100000000303031003030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000303000000030303100000000000031003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000300000003100000000000031003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003130303030303030003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000000000000000000000000003030303030303030003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303000303000000000000031003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003100310030303030303031003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003100310031000000003131003130303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003100310031000000003131000000000000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003100313030003030303031000000000000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003100000000000000300000000000000000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030300000000000000000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000310000000000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000310000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000310000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000310000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000025650246501e650226501e65022650206501d6501d6501c6501b6501965019650276502565019650236501a6501a6501e6502c6501f6501f650296502365026650256502665017650236502165018650
01100000156500e6502165012650116501a6501f65015650276502365013650276502165022650206501a650266501e65029650246501f6501b6501f65025650216501b650246502665026650246502465025650
