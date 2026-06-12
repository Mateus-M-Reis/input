local Input = require "init"

local input
local controllerInstance

function lovr.load()
  -- Default configuration for the adapted Input module
  input = Input.new({
    controls = {
      left =  { 'key:a', 'key:left',  'axis:leftx-', 'button:dpleft' },
      right = { 'key:d', 'key:right', 'axis:leftx+', 'button:dpright' },
      up =    { 'key:w', 'key:up',    'axis:lefty-', 'button:dpup' },
      down =  { 'key:s', 'key:down',  'axis:lefty+', 'button:dpdown' },
      action = { 'key:space', 'mouse:left', 'button:a' }
    },
    pairs = {
      move = { 'left', 'right', 'up', 'down' }
    },
    controller = controllerInstance, -- Pass the gamepad object here
    deadzone = 0.2
  })
end

function lovr.update(dt)
  -- If a new controller was plugged in mid-gameplay, update the reference:
  -- if did_not_have_controller and now_has_one then
  --   input:changeConfig({ controller = new_controller })
  -- end

  -- Update the Input state
  input:update()

  -- Input Test
  local mx, my = input:getAxisPair('move')
  if math.abs(mx) > 0 or math.abs(my) > 0 then
    print(string.format("Moving vector: X=%.2f, Y=%.2f", mx, my))
  end

  if input:pressed('action') then
    print("Action pressed! Current device: " .. input:getActiveDevice())
  end
end
