require('conf')
require('gfx')
require('util')

local ZONE_SIZE = 240
local WAVELENGTH = 250

world = {}
local world_mt = {__index = world}

world.GRASS = 0
world.DIRT = 1
world.BLOCK = 2
world.EDGE = 3
world.NUM_TILES = 4

function world.new(...)
  local ret = setmetatable({}, world_mt)
  ret:init(...)
  return ret
end

function world:check_corner(expect, x, y)
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

function world:gen_map()
  self.grass_map = {}
  self.dirt_map = {}
  self.tree_map = {}

  for x = 0, self.map_size - 1 do
    self.grass_map[x] = {}
    self.dirt_map[x] = {}
    self.tree_map[x] = {}

    for y = 0, self.map_size - 1 do
      -- draw grass layer
      if self.rng:random() < 0.8 then
        self.grass_map[x][y] = math.floor(self.rng:random() * 4)
      else
        self.grass_map[x][y] = math.floor(self.rng:random() * 3) + 4
      end

      -- draw dirt patches
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

      -- draw trees
      frame = 0
      if self.tiles[x][y] == self.DIRT then
        frame = 23
      elseif self.tiles[x][y] == self.BLOCK then
        frame = 7
      elseif self.tiles[x][y] == self.EDGE then
        frame = 7
      end

      if frame > 0 then
        self.tree_map[x][y] = frame
      end
    end
  end
end

function world:init(id, width, height, map_size)
  self.x = 0
  self.y = 0
  self.visible = true

  self.gfx = load_gfx(atlas[id].texture)
  self.quads = load_quads(atlas[id].frameset)
  self.tile_size = framesets[atlas[id].frameset].size

  self.rng = love.math.newRandomGenerator()
  self.xseed = self.rng.random() * ZONE_SIZE
  self.yseed = self.rng.random() * ZONE_SIZE

  self.map_size = map_size
  self.width = width
  self.height = height

  self.batch = love.graphics.newSpriteBatch(self.gfx, width * height * 3)

  self:update()
end

function world:update()
  local x_start = 0
  self.x_off = self.x

  while self.x_off + self.tile_size <= 0 do
    self.x_off = self.x_off + self.tile_size
    x_start = x_start + 1
  end

  while self.x_off - self.tile_size >= 0 do
    self.x_off = self.x_off - self.tile_Size
    x_start = x_start - 1
  end

  local y_start = 0
  self.y_off = self.y

  while self.y_off + self.tile_size <= 0 do
    self.y_off = self.y_off + self.tile_size
    y_start = y_start + 1
  end

  while self.y_off - self.tile_size >= 0 do
    self.y_off = self.y_off - self.tile_Size
    y_start = y_start - 1
  end

  self.batch:clear()

  for x = 0, self.width - 1 do
    for y = 0, self.height - 1 do
      local xreal = x_start + x
      local yreal = y_start + y

      local xzone = math.floor(xreal / ZONE_SIZE)
      local yzone = math.floor(yreal / ZONE_SIZE)

      local xcenter = xzone * ZONE_SIZE + ZONE_SIZE / 2
      local ycenter = yzone * ZONE_SIZE + ZONE_SIZE / 2

      local zone = math.floor(love.math.noise(self.xseed + xzone, self.yseed + yzone) * 4) + 1
      local dist = math.min(1, math.dist(xreal, yreal, xcenter, ycenter) / (ZONE_SIZE / 2))
      local prob = 1 - dist^2
      local val = love.math.noise(xreal / WAVELENGTH + self.xseed, yreal / WAVELENGTH + self.yseed)

      love.math.setRandomSeed(xreal * yreal)
      local subval = love.math.random()

      local grass_tex = 0

      if subval < 0.8 then
        grass_tex = math.floor(subval / 0.8 * 4)
      else
        grass_tex = math.floor((subval - 0.8) / 0.2 * 3) + 4
      end


      if val < prob then
        grass_tex = grass_tex + zone * 32
      end

      self.batch:add(self.quads[grass_tex], x * self.tile_size, y * self.tile_size)
    end
  end

  self.batch:flush()
end

function world:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.batch, S(self.x_off), S(self.y_off), 0, SCALE, SCALE)
  end
end
