framesets = {
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
    num = 32,
  },
}

atlas = {
  bare = {
    texture = "actor_bare",
    frameset = "actor",
  },

  map = {
    texture = "map",
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

local gfx = {}

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

function load_gfx(id)
  if gfx[id] == nil then
    print("loading gfx: " .. id)
    gfx[id] = love.graphics.newImage("gfx/" .. id .. ".png")
  end

  return gfx[id]
end
