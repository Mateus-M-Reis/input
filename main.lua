local Input = require 'init'

local input

function lovr.load()
  input = Input()
  input:bind('space', 'shoot')
  input:bind('x', 'shoot')     -- FFI gamepad X button
  input:bind('leftx', 'move')  -- Left thumbstick X-axis
end

function lovr.update(dt)
  input:update() -- Updates all states, timers, and sequences

  if input:pressed('shoot') then
    print("Pew Pew!")
  end

  local speed = input:getAxis('move')
  if speed ~= 0 then
    print("Moving at speed: " .. speed)
  end
end
