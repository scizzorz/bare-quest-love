require('conf')
require('gfx')
require('util')

local ZONE_SIZE = 240
local ZONE_OCTAVE = 250
local DIRT_OCTAVE = 50
local TREE_OCTAVE = 30

local TREE_THRESH = 0.05
local DIRT_THRESH = 0.06

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

function world:get_blocked(xreal, yreal)
  -- compute zone coordinates
  local xzone = math.floor(xreal / ZONE_SIZE)
  local yzone = math.floor(yreal / ZONE_SIZE)

  -- compute real center coordiantes
  local xcenter = xzone * ZONE_SIZE + ZONE_SIZE / 2
  local ycenter = yzone * ZONE_SIZE + ZONE_SIZE / 2

  -- compute the altitude of zone change
  local zone = math.floor(love.math.noise(self.xseed + xzone, self.yseed + yzone) * 4) + 1
  local dist = math.min(1, math.dist(xreal, yreal, xcenter, ycenter) / (ZONE_SIZE / 2))
  local prob = 1 - dist^2

  local tree_noise = love.math.noise(xreal / TREE_OCTAVE + self.xseed, yreal / TREE_OCTAVE + self.yseed)

  return (tree_noise < TREE_THRESH)
end

function world:get_tile(xreal, yreal)
  -- compute zone coordinates
  local xzone = math.floor(xreal / ZONE_SIZE)
  local yzone = math.floor(yreal / ZONE_SIZE)

  -- compute real center coordiantes
  local xcenter = xzone * ZONE_SIZE + ZONE_SIZE / 2
  local ycenter = yzone * ZONE_SIZE + ZONE_SIZE / 2

  -- compute the altitude of zone change
  local zone = math.floor(love.math.noise(self.xseed + xzone, self.yseed + yzone) * 4) + 1
  local dist = math.min(1, math.dist(xreal, yreal, xcenter, ycenter) / (ZONE_SIZE / 2))
  local prob = 1 - dist^2

  -- compute noise vars
  love.math.setRandomSeed(xreal * yreal)

  local zone_noise = love.math.noise(xreal / ZONE_OCTAVE + self.xseed, yreal / ZONE_OCTAVE + self.yseed)
  local tree_noise = love.math.noise(xreal / TREE_OCTAVE + self.xseed, yreal / TREE_OCTAVE + self.yseed)
  local dirt_noise = love.math.noise(xreal / DIRT_OCTAVE + self.xseed, yreal / DIRT_OCTAVE + self.yseed)
  local tex_noise = love.math.random()

  -- get a second set of random for this tile

  local grass_tex = 0
  local tree_tex = nil
  local dirt_tex = nil

  -- determine the type of grass
  if tex_noise < 0.8 then
    grass_tex = math.floor(tex_noise / 0.8 * 4)
  else
    grass_tex = math.floor((tex_noise - 0.8) / 0.2 * 3) + 4
  end

  -- determine the type of tree
  if tree_noise < TREE_THRESH then
    tree_tex = 7
  end

  -- determine the type of dirt
  if dirt_noise < DIRT_THRESH then
    dirt_tex = 23
  end

  -- shift it into this zone's style
  if zone_noise < prob then
    grass_tex = grass_tex + zone * 32
    tree_tex = tree_tex and tree_tex + zone * 32
    dirt_tex = dirt_tex and dirt_tex + zone * 32
  end

  return grass_tex, tree_tex, dirt_tex
end

function world:init(id, width, height, map_size)
  self.x = 0
  self.y = 0
  self.visible = true

  self.gfx = load_gfx(atlas[id].texture)
  self.quads = load_quads(atlas[id].frameset)
  self.tile_size = framesets[atlas[id].frameset].size

  self.rng = love.math.newRandomGenerator()
  self.xseed = self.rng:random() * ZONE_SIZE
  self.yseed = self.rng:random() * ZONE_SIZE

  self.map_size = map_size
  self.width = width
  self.height = height

  self.batch = love.graphics.newSpriteBatch(self.gfx, width * height * 3)

  self:update()
end

function world:update()
  self.x_start = -math.floor(self.x / self.tile_size)
  self.y_start = -math.floor(self.y / self.tile_size)
  self.x_off = self.x % self.tile_size - self.tile_size
  self.y_off = self.y % self.tile_size - self.tile_size

  self.batch:clear()

  for x = 0, self.width - 1 do
    for y = 0, self.height - 1 do
      local xreal = self.x_start + x
      local yreal = self.y_start + y

      local grass_tex, tree_tex, dirt_tex = self:get_tile(xreal, yreal)

      self.batch:add(self.quads[grass_tex], x * self.tile_size, y * self.tile_size)

      if dirt_tex then
        self.batch:add(self.quads[dirt_tex], x * self.tile_size, y * self.tile_size)
      end

      if tree_tex then
        self.batch:add(self.quads[tree_tex], x * self.tile_size, y * self.tile_size)
      end
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
