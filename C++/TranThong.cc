#include "TranThong.h"
#include <functional>
#include <cstdlib>

static inline int sign(int x) {
  return (x > 0) - (x < 0);
}

void TranThong(
  int x0, int y0,
  int x1, int y1,
  std::function<void(int, int)> callback
) {
  int dx = x1 - x0;
  int dy = y1 - y0;

  int sx = sign(dx);
  int sy = sign(dy);

  dx = std::abs(dx);
  dy = std::abs(dy);

  int x = x0;
  int y = y0;

  callback(x, y);

  if (dx >= dy) {
    // x-major
    int err = dx - dy;
    for (int i = 0; i < dx; ++i) {
      x += sx;
      err -= 2 * dy;
      if (err < 0) {
        y += sy;
        err += 2 * dx;
      }
      callback(x, y);
    }
  } else {
    // y-major
    int err = dy - dx;
    for (int i = 0; i < dy; ++i) {
      y += sy;
      err -= 2 * dx;
      if (err < 0) {
        x += sx;
        err += 2 * dy;
      }
      callback(x, y);
    }
  }
}
