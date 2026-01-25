--- @meta

--[[
  Really Symmetric Pre-Computed Visibility Tries (RSPCVT)
  Optimized for LuaJIT.
  Guarantees symmetry by ensuring A sees B if and only if the specific
  ray from A to B is unobstructed.
]]

--- @class VisibilityNode
--- @field x number Relative x coordinate from origin
--- @field y number Relative y coordinate from origin
--- @field child_nodes table<number, VisibilityNode> Map of direction-keys to child nodes
--- @field dependent_targets number[] List of target keys that pass through this node

--- @class RSPCVT
--- @field root VisibilityNode The root of the visibility trie (origin)
--- @field radius number The maximum pre-computed radius
--- @field valid_targets_map table<number, boolean> Set of all valid keys within the circle
--- @field _blocked_cache table<number, boolean> Reusable table to avoid GC pressure during FOV calls
local VisibilityTrie = {}
local VisibilityTrieMeta = { __index = VisibilityTrie }

local TranThong = require 'TranThong'

--- Generates a unique integer key for a coordinate pair within the radius
--- @param x number
--- @param y number
--- @param radius number
--- @return number
local function get_coord_key(x, y, radius)
    local stride = 2 * radius + 1
    return radius + x + stride * (y + radius)
end

--- Decodes a coordinate key back into x, y offsets
--- @param key number
--- @param radius number
--- @return number x, number y
local function key_to_offset(key, radius)
    local stride = 2 * radius + 1
    local y = math.floor(key / stride) - radius
    local x = (key % stride) - radius
    return x, y
end

--- Adds a single ray path to the trie
--- @param root VisibilityNode
--- @param radius number
--- @param target_x number
--- @param target_y number
--- @param valid_targets_map table<number, boolean>
local function add_ray_path(root, radius, target_x, target_y, valid_targets_map)
    if target_x * target_x + target_y * target_y > radius * radius then return end

    local target_key = get_coord_key(target_x, target_y, radius)
    valid_targets_map[target_key] = true

    local current_x, current_y = 0, 0
    local current_node = root

    -- Every target is technically "dependent" on the origin
    table.insert(current_node.dependent_targets, target_key)

    local function step_callback(next_x, next_y)
        local dx = next_x - current_x
        local dy = next_y - current_y
        if dx == 0 and dy == 0 then return end

        current_x, current_y = next_x, next_y

        -- Map direction (-1..1) to a 1..9 index for the children table
        local direction_key = dx + 1 + 3 * (dy + 1)

        if not current_node.child_nodes[direction_key] then
            current_node.child_nodes[direction_key] = {
                x = current_x,
                y = current_y,
                child_nodes = {},
                dependent_targets = {}
            }
        end

        current_node = current_node.child_nodes[direction_key]
        table.insert(current_node.dependent_targets, target_key)
    end

    TranThong(0, 0, target_x, target_y, step_callback)
end

--- Recursively traverses the trie unless a block is found
--- @param node VisibilityNode
--- @param visitor_func fun(node: VisibilityNode): boolean
local function traverse_trie(node, visitor_func)
    -- If visitor returns true, the node blocks vision; prune this branch.
    if not visitor_func(node) then
        for _, child in pairs(node.child_nodes) do
            traverse_trie(child, visitor_func)
        end
    end
end

--- Creates a new Pre-Computed Visibility Trie
--- @param radius number
--- @return RSPCVT
local function create_visibility_trie(radius)
    --- @type VisibilityNode
    local root = {
        x = 0,
        y = 0,
        child_nodes = {},
        dependent_targets = {},
    }
    local valid_targets_map = {}

    for i = -radius, radius do
        for j = -radius, radius do
            add_ray_path(root, radius, i, j, valid_targets_map)
        end
    end

    return setmetatable({
        root = root,
        radius = radius,
        valid_targets_map = valid_targets_map,
        _blocked_cache = {},
    }, VisibilityTrieMeta)
end

--- Utility to clear a table without re-allocating memory
local function clear_table(t)
    for k in pairs(t) do t[k] = nil end
end

--- Computes Field of View from a specific origin
--- @param origin_x number
--- @param origin_y number
--- @param is_blocking_func fun(x: number, y: number): boolean
--- @param set_visible_func fun(x: number, y: number)
function VisibilityTrie:FOV(origin_x, origin_y, is_blocking_func, set_visible_func)
    local blocked_set = self._blocked_cache
    clear_table(blocked_set)

    local radius = self.radius

    --- @param node VisibilityNode
    local function process_node(node)
        local world_x, world_y = node.x + origin_x, node.y + origin_y

        if is_blocking_func(world_x, world_y) then
            local self_key = get_coord_key(node.x, node.y, radius)
            local deps = node.dependent_targets

            -- Mark all target destinations that rely on this cell as blocked
            for i = 1, #deps do
                local target_key = deps[i]
                -- Walls remain visible; only cells strictly behind them are obscured
                if self_key ~= target_key then
                    blocked_set[target_key] = true
                end
            end
            return true -- Blocked: stop traversing deeper
        end
        return false    -- Clear: continue traversal
    end

    traverse_trie(self.root, process_node)

    -- Apply visibility to all coordinates that weren't caught in a blocked path
    for key in pairs(self.valid_targets_map) do
        if not blocked_set[key] then
            local dx, dy = key_to_offset(key, radius)
            set_visible_func(origin_x + dx, origin_y + dy)
        end
    end
end

--- Checks Line of Sight between two points using the same ray logic
--- @param origin_x number
--- @param origin_y number
--- @param target_x number
--- @param target_y number
--- @param is_blocking_func fun(x: number, y: number): boolean
--- @return boolean has_los Returns true if the path is clear
function VisibilityTrie:LOS(origin_x, origin_y, target_x, target_y, is_blocking_func)
    local is_obstructed = false

    local function check_step(x, y)
        if is_obstructed then return end
        if is_blocking_func(x, y) then
            is_obstructed = true
        end
    end

    TranThong(origin_x, origin_y, target_x, target_y, check_step)
    return not is_obstructed
end

return create_visibility_trie
