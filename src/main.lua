gfx = {
  actor_bare = {
    fsize = 16,
    fnum = 4,
  }
}

text = {
  img = nil,
  x = 100,
  dx = 50,
  min_x = 100,
  max_x = 200,

  y = 200,
  dy = 50,
  min_y = 200,
  max_y = 400,
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
  text.gfx = load_gfx("actor_bare")
end


function love.update(dt)
  text.x = text.x + text.dx * dt
  text.y = text.y + text.dy * dt
  if text.x < text.min_x or text.x > text.max_x then
    text.dx = text.dx * -1
  end

  if text.y < text.min_y or text.y > text.max_y then
    text.dy = text.dy * -1
  end
end


function love.draw()
  -- love.graphics.print('Hello World!', text.x, text.y)
  love.graphics.draw(text.gfx.img, text.gfx.frames[0], text.x, text.y, 0, 3, 3)
end
