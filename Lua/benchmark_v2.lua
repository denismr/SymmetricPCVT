local bit = require 'bit'

local function Difference(xstrt, xnd)
  if xnd >= xstrt then
    return xnd - xstrt, 1
  else
    return xstrt - xnd, -1
  end
end

local function TranThongInterruptible(xstart, ystart, xend, yend, callback)
  local x = xstart
  local y = ystart

  local deltax, signdx = Difference(xstart, xend)
  local deltay, signdy = Difference(ystart, yend)

  -- If the start tile blocks, we stop immediately
  if callback(x, y) then return end

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
      if callback(x, y) then break end
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
      if callback(x, y) then break end
    end
  end
end

local RSPCVT = require 'RSPCVT'
local TranThong = TranThongInterruptible
local getTime = os.clock

local ITERATIONS = 50000
local RADIUS = 20
local MAP_SIZE = 60
local DENSITY = 0.25

local fov_engine = RSPCVT(RADIUS)

-- Pre-calculate target list
local targets = {}
for i = -RADIUS, RADIUS do
  for j = -RADIUS, RADIUS do
    if i*i + j*j <= RADIUS*RADIUS then
      table.insert(targets, {x = i, y = j})
    end
  end
end

local function create_random_map(size, density)
  local map = {}
  for y = 0, size do
    map[y] = {}
    for x = 0, size do
      map[y][x] = math.random() < density
    end
  end
  return map
end

local function run_benchmark()
  print(string.format("Benchmarking (Fair): Radius %d, %d iterations", RADIUS, ITERATIONS))
  print("--------------------------------------------------")

  -- 1. Baseline Map Gen
  math.randomseed(42)
  local start_map = getTime()
  for _ = 1, ITERATIONS do
    create_random_map(MAP_SIZE, DENSITY)
  end
  local map_gen_total = getTime() - start_map

  -- 2. Naive with Early Exit
  math.randomseed(42)
  local start_naive = getTime()
  for _ = 1, ITERATIONS do
    local map = create_random_map(MAP_SIZE, DENSITY)
    local ox, oy = 30, 30
    
    for k = 1, #targets do
      local t = targets[k]
      TranThong(ox, oy, ox + t.x, oy + t.y, function(x, y)
        return map[y] and map[y][x] -- Return true to stop the ray
      end)
    end
  end
  local naive_total = (getTime() - start_naive) - map_gen_total
  
  -- 3. RSPCVT
  math.randomseed(42)
  local start_trie = getTime()
  for _ = 1, ITERATIONS do
    local map = create_random_map(MAP_SIZE, DENSITY)
    local ox, oy = 30, 30
    
    fov_engine:FOV(ox, oy, 
      function(x, y) return map[y] and map[y][x] end,
      function(x, y) end
    )
  end
  local trie_total = (getTime() - start_trie) - map_gen_total

  -- Output
  print(string.format("Avg Map Gen Time:    %.6f s", map_gen_total / ITERATIONS))
  print(string.format("Total Naive Time:    %.4f s (excl. map gen)", naive_total))
  print(string.format("Total RSPCVT Time:   %.4f s (excl. map gen)", trie_total))
  print("--------------------------------------------------")
  print(string.format("Speedup Factor:      %.2fx faster", naive_total / trie_total))
  print(string.format("Avg RSPCVT FOV:      %.6f s", trie_total / ITERATIONS))
end

run_benchmark()