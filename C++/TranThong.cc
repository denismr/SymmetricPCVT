#include "TranThong.h"
#include <utility>
#include <tuple>

void TranThong(int xstart, int ystart, int xend, int yend, std::function<void(int, int)> callback) {

  auto Difference = [](int xstrt, int xnd) {
    return xnd >= xstrt ? std::make_tuple(xnd - xstrt, 1) : std::make_tuple(xstrt - xnd, -1);
  };

  int x = xstart;
  int y = ystart;

  int deltax, signdx;
  std::tie(deltax, signdx) = Difference(xstart, xend);
  int deltay, signdy;
  std::tie(deltay, signdy) = Difference(ystart, yend);
  
  callback(x, y);

  int test = signdy == -1 ? -1 : 0;

  if (deltax >= deltay) {
    test = (deltax + test) >> 1;
    for (int i = 0; i < deltax; i++) {
      test -= deltay;
      x += signdx;
      if (test < 0) {
        y += signdy;
        test += deltax;
      }
      callback(x, y);
    }
  } else {
    test = (deltay + test) >> 1;
    for (int i = 0; i < deltay; i++) {
      test -= deltax;
      y += signdy;
      if (test < 0) {
        x += signdx;
        test += deltay;
      }
      callback(x, y);
    }
  }
}
