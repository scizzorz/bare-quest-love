require('conf')
require('gfx')
require('util')
local object = require('sprite')
local batch = require('world')
local engine = require('engine')
local overworldctl = require('overworldctl')

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

function love.update(dt)
  ENGINE:update(dt)
end

-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------

function love.mousepressed(x, y)
  pressed = true
  socket.visible = true
  knob.visible = true

  stick_x_start = s2p(x)
  stick_y_start = s2p(y)

  socket.x = stick_x_start - 16
  socket.y = stick_y_start - 16

  stick_x_cur = s2p(x)
  stick_y_cur = s2p(y)

  knob.x = stick_x_cur - 8
  knob.y = stick_y_cur - 8

  stick_x = 0.0
  stick_y = 0.0
end

function love.mousereleased(x, y)
  pressed = false
  socket.visible = false
  knob.visible = false
end

function love.mousemoved(x, y, dx, dy)
  if pressed then
    stick_x_cur = s2p(x)
    stick_y_cur = s2p(y)

    local angle = math.angle(stick_x_start, stick_y_start, stick_x_cur, stick_y_cur)
    local dist = math.dist(stick_x_start, stick_y_start, stick_x_cur, stick_y_cur)
    if dist > 8 then
      dist = 8
    end

    stick_x = math.cos(angle) * dist / 8
    stick_y = math.sin(angle) * dist / 8

    stick_x_cur = stick_x_start + stick_x * 8
    stick_y_cur = stick_y_start + stick_y * 8

    knob.x = stick_x_cur - 8
    knob.y = stick_y_cur - 8
  end
end
