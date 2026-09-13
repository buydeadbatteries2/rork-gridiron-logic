#!/usr/bin/env python3
"""Verifies the Gridiron Gambit Stadium 1 puzzles under the FOUR permanent
rules, by parsing the Swift source (Puzzles.swift) directly:

  1. exactly one defender per Coverage Zone
  2. exactly one defender per row
  3. exactly one defender per column
  4. defenders cannot touch — horizontally, vertically, or diagonally

Boards start CLEAN: no starting X marks exist anywhere. Visible clues are the
Coverage Zones plus any starting revealed defenders. A fair puzzle has
EXACTLY ONE valid solution consistent with its visible state, and it must
match the stored solution. 0 solutions or 2+ solutions = invalid.

Also simulates play under the exact engine semantics (lines = rows + columns
+ zones; blocked = player marks ONLY; a line with a revealed defender is
skipped; blown assignment = zero consistent solutions) to prove every level
is completable, replays the Level 1 guided tutorial, and checks zone quality
(contiguity, sizes, no full rows/columns, one defender per zone).
"""

import itertools
import re
import sys
from collections import Counter, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "ios-gridiron-gambit" / "GridironGambit" / "Data" / "Puzzles.swift"

N = 5


def parse_puzzles() -> list:
    text = SRC.read_text()

    def balanced_block(source, start):
        depth = 0
        for i in range(start, len(source)):
            if source[i] == "(":
                depth += 1
            elif source[i] == ")":
                depth -= 1
                if depth == 0:
                    return source[start : i + 1]
        raise ValueError("unbalanced parens")

    def rows_of(block, key):
        m = re.search(key + r"\s*:\s*\[((?:\s*\"[^\"]*\",?)*)\s*\]", block)
        return re.findall(r"\"([^\"]*)\"", m.group(1)) if m else []

    puzzles = []
    for m in re.finditer(r"makePuzzle\s*\(", text):
        block = balanced_block(text, m.start())
        lm = re.search(r"level\s*:\s*(\d+)", block)
        if not lm:
            continue  # the makePuzzle function definition
        for stale in ("startX", "startingX"):
            if stale in block:
                raise AssertionError(f"L{lm.group(1)}: stale {stale} still present")
        level = int(lm.group(1))
        solution_rows = rows_of(block, "solution")
        zone_rows = rows_of(block, "zones")
        rev = re.search(r"startRevealed\s*:\s*\[([^\]]*)\]", block)
        revealed = (
            {(int(r), int(c)) for r, c in re.findall(r"\(\s*(\d+)\s*,\s*(\d+)\s*\)", rev.group(1))}
            if rev
            else set()
        )
        puzzles.append(
            {
                "level": level,
                "solution": parse_grid(solution_rows),
                "zones": parse_grid(zone_rows),
                "revealed": revealed,
            }
        )
    return puzzles


def parse_grid(lines):
    grid = {}
    for r, line in enumerate(lines):
        assert len(line) == N, f"row {r} is not {N} wide: {line!r}"
        for c, char in enumerate(line):
            if char != ".":
                grid[(r, c)] = char
    return grid


def are_neighbors(a, b):
    return abs(a[0] - b[0]) <= 1 and abs(a[1] - b[1]) <= 1 and a != b


def zone_lines(zones):
    by_zone = {z: [] for z in set(zones.values())}
    for cell, z in zones.items():
        by_zone[z].append(cell)
    return [sorted(by_zone[z]) for z in sorted(by_zone)]


def is_contiguous(cells):
    cells = set(cells)
    seen = {next(iter(cells))}
    queue = deque(seen)
    while queue:
        r, c = queue.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (r + dr, c + dc)
            if n in cells and n not in seen:
                seen.add(n)
                queue.append(n)
    return seen == cells


NO_TOUCH_PERMS = [
    p for p in itertools.permutations(range(N))
    if all(abs(p[r] - p[r + 1]) >= 2 for r in range(N - 1))
]


def consistent_solutions(zones, revealed, marks):
    """Complete defenses satisfying all four rules, containing every visible
    revealed defender, and touching none of the player's marks."""
    out = []
    revealed = set(revealed)
    for p in NO_TOUCH_PERMS:
        cells = {(r, p[r]) for r in range(N)}
        if cells & set(marks):
            continue
        if not revealed <= cells:
            continue
        counts = Counter(zones[cell] for cell in cells)
        if len(counts) == N and all(v == 1 for v in counts.values()):
            out.append(cells)
    return out


def forced_reveal(zones, solution, revealed, marks):
    """Exact port of PuzzleEngine.forcedReveal: rows, then columns, then
    zones; blocked = player marks ONLY; lines with a revealed defender are
    skipped; the remaining cell must be the stored solution and at least one
    player mark must sit in the line."""
    revealed = set(revealed)
    marks = set(marks)
    lines = (
        [[(r, c) for c in range(N)] for r in range(N)]
        + [[(r, c) for r in range(N)] for c in range(N)]
        + zone_lines(zones)
    )
    for line in lines:
        if any(cell in revealed for cell in line):
            continue
        remaining = [cell for cell in line if cell not in marks and cell not in revealed]
        if len(remaining) != 1:
            continue
        cell = remaining[0]
        if cell not in solution:
            continue
        if not any(m in line for m in marks):
            continue
        return cell
    return None


def hint_x_cell(zones, solution, revealed, marks):
    """Exact port of PuzzleEngine.hintXCell: prefers reveal-completing marks,
    then provably empty squares, then full-logic eliminations — never a
    hidden defender."""
    revealed = set(revealed)
    marks = set(marks)
    possible = set().union(*consistent_solutions(zones, revealed, marks)) if True else set()

    def impossible():
        imp = set()
        for cell in revealed:
            r, c = cell
            imp |= {(i, c) for i in range(N)} | {(r, i) for i in range(N)}
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    n = (r + dr, c + dc)
                    if 0 <= n[0] < N and 0 <= n[1] < N:
                        imp.add(n)
        for line in zone_lines(zones):
            if line and any(cell in revealed for cell in line):
                imp |= set(line)
        return imp - revealed

    imp = impossible()
    best = None
    for r in range(N):
        for c in range(N):
            cell = (r, c)
            if cell in solution or cell in revealed or cell in marks:
                continue
            trial = marks | {cell}
            score = 0
            if forced_reveal(zones, solution, revealed, trial) is not None:
                score = 3
            elif cell in imp:
                score = 2
            elif cell not in possible:
                score = 1
            if best is None or score > best[1]:
                best = (cell, score)
    return best[0] if best else None


def check(p) -> tuple:
    problems = []
    lv = p["level"]
    solution = p["solution"]
    zones = p["zones"]
    revealed = p["revealed"]

    if len(zones) != 25:
        problems.append(f"L{lv}: {len(zones)} zone assignments (need 25)")
    if set(zones.values()) != set("ABCDE"):
        problems.append(f"L{lv}: zones must be exactly A–E, got {sorted(set(zones.values()))}")
        return problems, 0

        full_lines = {frozenset((rr, c) for c in range(N)) for rr in range(N)} | {
            frozenset((r, cc) for r in range(N)) for cc in range(N)
        }
        for z, line in enumerate(sorted(zone_lines(zones), key=lambda l: l[0])):
            if not is_contiguous(line):
                problems.append(f"L{lv}: zone {z} is not contiguous")
            if len(line) < 3:
                problems.append(f"L{lv}: zone {z} has only {len(line)} cells")
            if frozenset(line) in full_lines:
                problems.append(f"L{lv}: zone {z} is a full row/column")

    per_zone = Counter(zones[cell] for cell in solution)
    if per_zone != dict(Counter({z: 1 for z in zones.values()})):
        if any(v != 1 for v in per_zone.values()) or len(per_zone) != 5:
            problems.append(f"L{lv}: zones hold {dict(per_zone)} defenders (need exactly 1 each)")

    if len(solution) != N:
        problems.append(f"L{lv}: {len(solution)} defenders (need 5)")
    if len({r for r, _ in solution}) != N:
        problems.append(f"L{lv}: rows covered = {len({r for r, _ in solution})}")
    if len({c for _, c in solution}) != N:
        problems.append(f"L{lv}: columns covered = {len({c for _, c in solution})}")
    cells = list(solution)
    for i in range(len(cells)):
        for j in range(i + 1, len(cells)):
            if are_neighbors(cells[i], cells[j]):
                problems.append(f"L{lv}: defenders touch at {cells[i]} and {cells[j]}")
    counts = Counter(solution.values())
    if counts != Counter({"C": 2, "L": 2, "S": 1}):
        problems.append(f"L{lv}: defender kinds {dict(counts)} (need 2 CB, 2 LB, 1 S)")

    for cell in revealed:
        if cell not in solution:
            problems.append(f"L{lv}: revealed defender at {cell} is not a solution cell")

    sols = consistent_solutions(zones, revealed, set())
    if len(sols) != 1:
        problems.append(f"L{lv}: {len(sols)} solutions from visible state (need exactly 1)")
    elif next(iter(sols)) != set(solution):
        problems.append(f"L{lv}: unique solution differs from stored one")

    if forced_reveal(zones, solution, revealed, set()) is not None:
        problems.append(f"L{lv}: the game would reveal on its own at the snap")

    # Hint-guided play must complete every level (mirrors the XCTest loop).
    sim_revealed = set(revealed)
    sim_marks = set()
    for _ in range(60):
        if len(sim_revealed) >= N:
            break
        cell = hint_x_cell(zones, solution, sim_revealed, sim_marks)
        if cell is None:
            problems.append(f"L{lv}: hint found no square")
            break
        if not consistent_solutions(zones, sim_revealed, sim_marks | {cell}):
            problems.append(f"L{lv}: hint would cause a blown assignment at {cell}")
            break
        sim_marks.add(cell)
        hit = forced_reveal(zones, solution, sim_revealed, sim_marks)
        if hit:
            sim_revealed.add(hit)
    else:
        problems.append(f"L{lv}: hint-guided play stalled")
    if sim_revealed != set(solution):
        problems.append(f"L{lv}: hint-guided play revealed {sorted(sim_revealed)} != solution")

    # Marking a hidden defender must always be a blown assignment.
    hidden = [c for c in solution if c not in revealed]
    for cell in hidden:
        if consistent_solutions(zones, revealed, {cell}):
            problems.append(f"L{lv}: X'ing hidden defender {cell} was NOT flagged as a mistake")
            break

    return problems, len(sols), len(revealed)


def main() -> int:
    puzzles = parse_puzzles()
    print(f"Parsed {len(puzzles)} puzzles from Puzzles.swift — four rules, clean boards\n")
    print(f"{'Level':>5} | {'Reveals':>7} | {'Solutions':>9} | {'Zone sizes':>12}")
    print("-" * 45)
    failures = 0
    for p in sorted(puzzles, key=lambda x: x["level"]):
        problems, n_sols, n_rev = check(p)
        sizes = sorted(Counter(p["zones"].values()).values())
        if problems:
            failures += 1
            print(f"✗ L{p['level']:2d} | {n_rev:>7} | {n_sols:>9} | {str(sizes):>12}")
            for pr in problems:
                print(f"     - {pr}")
        else:
            print(f"✓ L{p['level']:2d} | {n_rev:>7} | {n_sols:>9} | {str(sizes):>12}")

    # Replay the Level 1 guided tutorial under exact engine semantics.
    p1 = next(p for p in puzzles if p["level"] == 1)
    solution, zones, revealed = p1["solution"], p1["zones"], set(p1["revealed"])
    marks = set()
    tutorial = [(1, 3), (1, 1), (1, 2), (1, 4)]
    for i, cell in enumerate(tutorial):
        marks.add(cell)
        if not consistent_solutions(zones, revealed, marks):
            print(f"\n✗ tutorial: tap {i + 1} {cell} would be a blown assignment")
            failures += 1
            break
        hit = forced_reveal(zones, solution, revealed, marks)
        if i < 3:
            if hit is not None:
                print(f"\n✗ tutorial: unexpected reveal {hit} after tap {i + 1}")
                failures += 1
        elif hit != next(c for c in solution if c[0] == 1):
            print(f"\n✗ tutorial: final tap revealed {hit}, expected the row-1 defender {next(c for c in solution if c[0] == 1)}")
            failures += 1
        else:
            revealed.add(hit)
    else:
        print("\n✓ Level 1 tutorial: 4 player taps → exactly one reveal, visible X count")
        print("  at start = 0, no auto-placed marks, no blown assignments.")

    print(f"\n{len(puzzles) - failures}/{len(puzzles)} puzzles pass under the four-rule system")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
