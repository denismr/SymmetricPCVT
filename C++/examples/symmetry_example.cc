#include "SPCVT.h"
#include <iostream>
#include <ctime>

int main() {
  const char *tilemap[11] = {
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

  auto displayVisible = [&]() {
    for (int i = 0; i < 11; i++) {
      for (int j = 0; j < 21; j++) {
        std::cout << (visibility[i][j] ? tilemap[i][j] : ' ');
        std::cout << ' ';
      }
      std::cout << '\n';
    }
    std::cout << std::endl;
  };

  SPCVT fov(30);

  std::cout << "Visibility for 1" << std::endl;
  visibility = std::vector<std::vector<bool>>(11, std::vector<bool>(21, false));
  fov.FOV(11, 2, blocksVisibility, setVisible);
  displayVisible();
  std::cout << std::endl;

  std::cout << "Visibility for 2" << std::endl;
  visibility = std::vector<std::vector<bool>>(11, std::vector<bool>(21, false));
  fov.FOV(10, 5, blocksVisibility, setVisible);
  displayVisible();
  std::cout << std::endl;
  
  std::cout << "Visibility for 3" << std::endl;
  visibility = std::vector<std::vector<bool>>(11, std::vector<bool>(21, false));
  fov.FOV(9, 9, blocksVisibility, setVisible);
  displayVisible();
  std::cout << std::endl;

}
