from RSPCVT import RSPCVT

def main():
    tilemap = [
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
    ]

    height = len(tilemap)
    width = len(tilemap[0])

    # State to keep track of visible tiles
    visibility = [[False for _ in range(width)] for _ in range(height)]

    def blocks_visibility(x, y):
        if x < 0 or x >= width or y < 0 or y >= height:
            return True
        return tilemap[y][x] == '#'

    def set_visible(x, y):
        visibility[y][x] = True

    def display_visible():
        for y in range(height):
            row_chars = []
            for x in range(width):
                char = tilemap[y][x] if visibility[y][x] else ' '
                row_chars.append(char)
            print(" ".join(row_chars))
        print()

    # Pre-compute the Trie once
    fov_engine = RSPCVT(radius=30)

    # Visibility for point '1'
    print("Visibility for 1")
    visibility = [[False for _ in range(width)] for _ in range(height)]
    fov_engine.fov(11, 2, blocks_visibility, set_visible)
    display_visible()

    # Visibility for point '2'
    print("Visibility for 2")
    visibility = [[False for _ in range(width)] for _ in range(height)]
    fov_engine.fov(10, 5, blocks_visibility, set_visible)
    display_visible()

    # Visibility for point '3'
    print("Visibility for 3")
    visibility = [[False for _ in range(width)] for _ in range(height)]
    fov_engine.fov(9, 9, blocks_visibility, set_visible)
    display_visible()

if __name__ == "__main__":
    main()