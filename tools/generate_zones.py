#!/usr/bin/env python3
"""Generates Coverage Zone layouts + solutions for the Gridiron Gambit puzzles.

The four permanent rules:
  1. exactly one defender per Coverage Zone
  2. exactly one defender per row
  3. exactly one defender per column
  4. defenders cannot touch — horizontally, vertically, or diagonally

Per level the generator searches for:
  - a solution (one per row/col, no touching, kinds 2 CB / 2 LB / 1 S),
  - 5 contiguous, irregular Coverage Zones grown around the solution cells,
    each containing exactly one defender, no zone equal to a full row/column,
  - starting revealed defenders: L1–L5 = 1 reveal, L6–L15 = 0 (fallback 1),
    such that EXACTLY ONE solution is consistent with the visible state,
  - for Level 1: a 4-tap guided tutorial (zone tap → row/column tap →
    no-touch tap → final tap) that ends in exactly one reveal through the
    line-closing engine.

Finally it patches Data/Puzzles.swift in place, keeping every level's
formation, routes, names and situations untouched.
"""

import itertools
import random
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "ios-gridiron-gambit" / "GridironGambit" / "Data" / "Puzzles.swift"

N = 5
ALL_CELLS = [(r, c) for r in range(N) for c in range(N)]
KINDS = ["C", "C", "L", "L", "S"]


def neighbors4(cell):
    r, c = cell
    for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if 0 <= r + dr < N and 0 <= c + dc < N:
            return_cell = (r + dr, c + dc)
            yield return_cell


NO_TOUCH_PERMS = [
    p for p in itertools.permutations(range(N))
    if all(abs(p[r] - p[r + 1]) >= 2 for r in range(N - 1))
]


def gen_solution(rng):
    while True:
        cols = rng.sample(range(N), N)
        if all(abs(cols[r] - cols[r + 1]) >= 2 for r in range(N - 1)):
            return cols


def gen_zones(rng, seeds, max_size):
    """Grow 5 contiguous zones from the solution cells, near-equal sizes."""
    owner = {}
    zone_cells = [[] for _ in range(N)]
    for z, seed in enumerate(seeds):
        owner[seed] = z
        zone_cells[z].append(seed)
    unassigned = set(ALL_CELLS) - set(seeds)
    while unassigned:
        growable = []
        for z in range(N):
            if len(zone_cells[z]) >= max_size:
                continue
            cands = [n for cell in zone_cells[z] for n in neighbors4(cell) if n in unassigned]
            if cands:
                growable.append((len(zone_cells[z]), z, cands))
        if not growable:
            return None
        growable.sort()
        z = rng.choice(growable[: min(2, len(growable))])[1]
        cands = [n for cell in zone_cells[z] for n in neighbors4(cell) if n in unassigned]
        cell = rng.choice(cands)
        owner[cell] = z
        zone_cells[z].append(cell)
        unassigned.discard(cell)

    # Quality: every zone at least 3 cells; no zone is a full row or column.
    for z in range(N):
        cells = set(cells_by_zone(zone_cells, z))
        if len(cells) < 3:
            return None
        if any(cells == {(r, c) for c in range(N)} for r in range(N)):
            return None
        if any(cells == {(r, c) for r in range(N)} for c in range(N)):
            return None
    return owner


def cells_by_zone(zone_cells, z):
    return zone_cells[z]


def zone_lines(owner):
    lines = []
    for z in range(N):
        lines.append([cell for cell in ALL_CELLS if owner[cell] == z])
    return lines


def consistent_solutions(owner, revealed, marks):
    out = []
    revealed = set(revealed)
    for p in NO_TOUCH_PERMS:
        cells = {(r, p[r]) for r in range(N)}
        if cells & marks:
            continue
        if not revealed <= cells:
            continue
        counts = Counter(owner[cell] for cell in cells)
        if len(counts) == N and all(v == 1 for v in counts.values()):
            out.append(cells)
    return out


def forced_reveal(owner, solution, revealed, marks):
    """Exact port of the Swift line-closing engine (rows, columns, zones)."""
    revealed = set(revealed)
    marks = set(marks)
    lines = [
        [(r, c) for c in range(N)] for r in range(N)
    ] + [
        [(r, c) for r in range(N)] for c in range(N)
    ] + zone_lines(owner)
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


def safe_cells(owner, revealed, marks=()):
    consistent = consistent_solutions(owner, revealed, set(marks))
    possible = set().union(*consistent) if consistent else set()
    return set(ALL_CELLS) - possible - set(marks) - set(revealed)


def solution_kinds(cols, kind_of):
    return {(r, cols[r]): kind_of[r] for r in range(N)}


def find_tutorial(owner, solution_kinds_map, revealed):
    """4 guided taps on Level 1 ending in exactly one reveal."""
    lb = next(cell for cell, k in solution_kinds_map.items() if k == "L")
    r_lb, c_lb = lb
    for r_row in (r_lb - 1, r_lb + 1):
        if not 0 <= r_row < N:
            continue
        row_cells = [(r_row, c) for c in range(N)]
        sol_cell = next(c for c in row_cells if c in solution_kinds_map)
        tappable = [c for c in row_cells if c != sol_cell]
        if len(tappable) != 4:
            continue
        zone_cells = [c for c in tappable if owner[c] == owner[lb]]
        touch_cells = [c for c in tappable if abs(c[1] - c_lb) <= 1]
        if not zone_cells or not touch_cells:
            continue
        for t1 in zone_cells:
            for t3 in touch_cells:
                if t3 == t1:
                    continue
                rest = [c for c in tappable if c not in (t1, t3)]
                for t2, t4 in (rest, rest[::-1]):
                    marks = set()
                    ok = True
                    for i, tap in enumerate((t1, t2, t3, t4)):
                        marks.add(tap)
                        fired = forced_reveal(owner, solution_kinds_map, revealed, marks)
                        if i < 3:
                            if fired is not None:
                                ok = False
                                break
                        else:
                            if fired is not None and fired not in revealed:
                                return (t1, t2, t3, t4), fired
                            ok = False
                    if not ok:
                        continue
    return None, None


def generate_level(level, attempts=4000):
    rng = random.Random(9100 + level * 77)
    # Zone size caps: early levels get tight zones (easier reads), later
    # levels can sprawl a little for a softer clue.
    max_zone = 5 if level <= 5 else (6 if level <= 10 else 7)
    want_reveal = 1 if level <= 5 else 0

    best = None
    for attempt in range(attempts):
        cols = gen_solution(rng)
        kind_of = KINDS[:]
        rng.shuffle(kind_of)
        kinds = solution_kinds(cols, kind_of)
        seeds = sorted(kinds)  # reading order → zone A..E
        owner = gen_zones(rng, seeds, max_zone)
        if owner is None:
            continue

        if want_reveal:
            lb_cells = [c for c, k in kinds.items() if k == "L"]
            reveal_options = [[lb_cells[0]]] if level == 1 else [[c] for c in kinds]
        else:
            reveal_options = [[], *[[c] for c in kinds]]

        for revealed in reveal_options:
            sols = consistent_solutions(owner, revealed, set())
            if len(sols) != 1:
                continue
            # No reveal may be available before the player touches anything.
            if forced_reveal(owner, kinds, revealed, set()) is not None:
                continue
            record = {
                "cols": cols, "kinds": kinds, "owner": owner,
                "revealed": set(revealed), "solutions": len(sols),
                "safe": len(safe_cells(owner, revealed)),
            }
            if level == 1:
                tutorial, final = find_tutorial(owner, kinds, set(revealed))
                if tutorial is None:
                    continue
                record["tutorial"] = tutorial
                record["tutorial_reveal"] = final
            if best is None:
                best = record
            elif want_reveal == 0:
                if not record["revealed"] and (best["revealed"] or record["safe"] < best["safe"]):
                    # Harder start = fewer cells already ruled out by pure logic.
                    best = record
        if best is not None:
            if want_reveal:
                break
            if not best["revealed"] and attempt >= attempts // 4:
                break
    return best


def fmt_solution(kinds):
    grid = [["."] * N for _ in range(N)]
    for (r, c), k in kinds.items():
        grid[r][c] = k
    return ["".join(row) for row in grid]


def fmt_zones(owner):
    grid = [[""] * N for _ in range(N)]
    for (r, c), z in owner.items():
        grid[r][c] = chr(ord("A") + z)
    return ["".join(row) for row in grid]


def patch_swift(records):
    text = SRC.read_text()

    def block_span(source, start):
        depth = 0
        for i in range(start, len(source)):
            if source[i] == "(":
                depth += 1
            elif source[i] == ")":
                depth -= 1
                if depth == 0:
                    return start, i + 1
        raise ValueError("unbalanced")

    for record in sorted(records, key=lambda r: r["level"]):
        m = re.search(r"makePuzzle\s*\(\s*\n\s*level:\s*" + str(record["level"]) + r"\b", text)
        if not m:
            raise SystemExit(f"makePuzzle for level {record['level']} not found")
        start, end = block_span(text, m.start())
        block = text[start:end]

        new_block = re.sub(
            r"solution:\s*\[.*?\],\s*startRevealed:\s*\[[^\]]*\],",
            "solution: [\n"
            + "".join(f'                "{row}",\n' for row in fmt_solution(record["kinds"]))
            + "            ],\n"
            + "            zones: [\n"
            + "".join(f'                "{row}",\n' for row in fmt_zones(record["owner"]))
            + "            ],\n"
            + "            startRevealed: ["
            + ", ".join(f"({r}, {c})" for r, c in sorted(record["revealed"]))
            + "],",
            block,
            count=1,
            flags=re.DOTALL,
        )
        if new_block == block:
            raise SystemExit(f"failed to patch level {record['level']}")
        text = text[:start] + new_block + text[end:]

    SRC.write_text(text)


def main():
    records = []
    print(f"{'Level':>5} | {'Reveals':>7} | {'Solutions':>9} | {'Zone sizes':>11} | Safe start")
    print("-" * 60)
    for level in range(1, 16):
        rec = generate_level(level)
        if rec is None:
            print(f"L{level:2d} | FAILED")
            sys.exit(1)
        rec["level"] = level
        records.append(rec)
        sizes = sorted(Counter(rec["owner"].values()).values())
        print(
            f"L{level:2d} | {len(rec['revealed']):>7} | {rec['solutions']:>9} | "
            f"{str(sizes):>11} | {rec['safe']}"
        )
        if level == 1:
            t = rec["tutorial"]
            print(f"     tutorial taps: {t} -> reveal {rec['tutorial_reveal']}")

    patch_swift(records)
    print(f"\nPatched {SRC.name} — formations, routes and level names untouched.")


if __name__ == "__main__":
    main()
