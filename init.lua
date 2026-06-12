---@class Input
local Input = {}

---@class Player
---@field controls table
---@field pairs table
---@field controller table|nil
---@field deadzone number
---@field activeDevice string
local Player = {}
Player.__index = Player

---Parses a source string like "key:w" into type and value.
---@param source string
---@return string, string
local function parseSource(source)
  local type, value = source:match("^(%a+):(.+)$")
  return type, value
end

local mouseMap = {
  left = 1,
  right = 2,
  middle = 3
}

---Creates a new input manager instance.
---@param config table
---@return Player
function Input.new(config)
  local instance = setmetatable({}, Player)
  instance:init(config)
  return instance
end

local ok, gc = pcall(require, "game_controller")

---Initializes the player input instance.
---@param config table
function Player:init(config)
  self.controls = config.controls or {}
  self.pairs = config.pairs or {}
  self.controller = config.controller 
  self.deadzone = config.deadzone or 0.5
  self.activeDevice = 'keyboard'

  self._activeControls = {}
  self._activePairs = {}

  self:changeConfig(config)
end

---Updates the configuration at runtime.
---@param config table
function Player:changeConfig(config)
  if config.controls then self.controls = config.controls end
  if config.pairs then self.pairs = config.pairs end
  if config.controller ~= nil then self.controller = config.controller end
  if config.deadzone then self.deadzone = config.deadzone end

  for controlName, _ in pairs(self.controls) do
    if not self._activeControls[controlName] then
      self._activeControls[controlName] = {
        raw = 0, value = 0, down = false, pressed = false, released = false
      }
    end
  end

  for pairName, _ in pairs(self.pairs) do
    if not self._activePairs[pairName] then
      self._activePairs[pairName] = { x = 0, y = 0, rawX = 0, rawY = 0 }
    end
  end
end

---Updates input state. Call this once per frame.
function Player:update()
  if ok then
    gc.update()
    if not self.controller then
      local controllers = gc.getControllers and gc.getControllers()
      if controllers and #controllers > 0 then
        self.controller = controllers[1]
      end
    end
  end

  local primaryDevice = nil

  for controlName, sources in pairs(self.controls) do
    local current = self._activeControls[controlName]
    local previousDown = current.down
    local maxValue = 0
    local maxRaw = 0

    for _, source in ipairs(sources) do
      local type, value = parseSource(source)
      local val, raw = 0, 0

      if type == "key" then
        raw = lovr.system.isKeyDown(value) and 1 or 0
        val = raw
        if val > 0 then primaryDevice = 'keyboard' end
      elseif type == "mouse" then
        local btn = tonumber(value) or mouseMap[value] or 1
        raw = lovr.system.isMouseDown(btn) and 1 or 0
        val = raw
        if val > 0 then primaryDevice = 'mouse' end
      elseif type == "button" and self.controller then
        local isDownFunc = self.controller.isDown or self.controller.isButtonDown or self.controller.getButton
        if isDownFunc then
          raw = isDownFunc(self.controller, value) and 1 or 0
          val = raw
          if val > 0 then primaryDevice = 'gamepad' end
        end
      elseif type == "axis" and self.controller then
        local axisName, direction = value:match("^([%a%d]+)([+-])$")
        if not axisName then axisName = value; direction = "+" end
        local getAxisFunc = self.controller.getAxis or self.controller.getAxisValue
        if getAxisFunc then
          local axisValue = getAxisFunc(self.controller, axisName) or 0
          raw = axisValue
          if direction == "+" then val = axisValue > self.deadzone and axisValue or 0
          elseif direction == "-" then val = axisValue < -self.deadzone and -axisValue or 0 end
          if val > 0 then primaryDevice = 'gamepad' end
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

  if primaryDevice then self.activeDevice = primaryDevice end

  for pairName, controls in pairs(self.pairs) do
    local pair = self._activePairs[pairName]
    local left  = self._activeControls[controls[1]] and self._activeControls[controls[1]].value or 0
    local right = self._activeControls[controls[2]] and self._activeControls[controls[2]].value or 0
    local up    = self._activeControls[controls[3]] and self._activeControls[controls[3]].value or 0
    local down  = self._activeControls[controls[4]] and self._activeControls[controls[4]].value or 0
    
    local x, y = right - left, down - up
    local len = math.sqrt(x * x + y * y)
    if len > 1 then x, y = x / len, y / len end
    
    pair.x, pair.y = x, y
    pair.rawX = (self._activeControls[controls[2]] and self._activeControls[controls[2]].raw or 0) - (self._activeControls[controls[1]] and self._activeControls[controls[1]].raw or 0)
    pair.rawY = (self._activeControls[controls[4]] and self._activeControls[controls[4]].raw or 0) - (self._activeControls[controls[3]] and self._activeControls[controls[3]].raw or 0)
  end
end

-- Public API
function Player:get(name) return self._activeControls[name] and self._activeControls[name].value or 0 end
function Player:getRaw(name) return self._activeControls[name] and self._activeControls[name].raw or 0 end
function Player:down(name) return self._activeControls[name] and self._activeControls[name].down or false end
function Player:pressed(name) return self._activeControls[name] and self._activeControls[name].pressed or false end
function Player:released(name) return self._activeControls[name] and self._activeControls[name].released or false end
function Player:getAxisPair(name) local p = self._activePairs[name]; return p and p.x or 0, p and p.y or 0 end
function Player:getRawAxisPair(name) local p = self._activePairs[name]; return p and p.rawX or 0, p and p.rawY or 0 end
function Player:getActiveDevice() return self.activeDevice end

return Input
