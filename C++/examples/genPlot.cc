#include "SPCVT.h"
#include <iostream>

int main() {
  auto doNothing = [](int x, int y){};
  std::cout << "radius,avg_visits_per_cell\n";
  for (int r = 1; r <= 150; r++) {
    SPCVT fov(r);
    int rows = (r * 2) + 1;
    std::vector<int> z ((2 * r + 1) * (2 * r + 1), 0);
    auto counter = [&](int x, int y) {
      int k = r + x + (2 * r + 1) * (y + r);
      z[k]++;
      return false;
    };
    fov.FOV(0, 0, counter, doNothing);
    double nonzeros = 0.0;
    double sum = 0.0; 
    for (int v: z) {
      sum += (double) v;
      nonzeros += (double) (v != 0);
    }
    std::cout << r << "," << (sum/nonzeros) << std::endl;
  }
  return 0;
}
