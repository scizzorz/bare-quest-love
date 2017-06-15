local MIN_WIDTH = 160
local MIN_HEIGHT = 160
local SCALE = 3

-------------------------------------------------------------------------------

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function S(v)
  return math.floor(SCALE * v)
end

function p2s(v)
  return v * SCALE * CANVAS_SCALE
end

function s2p(v)
  return v / SCALE / CANVAS_SCALE
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

batch.GRASS = 0
batch.DIRT = 1
batch.BLOCK = 2
batch.EDGE = 3
batch.NUM_TILES = 4

function batch.new(...)
  local ret = setmetatable({}, batch_mt)
  ret:init(...)
  return ret
end

function batch:gen_terrain()
  self.tiles = {}

  for x = 0, self.map_size - 1 do
    self.tiles[x] = {}
    for y = 0, self.map_size - 1 do
      self.tiles[x][y] = self.GRASS
    end
  end

  while self:density() <= 0.15 do
    local x = math.floor(self.rng:random() * self.map_size)
    local y = math.floor(self.rng:random() * self.map_size)
    local tile = math.floor(self.rng:random() * self.NUM_TILES)
    self:corrupt(x, y, tile, 0.8, 0.8)
  end

end

function batch:density()
  local total = 0
  local taken = 0

  for x = 0, self.map_size - 1 do
    for y = 0, self.map_size - 1 do
      total = total + 1
      if self.tiles[x][y] ~= self.GRASS then
        taken = taken + 1
      end
    end
  end

  return taken / total
end

function batch:corrupt(x, y, tile, spread, decay)
  -- don't corrupt near the edges
  if x < 5 or y < 5 or x > self.map_size - 5 or y > self.map_size - 5 then
    return
  end

  self.tiles[x][y] = tile

  -- recursively corrupt
  if self.rng:random() <= spread then
    self:corrupt(x - 1, y, tile, spread * decay, decay)
  end
  if self.rng:random() <= spread then
    self:corrupt(x + 1, y, tile, spread * decay, decay)
  end
  if self.rng:random() <= spread then
    self:corrupt(x, y - 1, tile, spread * decay, decay)
  end
  if self.rng:random() <= spread then
    self:corrupt(x, y + 1, tile, spread * decay, decay)
  end
end

function batch:check_corner(expect, x, y)
  if x > 0 and y > 0 and self.tiles[x-1][y-1] == expect then
    return true
  end

  if x > 0 and y < self.map_size and self.tiles[x-1][y] == expect then
    return true
  end

  if x < self.map_size and y > 0 and self.tiles[x][y-1] == expect then
    return true
  end

  if x < self.map_size and y < self.map_size and self.tiles[x][y] == expect then
    return true
  end

  return false
end

function batch:gen_map()
  self.grass_map = {}
  self.dirt_map = {}

  for x = 0, self.map_size - 1 do
    self.grass_map[x] = {}
    self.dirt_map[x] = {}

    for y = 0, self.map_size - 1 do
      if self.rng:random() < 0.8 then
        self.grass_map[x][y] = math.floor(self.rng:random() * 4)
      else
        self.grass_map[x][y] = math.floor(self.rng:random() * 3) + 4
      end

      local frame = 8
      if self:check_corner(self.DIRT, x, y+1) then
        frame = frame + 1
      end
      if self:check_corner(self.DIRT, x+1, y+1) then
        frame = frame + 2
      end
      if self:check_corner(self.DIRT, x+1, y) then
        frame = frame + 4
      end
      if self:check_corner(self.DIRT, x, y) then
        frame = frame + 8
      end

      self.dirt_map[x][y] = frame
    end
  end
end

function batch:init(id, width, height, map_size)
  self.x = 0
  self.y = 0
  self.visible = true

  self.gfx = load_gfx(sprites[id].texture)
  self.quads = load_quads(sprites[id].frameset)
  self.tile_size = framesets[sprites[id].frameset].size
  self.map_size = map_size
  self.rng = love.math.newRandomGenerator()

  self:gen_terrain()
  self:gen_map()

  self.width = width
  self.height = height

  self.grass = love.graphics.newSpriteBatch(self.gfx, width * height)
  self.dirt = love.graphics.newSpriteBatch(self.gfx, width * height)

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

  self.grass:clear()
  self.dirt:clear()

  for x = 0, self.width - 1 do
    for y = 0, self.height - 1 do
      if self.tiles[x_start + x] and self.tiles[x_start + x][y_start + y] then
        local tile = self.tiles[x_start + x][y_start + y]
        local grass_tex = self.grass_map[x_start + x][y_start + y]
        local dirt_tex = self.dirt_map[x_start + x][y_start + y]

        self.grass:add(self.quads[grass_tex], x * self.tile_size, y * self.tile_size)
        self.dirt:add(self.quads[dirt_tex], x * self.tile_size, y * self.tile_size)
      end
    end
  end

  self.grass:flush()
  self.dirt:flush()
end

function batch:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.grass, S(self.x_off), S(self.y_off), 0, SCALE, SCALE)
    love.graphics.draw(self.dirt, S(self.x_off), S(self.y_off), 0, SCALE, SCALE)
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
