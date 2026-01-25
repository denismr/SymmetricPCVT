--[[
  TranThong algorithm
  (a symmetric version of Bresenham's line algorithm)
  
  Reference:
  Thong, Tran. "A symmetric linear algorithm for line segment generation."
  Computers & Graphics 6.1 (1982): 15-17.
]]

local bit = require 'bit'

local function Difference(xstrt, xnd)
  if xnd >= xstrt then
    return xnd - xstrt, 1
  else
    return xstrt - xnd, -1
  end
end

local function TranThong(xstart, ystart, xend, yend, callback)
  local x = xstart
  local y = ystart

  local deltax, signdx = Difference(xstart, xend)
  local deltay, signdy = Difference(ystart, yend)

  callback(x, y)

  local test = signdy == -1 and -1 or 0

  if deltax >= deltay then
    test = bit.rshift(deltax + test, 1)
    for i = 1, deltax do
      test = test - deltay
      x = x + signdx
      if test < 0 then
        y = y + signdy
        test = test + deltax
      end
      callback(x, y)
    end
  else
    test = bit.rshift(deltay + test, 1)
    for i = 1, deltay do
      test = test - deltax
      y = y + signdy
      if test < 0 then
        x = x + signdx
        test = test + deltay
      end
      callback(x, y)
    end
  end
end

return TranThong
