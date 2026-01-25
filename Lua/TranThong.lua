--[[
  TranThong algorithm
  (a symmetric version of Bresenham's line algorithm)
  
  Reference:
  Thong, Tran. "A symmetric linear algorithm for line segment generation."
  Computers & Graphics 6.1 (1982): 15-17.
]]

local function abs(x) return x < 0 and -x or x end

local function sign(x)
  if x < 0 then return -1 end
  if x > 0 then return 1 end
  return 0
end

local function TranThong(x0, y0, x1, y1, callback)
  local dx = x1 - x0
  local dy = y1 - y0

  local sx = sign(dx)
  local sy = sign(dy)

  dx = abs(dx)
  dy = abs(dy)

  local x = x0
  local y = y0

  callback(x, y)

  if dx >= dy then
    -- x-major
    local e = dx - dy
    for _ = 1, dx do
      x = x + sx
      e = e - 2 * dy
      if e < 0 then
        y = y + sy
        e = e + 2 * dx
      end
      callback(x, y)
    end
  else
    -- y-major
    local e = dy - dx
    for _ = 1, dy do
      y = y + sy
      e = e - 2 * dx
      if e < 0 then
        x = x + sx
        e = e + 2 * dy
      end
      callback(x, y)
    end
  end
end

return TranThong
