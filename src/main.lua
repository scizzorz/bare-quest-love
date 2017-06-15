local MAX_WIDTH = 240
local MAX_HEIGHT = 240
local SCALE = 3

-------------------------------------------------------------------------------

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function S(v)
  return math.floor(SCALE * v)
end

-------------------------------------------------------------------------------

local gfx = {}

function load_gfx(id)
  if gfx[id] == nil then
    print("loading gfx: " .. id)
    gfx[id] = love.graphics.newImage("gfx/" .. id .. ".png")
  end

  return gfx[id]
end

-------------------------------------------------------------------------------

local framesets = {
  ui_knob = {
    size = 16,
    num = 1,
  },

  ui_socket = {
    size = 32,
    num = 1,
  },

  actor = {
    size = 16,
    num = 4,
  },

  map = {
    size = 16,
    num = 8,
  },
}

local quads = {}

function load_quads(id)
  if quads[id] == nil then
    print("loading quads: " .. id)
    quads[id] = {}

    local num = framesets[id].num
    local size = framesets[id].size
    for x = 0, num - 1 do
      for y = 0, num - 1 do
        quads[id][y*num + x] = love.graphics.newQuad(size * x, size * y, size, size, size*num, size*num)
      end
    end
  end

  return quads[id]
end

-------------------------------------------------------------------------------

local sprites = {
  bare = {
    texture = "actor_bare",
    frameset = "actor",
  },

  map_field = {
    texture = "map_field",
    frameset = "map",
  },

  ui_knob = {
    texture = "ui_stick_knob",
    frameset = "ui_knob",
  },

  ui_socket = {
    texture = "ui_stick_socket",
    frameset = "ui_socket",
  },
}

local object = {}
local object_mt = {__index = object}

function object.new(...)
  local ret = setmetatable({}, object_mt)
  ret:init(...)
  return ret
end

function object:init(id)
  self.x = 0
  self.y = 0
  self.sx = 1
  self.sy = 1
  self.angle = 0
  self.frame = 0
  self.visible = true

  self.gfx = load_gfx(sprites[id].texture)
  self.quads = load_quads(sprites[id].frameset)
end

function object:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.gfx, self.quads[self.frame],
                      S(self.x), S(self.y), self.angle,
                      SCALE * self.sx, SCALE * self.sy)
  end
end

-------------------------------------------------------------------------------

local batch = {}
local batch_mt = {__index = batch}

function batch.new(...)
  local ret = setmetatable({}, batch_mt)
  ret:init(...)
  return ret
end

function batch:init(id, width, height, map_size)
  self.x = 0
  self.y = 0
  self.visible = true

  self.gfx = load_gfx(sprites[id].texture)
  self.quads = load_quads(sprites[id].frameset)
  self.tile_size = framesets[sprites[id].frameset].size
  self.map_size = map_size

  self.map = {}
  for x = 0, map_size - 1 do
    self.map[x] = {}
    for y = 0, map_size - 1 do
      self.map[x][y] = (x + y) % 7
    end
  end

  self.width = width
  self.height = height
  self.batch = love.graphics.newSpriteBatch(self.gfx, width * height)

  self:update()
end

function batch:update()
  local x_start = 0
  self.x_off = self.x
  while self.x_off + self.tile_size <= 0 do
    self.x_off = self.x_off + self.tile_size
    x_start = x_start + 1
  end

  local y_start = 0
  self.y_off = self.y
  while self.y_off + self.tile_size <= 0 do
    self.y_off = self.y_off + self.tile_size
    y_start = y_start + 1
  end

  self.batch:clear()
  for x = 0, self.width - 1 do
    for y = 0, self.height - 1 do
      if self.map[x_start + x] and self.map[x_start + x][y_start + y] then
        self.batch:add(self.quads[self.map[x_start + x][y_start + y]],
                      x * self.tile_size, y * self.tile_size)
      end
    end
  end
  self.batch:flush()
end

function batch:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.batch,
                       S(self.x_off), S(self.y_off), 0,
                       SCALE, SCALE)
  end
end

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
    WIDTH = math.ceil((screen_width / screen_height) * MAX_WIDTH)
    HEIGHT = MAX_HEIGHT
    CANVAS_SCALE = screen_height / MAX_HEIGHT / SCALE
  else
    WIDTH = MAX_WIDTH
    HEIGHT = math.ceil((screen_height / screen_width) * MAX_HEIGHT)
    CANVAS_SCALE = screen_width / MAX_WIDTH / SCALE
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

  map:draw()
  bare:draw()
  socket:draw()
  knob:draw()

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

  stick_x_start = (x/SCALE)
  stick_y_start = (y/SCALE)

  socket.x = stick_x_start - 16
  socket.y = stick_y_start - 16

  stick_x_cur = (x/SCALE)
  stick_y_cur = (y/SCALE)

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
    stick_x_cur = (x/SCALE)
    stick_y_cur = (y/SCALE)

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
