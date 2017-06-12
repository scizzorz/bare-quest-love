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

gfx = {}

function load_gfx(filename)
  if gfx[filename] == nil then
    gfx[filename] = love.graphics.newImage("gfx/" .. filename)
  end

  return gfx[filename]
end


function love.load()
  text.img = load_gfx("actor_bare.png")
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
  love.graphics.draw(text.img, text.x, text.y, 0, 1, 1, 1, 1)
end
