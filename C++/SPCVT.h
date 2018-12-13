// Symmetric Pre-Computed Visibility Tries
// https://github.com/denismr/SymmetricPCVT

#ifndef SPCVT_H
#define SPCVT_H

#include <memory>
#include <functional>
#include <list>
#include <vector>

class SPCVT {
public:

  /**
   * Constructor of Symmetric Pre-Computed Visibility Trie.
   * @param radius the maximum distance from which an object is still visible.
   * @param dense if false, only casts rays towards the border of the square
   *        that enclouses the vision circle. Otherwise, casts ray towards each
   *        point within the square. Setting true is not recommended as the
   *        resulting trie will contain many more duplicated points (with
   *        different prefixes), which voids the utility of this structure.
   *        Default is false.
   */
  SPCVT(int radius, bool dense = false);

  /**
   * Computes the Field of View from an origin point.
   * @paran origin_x x-coordinate of the origin point.
   * @paran origin_y y-coordinate of the origin point.
   * @param DoesBlockVision function that is called to check whether a position
   *        blocks the vision (e.g. a wall). This callback function can be used
   *        to set visibility, if directly setting walls as visible is desirable.
   *        Alternative ways include post-processing the neighborhood of visible
   *        ground.
   * @param SetVisible this function is only called for non-blocking positions
   *        (e.g. ground). It can be set as a do-nothing function if the previous
   *        parameter already sets visibility.
   */
  void FOV(int origin_x, int origin_y,
      std::function<bool(int, int)> DoesBlockVision,
      std::function<void(int, int)> SetVisible) const;
 
  /**
   * Computes Line of Sight.
   * @param a_x x-coordinate of point A.
   * @param a_y y-coordinate of point A.
   * @param b_x x-coordinate of point B.
   * @param b_y y-coordinate of point B.
   * @param DoesBlockVision function that is called to check whether a position
   *        blocks the vision (e.g. a wall). If A or B are positions that would
   *        normally block vision, they must be filtered out by this function.
   * @param traceOut callback function that passes non-blocking points from B
   *        (inclusive; first item) to A (inclusive; last item). Useful for
   *        setting a trajectory for projectiles (optional parameter).
   * @return True if A can see B and vice-versa. False if A cannot see B and
   *         vice-versa.
   */
  bool LOS(int a_x, int a_y, int b_x, int b_y,
      std::function<bool(int, int)> DoesBlockVision,
      std::function<void(int, int)> TraceOut = nullptr) const;

private:
  struct Trie {
    int x;
    int y;
    int los_key;
    Trie* antecedent;
    std::unique_ptr<Trie> descendants[9];

    Trie(int x, int y, int los_key, Trie* antecedent);

    static void AddPath(Trie* root,
        std::vector<std::list<Trie*> > & fast_los_map,
        int radius, int tx, int ty);
    void PreOrder(std::function<bool(int,int)> ShouldStop) const;
  };

  std::unique_ptr<Trie> root;
  std::vector<std::list<Trie*> > fast_los_map;
  int radius;
};

#endif // SPCVT_H
