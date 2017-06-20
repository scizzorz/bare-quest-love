require('conf')
require('gfx')
require('util')
local object = require('sprite')
local batch = require('world')
local engine = require('engine')

-------------------------------------------------------------------------------

function move(x, y)
  local hspace = WIDTH / 3
  local vspace = HEIGHT / 3

  bare.x = bare.x + x
  bare.y = bare.y + y

  if map.x < 0 then
    if bare.x < hspace then
      map.x = map.x - (bare.x - hspace)
      bare.x = hspace
    end
  elseif bare.x < 0 then
    bare.x = 0
  end

  if map.x > WIDTH - 16 * 64 then
    if bare.x > WIDTH - 16 - hspace then
      map.x = map.x - (bare.x - (WIDTH - 16 - hspace))
      bare.x = (WIDTH - 16 - hspace)
    end
  elseif bare.x > WIDTH - 16 then
    bare.x = WIDTH - 16
  end

  if map.y < 0 then
    if bare.y < vspace then
      map.y = map.y - (bare.y - vspace)
      bare.y = vspace
    end
  elseif bare.y < 0 then
    bare.y = 0
  end

  if map.y > HEIGHT - 16 * 64 then
    if bare.y > HEIGHT - 16 - vspace then
      map.y = map.y - (bare.y - (HEIGHT - 16 - vspace))
      bare.y = (HEIGHT - 16 - vspace)
    end
  elseif bare.y > HEIGHT - 16 then
    bare.y = HEIGHT - 16
  end

end

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

  local map_size = 64
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

  print('window:  ' .. screen_width .. ' x ' .. screen_height)
  print('canvas:  ' .. WIDTH .. ' x ' .. HEIGHT)
  print('map:     ' .. map_width .. ' x ' .. map_height)
  print('scale:   ' .. SCALE)
  print('c scale: ' .. CANVAS_SCALE)

  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.graphics.setLineStyle('rough')

  ENGINE = engine.new()

  bare = object.new("bare")
  bare.x = WIDTH / 2 - 8
  bare.y = HEIGHT / 2 - 8

  map = batch.new("map_field", map_width, map_height, map_size)
  map.x = WIDTH / 2 - map_size * tile_size / 2
  map.y = HEIGHT / 2 - map_size * tile_size / 2

  knob = object.new("ui_knob")
  socket = object.new("ui_socket")

  knob.visible = false
  socket.visible = false

  pressed = false
  stick_x_start = 0.0
  stick_y_start = 0.0
  stick_x_cur = 0.0
  stick_y_cur = 0.0
  stick_x = 0.0
  stick_y = 0.0
  elapsed = 0.0

  ENGINE:add_sprite(map)
  ENGINE:add_sprite(bare)
  ENGINE:add_sprite(socket)
  ENGINE:add_sprite(knob)

end

-------------------------------------------------------------------------------

function love.update(dt)
  map:update()
  if pressed then
    move(stick_x, stick_y)
  end
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
