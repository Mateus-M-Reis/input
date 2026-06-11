# input

A simple, powerful, and action-based input manager optimized for **LÖVR**.

This module abstracts away raw keycodes, mouse buttons, and gamepad axes into semantic **actions** (like `'jump'` or `'shoot'`). It natively supports explicit state polling, repeating inputs, input sequences (combos), and raw analog gamepad values—all without hijacking LÖVR's global callbacks.

## Quick Start

Place the `input` folder (containing `init.lua` and `joystick.lua`) into your project and require it.

```lua
local Input = require 'input'

function lovr.load()
    input = Input()

    -- Bind keys, mouse buttons, and gamepad buttons to actions
    input:bind('space', 'jump')
    input:bind('mouse1', 'shoot')
    input:bind('r2', 'shoot')      -- Gamepad Right Trigger
    input:bind('leftx', 'move_x')  -- Gamepad Left Stick X-axis
    
    -- You can also bind a key directly to a function
    input:bind('escape', function() lovr.event.quit() end)
end

function lovr.update(dt)
    -- Must be called every frame to snapshot states!
    input:update()

    if input:pressed('jump') then
        print("Player jumped!")
    end

    if input:down('shoot', 0.1, 0.5) then
        print("Rapid fire! (Starts after 0.5s, fires every 0.1s)")
    end

    local speed = input:getAxis('move_x')
    if speed ~= 0 then
        print("Moving horizontally at speed: " .. speed)
    end
end

```

---

## API Reference

### Initialization & Core

#### `Input()`

Creates and returns a new Input instance. You can create multiple instances if you want separate control schemes for different players or contexts (e.g., UI vs. Gameplay).

```lua
input = Input()

```

#### `Input:update()`

**Must be called once per frame** (usually inside `lovr.update`). It explicitly polls LÖVR's system state and the FFI gamepad struct to update the internal history of what was pressed, held, or released.

---

### Binding

#### `Input:bind(key, action)`

Binds a specific physical `key` to a semantic string `action`.

* If `action` is a function instead of a string, that function will be automatically called when the key is pressed.

```lua
input:bind('w', 'up')
input:bind('dpup', 'up') -- Gamepad D-Pad Up
input:bind('f11', function() print("F11 pressed!") end)

```

#### `Input:unbind(key)`

Unbinds a specific physical `key` from all actions or standalone functions it is attached to.

```lua
input:unbind('mouse1')

```

#### `Input:unbindAll()`

Clears all current binds and standalone functions. Useful when switching from gameplay to a menu.

---

### State Checking

#### `Input:pressed(action)`

Returns `true` on the exact frame the `action` was pressed. Returns `false` otherwise.

```lua
if input:pressed('jump') then
    player:doJump()
end

```

#### `Input:released(action)`

Returns `true` on the exact frame the `action` was released. Returns `false` otherwise.

```lua
if input:released('charge_attack') then
    player:releaseAttack()
end

```

#### `Input:down(action, [interval, delay])`

Returns `true` if the `action` is currently being held down.

* **`interval`** *(optional)*: If provided, the function will return `true` repeatedly every `interval` seconds while the key is held.
* **`delay`** *(optional)*: If provided alongside `interval`, the repeating behavior will pause for `delay` seconds before starting the repeat cycle.

```lua
-- Returns true every frame the button is held
if input:down('walk') then 
    player.x = player.x + 1 
end

-- Returns true immediately, waits 0.5s, then returns true every 0.1s
if input:down('shoot', 0.1, 0.5) then
    spawnBullet()
end

```

#### `Input:getAxis(action)`

Returns the raw float value (`-1.0` to `1.0`) of an analog action. If the action is bound to a digital button (like a keyboard key), it will internally resolve to `1.0` if held, or `0.0` if not.

```lua
local turn_speed = input:getAxis('turn_camera')
camera:rotate(turn_speed * dt)

```

---

### Advanced

#### `Input:sequence(...)`

Checks if a specific sequence of actions and time delays has been executed. Extremely useful for fighting game combos or cheat codes.

* Arguments must alternate between `action` (string) and `delay` (number).
* The number of arguments must be odd, starting and ending with an action.
* The delay represents the *maximum* allowed time (in seconds) between the two actions.

```lua
-- Checks if 'up', 'up', 'down', 'down' was pressed. 
-- The player has a maximum of 0.5 seconds between each press.
if input:sequence('up', 0.5, 'up', 0.5, 'down', 0.5, 'down') then
    print("Konami Code Activated!")
end

```

---

## Valid Key Names

The module supports mapping directly to LÖVR's standard system keys, along with mapped strings for mice and gamepads.

### Keyboard

Standard LÖVR key names (`'space'`, `'return'`, `'escape'`, `'a'`, `'b'`, `'c'`, `'f1'`, `'up'`, `'down'`, etc.).

### Mouse

* `'mouse1'` (Left Click)
* `'mouse2'` (Right Click)
* `'mouse3'` (Middle Click)
* `'mouse4'`, `'mouse5'`

### Gamepad (via internal GLFW mapping)

**Buttons:**

* Face buttons: `'a'`, `'b'`, `'x'`, `'y'`
* Bumpers: `'l1'`, `'r1'`
* Sticks (Click): `'leftstick'`, `'rightstick'`
* D-Pad: `'dpup'`, `'dpdown'`, `'dpleft'`, `'dpright'`
* System: `'back'`, `'start'`, `'guide'`

**Axes:**

* Thumbsticks: `'leftx'`, `'lefty'`, `'rightx'`, `'righty'`
* Triggers: `'l2'`, `'r2'`
