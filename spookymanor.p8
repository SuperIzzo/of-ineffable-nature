pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- spookymanor
-- team spook

-- ##################
--       Flags
-- ##################
flag_collision = 6
flag_anim_end = 0


-- ##################
-- Movement Variables
-- ##################

-- Base speed for actors to move at
g_speed_accel = 0.1

-- How many frames between updating character frames
g_anim_update_interval = 5


-- ##################
--    Common vars
-- ##################

-- Global frame count 
g_frame = 0

-- ##################
--    Camera Vars
-- ##################
camera_x = 0
camera_y = 0

-- The global pool of actors
actors = {}

-- Add an actor to the pool: 
-- x pos
-- y pos
-- right sprite animation start index
-- left sprite animation start index
-- up sprite animation start index
-- down sprite animation start index
-- idle sprite animation
function add_actor(x,y,rs,ls,us,ds,is)
    local a = {}

    -- This x and y is world position, in pixels
    a.x = x
    a.y = y

    a.rs = rs
    a.ls = ls
    a.us = us
    a.ds = ds
    a.is = is

    -- Physics delta speed variables.
    a.dx = 0
    a.dy = 0

    -- Facing direction. 0 = right, 1 = down, 2 = left, 3 = up
    a.dir = 0

    -- Is the actor moving
    a.moving = false

    -- Current sprite displaying
    a.spr = 0
    -- Current animation frame timer
    a.frameTime = 0

    add(actors, a)

    return a
end

-- Add movement force to the actor:
-- the actor to add to
-- desired x direction - 0 is still, -1 is left, 1 is right
-- desired y direction - 0 is still, -1 is up, 1 is down
function add_force_to_actor(a,x,y)

    -- TODO Do we want this here? Need to degrade it somehow rather than straight 0?
    a.dx = 0
    a.dy = 0

    -- Any movement at all? Set the actor moving
    a.moving = (x+y != 0)

    -- If not moving, apply the actors idle sprite then EXIT OUT
    if (not a.moving) a.spr = a.is return


    -- MOVEMENT PHYSICS BELOW


    -- Apply global acceleration depending on desired x/y
    a.dx += g_speed_accel * x
    a.dy += g_speed_accel * y


    -- ANIMATION SELECTION BELOW


    -- EXIT OUT if we haven't reached the frame update time
    if (a.frameTime % g_anim_update_interval != 0) return

    -- Keep incrementing the sprite index until we reach a anim end tagged sprite
    if fget(a.spr,flag_anim_end) then
        
        -- We've reached the end, loop to the default direction sprite
        if      a.dir == 0 then a.spr = a.rs --right
        elseif  a.dir == 1 then a.spr = a.ds --down
        elseif  a.dir == 2 then a.spr = a.ls --left
        else                    a.spr = a.us --up
        end

    else 
        a.spr += 1
    end

end

function update_actor(a)



end

function draw_actor(a)

end


-- Player Functions
function pl_move()

    local x = 0
    local y = 0

    -- Left
    if (btn(0)) x = -1

    -- Right
    if (btn(1)) x = 1

    -- Up
    if (btn(2)) y = -1

    -- Down
    if (btn(3)) y = 1

    add_force_to_actor(pl,x,y)

end


-- Main Entry Points
function _init()
    pl = add_actor(20,20)
end

function _update()

end

function _draw()

end