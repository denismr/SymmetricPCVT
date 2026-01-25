#include "RSPCVT.h"
#include <cmath>
#include <algorithm>

extern void TranThong(int x0, int y0, int x1, int y1, std::function<void(int, int)> cb);

RSPCVT::RSPCVT(int radius) : radius(radius) {
    stride = 2 * radius + 1;
    root = std::make_unique<Node>(0, 0);
    blocked_cache.resize(stride * stride);

    for (int i = -radius; i <= radius; ++i) {
        for (int j = -radius; j <= radius; ++j) {
            if (i * i + j * j <= radius * radius) {
                add_path(i, j);
            }
        }
    }
}

int RSPCVT::get_key(int x, int y) const {
    return (radius + x) + stride * (y + radius);
}

void RSPCVT::decode_key(int key, int& x, int& y) const {
    y = (key / stride) - radius;
    x = (key % stride) - radius;
}

void RSPCVT::add_path(int tx, int ty) {
    int target_key = get_key(tx, ty);
    all_valid_keys.push_back(target_key);

    int cur_x = 0, cur_y = 0;
    Node* current = root.get();
    current->dependent_targets.push_back(target_key);

    TranThong(0, 0, tx, ty, [&](int nx, int ny) {
        int dx = nx - cur_x;
        int dy = ny - cur_y;
        if (dx == 0 && dy == 0) return;

        cur_x = nx;
        cur_y = ny;

        int dir_idx = (dx + 1) + 3 * (dy + 1);
        if (!current->children[dir_idx]) {
            current->children[dir_idx] = std::make_unique<Node>(cur_x, cur_y);
        }

        current = current->children[dir_idx].get();
        current->dependent_targets.push_back(target_key);
    });
}

void RSPCVT::FOV(int origin_x, int origin_y,
                 std::function<bool(int, int)> DoesBlockVision,
                 std::function<void(int, int)> SetVisible) const {
    
    std::fill(blocked_cache.begin(), blocked_cache.end(), false);

    traverse(root.get(), origin_x, origin_y, DoesBlockVision);

    for (int key : all_valid_keys) {
        if (!blocked_cache[key]) {
            int dx, dy;
            decode_key(key, dx, dy);
            SetVisible(origin_x + dx, origin_y + dy);
        }
    }
}

void RSPCVT::traverse(const Node* node, int ox, int oy, 
                      const std::function<bool(int, int)>& DoesBlockVision) const {
    
    if (DoesBlockVision(node->x + ox, node->y + oy)) {
        int self_key = get_key(node->x, node->y);
        for (int target_key : node->dependent_targets) {
            // Walls are visible; block everything behind them.
            if (target_key != self_key) {
                blocked_cache[target_key] = true;
            }
        }
        return; // Prune branch
    }

    for (int i = 0; i < 9; ++i) {
        if (node->children[i]) {
            traverse(node->children[i].get(), ox, oy, DoesBlockVision);
        }
    }
}

bool RSPCVT::LOS(int a_x, int a_y, int b_x, int b_y,
                 std::function<bool(int, int)> DoesBlockVision,
                 std::function<void(int, int)> TraceOut) const {
    
    int dx = b_x - a_x;
    int dy = b_y - a_y;
    if (dx * dx + dy * dy > radius * radius) return false;

    bool obstructed = false;
    TranThong(a_x, a_y, b_x, b_y, [&](int x, int y) {
        if (obstructed) return;
        if (DoesBlockVision(x, y)) {
            obstructed = true;
        } else if (TraceOut) {
            TraceOut(x, y);
        }
    });

    return !obstructed;
}
