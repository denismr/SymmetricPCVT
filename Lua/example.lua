local SPCVT = require 'SPCVT'

local tilemap = {
  "#####################",
  "#....#..........#...#",
  "#....#..............#",
  "#........#......#...#",
  "#..#................#",
  "#.........@.........#",
  "#.....#.............#",
  "#.........#....#....#",
  "#...................#",
  "#...................#",
  "#####################"
};

local visibility = {}
for k, v in ipairs(tilemap) do
  tilemap[k] = {}
  visibility[k] = {}
  for ch in v:gmatch '.' do
    table.insert(tilemap[k], ch)
    table.insert(visibility[k], false)
  end
end

local function blocksVisibility(x, y)
  if x < 1 or x > 21 or y < 1 or y > 11 then return false end
  visibility[y][x] = true -- You can place it here to draw the visible walls as well
  return tilemap[y][x] == '#'
end

local function setVisible(x, y)
  -- visibility[y][x] = true -- not needed (see previous comment)
end

local before = os.clock()
local fov = SPCVT(30)
local after = os.clock()

print(string.format('%.3f seconds to create SPCVT with radius = 30.', after - before))

before = os.clock()
fov:FOV(11, 6, blocksVisibility, setVisible)
after = os.clock()

print(string.format('%.3f seconds to copute FOV from %s', after - before, tilemap[6][11]))
print()

local function PrintVisible()
  for i, vis in ipairs(visibility) do
    for j, v in ipairs(vis) do
      io.write(v and tilemap[i][j] or ' ', ' ')
    end
    print()
  end
end
PrintVisible()
print()

-- Now we test the LOS using it for each position.
-- The final result should be the same as before.
-- Do not do this to compute FOV. Use FOV instead.
-- LOS is useful to check whether something can see another
-- thing without computing the entire FOV.
for i, vis in ipairs(visibility) do
  for j in ipairs(vis) do
    vis[j] = false
  end
end

local cx, cy = 0, 0
local function checkblock(x, y)
  if x == cx and y == cy then return false end -- ignores the first point so we can draw walls as well
  return tilemap[y][x] == '#'
end

before = os.clock()
for x = 1, 21 do
  for y = 1, 11 do
    cx, cy = x, y
    visibility[y][x] = fov:LOS(11, 6, x, y, checkblock)
  end
end
after = os.clock()

local diff = after - before
local avg_per_cell = diff / 231

print(string.format('%.3fs to compute 231 LOSs. Avg per cell: %.3fs.', diff, avg_per_cell))
print()

PrintVisible()
