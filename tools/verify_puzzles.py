#!/usr/bin/env python3
"""Verifies the Gridiron Gambit Stadium 1 puzzles by parsing the Swift source
(Puzzles.swift) directly and brute-force checking every puzzle under the three
universal rules:

  1. Exactly one defender per row (5 rows, 5 defenders).
  2. Exactly one defender per column.
  3. Defenders cannot touch — horizontally, vertically, or diagonally.

A fair puzzle has EXACTLY ONE valid solution consistent with its starting X
clues and starting revealed defenders, and it must match the stored solution.
0 solutions or 2+ solutions = invalid.
"""

import itertools
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "ios-gridiron-gambit" / "GridironGambit" / "Data" / "Puzzles.swift"

N = 5
KINDS = {"C": "cb", "L": "lb", "S": "s"}
EXPECTED_COUNTS = {"cb": 2, "lb": 2, "s": 1}


def balanced_block(text: str, start: int) -> str:
    """Returns the substring from `start` through the matching close paren."""
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
        level = int(lm.group(1))
        solution = parse_string_array(block, "solution")
        startX = parse_string_array(block, "startX")
        rev = re.search(r"startRevealed\s*:\s*\[([^\]]*)\]", block)
        revealed = [(int(r), int(c)) for r, c in re.findall(r"\(\s*(\d+)\s*,\s*(\d+)\s*\)", rev.group(1))] if rev else []
        puzzles.append(
            {
                "level": level,
                "solution": solution,
                "startX": startX,
                "startRevealed": revealed,
            }
        )
    return puzzles


def parse_grid(lines):
    """Grid of strings -> dict (row, col) -> char."""
    grid = {}
    for r, line in enumerate(lines):
        assert len(line) == N, f"row {r} is not {N} wide: {line!r}"
        for c, char in enumerate(line):
            if char != ".":
                grid[(r, c)] = char
    return grid


def are_neighbors(a, b):
    return abs(a[0] - b[0]) <= 1 and abs(a[1] - b[1]) <= 1 and a != b


def check(p) -> list:
    problems = []
    lv = p["level"]
    solution = parse_grid(p["solution"])
    startX = parse_grid(p["startX"])

    # Shape: five defenders, one per row/column, never touching.
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

    # Starting clues must never sit on a defender.
    for cell in startX:
        if cell in solution:
            problems.append(f"L{lv}: starting X on solution cell {cell}")
    for (r, c) in p["startRevealed"]:
        if solution.get((r, c)) is None:
            problems.append(f"L{lv}: revealed defender at ({r},{c}) is not a solution cell")

    # Brute force: exactly one position set satisfies rules + clues.
    revealed_by_row = {r: c for r, c in p["startRevealed"]}
    valid = []
    for perm in itertools.permutations(range(N)):
        if any(abs(perm[i] - perm[i + 1]) <= 1 for i in range(N - 1)):
            continue
        cells = {(r, perm[r]) for r in range(N)}
        if cells & set(startX):
            continue
        if any((r, revealed_by_row[r]) not in cells for r in revealed_by_row):
            continue
        valid.append(perm)

    if len(valid) != 1:
        problems.append(f"L{lv}: {len(valid)} solutions exist (need exactly 1)")
    else:
        stored_perm = tuple(next(c for (r, c) in solution if r == row) for row in range(N))
        if valid[0] != stored_perm:
            problems.append(f"L{lv}: unique solution {valid[0]} differs from stored {stored_perm}")

    return problems


def main() -> int:
    puzzles = parse_puzzles()
    print(f"Parsed {len(puzzles)} puzzles from Puzzles.swift")
    failures = 0
    for p in sorted(puzzles, key=lambda x: x["level"]):
        problems = check(p)
        if problems:
            failures += 1
            print(f"\n✗ Level {p['level']}")
            for pr in problems:
                print(f"   - {pr}")
        else:
            marks = sum(line.count("X") for line in p["startX"])
            print(f"✓ Level {p['level']:2d}: unique solution, matches stored  ({marks} starting X marks)")
    print(f"\n{len(puzzles) - failures}/{len(puzzles)} puzzles pass")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
