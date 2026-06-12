local Input = require "init"

local input1, input2

function lovr.load()
  input1 = Input.new({
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
    controllerIndex = 1, -- 0 para o primeiro controle, 1 para o segundo
    deadzone = 0.2
  })

  input2 = Input.new({
    controls = {
      left =  { 'axis:leftx-', 'button:dpleft' },
      right = { 'axis:leftx+', 'button:dpright' },
      up =    { 'axis:lefty-', 'button:dpup' },
      down =  { 'axis:lefty+', 'button:dpdown' },
      action = { 'button:a' }
    },
    pairs = {
      move = { 'left', 'right', 'up', 'down' }
    },
    controllerIndex = 2, -- 0 para o primeiro controle, 1 para o segundo
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

  if input1:pressed('action') then print("Player 1 -> Botão de ação pressionado!") end
  if input2:pressed('action') then print("Player 2 -> Botão de ação pressionado!") end
end

function lovr.draw()
  -- Renderização do seu jogo...
end
