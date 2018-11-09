#include "SPCVT.h"
#include <iostream>

int main() {
  int radius = 30;
  
  std::cout << "radius,radius_within,avg_visits_per_cell\n";
  SPCVT fov(radius);
  int r = radius;

  for (int r = 1; r <= radius; r++) {
    auto checkIn = [=](int x, int y){
      return x * x + y * y > r * r;
    };
    int rows = (r * 2) + 1;
    std::vector<int> z ((2 * r + 1) * (2 * r + 1), 0);
    auto counter = [&](int x, int y) {
      int k = r + x + (2 * r + 1) * (y + r);
      z[k]++;
    };
    fov.FOV(0, 0, checkIn, counter);
    double nonzeros = 0.0;
    double sum = 0.0; 
    for (int v: z) {
      sum += (double) v;
      nonzeros += (double) (v != 0);
    }
    std::cout << radius << "," << r << "," << (sum/nonzeros) << std::endl;
  }
  return 0;
}
