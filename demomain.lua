local Input = require "init"

local input1, input2

function lovr.load()
  input1 = Input.new({
    controls = {
      start = {'key:return', 'key:u', 'button:start'},
      back = {'key:backspace', 'key:h', 'button:back'},
      guide = {'key:b', 'button:guide'},

      left =  { 'key:a', 'key:left',  'axis:leftx-', 'button:dpleft' },
      right = { 'key:d', 'key:right', 'axis:leftx+', 'button:dpright' },
      up =    { 'key:w', 'key:up',    'axis:lefty-', 'button:dpup' },
      down =  { 'key:s', 'key:down',  'axis:lefty+', 'button:dpdown' },

      x = { 'key:n', 'button:x' },
      a = { 'key:j', 'button:a' },
      y = { 'key:k', 'button:y' },
      b = { 'key:l', 'button:b' },

      ls = {'key:m', 'button:leftshoulder'}, rs = {'key:,', 'button:rightshoulder'},
      l2 = {'key:i', 'button:l2'}, r2 = {'key:o', 'button:r2'},
    },
    pairs = {
      move = { 'left', 'right', 'up', 'down' }
    },
    controllerIndex = 1, -- 1 para o primeiro controle, 2 para o segundo
    deadzone = 0.2
  })

  input2 = Input.new({
    controls = {
      start = {'button:start'}, back =  {'button:back'}, guide = {'button:guide'},

      left =  {'axis:leftx-', 'button:dpleft'}, right = {'axis:leftx+', 'button:dpright'},
      up = {'axis:lefty-', 'button:dpup'}, down =  {'axis:lefty+', 'button:dpdown'},

      x = {'button:x'}, a = {'button:a'}, y = {'button:y'}, b = {'button:b'},
      ls = {'button:leftshoulder'}, rs = {'button:rightshoulder'},
      l2 = {'button:l2'}, r2 = {'button:r2'},
    },
    pairs = {
      move = { 'left', 'right', 'up', 'down' }
    },
    controllerIndex = 2,
    deadzone = 0.2
  })
end

function lovr.update(dt)
  -- Aqui o input:update() chama o gc.getControllers() do seu joystick.lua
  input1:update()
  input2:update()

  -- Teste para ver se está lendo algo (vai printar se você mover o analógico ou apertar algo)
  local mx1, my1 = input1:getAxisPair('move')
  if math.abs(mx1) > 0.1 or math.abs(my1) > 0.1 then
    print(string.format("Movendo: X=%.2f, Y=%.2f", mx1, my1))
  end
  local mx2, my2 = input2:getAxisPair('move')
  if math.abs(mx2) > 0.1 or math.abs(my2) > 0.1 then
    print(string.format("Movendo: X=%.2f, Y=%.2f", mx2, my2))
  end

  if input1:pressed('start') then print("Player 1 -> Botão start pressionado!") end
  if input1:pressed('back')  then print("Player 1 -> Botão back pressionado!") end
  if input1:pressed('guide') then print("Player 1 -> Botão guide pressionado!") end
  if input1:pressed('x') then print("Player 1 -> Botão x pressionado!") end
  if input1:pressed('a') then print("Player 1 -> Botão a pressionado!") end
  if input1:pressed('y') then print("Player 1 -> Botão y pressionado!") end
  if input1:pressed('b') then print("Player 1 -> Botão b pressionado!") end
  if input1:pressed('left')  then print("Player 1 -> Botão left pressionado!") end
  if input1:pressed('right') then print("Player 1 -> Botão right pressionado!") end
  if input1:pressed('up')    then print("Player 1 -> Botão up pressionado!") end
  if input1:pressed('down')  then print("Player 1 -> Botão b pressionado!") end
  if input1:pressed('ls') then print("Player 1 -> Botão leftshoulder  pressionado!") end
  if input1:pressed('rs') then print("Player 1 -> Botão rightshoulder pressionado!") end
  if input1:pressed('l2') then print("Player 1 -> Botão l2 pressionado!") end
  if input1:pressed('r2') then print("Player 1 -> Botão r2 pressionado!") end

  if input2:pressed('start') then print("Player 2 -> Botão start pressionado!") end
  if input2:pressed('back')  then print("Player 2 -> Botão back pressionado!") end
  if input2:pressed('guide') then print("Player 2 -> Botão guide pressionado!") end
  if input2:pressed('x') then print("Player 2 -> Botão x pressionado!") end
  if input2:pressed('a') then print("Player 2 -> Botão a pressionado!") end
  if input2:pressed('y') then print("Player 2 -> Botão y pressionado!") end
  if input2:pressed('b') then print("Player 2 -> Botão b pressionado!") end
  if input2:pressed('left')  then print("Player 2 -> Botão left pressionado!") end
  if input2:pressed('right') then print("Player 2 -> Botão right pressionado!") end
  if input2:pressed('up')    then print("Player 2 -> Botão up pressionado!") end
  if input2:pressed('down')  then print("Player 2 -> Botão b pressionado!") end
  if input2:pressed('ls') then print("Player 2 -> Botão leftshoulder  pressionado!") end
  if input2:pressed('rs') then print("Player 2 -> Botão rightshoulder pressionado!") end
  if input2:pressed('l2') then print("Player 2 -> Botão l2 pressionado!") end
  if input2:pressed('r2') then print("Player 2 -> Botão r2 pressionado!") end
end
