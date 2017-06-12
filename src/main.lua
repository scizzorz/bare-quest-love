local Terebi = require('terebi')

gfx = {
  actor_bare = {
    fsize = 16,
    fnum = 4,
  }
}

text = {
  img = nil,
  x = 0,
  dx = 1,
  min_x = 0,
  max_x = 144,

  y = 0,
  dy = 1,
  min_y = 0,
  max_y = 224,
}

function load_gfx(id)
  if gfx[id].img == nil then
    gfx[id].img = love.graphics.newImage("gfx/" .. id .. ".png")
    gfx[id].frames = {}

    local fnum = gfx[id].fnum
    local fsize = gfx[id].fsize
    for x = 0, fnum - 1 do
      for y = 0, fnum - 1 do
        gfx[id].frames[y*fnum + x] = love.graphics.newQuad(fsize * x, fsize * y, fsize, fsize, fsize*fnum, fsize*fnum)
      end
    end
  end

  return gfx[id]
end


function love.load()
  Terebi.initializeLoveDefaults()

  screen = Terebi.newScreen(160, 240, 3)
  text.gfx = load_gfx("actor_bare")
  elapsed = 0.0
end


function love.update(dt)
  elapsed = elapsed + dt
  if elapsed > 1.0 / 6.0 then
    love.tick()
    elapsed = 0.0
  end
end

function love.tick()
  text.x = text.x + text.dx
  text.y = text.y + text.dy
  if text.x < text.min_x or text.x > text.max_x then
    text.dx = text.dx * -1
  end

  if text.y < text.min_y or text.y > text.max_y then
    text.dy = text.dy * -1
  end
end


function love.draw()
  love.graphics.setCanvas(screen:getCanvas())

  love.graphics.setColor(50, 0, 0)
  love.graphics.rectangle('fill', 0, 0, 160, 240)
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(text.gfx.img, text.gfx.frames[0], text.x, text.y)

  screen:draw()
end
