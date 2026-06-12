local Input = require "init"

local input

function lovr.load()
  -- O init.lua agora é inteligente: ele procura o 'joystick.lua' (seu antigo game_controller)
  -- e faz a busca dos controles automaticamente dentro do input:update()
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
    controllerIndex = 1, -- 0 para o primeiro controle, 1 para o segundo
    deadzone = 0.2
  })
end

function lovr.update(dt)
  -- Aqui o input:update() chama o gc.getControllers() do seu joystick.lua
  input:update()

  -- Teste para ver se está lendo algo (vai printar se você mover o analógico ou apertar algo)
  local mx, my = input:getAxisPair('move')
  if math.abs(mx) > 0.1 or math.abs(my) > 0.1 then
    print(string.format("Movendo: X=%.2f, Y=%.2f", mx, my))
  end

  if input:pressed('action') then
    print("Botão de ação pressionado!")
  end
end

function lovr.draw()
  -- Renderização do seu jogo...
end
