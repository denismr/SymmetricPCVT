#include "SPCVT.h"
#include <iostream>
#include <ctime>

int main() {
  const char *tilemap[11] = {
    "#####################",
    "#....#..........#...#",
    "#....#..............#",
    "#........#......#...#",
    "#..#................#",
    "#.........@.........#",
    "#.....#.............#",
    "#.........#....#....#",
    "#...................#",
    "#...................#",
    "#####################"
  };

  auto visibility = std::vector<std::vector<bool>>(11, std::vector<bool>(21, false));
  
  auto blocksVisibility = [&](int x, int y) {
    if (x < 0 || x >= 21 || y < 0 || y >= 11) return true;
    visibility[y][x] = true; // You can place it here to draw the visible walls as well
    return tilemap[y][x] == '#';
  };

  auto setVisible = [&](int x, int y) {
    // visibility[y][x] = true; // not needed (see previous comment)
  };

  clock_t before = clock();
  SPCVT fov(30);
  clock_t after = clock();
  std::cout << ((after - before)/(double)CLOCKS_PER_SEC) << " seconds to create SPCVT with radius = 30.\n";

  before = clock();
  fov.FOV(10, 5, blocksVisibility, setVisible);
  after = clock();

  std::cout << ((after - before)/(double)CLOCKS_PER_SEC) << " seconds to compute FOV from " << tilemap[5][10] << ".\n\n";

  for (int i = 0; i < 11; i++) {
    for (int j = 0; j < 21; j++) {
      std::cout << (visibility[i][j] ? tilemap[i][j] : ' ');
      std::cout << ' ';
    }
    std::cout << '\n';
  }
  std::cout << std::endl;

  // Now we test the LOS using it for each position.
  // The final result should be the same as before.
  // Do not do this to compute FOV. Use FOV instead.
  // LOS is useful to check whether something can see another
  // thing without computing the entire FOV.
  visibility = std::vector<std::vector<bool>>(11, std::vector<bool>(21, false));

  int cx, cy;
  auto checkblock = [&](int x, int y) {
    if(x == cx && y == cy) return false; // ignores the first point so we can draw walls as well

    return tilemap[y][x] == '#';
  };

  before = clock();
  for (cx = 0; cx < 21; cx++) {
    for (cy = 0; cy < 11; cy++) {
      visibility[cy][cx] = fov.LOS(10, 5, cx, cy, checkblock);
    }
  }
  after = clock();
  double diff = ((after - before)/(double)CLOCKS_PER_SEC);
  double avg_per_cell = diff/231.0;

  std::cout << diff << "s to compute 231 LOSs. Avg per cell: " << avg_per_cell << "s.\n\n";
  
  for (int i = 0; i < 11; i++) {
    for (int j = 0; j < 21; j++) {
      std::cout << (visibility[i][j] ? tilemap[i][j] : ' ');
      std::cout << ' ';
    }
    std::cout << '\n';
  }

  return 0;
}
