#!/usr/bin/env python3
"""Generates the 15 Stadium 1 puzzles for the simplified 5x5 Gridiron Gambit
gameplay.

Rules (universal):
  1. Exactly one defender per row (5 rows, 5 defenders).
  2. Exactly one defender per column.
  3. Defenders cannot touch — horizontally, vertically, or diagonally.

Each puzzle = a solution (5 cells with defender types), starting X clue cells,
and optional starting revealed defenders. HARD REQUIREMENT: the starting X's
and revealed defenders must leave EXACTLY ONE valid solution, and it must be
the stored one.

Difficulty ramp = number of starting X marks (of the 20 non-solution cells):
  L1-3 very easy (14/13/12), L4-6 easy (11/11/10), L7-10 medium (9/9/8/8),
  L11-14 hard (7/7/6/6), L15 Game Day (5).

Type mapping by depth row (one defender per row):
  deep row -> S or CB; intermediate -> the other of S/CB; underneath + short
  -> LB, LB; line -> CB. Every level therefore hides 2 CB, 2 LB, 1 S.

Levels 1 and 2 start with one revealed defender so the first chain reaction
teaches the reveal moment immediately.
"""

import json
import random
import sys

N = 5
ROWS = list(range(N))

# Per level: (x-target among 20 non-solution cells, number of starting revealed)
TARGETS = {
    1: (14, 1), 2: (13, 1), 3: (12, 0),
    4: (11, 0), 5: (11, 0), 6: (10, 0),
    7: (9, 0), 8: (9, 0), 9: (8, 0), 10: (8, 0),
    11: (7, 0), 12: (7, 0), 13: (6, 0), 14: (6, 0),
    15: (5, 0),
}

TYPE_BY_ROW = {
    "A": ["s", "cb", "lb", "lb", "cb"],  # S deep
    "B": ["cb", "s", "lb", "lb", "cb"],  # S intermediate
}


def random_solution(rng):
    """Random permutation of columns per row with no adjacent-row defenders
    touching diagonally (|col_i - col_{i+1}| >= 2)."""
    for _ in range(400):
        cols = list(range(N))
        rng.shuffle(cols)
        if all(abs(cols[i] - cols[i + 1]) >= 2 for i in range(N - 1)):
            return list(cols)
    raise RuntimeError("no permutation found")


def all_solutions(xcells, revealed):
    """Every (row -> col) placement satisfying the three rules, avoiding X
    cells, and matching the revealed defenders."""
    out = []
    for cols in __import__("itertools").permutations(range(N)):
        if any(abs(cols[i] - cols[i + 1]) < 2 for i in range(N - 1)):
            continue
        cells = {(r, cols[r]) for r in ROWS}
        if cells & xcells:
            continue
        if any((r, c) not in cells for (r, c) in revealed):
            continue
        out.append(cols)
    return out


def neighbors(cell):
    r, c = cell
    return [(r + dr, c + dc) for dr in (-1, 0, 1) for dc in (-1, 0, 1)
            if (dr, dc) != (0, 0) and 0 <= r + dr < N and 0 <= c + dc < N]


def build_level(level, rng, attempts=400):
    target, revealed_count = TARGETS[level]
    best = None  # (excess over target, puzzle dict)

    for _ in range(attempts):
        cols = random_solution(rng)
        solution_cells = {(r, cols[r]) for r in ROWS}
        type_map = TYPE_BY_ROW[rng.choice(list(TYPE_BY_ROW))]
        types = {(r, cols[r]): type_map[r] for r in ROWS}

        revealed = set()
        if revealed_count:
            # Reveal the underneath-row LB for a strong first chain.
            reveal_cell = (2, cols[2])
            revealed.add(reveal_cell)

        x = set()
        candidates = [(r, c) for r in ROWS for c in range(N)
                      if (r, c) not in solution_cells and (r, c) not in revealed]

        # Greedily X the cells that kill the most alternative solutions.
        while len(all_solutions(x, revealed)) > 1:
            alts = all_solutions(x, revealed)
            alt_cells = {}
            for alt in alts:
                for r in ROWS:
                    cell = (r, alt[r])
                    if cell not in solution_cells:
                        alt_cells[cell] = alt_cells.get(cell, 0) + 1
            if not alt_cells:
                break
            top = max(alt_cells.values())
            pick = rng.choice([c for c, k in alt_cells.items() if k == top])
            x.add(pick)

        if len(all_solutions(x, revealed)) != 1:
            continue

        # Pad with harmless extra X's up to the difficulty target.
        rest = [c for c in candidates if c not in x]
        rng.shuffle(rest)
        while len(x) < target and rest:
            x.add(rest.pop())

        final = all_solutions(x, revealed)
        if len(final) != 1 or set((r, final[0][r]) for r in ROWS) != solution_cells:
            continue

        excess = max(0, len(x) - target)
        if best is None or excess < best[0]:
            best = (excess, {
                "level": level,
                "solution": {(r, cols[r]): types[(r, cols[r])] for r in ROWS},
                "startX": sorted(x),
                "startRevealed": sorted(revealed),
            })
        if excess == 0:
            break

    if best is None:
        raise RuntimeError(f"level {level}: no unique puzzle found")
    return best[1]


def render(p):
    rows = []
    for r in ROWS:
        line = ""
        for c in range(N):
            line += {"cb": "C", "lb": "L", "s": "S"}.get(p["solution"].get((r, c)), ".")
        rows.append(line)
    xrows = []
    for r in ROWS:
        line = ""
        for c in range(N):
            line += "X" if (r, c) in p["startX"] else "."
        xrows.append(line)
    return rows, xrows


def main():
    rng = random.Random(20260913)
    out = []
    for level in range(1, 16):
        p = build_level(level, rng)
        sol, xs = render(p)
        revealed = [f"({r}, {c})" for r, c in p["startRevealed"]]
        out.append({
            "level": level,
            "solution": sol,
            "startX": xs,
            "startRevealed": revealed,
            "startRevealedCount": len(revealed),
        })
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    sys.exit(main())
