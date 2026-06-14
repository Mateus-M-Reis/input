---@alias DeviceType 'keyboard'|'mouse'|'gamepad'

---@class ControlState
---@field raw number The raw input value before deadzones are applied.
---@field value number The processed input value (with deadzones applied).
---@field down boolean Is the control currently held down?
---@field pressed boolean Was the control pressed down on this specific frame?
---@field released boolean Was the control released on this specific frame?

---@class AxisPairState
---@field x number The processed X axis value (normalized between -1 and 1).
---@field y number The processed Y axis value (normalized between -1 and 1).
---@field rawX number The raw, unprocessed X axis value.
---@field rawY number The raw, unprocessed Y axis value.

---@class InputConfig
---@field controls table<string, string[]> A dictionary mapping action names to a list of source strings (e.g., `{'key:w', 'button:a'}`).
---@field pairs table<string, [string, string, string, string]> Maps a directional action to an array of 4 control names: `{left, right, up, down}`.
---@field controllerIndex? number The index of the gamepad (1-based index following Lua standards). Defaults to 1.
---@field controller? number An explicit override for the hardware joystick ID.
---@field deadzone? number Axis deadzone threshold between 0 and 1. Defaults to 0.5.

---@class Input
local Input = {}

---@class Player
---@field controls table<string, string[]>
---@field pairs table<string, [string, string, string, string]>
---@field controller number|nil
---@field controllerIndex number
---@field deadzone number
---@field activeDevice DeviceType
---@field _activeControls table<string, ControlState>
---@field _activePairs table<string, AxisPairState>
---@field _explicitController number|nil
local Player = {}
Player.__index = Player

---Parses a source string like "key:w" into type and value components.
---@param source string
---@return string? type The type of input device (e.g., "key", "button").
---@return string? value The specific key, button, or axis identifier.
local function parseSource(source)
  local type, value = source:match("^(%a+):(.+)$")
  return type, value
end

---@type table<string, number>
local mouseMap = { left = 1, right = 2, middle = 3 }

---Mapeamento dos botões (String do Baton -> Índice do GLFWgamepadstate)
---@type table<string, number>
local gamepadButtons = {
  a = 0, b = 1, x = 2, y = 3,
  leftshoulder = 4, rightshoulder = 5,
  back = 6, start = 7, guide = 8,
  leftstick = 9, rightstick = 10,
  dpup = 11, dpright = 12, dpdown = 13, dpleft = 14
}

---Mapeamento dos eixos (String do Baton -> Índice do GLFWgamepadstate)
---@type table<string, number>
local gamepadAxes = {
  leftx = 0, lefty = 1,
  rightx = 2, righty = 3,
  lefttrigger = 4, righttrigger = 5
}

local ok, gc = pcall(require, (...):gsub("%.init$", "") .. "joystick")

---Creates a new input manager instance.
---@param config InputConfig
---@return Player
function Input.new(config)
  local instance = setmetatable({}, Player)
  instance:init(config)
  return instance
end

---Initializes the player input instance.
---@param config InputConfig
function Player:init(config)
  self.controls = config.controls or {}
  self.pairs = config.pairs or {}
  self.controller = config.controller
  self.controllerIndex = config.controllerIndex or 1
  self.deadzone = config.deadzone or 0.5
  self.activeDevice = 'keyboard'

  self._activeControls = {}
  self._activePairs = {}

  self:changeConfig(config)
end

---Updates the configuration at runtime.
---@param config InputConfig
function Player:changeConfig(config)
  if config.controls then self.controls = config.controls end
  if config.pairs then self.pairs = config.pairs end
  if config.deadzone then self.deadzone = config.deadzone end
  if config.controllerIndex ~= nil then self.controllerIndex = config.controllerIndex end

  if config.controller ~= nil then
    self.controller = config.controller
    self._explicitController = config.controller
  end

  -- Inicializa ou limpa estados dos controles definidos
  for controlName, _ in pairs(self.controls) do
    if not self._activeControls[controlName] then
      self._activeControls[controlName] = {
        raw = 0, value = 0, down = false, pressed = false, released = false
      }
    end
  end

  -- Inicializa ou limpa estados dos eixos combinados (pairs)
  for pairName, _ in pairs(self.pairs) do
    if not self._activePairs[pairName] then
      self._activePairs[pairName] = { x = 0, y = 0, rawX = 0, rawY = 0 }
    end
  end
end

---Updates input state. Call this once per frame inside `lovr.update`.
function Player:update()
  -- Busca dinâmica do controle via ID numérico (jid) do joystick.lua
  if ok and gc then
    if not self._explicitController then
      self.controller = nil
      local targetIndex = self.controllerIndex or 1
      local count = 1

      -- GLFW IDs vão de 1 a 16 no joystick.lua
      for i = 1, 16 do
        if gc.isDevicePresent(i) and gc.isDeviceGamepad(i) then
          if count == targetIndex then
            self.controller = i
            break
          end
          count = count + 1
        end
      end
    end
  end

  ---@type DeviceType|nil
  local primaryDevice = nil
  local gamepadState = nil

  -- Se temos um controle e a lib carregou, pegamos a struct com o estado atual
  if self.controller and ok and gc then
    gamepadState = gc.getGamepadState(self.controller)
  end

  -- 1. Atualizar Controles Individuais
  for controlName, sources in pairs(self.controls) do
    local current = self._activeControls[controlName]
    local previousDown = current.down

    local maxValue = 0
    local maxRaw = 0

    for _, source in ipairs(sources) do
      local type, value = parseSource(source)
      local val = 0
      local raw = 0

      if type == "key" then
        raw = lovr.system.isKeyDown(value) and 1 or 0
        val = raw
        if val > 0 then primaryDevice = 'keyboard' end

      elseif type == "mouse" then
        local btn = tonumber(value) or mouseMap[value] or 1
        raw = lovr.system.isMouseDown(btn) and 1 or 0
        val = raw
        if val > 0 then primaryDevice = 'mouse' end

      elseif type == "button" and gamepadState then
        local btnId = gamepadButtons[value:lower()]
        if btnId then
          raw = gamepadState.buttons[btnId]
          val = raw
          if val > 0 then primaryDevice = 'gamepad' end
        end

      elseif type == "axis" and gamepadState then
        local axisName, direction = value:match("^([%a%d]+)([+-])$")
        axisName = axisName or value
        direction = direction or "+"

        local axisId = gamepadAxes[axisName:lower()]
        if axisId then
          local axisValue = gamepadState.axes[axisId]
          raw = axisValue

          if direction == "+" then
            val = (axisValue > self.deadzone) and axisValue or 0
          else
            val = (axisValue < -self.deadzone) and -axisValue or 0
          end

          if math.abs(val) > 0 then primaryDevice = 'gamepad' end
        end
      end

      if math.abs(val) > math.abs(maxValue) then maxValue = val end
      if math.abs(raw) > math.abs(maxRaw) then maxRaw = raw end
    end

    current.value = maxValue
    current.raw = maxRaw
    current.down = maxValue > 0
    current.pressed = current.down and not previousDown
    current.released = not current.down and previousDown
  end

  if primaryDevice then
    self.activeDevice = primaryDevice
  end

  -- 2. Atualizar Axis Pairs (Combinações Direcionais)
  for pairName, controls in pairs(self.pairs) do
    local pair = self._activePairs[pairName]

    local left  = self._activeControls[controls[1]] and self._activeControls[controls[1]].value or 0
    local right = self._activeControls[controls[2]] and self._activeControls[controls[2]].value or 0
    local up    = self._activeControls[controls[3]] and self._activeControls[controls[3]].value or 0
    local down  = self._activeControls[controls[4]] and self._activeControls[controls[4]].value or 0

    local rawLeft  = self._activeControls[controls[1]] and self._activeControls[controls[1]].raw or 0
    local rawRight = self._activeControls[controls[2]] and self._activeControls[controls[2]].raw or 0
    local rawUp    = self._activeControls[controls[3]] and self._activeControls[controls[3]].raw or 0
    rawDown  = self._activeControls[controls[4]] and self._activeControls[controls[4]].raw or 0

    local x = right - left
    local y = down - up

    local len = math.sqrt(x * x + y * y)
    if len > 1 then
      x = x / len
      y = y / len
    end

    pair.x = x
    pair.y = y
    pair.rawX = rawRight - rawLeft
    pair.rawY = rawDown - rawUp
  end
end

---Gets the current processed numeric value of a control action (0 to 1).
---@param name string The name of the control action.
---@return number value
function Player:get(name) return self._activeControls[name] and self._activeControls[name].value or 0 end

---Gets the raw numeric value of a control action before deadzones are calculated.
---@param name string The name of the control action.
---@return number rawValue
function Player:getRaw(name) return self._activeControls[name] and self._activeControls[name].raw or 0 end

---Checks if a control action is currently being held down.
---@param name string The name of the control action.
---@return boolean isDown
function Player:down(name) return self._activeControls[name] and self._activeControls[name].down or false end

---Checks if a control action was triggered exactly on this frame.
---@param name string The name of the control action.
---@return boolean isPressed
function Player:pressed(name) return self._activeControls[name] and self._activeControls[name].pressed or false end

---Checks if a control action was released exactly on this frame.
---@param name string The name of the control action.
---@return boolean isReleased
function Player:released(name) return self._activeControls[name] and self._activeControls[name].released or false end

---Returns the processed X and Y values of a directional control pair.
---@param name string The name of the axis pair.
---@return number x Normalized value between -1 and 1.
---@return number y Normalized value between -1 and 1.
function Player:getAxisPair(name)
  local p = self._activePairs[name]
  return p and p.x or 0, p and p.y or 0
end

---Returns the raw X and Y values of a directional control pair (unprocessed by deadzones).
---@param name string The name of the axis pair.
---@return number rawX Unprocessed value.
---@return number rawY Unprocessed value.
function Player:getRawAxisPair(name)
  local p = self._activePairs[name]
  return p and p.rawX or 0, p and p.rawY or 0
end

---Returns the device type that triggered the most recent input change.
---@return DeviceType activeDevice
function Player:getActiveDevice() return self.activeDevice end

return Input
