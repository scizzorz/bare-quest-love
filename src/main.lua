require('conf')
require('gfx')
require('util')
local object = require('sprite')
local batch = require('world')
local engine = require('engine')
local overworldctl = require('overworldctl')

function love.load()
  print("love.load")

  local screen_width, screen_height = love.graphics.getDimensions()
  if screen_width < screen_height then
    WIDTH = MIN_WIDTH
    HEIGHT = math.ceil(screen_height / screen_width * MIN_WIDTH)
    CANVAS_SCALE = screen_width / MIN_WIDTH / SCALE
  else
    HEIGHT = MIN_HEIGHT
    WIDTH = math.ceil(screen_width / screen_height * MIN_HEIGHT)
    CANVAS_SCALE = screen_height / MIN_HEIGHT / SCALE
  end

  canvas = love.graphics.newCanvas(WIDTH * SCALE, HEIGHT * SCALE)

  print('window:  ' .. screen_width .. ' x ' .. screen_height)
  print('canvas:  ' .. WIDTH .. ' x ' .. HEIGHT)
  print('scale:   ' .. SCALE)
  print('c scale: ' .. CANVAS_SCALE)

  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.graphics.setLineStyle('rough')

  ENGINE = engine.new()
  OVERWORLD = overworldctl.new()

  ENGINE:add_control(OVERWORLD)

  ENGINE:add_sprite(map)
  ENGINE:add_sprite(bare)
  ENGINE:add_sprite(socket)
  ENGINE:add_sprite(knob)

end

function love.draw()
  love.graphics.setCanvas(canvas)

  ENGINE:draw()

  if pressed then
    love.graphics.print(stick_x, 0, 0)
    love.graphics.print(stick_y, 0, 16)
  end

  love.graphics.setCanvas()
  love.graphics.draw(canvas, 0, 0, 0, CANVAS_SCALE, CANVAS_SCALE)
end

function love.update(...)
  ENGINE:update(...)
end

function love.mousepressed(...)
  ENGINE:mousepressed(...)
end

function love.mousereleased(...)
  ENGINE:mousereleased(...)
end

function love.mousemoved(...)
  ENGINE:mousemoved(...)
end
