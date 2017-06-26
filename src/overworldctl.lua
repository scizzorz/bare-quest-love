require('sprite')
require('world')

overworldctl = {}
local overworldctl_mt = {__index = overworldctl}

function overworldctl.new(...)
  local ret = setmetatable({}, overworldctl_mt)
  ret:init(...)
  return ret
end

function overworldctl:init(engine)
  self.engine = engine

  local map_size = 240
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

  bare = sprite.new("bare")
  bare.x = WIDTH / 2 - 8
  bare.y = HEIGHT / 2 - 8

  map = world.new("map", map_width, map_height, map_size)
  map.x = WIDTH / 2 - map_size * tile_size / 2
  map.y = HEIGHT / 2 - map_size * tile_size / 2

  knob = sprite.new("ui_knob")
  socket = sprite.new("ui_socket")

  knob.visible = false
  socket.visible = false

  pressed = false
  stick_x_start = 0.0
  stick_y_start = 0.0
  stick_x_cur = 0.0
  stick_y_cur = 0.0
  stick_x = 0.0
  stick_y = 0.0
end

function overworldctl:update(dt)
  map:update()

  if pressed then
    self:move(stick_x * math.abs(stick_x), stick_y * math.abs(stick_y))
  end

  return true
end

function overworldctl:mousepressed(x, y)
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

  return true
end

function overworldctl:mousereleased(x, y)
  pressed = false
  socket.visible = false
  knob.visible = false

  return true
end

function overworldctl:mousemoved(x, y, dx, dy)
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

  return true
end

function overworldctl:move(x, y)
  local hspace = WIDTH / 3
  local vspace = HEIGHT / 3

  bare.x = bare.x + x
  bare.y = bare.y + y

  if bare.x < hspace then
    map.x = map.x - (bare.x - hspace)
    bare.x = hspace
  end

  if bare.x > WIDTH - bare.size - hspace then
    map.x = map.x - (bare.x - (WIDTH - bare.size - hspace))
    bare.x = (WIDTH - bare.size - hspace)
  end

  if bare.y < vspace then
    map.y = map.y - (bare.y - vspace)
    bare.y = vspace
  end

  if bare.y > HEIGHT - bare.size - vspace then
    map.y = map.y - (bare.y - (HEIGHT - bare.size - vspace))
    bare.y = (HEIGHT - bare.size - vspace)
  end
end
