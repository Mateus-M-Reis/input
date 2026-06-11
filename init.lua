local joystick = require "joystick" -- Make sure your renamed FFI file is accessible

local Input = {}
Input.__index = Input

-- Mouse mapping
local mouse_buttons = { mouse1 = 1, mouse2 = 2, mouse3 = 3, mouse4 = 4, mouse5 = 5 }

-- Gamepad button mapping (linking your string keys to the GLFW globals)
local gamepad_buttons = {
  a = GAMEPAD_BUTTON_A, b = GAMEPAD_BUTTON_B, x = GAMEPAD_BUTTON_X, y = GAMEPAD_BUTTON_Y,
  back = GAMEPAD_BUTTON_BACK, start = GAMEPAD_BUTTON_START, guide = GAMEPAD_BUTTON_GUIDE,
  leftstick = GAMEPAD_BUTTON_LEFT_THUMB, rightstick = GAMEPAD_BUTTON_RIGHT_THUMB,
  l1 = GAMEPAD_BUTTON_LEFT_BUMPER, r1 = GAMEPAD_BUTTON_RIGHT_BUMPER,
  dpup = GAMEPAD_BUTTON_DPAD_UP, dpdown = GAMEPAD_BUTTON_DPAD_DOWN,
  dpleft = GAMEPAD_BUTTON_DPAD_LEFT, dpright = GAMEPAD_BUTTON_DPAD_RIGHT
}

-- Gamepad axis mapping
local gamepad_axes = {
  leftx = GAMEPAD_AXIS_LEFT_X, lefty = GAMEPAD_AXIS_LEFT_Y,
  rightx = GAMEPAD_AXIS_RIGHT_X, righty = GAMEPAD_AXIS_RIGHT_Y,
  l2 = GAMEPAD_AXIS_LEFT_TRIGGER, r2 = GAMEPAD_AXIS_RIGHT_TRIGGER
}

function Input.new()
  local self = setmetatable({}, Input)

  self.binds = {}
  self.functions = {}
  self.repeat_state = {}
  self.sequences = {}

  self.state = {}
  self.prev_state = {}
  self.axis_state = {} -- Stores raw float values for analog sticks/triggers

  return self
end

function Input:bind(key, action)
  if type(action) == 'function' then
    self.functions[key] = action
    return
  end
  if not self.binds[action] then self.binds[action] = {} end
  table.insert(self.binds[action], key)
end

function Input:unbind(key)
  for action, keys in pairs(self.binds) do
    for i = #keys, 1, -1 do
      if key == keys[i] then
        table.remove(keys, i)
      end
    end
  end
  self.functions[key] = nil
end

function Input:unbindAll()
  self.binds = {}
  self.functions = {}
end

function Input:update()
  -- Copy current state to prev_state for accurate :pressed() and :released() checks
  for k, v in pairs(self.state) do
    self.prev_state[k] = v
  end

  -- Build a list of actively bound keys to avoid polling the entire keyboard layout
  local keys_to_poll = {}
  for action, keys in pairs(self.binds) do
    for _, key in ipairs(keys) do keys_to_poll[key] = true end
  end
  for key in pairs(self.functions) do
    keys_to_poll[key] = true
  end

  -- Check if gamepad 1 is active via FFI
  local gamepad_present = joystick.isDevicePresent(1) and joystick.isDeviceGamepad(1)
  local gp_state = gamepad_present and joystick.getGamepadState(1) or nil

  -- Explicit Polling
  for key in pairs(keys_to_poll) do
    local is_down = false

    if mouse_buttons[key] then
      is_down = lovr.system.isMouseDown(mouse_buttons[key])
    elseif gamepad_buttons[key] then
      if gp_state then
        is_down = (gp_state.buttons[gamepad_buttons[key]] == 1)
      end
    elseif gamepad_axes[key] then
      if gp_state then
        local val = gp_state.axes[gamepad_axes[key]]
        self.axis_state[key] = val
        -- Treat analog movement over 50% as a boolean "press" for standard binds
        is_down = (math.abs(val) > 0.5)
      end
    else
      is_down = lovr.system.isKeyDown(key)
    end

    self.state[key] = is_down
  end

  -- Handle repeating inputs
  for k, v in pairs(self.repeat_state) do
    if v and self.state[k] then
      v.pressed = false
      local t = lovr.timer.getTime() - v.pressed_time
      if v.delay_stage then
        if t > v.delay then
          v.pressed = true
          v.pressed_time = lovr.timer.getTime()
          v.delay_stage = false
        end
      else
        if t > v.interval then
          v.pressed = true
          v.pressed_time = lovr.timer.getTime()
        end
      end
    elseif not self.state[k] then
      self.repeat_state[k] = false
    end
  end

  -- Call freestanding bound functions
  for key, func in pairs(self.functions) do
    if self.state[key] and not self.prev_state[key] then
      func()
    end
  end
end

function Input:pressed(action)
  if not action or not self.binds[action] then return false end

  for _, key in ipairs(self.binds[action]) do
    if self.state[key] and not self.prev_state[key] then
      return true
    end
  end
  return false
end

function Input:released(action)
  if not action or not self.binds[action] then return false end

  for _, key in ipairs(self.binds[action]) do
    if self.prev_state[key] and not self.state[key] then
      return true
    end
  end
  return false
end

function Input:down(action, interval, delay)
  if not action or not self.binds[action] then return false end

  for _, key in ipairs(self.binds[action]) do
    -- If it's an analog axis and no repeat is asked, return its raw float value
    if gamepad_axes[key] and not interval and not delay then
      if self.state[key] then return self.axis_state[key] end
    end

    if interval then
      if self.state[key] and not self.prev_state[key] then
        self.repeat_state[key] = {
          pressed_time = lovr.timer.getTime(),
          delay = delay or 0,
          interval = interval,
          delay_stage = (delay ~= nil)
        }
        return true
      elseif self.repeat_state[key] and self.repeat_state[key].pressed then
        return true
      end
    else
      if self.state[key] then
        return true
      end
    end
  end
  return false
end

function Input:getAxis(action)
  -- Custom helper to securely fetch raw -1.0 to 1.0 analog data
  if not action or not self.binds[action] then return 0 end
  for _, key in ipairs(self.binds[action]) do
    if gamepad_axes[key] then
      return self.axis_state[key] or 0
    end
  end
  return 0
end

function Input:sequence(...)
  local sequence = {...}
  if #sequence <= 1 then error("Use :pressed instead if you only need to check 1 action") end
  if type(sequence[#sequence]) ~= 'string' then error("The last argument must be an action") end
  if #sequence % 2 == 0 then error("The number of arguments passed in must be odd") end

  local sequence_key = table.concat(sequence, "")

  if not self.sequences[sequence_key] then
    self.sequences[sequence_key] = {sequence = sequence, current_index = 1}
  else
    local seq = self.sequences[sequence_key]
    if seq.current_index == 1 then
      local action = seq.sequence[seq.current_index]
      for _, key in ipairs(self.binds[action] or {}) do
        if self.state[key] and not self.prev_state[key] then
          seq.last_pressed = lovr.timer.getTime()
          seq.current_index = seq.current_index + 1
        end
      end
    else
      local delay = seq.sequence[seq.current_index]
      local action = seq.sequence[seq.current_index + 1]

      if (lovr.timer.getTime() - seq.last_pressed) > delay then
        self.sequences[sequence_key] = nil
        return false
      end
      for _, key in ipairs(self.binds[action] or {}) do
        if self.state[key] and not self.prev_state[key] then
          if (lovr.timer.getTime() - seq.last_pressed) <= delay then
            if seq.current_index + 1 == #seq.sequence then
              self.sequences[sequence_key] = nil
              return true
            else
              seq.last_pressed = lovr.timer.getTime()
              seq.current_index = seq.current_index + 2
            end
          else
            self.sequences[sequence_key] = nil
          end
        end
      end
    end
  end
  return false
end

return setmetatable({}, {__call = function(_, ...) return Input.new(...) end})
