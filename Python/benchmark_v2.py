import time
import random
from RSPCVT import RSPCVT

def tranthong_interruptible(xstart, ystart, xend, yend, callback):
    x, y = xstart, ystart
    
    deltax = abs(xend - xstart)
    signdx = 1 if xend >= xstart else -1
    
    deltay = abs(yend - ystart)
    signdy = 1 if yend >= ystart else -1

    # If callback returns True, stop the ray immediately
    if callback(x, y):
        return

    test = -1 if signdy == -1 else 0

    if deltax >= deltay:
        test = (deltax + test) >> 1
        for _ in range(deltax):
            test -= deltay
            x += signdx
            if test < 0:
                y += signdy
                test += deltax
            if callback(x, y):
                break
    else:
        test = (deltay + test) >> 1
        for _ in range(deltay):
            test -= deltax
            y += signdy
            if test < 0:
                x += signdx
                test += deltay
            if callback(x, y):
                break

def create_random_map(size, density):
    return [[random.random() < density for _ in range(size)] for _ in range(size)]

def run_fair_benchmark():
    ITERATIONS = 10000
    RADIUS = 20
    MAP_SIZE = 60
    DENSITY = 0.25
    SEED = 42

    fov_engine = RSPCVT(RADIUS)
    
    # Pre-calculate targets
    targets = []
    for i in range(-RADIUS, RADIUS + 1):
        for j in range(-RADIUS, RADIUS + 1):
            if i*i + j*j <= RADIUS*RADIUS:
                targets.append((i, j))

    print(f"Benchmarking Python (Fair): Radius {RADIUS}, {ITERATIONS} iterations")
    print("-" * 50)

    # 1. Map Gen Overhead
    random.seed(SEED)
    start_map = time.perf_counter()
    for _ in range(ITERATIONS):
        create_random_map(MAP_SIZE, DENSITY)
    map_gen_total = time.perf_counter() - start_map

    # 2. Naive with Early Exit
    random.seed(SEED)
    start_naive = time.perf_counter()
    for _ in range(ITERATIONS):
        world_map = create_random_map(MAP_SIZE, DENSITY)
        ox, oy = 30, 30
        
        for tx_off, ty_off in targets:
            tx, ty = ox + tx_off, oy + ty_off
            # Passing a lambda that returns True if it hits a wall
            tranthong_interruptible(ox, oy, tx, ty, lambda x, y: world_map[y][x] if 0 <= x < MAP_SIZE and 0 <= y < MAP_SIZE else True)
    
    naive_total = (time.perf_counter() - start_naive) - map_gen_total

    # 3. RSPCVT
    random.seed(SEED)
    start_trie = time.perf_counter()
    for _ in range(ITERATIONS):
        world_map = create_random_map(MAP_SIZE, DENSITY)
        ox, oy = 30, 30
        
        fov_engine.fov(ox, oy, 
            lambda x, y: world_map[y][x] if 0 <= x < MAP_SIZE and 0 <= y < MAP_SIZE else True,
            lambda x, y: None
        )

    trie_total = (time.perf_counter() - start_trie) - map_gen_total

    # Results
    print(f"Avg Map Gen Time:    {map_gen_total / ITERATIONS:.6f} s")
    print(f"Total Naive Time:    {naive_total:.4f} s (excl. map gen)")
    print(f"Total RSPCVT Time:   {trie_total:.4f} s (excl. map gen)")
    print("-" * 50)
    print(f"Speedup Factor:      {naive_total / trie_total:.2f}x faster")
    print(f"Avg RSPCVT FOV:      {trie_total / ITERATIONS:.6f} s")

if __name__ == "__main__":
    run_fair_benchmark()