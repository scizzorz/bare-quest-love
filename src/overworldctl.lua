local object = require('sprite')
local batch = require('world')

local overworldctl = {}
local overworldctl_mt = {__index = overworldctl}

function overworldctl.new(...)
  local ret = setmetatable({}, overworldctl_mt)
  ret:init(...)
  return ret
end

function overworldctl:init()
  local map_size = 64
  local tile_size = 16
  local map_width = math.ceil(WIDTH / tile_size) + 2
  local map_height = math.ceil(HEIGHT / tile_size) + 2

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
end

function overworldctl:update(dt)
  map:update()

  if pressed then
    self:move(stick_x, stick_y)
  end

  return true
end

function overworldctl:move(x, y)
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

return overworldctl
