
#include "SPCVT.h"
#include "TranThong.h"

SPCVT::Trie::Trie(int x, int y, int los_key, Trie* antecedent) {
  this->x = x;
  this->y = y;
  this->los_key = los_key;
  this->antecedent = antecedent;
}

void SPCVT::Trie::AddPath(Trie* root, std::vector<std::list<Trie*> > & fast_los_map, int radius, int tx, int ty) {
  int x = root->x;
  int y = root->y;
  int radius2 = radius * radius;
  Trie* current = root;

  auto los_keygen = [=](int x, int y) {
    return radius + x + (2 * radius + 1) * (y + radius);
  };

  auto cb = [&](int nx, int ny) {
    if (nx * nx + ny * ny > radius2) return; // filters everything farther than the radius
    int dx = nx - x;
    int dy = ny - y;
    if (dx == 0 && dy == 0) return; // skips first point

    x = nx;
    y = ny;

    int key = dx + 1 + 3 * (dy + 1);
    if (!current->descendants[key]) {
      int los_key = los_keygen(x, y);
      auto descendant = new Trie(x, y, los_key, current);
      fast_los_map[los_key].push_back(descendant);
      current->descendants[key].reset(descendant);
    }
    current = current->descendants[key].get();
  };

  TranThong(0, 0, tx, ty, cb);
}

void SPCVT::Trie::PreOrder(std::function<bool(int,int)> ShouldStop) const {
  if (ShouldStop(x, y)) return;
  for (int i = 0; i < 9; i++)
    if (descendants[i])
      descendants[i]->PreOrder(ShouldStop);
}

SPCVT::SPCVT(int radius, bool dense) {
  root.reset(new Trie(0, 0, radius + (2 * radius + 1) * radius, nullptr));
  fast_los_map.resize((2 * radius + 1) * (2 * radius + 1));
  fast_los_map[root->los_key].push_back(root.get());
  this->radius = radius;

  for (int i = -radius; i <= radius; i++) {
    if (dense) {
      for (int j = -radius; j <= radius; j++) {
        Trie::AddPath(root.get(), fast_los_map, radius, i, j);
      }
    } else {
      Trie::AddPath(root.get(), fast_los_map, radius, -radius, i);
      Trie::AddPath(root.get(), fast_los_map, radius, radius, i);
      Trie::AddPath(root.get(), fast_los_map, radius, i, -radius);
      Trie::AddPath(root.get(), fast_los_map, radius, i, radius);
    }
  }
}

void SPCVT::FOV(int origin_x, int origin_y,
    std::function<bool(int, int)> DoesBlockVision,
    std::function<void(int, int)> SetVisible) const {
  auto cb = [=](int x, int y) {
    if (DoesBlockVision(x + origin_x, y + origin_y)) return true;
    SetVisible(x + origin_x, y + origin_y);
    return false;
  };
  root->PreOrder(cb);
}

bool SPCVT::LOS(int a_x, int a_y, int b_x, int b_y,
    std::function<bool(int, int)> DoesBlockVision,
    std::function<void(int, int)> TraceOut) const {
  int x = b_x - a_x;
  int y = b_y - a_y;

  if (x * x + y * y > radius * radius) return false;

  int los_key = radius + x + (2 * radius + 1) * (y + radius);

  Trie* trace = nullptr;
  for (Trie* possible : fast_los_map[los_key]) {
    for (Trie* cur = possible; cur != nullptr; cur = cur->antecedent) {
      trace = cur;
      if (DoesBlockVision(cur->x + a_x, cur->y + a_y)) {
        trace = nullptr;
        break;
      }
    }
    if (trace != nullptr) break;
  }
  if (TraceOut) {
    for (Trie* cur = trace; cur != nullptr; cur = cur->antecedent) {
      TraceOut(cur->x + a_x, cur->y + a_y);
    }
  }
  return trace != nullptr;
}
