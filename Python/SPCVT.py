from typing import Callable, List, Optional, Tuple


def tranthong(xstart: int,
               ystart: int,
               xend: int,
               yend: int,
               callback: Callable[[int, int], None]) -> None:
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


class Trie:
  def __init__(self, x: int, y: int, los_key: int,
               antecedent: Optional['Trie']):
    self.x = x
    self.y = y
    self.los_key = los_key
    self.antecedent = antecedent
    self.descendants: List[Optional['Trie']] = [None] * 9
 

  @classmethod
  def add_path(cls, root: 'Trie', fast_los_map: List[List['Trie']],
               radius: int, tx: int, ty: int):
    x: int = root.x
    y: int = root.y
    radius2: int = radius * radius
    current: Optional['Trie'] = root

    def los_keygen(x: int, y: int) -> int:
      return radius + x + (2 * radius + 1) * (y + radius)

    def cb(nx: int, ny: int) -> None:
      nonlocal current, x, y

      if nx * nx + ny * ny > radius2: return
      dx: int = nx - x
      dy: int = ny - y
      if dx == 0 and dy == 0: return

      x = nx
      y = ny

      key: int = dx + 1 + 3 * (dy + 1)
      
      if current.descendants[key] is None:
        los_key = los_keygen(x, y)
        descendant = Trie(x, y, los_key, current)
        fast_los_map[los_key].append(descendant)
        current.descendants[key] = descendant

      current = current.descendants[key]

    tranthong(0, 0, tx, ty, cb)


  def pre_order(self, should_stop: Callable[[int, int], bool]):
    if should_stop(self.x, self.y): return
    for i in range(9):
      if self.descendants[i] is not None:
        self.descendants[i].pre_order(should_stop)


class SPCVT:
  def __init__(self, radius: int):
    self.root: Trie = Trie(0, 0, radius + (2 * radius + 1) * radius, None)
    self.fast_los_map: List[List[Trie]] = [
      [] for _ in range((2 * radius + 1) * (2 * radius + 1))
    ]
    self.fast_los_map[self.root.los_key].append(self.root)
    self.radius: int = radius

    for i in range(-radius, radius + 1):
      Trie.add_path(self.root, self.fast_los_map, radius, -radius, i)
      Trie.add_path(self.root, self.fast_los_map, radius, radius, i)
      Trie.add_path(self.root, self.fast_los_map, radius, i, -radius)
      Trie.add_path(self.root, self.fast_los_map, radius, i, radius)


  def fov(self, origin_x: int, origin_y: int,
          does_block_vision: Callable[[int, int], bool],
          set_visible: Callable[[int, int], None]) -> None:
    def cb(x: int, y: int) -> bool:
      if does_block_vision(x + origin_x, y + origin_y): return True
      set_visible(x + origin_x, y + origin_y)
      return False
    self.root.pre_order(cb)


  def los(self, a_x: int, a_y: int, b_x: int, b_y: int,
          does_block_vision: Callable[[int, int], bool],
          trace_out: Optional[Callable[[int, int], None]]) -> None:
    x: int = b_x - a_x
    y: int = b_y - a_y

    if x * x + y * y > self.radius * self.radius:
      return False

    los_key: int = self.radius + x + (2 * self.radius + 1) * (y + self.radius)

    cur: Optional[Trie] = None
    trace: Optional[Trie] = None
    for possible in self.fast_los_map[los_key]:
      trace = possible
      cur = possible
      while cur is not None:
        if does_block_vision(cur.x + a_x, cur.y + a_y):
          trace = None
          break
        cur = cur.antecedent
      if trace is not None:
        break
    
    if trace_out is not None:
      cur = trace
      while cur is not None:
        trace_out(cur.x + a_x, cur.y + a_y)
        cur = cur.antecedent
    
    return trace is not None
