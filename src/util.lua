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
