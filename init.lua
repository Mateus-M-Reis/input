-- At the top of your input/init.lua
local current_path = ...
local joystick_path = "joystick"

if current_path and current_path ~= 'init' then
  local base_path = current_path:match('(.-)%.init$') or current_path
  joystick_path = base_path .. '.joystick'
end

local joystick = require(joystick_path)

local Input = {}
Input.__index = Input

-- Mouse mapping
local mouse_buttons = { mouse1 = 1, mouse2 = 2, mouse3 = 3, mouse4 = 4, mouse5 = 5 }

-- Gamepad button mapping (Prefixed with gp_ to prevent keyboard collisions)
local gamepad_buttons = {
  gp_a = GAMEPAD_BUTTON_A, gp_b = GAMEPAD_BUTTON_B, gp_x = GAMEPAD_BUTTON_X, gp_y = GAMEPAD_BUTTON_Y,
  gp_back = GAMEPAD_BUTTON_BACK, gp_start = GAMEPAD_BUTTON_START, gp_guide = GAMEPAD_BUTTON_GUIDE,
  gp_leftstick = GAMEPAD_BUTTON_LEFT_THUMB, gp_rightstick = GAMEPAD_BUTTON_RIGHT_THUMB,
  gp_l1 = GAMEPAD_BUTTON_LEFT_BUMPER, gp_r1 = GAMEPAD_BUTTON_RIGHT_BUMPER,
  gp_dpup = GAMEPAD_BUTTON_DPAD_UP, gp_dpdown = GAMEPAD_BUTTON_DPAD_DOWN,
  gp_dpleft = GAMEPAD_BUTTON_DPAD_LEFT, gp_dpright = GAMEPAD_BUTTON_DPAD_RIGHT
}

-- Gamepad axis mapping
local gamepad_axes = {
  gp_leftx = GAMEPAD_AXIS_LEFT_X, gp_lefty = GAMEPAD_AXIS_LEFT_Y,
  gp_rightx = GAMEPAD_AXIS_RIGHT_X, gp_righty = GAMEPAD_AXIS_RIGHT_Y,
  gp_l2 = GAMEPAD_AXIS_LEFT_TRIGGER, gp_r2 = GAMEPAD_AXIS_RIGHT_TRIGGER
}

-- FIX 1: Accept and store the device_id
function Input.new(device_id)
  local self = setmetatable({}, Input)

  self.device_id = device_id or 1 -- Default to Player 1 if nil
  self.binds = {}
  self.functions = {}
  self.repeat_state = {}
  self.sequences = {}

  self.state = {}
  self.prev_state = {}
  self.axis_state = {} 

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
  for k, v in pairs(self.state) do
    self.prev_state[k] = v
  end

  local keys_to_poll = {}
  for action, keys in pairs(self.binds) do
    for _, key in ipairs(keys) do keys_to_poll[key] = true end
  end
  for key in pairs(self.functions) do
    keys_to_poll[key] = true
  end

  -- FIX 2: Check gamepad state using self.device_id, NOT hardcoded 1
  local gamepad_present = joystick.isDevicePresent(self.device_id) and joystick.isDeviceGamepad(self.device_id)
  local gp_state = gamepad_present and joystick.getGamepadState(self.device_id) or nil

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
        is_down = (math.abs(val) > 0.5)
      end
    else
      -- FIX 3: Safely check physical keyboard. pcall prevents LÖVR from crashing on weird strings.
      pcall(function()
        is_down = lovr.system.isKeyDown(key)
      end)
    end

    self.state[key] = is_down
  end

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
      if self.state[key] then return true end
    end
  end
  return false
end

function Input:getAxis(action)
  if not action or not self.binds[action] then return 0 end
  for _, key in ipairs(self.binds[action]) do
    if gamepad_axes[key] then return self.axis_state[key] or 0 end
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
