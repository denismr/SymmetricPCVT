local RSPCVT = require 'RSPCVT'

local MAP_SIZE = 50
local RADIUS = 20
local fov_engine = RSPCVT(RADIUS)

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

local function test_smart_symmetry(iterations)
    local map = create_random_map(MAP_SIZE, 0.25)
    
    -- Confusion Matrix stats
    local stats = {
        both_see    = 0, -- A sees B AND B sees A
        neither_see = 0, -- A blind to B AND B blind to A
        only_a_sees = 0, -- A sees B BUT B blind to A (Failure)
        only_b_sees = 0, -- B sees A BUT A blind to B (Failure)
    }
    
    local total_valid = 0
    local bar_width = 40

    print(string.format("Running %d iterations (Radius: %d)...", iterations, RADIUS))

    for i = 1, iterations do
        local ax, ay = math.random(RADIUS, MAP_SIZE - RADIUS), math.random(RADIUS, MAP_SIZE - RADIUS)
        local bx, by = ax + math.random(-RADIUS, RADIUS), ay + math.random(-RADIUS, RADIUS)

        local dx, dy = bx - ax, by - ay
        if dx*dx + dy*dy <= RADIUS*RADIUS then
            total_valid = total_valid + 1

            -- Observers can stand on walls
            local function blocks_a(x, y) return (x ~= ax or y ~= ay) and map[y] and map[y][x] end
            local function blocks_b(x, y) return (x ~= bx or y ~= by) and map[y] and map[y][x] end

            local a_sees_b = false
            fov_engine:FOV(ax, ay, blocks_a, function(x, y)
                if x == bx and y == by then a_sees_b = true end
            end)

            local b_sees_a = false
            fov_engine:FOV(bx, by, blocks_b, function(x, y)
                if x == ax and y == ay then b_sees_a = true end
            end)

            -- Update Matrix
            if a_sees_b and b_sees_a then
                stats.both_see = stats.both_see + 1
            elseif not a_sees_b and not b_sees_a then
                stats.neither_see = stats.neither_see + 1
            elseif a_sees_b and not b_sees_a then
                stats.only_a_sees = stats.only_a_sees + 1
            else
                stats.only_b_sees = stats.only_b_sees + 1
            end
        end

        -- Progress Bar
        if i % (iterations / 100) == 0 then
            local progress = i / iterations
            local filled = math.floor(progress * bar_width)
            local bar = string.rep("#", filled) .. string.rep("-", bar_width - filled)
            io.write(string.format("\r[%s] %d%%", bar, math.floor(progress * 100)))
            io.flush()
        end
    end

    local failed = stats.only_a_sees + stats.only_b_sees
    local passed = stats.both_see + stats.neither_see

    print("\n\n" .. string.rep("=", 40))
    print("   SYMMETRY CONFUSION MATRIX")
    print(string.rep("=", 40))
    print(string.format(" Total Valid Paths: %d", total_valid))
    print(string.rep("-", 40))
    print(string.format(" Both See (A<->B):   %d", stats.both_see))
    print(string.format(" Neither See:        %d", stats.neither_see))
    print(string.rep("-", 40))
    print(string.format(" Only A sees B:      %d  (FAIL)", stats.only_a_sees))
    print(string.format(" Only B sees A:      %d  (FAIL)", stats.only_b_sees))
    print(string.rep("-", 40))
    print(string.format(" Final Result:       %s", failed == 0 and "PERFECT SYMMETRY" or "FAILED"))
    print(string.rep("=", 40) .. "\n")
end

math.randomseed(os.time())
test_smart_symmetry(1000000)