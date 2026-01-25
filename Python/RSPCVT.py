from typing import Callable, List, Optional, Tuple, Set, Dict

def tranthong(xstart: int,
              ystart: int,
              xend: int,
              yend: int,
              callback: Callable[[int, int], None]) -> None:
    """
    Standard TranThong (Bresenham-like) line algorithm.
    Ensures that the path from A to B is the same as B to A.
    """
    def difference(xstrt: int, xnd: int) -> Tuple[int, int]:
        return (xnd - xstrt, 1) if xnd >= xstrt else (xstrt - xnd, -1)
    
    x: int = xstart
    y: int = ystart

    deltax, signdx = difference(xstart, xend)
    deltay, signdy = difference(ystart, yend)

    callback(x, y)

    test: int = -1 if signdy == 1 else 0

    if deltax >= deltay:
        test = (deltax + test) >> 1
        for _ in range(deltax):
            test -= deltay
            x += signdx
            if test < 0:
                y += signdy
                test += deltax
            callback(x, y)
    else:
        test = (deltay + test) >> 1
        for _ in range(deltay):
            test -= deltax
            y += signdy
            if test < 0:
                x += signdx
                test += deltay
            callback(x, y)


class VisibilityNode:
    """
    A single node in the visibility trie representing a relative coordinate.
    """
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y
        self.child_nodes: Dict[int, 'VisibilityNode'] = {}
        self.dependent_targets: List[int] = []


class RSPCVT:
    """
    Really Symmetric Pre-Computed Visibility Tries (RSPCVT).
    
    This algorithm pre-calculates rays using the TranThong algorithm and 
    stores them in a Trie. Visibility is strictly defined: A sees B if 
    and only if the specific ray path between them is unobstructed.
    """

    def __init__(self, radius: int):
        """
        Initializes the Trie by pre-computing all rays within the radius.
        
        :param radius: The maximum vision range.
        """
        self.radius = radius
        self.stride = 2 * radius + 1
        self.root = VisibilityNode(0, 0)
        self.valid_targets_list: List[int] = []

        # Dense generation: every point in the circle gets its own specific ray
        for i in range(-radius, radius + 1):
            for j in range(-radius, radius + 1):
                if i*i + j*j <= radius*radius:
                    self._add_ray_path(i, j)

    def _get_key(self, x: int, y: int) -> int:
        """Generates a unique integer key for a relative coordinate."""
        return (self.radius + x) + self.stride * (self.radius + y)

    def _decode_key(self, key: int) -> Tuple[int, int]:
        """Decodes an integer key back into relative x, y coordinates."""
        y = (key // self.stride) - self.radius
        x = (key % self.stride) - self.radius
        return x, y

    def _add_ray_path(self, tx: int, ty: int):
        """Pre-computes a ray path to a target and merges it into the Trie."""
        target_key = self._get_key(tx, ty)
        self.valid_targets_list.append(target_key)

        cur_x, cur_y = 0, 0
        current_node = self.root
        current_node.dependent_targets.append(target_key)

        def step_callback(nx, ny):
            nonlocal cur_x, cur_y, current_node
            dx, dy = nx - cur_x, ny - cur_y
            if dx == 0 and dy == 0:
                return

            cur_x, cur_y = nx, ny
            # Map direction (-1..1) to a 1..9 key
            direction_key = (dx + 1) + 3 * (dy + 1)

            if direction_key not in current_node.child_nodes:
                current_node.child_nodes[direction_key] = VisibilityNode(cur_x, cur_y)
            
            current_node = current_node.child_nodes[direction_key]
            current_node.dependent_targets.append(target_key)

        tranthong(0, 0, tx, ty, step_callback)

    def fov(self, origin_x: int, origin_y: int,
            does_block_vision: Callable[[int, int], bool],
            set_visible: Callable[[int, int], None]) -> None:
        """
        Computes the Field of View from a specific origin point.
        
        :param origin_x: World X coordinate of origin.
        :param origin_y: World Y coordinate of origin.
        :param does_block_vision: Callback function(x, y) -> bool.
        :param set_visible: Callback function(x, y) for visible cells.
        """
        blocked_set: Set[int] = set()

        def traverse(node: VisibilityNode):
            # Check world position blocking
            if does_block_vision(node.x + origin_x, node.y + origin_y):
                self_key = self._get_key(node.x, node.y)
                # Mark all targets that pass through this block
                for target_key in node.dependent_targets:
                    # The wall itself remains visible
                    if target_key != self_key:
                        blocked_set.add(target_key)
                return # Prune branch

            for child in node.child_nodes.values():
                traverse(child)

        traverse(self.root)

        # Final pass: render all non-blocked cells
        for key in self.valid_targets_list:
            if key not in blocked_set:
                dx, dy = self._decode_key(key)
                set_visible(origin_x + dx, origin_y + dy)

    def los(self, a_x: int, a_y: int, b_x: int, b_y: int,
            does_block_vision: Callable[[int, int], bool],
            trace_out: Optional[Callable[[int, int], None]] = None) -> bool:
        """
        Checks Line of Sight between two points using the same ray logic.
        
        :return: True if the path is clear.
        """
        dx, dy = b_x - a_x, b_y - a_y
        if dx*dx + dy*dy > self.radius * self.radius:
            return False

        obstructed = False
        def check_step(x, y):
            nonlocal obstructed
            if obstructed: return
            if does_block_vision(x, y):
                obstructed = True
            elif trace_out:
                trace_out(x, y)

        tranthong(a_x, a_y, b_x, b_y, check_step)
        return not obstructed
