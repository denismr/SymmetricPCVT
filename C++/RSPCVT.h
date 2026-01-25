#ifndef RSPCVT_H
#define RSPCVT_H

#include <memory>
#include <functional>
#include <vector>

/**
 * Really Symmetric Pre-Computed Visibility Tries (RSPCVT)
 * A strictly symmetric FOV algorithm based on pre-computed Bresenham-style rays.
 */
class RSPCVT
{
public:
  /**
   * @param radius the maximum distance for pre-computation.
   */
  RSPCVT(int radius);

  /**
   * Computes the Field of View from an origin point.
   * @param origin_x x-coordinate of the origin point.
   * @param origin_y y-coordinate of the origin point.
   * @param DoesBlockVision Returns true if (x, y) blocks light.
   * @param SetVisible Called for all cells that are determined to be visible.
   */
  void FOV(int origin_x, int origin_y,
           std::function<bool(int, int)> DoesBlockVision,
           std::function<void(int, int)> SetVisible) const;

  /**
   * Computes Line of Sight using the same underlying ray algorithm.
   */
  bool LOS(int a_x, int a_y, int b_x, int b_y,
           std::function<bool(int, int)> DoesBlockVision,
           std::function<void(int, int)> TraceOut = nullptr) const;

private:
  struct Node
  {
    int x, y;
    std::unique_ptr<Node> children[9];  // 3x3 grid directions
    std::vector<int> dependent_targets; // List of coordinate keys

    Node(int x, int y) : x(x), y(y) {}
  };

  int radius;
  int stride;
  std::unique_ptr<Node> root;
  std::vector<int> all_valid_keys;

  // Internal cache to prevent reallocations during FOV calls
  mutable std::vector<bool> blocked_cache;

  int get_key(int x, int y) const;
  void decode_key(int key, int &x, int &y) const;

  void add_path(int tx, int ty);
  void traverse(const Node *node, int ox, int oy,
                const std::function<bool(int, int)> &DoesBlockVision) const;
};

#endif // RSPCVT_H