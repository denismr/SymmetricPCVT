local SPCVT = require 'SPCVT'

local tilemap = {
  "#####################",
  "#...................#",
  "#..........1........#",
  "#..........#........#",
  "#..........#........#",
  "#.........2#........#",
  "#.........##........#",
  "#.........#.........#",
  "#.........#.........#",
  "#........3#.........#",
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
  if x < 1 or x > 21 or y < 1 or y > 11 then return true end
  visibility[y][x] = true -- You can place it here to draw the visible walls as well
  return tilemap[y][x] == '#'
end

local function setVisible(x, y)
  -- visibility[y][x] = true -- not needed (see previous comment)
end

local function PrintVisible()
  for i, vis in ipairs(visibility) do
    for j, v in ipairs(vis) do
      io.write(v and tilemap[i][j] or ' ', ' ')
    end
    print()
  end
end

local function ResetVisibility()
  for i, vis in ipairs(visibility) do
    for j in ipairs(vis) do
      vis[j] = false
    end
  end
end

local before = os.clock()
local fov = SPCVT(30)
local after = os.clock()

-- find positions:
to_find = {
  ["1"] = true,
  ["2"] = true,
  ["3"] = true
}

for y, row in ipairs(tilemap) do
  for x, value in ipairs(row) do
    if to_find[value] then
      print(value, x, y)
      to_find[value] = {x, y}
    end
  end
end

for k, position in pairs(to_find) do
  ResetVisibility()
  print("Printing visibility for", k)
  fov:FOV(position[1], position[2], blocksVisibility, setVisible)
  PrintVisible()
  print()
end
