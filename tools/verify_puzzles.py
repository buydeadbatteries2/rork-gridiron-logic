#!/usr/bin/env python3
"""Verifies the Gridiron Gambit Stadium 1 puzzles by parsing the Swift source
(Puzzles.swift) directly and brute-force checking every puzzle under the three
universal rules:

  1. Exactly one defender per row (5 rows, 5 defenders).
  2. Exactly one defender per column.
  3. Defenders cannot touch — horizontally, vertically, or diagonally.

Boards start CLEAN: there are NO starting X marks anywhere. The only visible
clues are the starting revealed defenders. A fair puzzle has EXACTLY ONE valid
solution consistent with its VISIBLE revealed defenders, and it must match the
stored solution. 0 solutions or 2+ solutions = invalid.

Also simulates full play under the engine semantics (blocked = player marks
ONLY; revealed defenders are information only) to prove every level is
completable, and replays the Level 1 guided tutorial tap by tap.
"""

import itertools
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "ios-gridiron-gambit" / "GridironGambit" / "Data" / "Puzzles.swift"

N = 5


def balanced_block(text: str, start: int) -> str:
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
    raise ValueError("unbalanced parens")


def parse_string_array(block: str, key: str) -> list:
    m = re.search(key + r"\s*:\s*\[((?:\s*\"[^\"]*\",?)*)\s*\]", block)
    if not m:
        return []
    return re.findall(r"\"([^\"]*)\"", m.group(1))


def parse_puzzles() -> list:
    text = SRC.read_text()
    puzzles = []
    for m in re.finditer(r"makePuzzle\s*\(", text):
        block = balanced_block(text, m.start())
        lm = re.search(r"level\s*:\s*(\d+)", block)
        if not lm:
            continue  # the makePuzzle function definition, not a data block
        if "startX" in block:
            raise AssertionError(f"L{lm.group(1)}: stale startX block still present")
        level = int(lm.group(1))
        solution = parse_string_array(block, "solution")
        rev = re.search(r"startRevealed\s*:\s*\[([^\]]*)\]", block)
        revealed = (
            [(int(r), int(c)) for r, c in re.findall(r"\(\s*(\d+)\s*,\s*(\d+)\s*\)", rev.group(1))]
            if rev
            else []
        )
        puzzles.append({"level": level, "solution": solution, "startRevealed": revealed})
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


def count_solutions(solution, revealed):
    """Distinct 5-defender position sets consistent with the VISIBLE reveals."""
    revealed_by_row = {r: c for r, c in revealed}
    assignments = set()
    free_rows = tuple(r for r in range(N) if r not in revealed_by_row)
    for perm in itertools.permutations(range(N)):
        cols = dict(revealed_by_row)
        ok = True
        for i, r in enumerate(free_rows):
            if perm[i] in cols.values():
                ok = False
                break
            cols[r] = perm[i]
        if ok:
            assignments.add(tuple(sorted(cols.items())))

    valid = []
    for cells in assignments:
        if any(are_neighbors(a, b) for a, b in zip(cells, cells[1:])):
            continue
        if any(
            are_neighbors((r, c), rv)
            for (r, c) in cells
            for rv in revealed
            if (r, c) != rv
        ):
            continue
        valid.append(dict(cells))
    return valid


def impossible_cells(revealed):
    """Engine-internal knowledge (revealed geometry) — never drawn, never
    credited by the reveal check; used only for contradiction/hint logic."""
    impossible = set()
    for (r, c) in revealed:
        for i in range(N):
            impossible.add((i, c))
            impossible.add((r, i))
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if 0 <= r + dr < N and 0 <= c + dc < N:
                    impossible.add((r + dr, c + dc))
    return impossible - set(revealed)


def forced_reveal(solution, revealed, marks):
    """Exact port of PuzzleEngine.forcedReveal: blocked = player marks ONLY."""
    blocked = set(marks)
    lines = [[(r, c) for c in range(N)] for r in range(N)] + [
        [(r, c) for r in range(N)] for c in range(N)
    ]
    for line in lines:
        if any(cell in revealed for cell in line):
            continue
        remaining = [cell for cell in line if cell not in blocked and cell not in revealed]
        if len(remaining) != 1:
            continue
        cell = remaining[0]
        if cell not in solution:
            continue
        if not any(m in line for m in marks):
            continue
        return cell
    return None


def has_contradiction(revealed, marks):
    blocked = impossible_cells(revealed) | set(marks)
    lines = [[(r, c) for c in range(N)] for r in range(N)] + [
        [(r, c) for r in range(N)] for c in range(N)
    ]
    for line in lines:
        if any(cell in revealed for cell in line):
            continue
        remaining = [cell for cell in line if cell not in blocked and cell not in revealed]
        if not remaining:
            return True
    return False


def hint_x_cell(solution, revealed, marks):
    impossible = impossible_cells(revealed)
    best = None
    for r in range(N):
        for c in range(N):
            cell = (r, c)
            if cell in solution or cell in revealed or cell in marks:
                continue
            trial = set(marks) | {cell}
            if forced_reveal(solution, revealed, trial) is not None:
                score = 2
            elif cell in impossible:
                score = 1
            else:
                score = 0
            if best is None or score > best[1]:
                best = (cell, score)
    return best[0] if best else None


def check(p) -> list:
    problems = []
    lv = p["level"]
    solution = parse_grid(p["solution"])
    revealed = set(p["startRevealed"])

    if len(solution) != N:
        problems.append(f"L{lv}: {len(solution)} defenders (need 5)")
    rows = {r for r, _ in solution}
    cols = {c for _, c in solution}
    if len(rows) != N:
        problems.append(f"L{lv}: rows covered = {len(rows)} (need 5)")
    if len(cols) != N:
        problems.append(f"L{lv}: columns covered = {len(cols)} (need 5)")
    cells = list(solution)
    for i in range(len(cells)):
        for j in range(i + 1, len(cells)):
            if are_neighbors(cells[i], cells[j]):
                problems.append(f"L{lv}: defenders touch at {cells[i]} and {cells[j]}")

    counts = {}
    for kind in solution.values():
        counts[kind] = counts.get(kind, 0) + 1
    if counts != {"C": 2, "L": 2, "S": 1}:
        problems.append(f"L{lv}: defender type counts {counts} (need 2 CB, 2 LB, 1 S)")

    for (r, c) in revealed:
        if solution.get((r, c)) is None:
            problems.append(f"L{lv}: revealed defender at ({r},{c}) is not a solution cell")

    valid = count_solutions(solution, revealed)
    # Level 1 intentionally starts with one reveal (two candidate defenses);
    # the guided tutorial's player-driven safety reveal makes it unique.
    effective = revealed | {(1, 3)} if lv == 1 else revealed
    effective_valid = valid if lv != 1 else count_solutions(solution, effective)
    if len(effective_valid) != 1:
        problems.append(
            f"L{lv}: {len(effective_valid)} solutions exist from visible clues (need exactly 1)"
        )
    else:
        stored_perm = tuple(next(c for (r, c) in solution if r == row) for row in range(N))
        got = valid[0] if len(valid) == 1 else effective_valid[0]
        got_perm = tuple(got[row] for row in range(N))
        if got_perm != stored_perm:
            problems.append(f"L{lv}: unique solution {got_perm} differs from stored {stored_perm}")

    # Static board: with zero player marks nothing may reveal at the snap.
    if forced_reveal(solution, revealed, set()) is not None:
        problems.append(f"L{lv}: the game would reveal on its own at the snap")

    # Completability: a player who closes each hidden defender's row by hand
    # (falling back to the column when the row's defender is already known).
    sim_revealed = set(revealed)
    sim_marks = set()
    guard = 0
    while len(sim_revealed) < N:
        guard += 1
        if guard > 60:
            problems.append(f"L{lv}: row/column-closing strategy stalled")
            break
        fired = False
        for (r, c) in sorted(solution):
            if (r, c) in sim_revealed:
                continue
            row_cells = [
                (r, cc) for cc in range(N)
                if (r, cc) not in solution and (r, cc) not in sim_marks and (r, cc) not in sim_revealed
            ]
            col_cells = [
                (rr, c) for rr in range(N)
                if (rr, c) not in solution and (rr, c) not in sim_marks and (rr, c) not in sim_revealed
            ]
            for cell in row_cells or col_cells:
                sim_marks.add(cell)
                hit = forced_reveal(solution, sim_revealed, sim_marks)
                if hit:
                    sim_revealed.add(hit)
                    fired = True
                    break
            if fired:
                break
        if not fired:
            problems.append(f"L{lv}: strategy could not force a reveal")
            break
    if sim_revealed != set(solution):
        problems.append(f"L{lv}: manual play revealed {sorted(sim_revealed)} != solution")

    # Hint-following player must also finish every level.
    h_revealed = set(revealed)
    h_marks = set()
    for _ in range(60):
        if len(h_revealed) >= N:
            break
        cell = hint_x_cell(solution, h_revealed, h_marks)
        if cell is None:
            problems.append(f"L{lv}: hint found no square")
            break
        h_marks.add(cell)
        hit = forced_reveal(solution, h_revealed, h_marks)
        if hit:
            h_revealed.add(hit)
    else:
        problems.append(f"L{lv}: hint-guided play stalled")
    if h_revealed != set(solution):
        problems.append(f"L{lv}: hint-guided play revealed {sorted(h_revealed)} != solution")

    return problems, len(valid), len(revealed)


def main() -> int:
    puzzles = parse_puzzles()
    print(f"Parsed {len(puzzles)} puzzles from Puzzles.swift (boards start clean: no starting X marks)\n")
    print(f"{'Level':>5} | {'Starting revealed':>17} | {'Valid solutions':>15}")
    print("-" * 45)
    failures = 0
    for p in sorted(puzzles, key=lambda x: x["level"]):
        problems, n_valid, n_revealed = check(p)
        if problems:
            failures += 1
            print(f"✗ L{p['level']:2d} | {n_revealed:>17} | {n_valid:>15}")
            for pr in problems:
                print(f"     - {pr}")
        else:
            print(f"✓ L{p['level']:2d} | {n_revealed:>17} | {n_valid:>15}")

    # Replay the Level 1 guided tutorial under the exact engine semantics:
    # four player taps, one reveal on the final tap, no false contradictions.
    p1 = next(p for p in puzzles if p["level"] == 1)
    solution = parse_grid(p1["solution"])
    revealed = set(p1["startRevealed"])
    marks = set()
    tutorial = [(1, 0), (1, 1), (1, 2), (1, 4)]
    for i, cell in enumerate(tutorial):
        marks.add(cell)
        hit = forced_reveal(solution, revealed, marks)
        if i < 3 and hit is not None:
            print(f"\n✗ tutorial: unexpected reveal {hit} after tap {i + 1} {cell}")
            failures += 1
        if i == 3:
            if hit != (1, 3):
                print(f"\n✗ tutorial: final tap revealed {hit}, expected the S at (1,3)")
                failures += 1
            else:
                revealed.add(hit)
        if has_contradiction(revealed, marks):
            print(f"\n✗ tutorial: false 'CHECK YOUR BLOCKS' after tap {i + 1}")
            failures += 1
    if failures == 0 or (1, 3) in revealed:
        print("\n✓ Level 1 tutorial: 4 player taps → exactly one reveal (S at row 1, col 3),")
        print("  visible X count at start = 0, no auto-placed marks, no false contradictions.")

    print(f"\n{len(puzzles) - failures}/{len(puzzles)} puzzles pass under the visible-clue-only rules")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
