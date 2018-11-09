// TranThong algorithm
// (a symmetric version of Bresenham's line algorithm)

// Reference:
// Thong, Tran. "A symmetric linear algorithm for line segment generation."
// Computers & Graphics 6.1 (1982): 15-17.


#ifndef TRAN_THONG_H
#define TRAN_THONG_H

#include <functional>

void TranThong(int xstart, int ystart, int xend, int yend, std::function<void(int, int)> callback);

#endif // TRAN_THONG_H
