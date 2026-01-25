from typing import List
from SPCVT import SPCVT


def main() -> None:
    tilemap: List[str] = [
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
        "#####################",
    ]

    height = len(tilemap)
    width = len(tilemap[0])

    visibility: List[List[bool]] = [
        [False] * width for _ in range(height)
    ]

    def reset_visibility() -> None:
        for y in range(height):
            for x in range(width):
                visibility[y][x] = False

    def blocks_visibility(x: int, y: int) -> bool:
        if x < 0 or x >= width or y < 0 or y >= height:
            return True
        visibility[y][x] = True  # draw visible walls as well
        return tilemap[y][x] == '#'

    def set_visible(x: int, y: int) -> None:
        # Not needed; visibility is set in blocks_visibility
        pass

    def display_visible() -> None:
        for y in range(height):
            for x in range(width):
                ch = tilemap[y][x] if visibility[y][x] else ' '
                print(ch, end=' ')
            print()
        print()

    # Build SPCVT (same as C++)
    fov = SPCVT(30)

    print("Visibility for 1")
    reset_visibility()
    fov.fov(11, 2, blocks_visibility, set_visible)
    display_visible()

    print("Visibility for 2")
    reset_visibility()
    fov.fov(10, 5, blocks_visibility, set_visible)
    display_visible()

    print("Visibility for 3")
    reset_visibility()
    fov.fov(9, 9, blocks_visibility, set_visible)
    display_visible()


if __name__ == "__main__":
    main()
