--[[
  Symmetric Pre-Computed Visibility Tries
  https://github.com/denismr/SymmetricPCVT
]]

local TranThong = require 'TranThong'

local index = {}
local meta = {__index = index}

local function AddPath(root, fast_los_map, radius, tx, ty)
  local x = root.x
  local y = root.y
  local radius2 = radius * radius
  local current = root

  local function los_keygen(x, y)
    return radius + x + (2 * radius + 1) * (y + radius)
  end

  local function cb(nx, ny)
    if nx * nx + ny * ny > radius2 then return end
    local dx = nx - x
    local dy = ny - y
    if dx == 0 and dy == 0 then return end
    
    x = nx
    y = ny

    local key = dx + 1 + 3 * (dy + 1)
    if not current.descendants[key] then
      local los_key = los_keygen(x, y)
      local descendant = {x = x, y = y, los_key = los_key, antecedent = current, descendants = {}}
      if not fast_los_map[los_key] then
        fast_los_map[los_key] = {}
      end
      table.insert(fast_los_map[los_key], descendant)
      current.descendants[key] = descendant
    end
    current = current.descendants[key]
  end

  TranThong(0, 0, tx, ty, cb)
end

local function PreOrder(trie, ShouldStop)
  if not ShouldStop(trie.x, trie.y) then
    for k, v in pairs(trie.descendants) do
      PreOrder(v, ShouldStop)
    end
  end
end

local function SPCVT(radius, dense)
  local root = {
    x = 0,
    y = 0,
    los_key = radius + (2 * radius + 1) * radius,
    descendants = {},
  }
  local fast_los_map = {[root.los_key] = {root}}

  for i = -radius, radius do
    if dense then
      for j = -radius, radius do
        AddPath(root, fast_los_map, radius, i, j)
      end
    else
      AddPath(root, fast_los_map, radius, -radius, i)
      AddPath(root, fast_los_map, radius, radius, i)
      AddPath(root, fast_los_map, radius, i, -radius)
      AddPath(root, fast_los_map, radius, i, radius)
    end
  end

  return setmetatable({
    root = root,
    fast_los_map = fast_los_map,
    radius = radius,
  }, meta)
end

function index:FOV(origin_x, origin_y, DoesBlockVision, SetVisible)
  local function cb(x, y)
    if DoesBlockVision(x + origin_x, y + origin_y) then return true end
    SetVisible(x + origin_x, y + origin_y)
    return false
  end
  PreOrder(self.root, cb)
end

local function clear(tab)
  for k,v in pairs(tab) do tab[k] = nil end
end

function index:LOS(a_x, a_y, b_x, b_y, DoesBlockVision, TraceOut)
  local x = b_x - a_x
  local y = b_y - a_y
  local radius = self.radius

  if x * x + y * y > radius * radius then return false end
  local los_key = radius + x + (2 * radius + 1) * (y + radius)

  local trace = nil
  
  for _, cur in ipairs(self.fast_los_map[los_key]) do
    trace = cur
    while cur do
      if DoesBlockVision(cur.x + a_x, cur.y + a_y) then
        trace = nil
        break
      end
      cur = cur.antecedent
    end
    if trace then break end
  end
  local cansee = trace ~= nil
  if TraceOut then
    while trace do
      TraceOut(trace.x + a_x, trace.y + a_y)
      trace = trace.antecedent
    end
  end
  return cansee
end

return SPCVT
