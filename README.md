# input

**input** is an input library for LÖVR that bridges the gap between keyboard, mouse, and gamepad controls, allowing you to easily define and change controls on the fly. It automatically wraps around the [game_controller](https://github.com/immortalx74/game_controller) library to handle gamepads seamlessly. It is a port of love2d [baton](https://github.com/tesselode/baton) to lovr.

```lua
local Input = require 'input'

local input = Input.new {
  controls = {
    left = {'key:left', 'key:a', 'axis:leftx-', 'button:dpleft'},
    right = {'key:right', 'key:d', 'axis:leftx+', 'button:dpright'},
    up = {'key:up', 'key:w', 'axis:lefty-', 'button:dpup'},
    down = {'key:down', 'key:s', 'axis:lefty+', 'button:dpdown'},
    action = {'key:space', 'mouse:left', 'button:a'},
  },
  pairs = {
    move = {'left', 'right', 'up', 'down'}
  },
  controllerIndex = 1,
  deadzone = 0.2
}

function lovr.update(dt)
  input:update()

  local x, y = input:getAxisPair 'move'
  playerShip:move(x * 100, y * 100)
  
  if input:pressed 'action' then
    playerShip:shoot()
  end
end

```

## Installation

To use input, place `init.lua` (or rename it to `input.lua`) in your project along with the `game_controller` dependency, and then require it:

```lua
input = require 'input' -- if your file is named input.lua in the root directory

```

## Usage

### Defining controls

Controls are defined using a table. Each key should be the name of a control, and each value should be another table. This table contains strings defining what sources should be mapped to the control. For example, this table:

```lua
controls = {
  left = {'key:left', 'key:a', 'axis:leftx-'},
  shoot = {'key:space', 'button:a'},
}

```

will create a control called `"left"` that responds to the left arrow key, the A key, and pushing the left analog stick on the controller to the left, and a control called `"shoot"` that responds to the Space key on the keyboard and the A button on the gamepad.

Sources are strings with the following format:

```lua
'[input type]:[input source]'

```

Here are the different input types and the sources that can be associated with them:

| Type | Description | Source |
| --- | --- | --- |
| `key` | A keyboard key. | Any string recognized by [lovr.system.isKeyDown](https://lovr.org/docs/lovr.system.isKeyDown) (e.g., `'w'`, `'space'`, `'left'`). |
| `mouse` | A mouse button. | Standard string names (`'left'`, `'right'`, `'middle'`) or a number representing a mouse button index. |
| `axis` | A gamepad axis. | An axis name recognized by your `game_controller` library. Add a `'+'` or `'-'` on the end to denote the direction to detect (e.g., `'leftx+'`, `'lefty-'`). |
| `button` | A gamepad button. | A button name recognized by your `game_controller` library (e.g., `'a'`, `'b'`, `'dpleft'`). |

### Defining axis pairs

input allows you to define **axis pairs**, which group four directional controls under a single name. This is perfect for analog sticks, arrow keys, etc., as it allows you to get X and Y components quickly. Each pair is defined by a table with the names of the four controls in the exact order: **left, right, up, down**.

```lua
pairs = {
  move = {'left', 'right', 'up', 'down'},
  aim = {'aimLeft', 'aimRight', 'aimUp', 'aimDown'},
}

```

### Players

**Players** are the instantiated objects that monitor and manage inputs.

#### Creating players

To create a player instance, use `Input.new`:

```lua
player = Input.new(config)

```

`config` is a table containing the following values:

* `controls` - a table of controls.
* `pairs` - a table of axis pairs (optional).
* `controller` - a gamepad instance from your `game_controller` library (optional). If omitted, the module will automatically attempt to find and bind the first available gamepad connected to the system.
* `deadzone` - a number from 0-1 representing the minimum value axes have to cross to be detected (optional, defaults to `0.5`).

#### Updating players

You must update your player instance every frame inside `lovr.update`:

```lua
player:update()

```

#### Getting the value of controls

To get the current digital/analog value of a control, use:

```lua
value = player:get(control)

```

`player:get` always returns a number between `0` and `1`. To get the raw value of a control without applying the deadzone, use `player:getRaw`.

#### Getting the value of axis pairs

To get the X and Y components of a registered axis pair, use:

```lua
x, y = player:getAxisPair(pair)

```

In this case, `x` and `y` are numbers between `-1` and `1`. The length of the vector is automatically capped to `1` to prevent faster movement along diagonals. To get these values without deadzones applied, use `player:getRawAxisPair(pair)`.

#### Getting down, pressed, and released states

To check whether a control is currently held down, use:

```lua
down = player:down(control)

```

`player:down` returns `true` if the value of the control is greater than the deadzone, and `false` if not.

```lua
pressed = player:pressed(control)

```

`player:pressed` returns `true` if the control transitioned to being pressed *this exact frame*, and `false` otherwise.

```lua
released = player:released(control)

```

`player:released` returns `true` if the control transitioned to being released *this exact frame*, and `false` otherwise.

#### Updating the configuration at runtime

The configuration can be modified dynamically at runtime by passing a new table to `changeConfig`:

```lua
player:changeConfig({ deadzone = 0.3, controller = newGamepad })

```

Note that while you can safely adjust deadzones or switch controllers, you should not add entirely new control names or pairs after instantiation.

#### Getting the active input device

You can call `player:getActiveDevice()` to see which type of input hardware was last used actively by the player. This is useful for dynamically updating on-screen UI prompts. It returns one of the following strings:

* `'keyboard'`
* `'mouse'`
* `'gamepad'`
