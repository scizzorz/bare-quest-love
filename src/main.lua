local SCALE = 3
local WIDTH = 160
local HEIGHT = 240

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
                      S(self.sx), S(self.sy))
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
      self.batch:add(self.quads[self.map[x_start + x][y_start + y]],
                     x * self.tile_size, y * self.tile_size)
    end
  end
  self.batch:flush()
end

function batch:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.batch,
                       S(self.x_off), S(self.y_off), 0,
                       S(1), S(1))
  end
end

-------------------------------------------------------------------------------

function love.load()
  print("love.load")

  WIDTH = love.graphics.getWidth() / SCALE
  HEIGHT = love.graphics.getHeight() / SCALE

  love.graphics.setDefaultFilter('nearest', 'nearest')
  love.graphics.setLineStyle('rough')

  bare = object.new("bare")
  bare.x = WIDTH / 2 - 8
  bare.y = HEIGHT / 2 - 8

  map = batch.new("map_field", 12, 20, 64)
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
    -- bare.x = bare.x + stick_x
    -- bare.y = bare.y + stick_y

    -- faults if you go out of bounds
    map.x = map.x - stick_x
    map.y = map.y - stick_y
  end
end

-------------------------------------------------------------------------------

function love.draw()
  map:draw()
  bare:draw()
  socket:draw()
  knob:draw()

  if pressed then
    love.graphics.print(stick_x, 0, 208)
    love.graphics.print(stick_y, 0, 224)
  end
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
