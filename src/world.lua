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

  self.gfx = load_gfx(atlas[id].texture)
  self.quads = load_quads(atlas[id].frameset)
  self.tile_size = framesets[atlas[id].frameset].size
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

return batch
