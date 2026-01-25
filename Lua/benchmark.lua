local RSPCVT = require 'RSPCVT'
local TranThong = require 'TranThong'

-- Use os.clock() for standard Lua timing, or socket.gettime() for precision
local getTime = os.clock

local ITERATIONS = 50000
local RADIUS = 20
local MAP_SIZE = 60
local DENSITY = 0.25

local fov_engine = RSPCVT(RADIUS)

-- Pre-calculate the list of all relative targets in the circle for the Naive approach
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
    print(string.format("Benchmarking: Radius %d, %d iterations", RADIUS, ITERATIONS))
    print("--------------------------------------------------")

    -- 1. Measure Map Generation Overhead
    math.randomseed(42)
    local start_map = getTime()
    for _ = 1, ITERATIONS do
        create_random_map(MAP_SIZE, DENSITY)
    end
    local map_gen_total = getTime() - start_map
    local map_gen_avg = map_gen_total / ITERATIONS
    print(string.format("Avg Map Gen Time:    %.6f s", map_gen_avg))

    -- 2. Measure Naive Dense Raycasting
    math.randomseed(42)
    local start_naive = getTime()
    for _ = 1, ITERATIONS do
        local map = create_random_map(MAP_SIZE, DENSITY)
        local ox, oy = 30, 30
        
        -- For every single target tile, shoot a dedicated ray
        for k = 1, #targets do
            local t = targets[k]
            local tx, ty = ox + t.x, oy + t.y
            local blocked = false
            TranThong(ox, oy, tx, ty, function(x, y)
                if blocked then return end
                if map[y] and map[y][x] then
                    blocked = true
                end
                -- set_visible would happen here
            end)
        end
    end
    local naive_total = (getTime() - start_naive) - map_gen_total
    
    -- 3. Measure RSPCVT
    math.randomseed(42)
    local start_trie = getTime()
    for _ = 1, ITERATIONS do
        local map = create_random_map(MAP_SIZE, DENSITY)
        local ox, oy = 30, 30
        
        fov_engine:FOV(ox, oy, 
            function(x, y) return map[y] and map[y][x] end,
            function(x, y) --[[ set_visible --]] end
        )
    end
    local trie_total = (getTime() - start_trie) - map_gen_total

    -- Results
    print(string.format("Total Naive Time:    %.4f s (excl. map gen)", naive_total))
    print(string.format("Total RSPCVT Time:   %.4f s (excl. map gen)", trie_total))
    print("--------------------------------------------------")
    print(string.format("Speedup Factor:      %.2fx faster", naive_total / trie_total))
    print(string.format("Avg RSPCVT FOV:      %.6f s", trie_total / ITERATIONS))
end

run_benchmark()
