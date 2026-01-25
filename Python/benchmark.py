import time
import random
import math
from typing import List, Dict, Tuple, Callable
from RSPCVT import tranthong, RSPCVT

def create_random_map(size: int, density: float) -> List[List[bool]]:
    """Generates a 2D grid where True represents a wall."""
    return [[random.random() < density for _ in range(size)] for _ in range(size)]

def run_benchmark():
    ITERATIONS = 10000  # Python is slower, so we use fewer iterations than LuaJIT
    RADIUS = 20
    MAP_SIZE = 60
    DENSITY = 0.25
    SEED = 42

    print(f"Benchmarking Python RSPCVT: Radius {RADIUS}, {ITERATIONS} iterations")
    print("-" * 50)

    # Pre-compute the Trie
    fov_engine = RSPCVT(RADIUS)
    
    # Pre-calculate the list of all relative targets for Naive
    targets = []
    for i in range(-RADIUS, RADIUS + 1):
        for j in range(-RADIUS, RADIUS + 1):
            if i*i + j*j <= RADIUS*RADIUS:
                targets.append((i, j))

    # 1. Baseline: Map Generation Overhead
    random.seed(SEED)
    start_map = time.perf_counter()
    for _ in range(ITERATIONS):
        create_random_map(MAP_SIZE, DENSITY)
    map_gen_total = time.perf_counter() - start_map
    print(f"Avg Map Gen Time:    {map_gen_total / ITERATIONS:.6f} s")

    # 2. Naive Dense Raycasting
    random.seed(SEED)
    start_naive = time.perf_counter()
    for _ in range(ITERATIONS):
        world_map = create_random_map(MAP_SIZE, DENSITY)
        ox, oy = 30, 30
        
        # Every single target tile gets a dedicated ray
        for tx_off, ty_off in targets:
            tx, ty = ox + tx_off, oy + ty_off
            is_obstructed = False
            
            def check_step(x, y):
                nonlocal is_obstructed
                if is_obstructed: return
                if 0 <= x < MAP_SIZE and 0 <= y < MAP_SIZE:
                    if world_map[y][x]:
                        is_obstructed = True

            tranthong(ox, oy, tx, ty, check_step)
    
    naive_total = (time.perf_counter() - start_naive) - map_gen_total

    # 3. RSPCVT FOV
    random.seed(SEED)
    start_trie = time.perf_counter()
    for _ in range(ITERATIONS):
        world_map = create_random_map(MAP_SIZE, DENSITY)
        ox, oy = 30, 30
        
        def blocks_vision(x, y):
            if 0 <= x < MAP_SIZE and 0 <= y < MAP_SIZE:
                return world_map[y][x]
            return True

        def set_visible(x, y):
            pass

        fov_engine.fov(ox, oy, blocks_vision, set_visible)

    trie_total = (time.perf_counter() - start_trie) - map_gen_total

    # Results
    print(f"Total Naive Time:    {naive_total:.4f} s (excl. map gen)")
    print(f"Total RSPCVT Time:   {trie_total:.4f} s (excl. map gen)")
    print("-" * 50)
    print(f"Speedup Factor:      {naive_total / trie_total:.2f}x faster")
    print(f"Avg RSPCVT FOV:      {trie_total / ITERATIONS:.6f} s")

if __name__ == "__main__":
    run_benchmark()