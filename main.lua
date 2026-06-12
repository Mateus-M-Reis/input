local Input = require 'init'

local input = { }

local function map_input(list)
  for _, player_id in ipairs(list) do
    input['p' .. player_id] = Input(player_id)

    -- Using the new gp_ prefix for gamepads
    input['p' .. player_id]:bind('gp_dpup', 'up')
    input['p' .. player_id]:bind('gp_dpdown', 'down')
    input['p' .. player_id]:bind('gp_dpleft', 'left')
    input['p' .. player_id]:bind('gp_dpright', 'right')

    input['p' .. player_id]:bind('gp_a', 'a')
    input['p' .. player_id]:bind('gp_b', 'b')
    input['p' .. player_id]:bind('gp_x', 'x')
    input['p' .. player_id]:bind('gp_y', 'y')

    input['p' .. player_id]:bind('gp_start', 'start')
    input['p' .. player_id]:bind('gp_back', 'back')
    input['p' .. player_id]:bind('gp_guide', 'guide')

    input['p' .. player_id]:bind('gp_r1', 'r1')
    input['p' .. player_id]:bind('gp_l1', 'l1')
  end
end

-- Pass integers (1, 2) instead of strings ('1', '2')
map_input({1, 2})

-- Add p1 keyboard bindings for player 1
input['p1']:bind('w', 'up')
input['p1']:bind('s', 'down')
input['p1']:bind('a', 'left')
input['p1']:bind('d', 'right')

-- These will now work flawlessly alongside the gamepads!
input['p1']:bind('b', 'start')
input['p1']:bind('h', 'back')


function lovr.update(dt)
  input['p1']:update()
  input['p2']:update()

  if input['p1']:pressed('up') then print("Player 1 pressed up") end

  if input['p1']:pressed('a') then print("Player 1 pressed a") end
  if input['p1']:pressed('b') then print("Player 1 pressed b") end
  if input['p1']:pressed('x') then print("Player 1 pressed x") end
  if input['p1']:pressed('y') then print("Player 1 pressed y") end

  if input['p1']:pressed('start') then print("Player 1 pressed start") end
  if input['p1']:pressed('back') then print("Player 1 pressed back") end

  if input['p2']:pressed('start') then print("Player 2 pressed start") end
  if input['p2']:pressed('up') then print("Player 2 pressed up") end
end
