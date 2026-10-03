#!/usr/bin/env python3
"""Generate Ash March, the second campaign pack (stages 21-40).

Maps are carved as wall/floor grids. Waves stay in the same economy band as
stage 20: player power is already flat, so pressure comes from lane count,
path length, and enemy mix. Loadout size stays at 6 until the last six stages,
which try 7 and then 8.
"""

import base64
import json
import struct
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ALPH = "abcdefghijklmnopqrstuvwxyz012345"

SPAWNER_NAMES = {"S": "Spawner", "T": "Spawner2", "U": "Spawner3", "V": "Spawner4"}
EXIT_NAMES = {"E": "Exit", "F": "Exit2"}

# Per-lane recipes: (enemy, count, interval, delay). Counts are for one lane
# at pressure 1.0 and are scaled down as more lanes are open.
KINDS = {
    "grind": [("grunt", 16, 1.0, 0.4), ("heavy", 6, 1.45, 1.4), ("light", 8, 0.75, 0.6)],
    "rush": [("speeder", 12, 0.38, 0.25), ("light", 14, 0.5, 0.2), ("bomber", 7, 0.42, 1.0)],
    "armor": [("heavy", 8, 1.15, 0.4), ("tank", 3, 1.9, 1.8), ("grunt", 10, 0.85, 0.35)],
    "snipe": [("sniper", 5, 1.55, 0.5), ("heavy", 6, 1.25, 0.4), ("booster", 2, 2.1, 1.6), ("grunt", 8, 0.9, 0.3)],
    "spectral": [("ghost", 6, 1.05, 0.45), ("light_ghost", 6, 0.65, 0.7), ("grunt", 10, 0.95, 0.3)],
    "escort": [("tank", 3, 1.7, 0.5), ("healer", 3, 1.55, 1.1), ("heavy", 6, 1.15, 0.35), ("grunt", 8, 0.85, 0.3)],
    "split": [("splitter", 5, 1.15, 0.8), ("light", 12, 0.55, 0.25), ("speeder", 6, 0.4, 0.7)],
    "wraith": [("heavy_ghost", 2, 1.9, 1.4), ("ghost", 5, 1.0, 0.4), ("light_ghost", 6, 0.6, 0.5), ("grunt", 8, 0.9, 0.3)],
    "boss": [("citadel", 1, 3.5, 2.2), ("heavy", 6, 1.15, 0.35), ("healer", 2, 1.7, 1.3), ("grunt", 10, 0.8, 0.25)],
    "finale": [("grunt", 14, 0.65, 0.25), ("speeder", 8, 0.32, 0.5), ("heavy", 6, 1.05, 0.8), ("tank", 2, 1.9, 1.8), ("splitter", 3, 1.15, 1.2), ("light_ghost", 4, 0.65, 0.6)],
}

SEQUENCES = {
    "dual": ["grind", "armor", "rush", "grind", "snipe", "split", "armor", "finale"],
    "snipe": ["grind", "snipe", "armor", "escort", "snipe", "split", "snipe", "finale"],
    "rush": ["rush", "grind", "split", "rush", "armor", "rush", "split", "finale"],
    "throat": ["grind", "split", "rush", "armor", "split", "escort", "rush", "finale"],
    "pincer": ["armor", "grind", "rush", "escort", "armor", "split", "snipe", "finale"],
    "flank": ["grind", "armor", "rush", "grind", "split", "rush", "armor", "finale"],
    "spectral": ["grind", "spectral", "armor", "wraith", "spectral", "escort", "wraith", "finale"],
    "escort": ["grind", "escort", "armor", "snipe", "escort", "boss", "armor", "finale"],
    "ring": ["spectral", "grind", "wraith", "rush", "spectral", "split", "wraith", "finale"],
    "boss": ["armor", "escort", "grind", "boss", "rush", "escort", "boss", "finale"],
    "finale": ["grind", "rush", "armor", "spectral", "escort", "split", "boss", "wraith", "snipe", "rush", "armor", "finale"],
}


class Grid:
    def __init__(self, w: int, h: int):
        self.w = w
        self.h = h
        self.g = [["#" for _ in range(w)] for _ in range(h)]

    def fill(self, x: int, y: int, w: int, h: int, ch: str = ".") -> None:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = ch

    def set(self, x: int, y: int, ch: str) -> None:
        self.g[y][x] = ch

    def rows(self) -> list[str]:
        return ["".join(row) for row in self.g]


def carve_switchback(w: int, h: int) -> Grid:
    g = Grid(w, h)
    bands = [(1, 3), (6, 8), (11, 13), (16, h - 2)]
    for y0, y1 in bands:
        g.fill(1, y0, w - 2, y1 - y0 + 1, ".")
    g.fill(1, 4, 3, 2, ".")
    g.fill(w - 4, 9, 3, 2, ".")
    g.fill(1, 14, 3, 2, ".")
    g.set(2, 2, "S")
    g.set(w - 3, 7, "T")
    g.set(w // 2, h - 3, "E")
    return g


def carve_spiral(n: int = 19) -> Grid:
    g = Grid(n, n)
    # 2-tile rings, opening on the south side of each ring into the next.
    rings = [(1, n - 2), (4, n - 5), (7, n - 8)]
    for x0, x1 in rings:
        g.fill(x0, x0, x1 - x0 + 1, 2, ".")
        g.fill(x0, x1 - 1, x1 - x0 + 1, 2, ".")
        g.fill(x0, x0, 2, x1 - x0 + 1, ".")
        g.fill(x1 - 1, x0, 2, x1 - x0 + 1, ".")
    # Doorways inward, staggered so the path is a spiral rather than a shortcut.
    g.fill(n // 2 - 1, n - 4, 2, 3, ".")  # outer south into middle
    g.fill(4, n // 2 - 1, 3, 2, ".")  # middle west into inner
    g.fill(7, 8, 2, 3, ".")  # inner into the core
    g.fill(8, 8, 3, 3, ".")
    g.set(2, 2, "S")
    g.set(n - 3, n - 4, "T")
    g.set(n // 2, n // 2, "E")
    return g


def build_maps() -> list[dict]:
    stages = []

    g = Grid(17, 22)
    g.fill(1, 1, 7, 16, ".")
    g.fill(9, 1, 7, 16, ".")
    g.fill(1, 16, 15, 4, ".")
    g.set(3, 2, "S")
    g.set(13, 2, "T")
    g.set(8, 19, "E")
    stages.append(dict(name="21 · Twin Gate", profile="dual", pressure=0.86, energy=1700, lives=30, slots=6, waves=8, palette=2, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = carve_switchback(17, 22)
    stages.append(dict(name="22 · Switchback", profile="snipe", pressure=0.88, energy=1700, lives=28, slots=6, waves=8, palette=3, grid=g, open={"S": 1, "T": 4}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 17)
    g.fill(1, 7, 15, 3, ".")
    g.fill(7, 1, 3, 15, ".")
    g.set(2, 8, "S")
    g.set(14, 8, "T")
    g.set(8, 2, "U")
    g.set(8, 14, "V")
    g.set(8, 8, "E")
    stages.append(dict(name="23 · Crossfire", profile="rush", pressure=0.9, energy=1650, lives=26, slots=6, waves=8, palette=0, grid=g, open={"S": 1, "T": 1, "U": 3, "V": 5}, routes={"S": "E", "T": "E", "U": "E", "V": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 15, 7, ".")
    g.fill(7, 8, 3, 6, ".")
    g.fill(1, 14, 15, 6, ".")
    g.set(3, 2, "S")
    g.set(13, 2, "T")
    g.set(8, 18, "E")
    stages.append(dict(name="24 · The Throat", profile="throat", pressure=0.92, energy=1750, lives=30, slots=6, waves=8, palette=4, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = Grid(19, 19)
    g.fill(1, 8, 17, 3, ".")
    g.fill(1, 1, 3, 10, ".")
    g.fill(15, 1, 3, 10, ".")
    g.fill(8, 11, 3, 6, ".")
    g.set(2, 2, "S")
    g.set(16, 2, "T")
    g.set(9, 16, "E")
    stages.append(dict(name="25 · Pincer", profile="pincer", pressure=0.94, energy=1680, lives=26, slots=6, waves=9, palette=1, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 5, 19, ".")
    g.fill(10, 1, 5, 14, ".")
    g.fill(1, 15, 15, 5, ".")
    g.set(3, 2, "S")
    g.set(12, 2, "T")
    g.set(8, 18, "E")
    stages.append(dict(name="26 · Late Flank", profile="flank", pressure=0.96, energy=1720, lives=28, slots=6, waves=9, palette=2, grid=g, open={"S": 1, "T": 5}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 6, 19, ".")
    g.fill(10, 1, 6, 19, ".")
    g.set(3, 2, "S")
    g.set(13, 2, "T")
    g.set(3, 18, "E")
    g.set(13, 18, "F")
    stages.append(dict(name="27 · Split Road", profile="spectral", pressure=0.98, energy=1700, lives=28, slots=6, waves=9, palette=1, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "F"}))

    g = Grid(17, 21)
    g.fill(1, 1, 15, 19, ".")
    for py in (4, 9, 14):
        for px in (4, 8, 12):
            g.fill(px, py, 2, 2, "#")
    g.set(2, 2, "S")
    g.set(14, 2, "T")
    g.set(8, 18, "E")
    stages.append(dict(name="28 · Pillars", profile="escort", pressure=1.0, energy=1750, lives=28, slots=6, waves=9, palette=4, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = carve_spiral(19)
    stages.append(dict(name="29 · Spiral", profile="snipe", pressure=1.0, energy=1650, lives=26, slots=6, waves=10, palette=3, grid=g, open={"S": 1, "T": 6}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 3, 16, ".")
    g.fill(7, 1, 3, 16, ".")
    g.fill(13, 1, 3, 16, ".")
    g.fill(1, 16, 15, 4, ".")
    g.set(2, 2, "S")
    g.set(8, 2, "T")
    g.set(14, 2, "U")
    g.set(8, 18, "E")
    stages.append(dict(name="30 · Three Fronts", profile="rush", pressure=1.02, energy=1740, lives=28, slots=6, waves=10, palette=0, grid=g, open={"S": 1, "T": 1, "U": 4}, routes={"S": "E", "T": "E", "U": "E"}))

    g = Grid(15, 22)
    g.fill(5, 1, 5, 20, ".")
    for i, y in enumerate(range(3, 19, 3)):
        if i % 2 == 0:
            g.fill(2, y, 3, 2, ".")
        else:
            g.fill(10, y, 3, 2, ".")
    g.set(7, 2, "S")
    g.set(7, 19, "E")
    stages.append(dict(name="31 · Alcoves", profile="snipe", pressure=1.04, energy=1680, lives=26, slots=6, waves=10, palette=2, grid=g, open={"S": 1}, routes={"S": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 15, 5, ".")
    g.fill(7, 6, 3, 4, ".")
    g.fill(1, 10, 15, 4, ".")
    g.fill(7, 14, 3, 3, ".")
    g.fill(1, 17, 15, 3, ".")
    g.set(3, 2, "S")
    g.set(13, 2, "T")
    g.set(8, 18, "E")
    stages.append(dict(name="32 · Hourglass", profile="throat", pressure=1.05, energy=1720, lives=26, slots=6, waves=10, palette=4, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 4, 20, ".")
    g.fill(11, 1, 5, 6, ".")
    g.fill(4, 6, 12, 3, ".")
    g.fill(1, 16, 15, 4, ".")
    g.set(2, 2, "S")
    g.set(13, 3, "T")
    g.set(8, 18, "E")
    stages.append(dict(name="33 · Short Cut", profile="flank", pressure=1.08, energy=1600, lives=24, slots=6, waves=10, palette=0, grid=g, open={"S": 1, "T": 4}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 21)
    g.fill(1, 1, 15, 19, ".")
    # Diamond of walls, open cross through the middle so four approaches remain.
    for y in range(4, 16):
        for x in range(4, 13):
            if abs(x - 8) + abs(y - 10) > 6 and abs(x - 8) > 1 and abs(y - 10) > 1:
                g.set(x, y, "#")
    g.set(2, 2, "S")
    g.set(14, 2, "T")
    g.set(2, 18, "U")
    g.set(14, 18, "V")
    g.set(8, 10, "E")
    stages.append(dict(name="34 · Diamond", profile="escort", pressure=1.08, energy=1760, lives=28, slots=6, waves=10, palette=3, grid=g, open={"S": 1, "T": 1, "U": 5, "V": 5}, routes={"S": "E", "T": "E", "U": "E", "V": "E"}))

    g = Grid(19, 19)
    g.fill(1, 1, 17, 3, ".")
    g.fill(1, 15, 17, 3, ".")
    g.fill(1, 1, 3, 17, ".")
    g.fill(15, 1, 3, 17, ".")
    g.fill(7, 12, 5, 4, ".")
    g.fill(8, 9, 3, 4, ".")
    g.set(3, 2, "S")
    g.set(15, 2, "T")
    g.set(3, 16, "U")
    g.set(9, 10, "E")
    stages.append(dict(name="35 · Ring", profile="ring", pressure=1.1, energy=1740, lives=28, slots=7, waves=10, palette=1, grid=g, open={"S": 1, "T": 1, "U": 6}, routes={"S": "E", "T": "E", "U": "E"}))

    g = Grid(17, 22)
    g.fill(4, 1, 9, 20, ".")
    for y, side in ((4, 0), (8, 1), (12, 0), (16, 1)):
        if side == 0:
            g.fill(4, y, 5, 2, "#")
        else:
            g.fill(8, y, 5, 2, "#")
    g.set(8, 2, "S")
    g.set(11, 2, "T")
    g.set(8, 19, "E")
    stages.append(dict(name="36 · Baffles", profile="pincer", pressure=1.12, energy=1700, lives=26, slots=7, waves=10, palette=2, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = Grid(15, 15)
    g.fill(1, 1, 13, 13, ".")
    g.fill(6, 3, 3, 8, "#")
    g.set(2, 2, "S")
    g.set(12, 2, "T")
    g.set(7, 12, "E")
    stages.append(dict(name="37 · Short Fuse", profile="rush", pressure=1.16, energy=1550, lives=22, slots=7, waves=8, palette=0, grid=g, open={"S": 1, "T": 1}, routes={"S": "E", "T": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 15, 20, ".")
    g.fill(3, 5, 11, 2, "#")
    g.fill(7, 5, 3, 2, ".")
    g.fill(3, 12, 11, 2, "#")
    g.fill(3, 12, 3, 2, ".")
    g.fill(11, 12, 3, 2, ".")
    g.set(2, 2, "S")
    g.set(14, 2, "T")
    g.set(8, 8, "U")
    g.set(8, 18, "E")
    stages.append(dict(name="38 · Plaza", profile="boss", pressure=1.14, energy=1800, lives=30, slots=7, waves=11, palette=4, grid=g, open={"S": 1, "T": 1, "U": 6}, routes={"S": "E", "T": "E", "U": "E"}))

    g = Grid(17, 22)
    g.fill(1, 1, 4, 20, ".")
    g.fill(1, 8, 8, 3, ".")
    g.fill(8, 1, 3, 10, ".")
    g.fill(11, 4, 5, 3, ".")
    g.fill(13, 4, 3, 16, ".")
    g.fill(1, 17, 15, 3, ".")
    g.set(2, 2, "S")
    g.set(14, 6, "T")
    g.set(8, 18, "E")
    stages.append(dict(name="39 · Uneven", profile="spectral", pressure=1.16, energy=1680, lives=24, slots=8, waves=11, palette=3, grid=g, open={"S": 1, "T": 4}, routes={"S": "E", "T": "E"}))

    g = Grid(19, 22)
    g.fill(1, 1, 7, 9, ".")
    g.fill(11, 1, 7, 9, ".")
    g.fill(1, 12, 7, 8, ".")
    g.fill(11, 12, 7, 8, ".")
    g.fill(7, 4, 5, 3, ".")
    g.fill(7, 14, 5, 3, ".")
    g.set(2, 2, "S")
    g.set(16, 2, "T")
    g.set(2, 18, "U")
    g.set(16, 18, "V")
    g.set(9, 5, "E")
    g.set(9, 15, "F")
    stages.append(dict(name="40 · Last Light", profile="finale", pressure=1.2, energy=1850, lives=30, slots=8, waves=12, palette=1, grid=g, open={"S": 1, "T": 1, "U": 5, "V": 7}, routes={"S": "E", "T": "E", "U": "F", "V": "F"}))

    return stages


def neighbors(x: int, y: int, w: int, h: int):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            yield nx, ny


def walkable(ch: str) -> bool:
    return ch != "#" and ch != " "


def find_char(rows: list[str], ch: str) -> tuple[int, int]:
    for y, row in enumerate(rows):
        x = row.find(ch)
        if x != -1:
            return x, y
    raise ValueError(f"missing {ch}")


def shortest(rows: list[str], start: tuple[int, int], goal: tuple[int, int]) -> int:
    from collections import deque

    w, h = len(rows[0]), len(rows)
    q = deque([(start, 0)])
    seen = {start}
    while q:
        (x, y), dist = q.popleft()
        if (x, y) == goal:
            return dist
        for nx, ny in neighbors(x, y, w, h):
            if (nx, ny) in seen or not walkable(rows[ny][nx]):
                continue
            seen.add((nx, ny))
            q.append(((nx, ny), dist + 1))
    return -1


def validate(stage: dict) -> None:
    rows = stage["grid"].rows()
    w = len(rows[0])
    assert all(len(r) == w for r in rows), stage["name"]
    assert all(r[0] == "#" and r[-1] == "#" for r in rows), stage["name"]
    assert set(rows[0]) == {"#"} and set(rows[-1]) == {"#"}, stage["name"]
    for letter, exit_letter in stage["routes"].items():
        dist = shortest(rows, find_char(rows, letter), find_char(rows, exit_letter))
        if dist < 6:
            raise SystemExit(f"{stage['name']}: {letter}->{exit_letter} path {dist}\n" + "\n".join(rows))
    # Every spawner/exit sits on a cell with a walkable neighbor.
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in SPAWNER_NAMES or ch in EXIT_NAMES:
                if not any(walkable(rows[ny][nx]) for nx, ny in neighbors(x, y, w, len(rows))):
                    raise SystemExit(f"{stage['name']}: {ch} is sealed")


def sequence_for(profile: str, count: int) -> list[str]:
    base = SEQUENCES[profile]
    if count <= len(base):
        return base[: count - 1] + [base[-1]]
    filler = ["grind", "armor", "rush", "spectral", "escort", "split", "snipe", "wraith"]
    extra = count - len(base)
    return base[:-1] + [filler[i % len(filler)] for i in range(extra)] + [base[-1]]


def lane_factor(kind: str, lanes: int) -> float:
    if kind == "finale":
        return {1: 1.0, 2: 0.82, 3: 0.68, 4: 0.58}[lanes]
    if kind == "boss":
        return {1: 1.0, 2: 0.8, 3: 0.66, 4: 0.55}[lanes]
    return {1: 1.0, 2: 0.7, 3: 0.55, 4: 0.46}[lanes]


def build_waves(stage: dict) -> list[dict]:
    seq = sequence_for(stage["profile"], stage["waves"])
    letters = [ch for ch in ("S", "T", "U", "V") if ch in stage["open"]]
    waves = []
    for index, kind in enumerate(seq):
        wave_num = index + 1
        open_letters = [ch for ch in letters if stage["open"][ch] <= wave_num]
        factor = lane_factor(kind, len(open_letters))
        growth = 1.0 + index * 0.045
        groups = []
        for lane_i, letter in enumerate(open_letters):
            spawner = SPAWNER_NAMES[letter]
            for enemy, count, interval, delay in KINDS[kind]:
                use_letters = open_letters
                if enemy == "citadel":
                    use_letters = open_letters[: 1 if stage["pressure"] < 1.1 else 2]
                elif enemy == "heavy_ghost":
                    use_letters = open_letters[:2]
                elif enemy in ("healer", "booster") and kind != "escort":
                    use_letters = open_letters[:2]
                if letter not in use_letters:
                    continue
                scaled = int(round(count * stage["pressure"] * factor * growth))
                if enemy == "citadel":
                    scaled = 1
                elif enemy == "heavy_ghost":
                    scaled = max(1, min(3, scaled))
                elif enemy in ("healer", "booster"):
                    scaled = max(1, min(4, scaled))
                else:
                    scaled = max(2, scaled)
                groups.append({
                    "count": scaled,
                    "delay": round(delay + lane_i * 0.35, 2),
                    "enemy_type": enemy,
                    "interval": round(max(0.28, interval * (1.0 - index * 0.02)), 2),
                    "spawner_id": spawner,
                })
        reward = 0 if wave_num == stage["waves"] else int(250 + index * 14 + stage["pressure"] * 30)
        waves.append({"wave_number": wave_num, "reward_energy": reward, "spawns": groups})
    return waves


def encode_tiles(rows: list[str], palette: int) -> str:
    body = struct.pack("<H", 0)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            atlas_x = 0 if walkable(ch) else 1
            body += struct.pack("<hhHHHH", x, y, 0, atlas_x, palette, 0)
    return base64.b64encode(body).decode("ascii")


def make_uid(n: int) -> str:
    chars = []
    for _ in range(13):
        chars.append(ALPH[n % 32])
        n //= 32
    return "uid://" + "".join(reversed(chars))


def cell_center(x: int, y: int) -> tuple[float, float]:
    return ((x + 0.5) * 64.0, (y + 0.5) * 64.0)


def write_scene(stage_num: int, stage: dict, scene_uid: str) -> None:
    rows = stage["grid"].rows()
    tile_data = encode_tiles(rows, stage["palette"])
    exits = []
    spawners = []
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in EXIT_NAMES:
                exits.append((EXIT_NAMES[ch], x, y))
            elif ch in SPAWNER_NAMES:
                spawners.append((ch, x, y))
    exits.sort()
    spawners.sort(key=lambda item: "STUV".index(item[0]))

    lines = [
        f'[gd_scene format=4 uid="{scene_uid}"]',
        "",
        '[ext_resource type="Script" uid="uid://djqjbhfaeaqt2" path="res://src/scenes/stages/Stage.gd" id="1_stage"]',
        '[ext_resource type="PackedScene" uid="uid://c3o5j8cdgdxmc" path="res://src/scenes/tiles/tiles.tscn" id="2_tiles"]',
        '[ext_resource type="PackedScene" uid="uid://xyww0xmxe1ss" path="res://src/scenes/utility/exit.tscn" id="3_exit"]',
        '[ext_resource type="PackedScene" uid="uid://cq3ofdmp8sxea" path="res://src/scenes/utility/spawner.tscn" id="4_spawner"]',
        "",
        f'[node name="Stage{stage_num}" type="Node2D" unique_id={800000000 + stage_num}]',
        'script = ExtResource("1_stage")',
        "",
        f'[node name="NavigationRegion2D" type="NavigationRegion2D" parent="." unique_id={810000000 + stage_num}]',
        "",
        f'[node name="Tiles" parent="NavigationRegion2D" unique_id={820000000 + stage_num} instance=ExtResource("2_tiles")]',
        f'tile_map_data = PackedByteArray("{tile_data}")',
        "",
    ]
    for i, (name, x, y) in enumerate(exits):
        px, py = cell_center(x, y)
        lines += [
            f'[node name="{name}" parent="NavigationRegion2D" unique_id={830000000 + stage_num * 10 + i} instance=ExtResource("3_exit")]',
            f"position = Vector2({px}, {py})",
            "",
        ]
    for i, (letter, x, y) in enumerate(spawners):
        name = SPAWNER_NAMES[letter]
        exit_name = EXIT_NAMES[stage["routes"][letter]]
        px, py = cell_center(x, y)
        lines += [
            f'[node name="{name}" parent="NavigationRegion2D" unique_id={840000000 + stage_num * 10 + i} node_paths=PackedStringArray("exits") instance=ExtResource("4_spawner")]',
            f"position = Vector2({px}, {py})",
            f'exits = [NodePath("../{exit_name}")]',
            "",
        ]
    lines += [
        f'[node name="Towers" type="Node2D" parent="NavigationRegion2D" unique_id={850000000 + stage_num}]',
        "",
    ]
    path = ROOT / f"src/scenes/stages/Stage{stage_num}.tscn"
    path.write_text("\n".join(lines))


def write_preview(stage_num: int, stage: dict, icon_uid: str) -> None:
    rows = stage["grid"].rows()
    sheet = Image.open(ROOT / "src/textures/tiles/tiles.png").convert("RGBA")
    palette = stage["palette"]
    floor = sheet.crop((0, palette * 64, 64, palette * 64 + 64)).resize((16, 16), Image.Resampling.NEAREST)
    wall = sheet.crop((64, palette * 64, 128, palette * 64 + 64)).resize((16, 16), Image.Resampling.NEAREST)
    img = Image.new("RGBA", (len(rows[0]) * 16, len(rows) * 16))
    draw = ImageDraw.Draw(img)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            img.paste(floor if walkable(ch) else wall, (x * 16, y * 16))
            cx, cy = x * 16 + 8, y * 16 + 8
            if ch in SPAWNER_NAMES:
                draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(255, 150, 40, 255))
            elif ch in EXIT_NAMES:
                draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(80, 220, 255, 255))
    out = ROOT / f"src/textures/stages/Stage{stage_num}.png"
    img.save(out)
    (ROOT / f"src/textures/stages/Stage{stage_num}.png.uid").write_text(icon_uid + "\n")


def write_resource(stage_num: int, stage: dict, tres_uid: str, scene_uid: str, icon_uid: str) -> None:
    text = f'''[gd_resource type="Resource" script_class="StageData" format=3 uid="{tres_uid}"]

[ext_resource type="Texture2D" uid="{icon_uid}" path="res://src/textures/stages/Stage{stage_num}.png" id="1_icon"]
[ext_resource type="Script" uid="uid://xynccep1kdc5" path="res://src/data/stages/StageData.gd" id="2_script"]
[ext_resource type="PackedScene" uid="{scene_uid}" path="res://src/scenes/stages/Stage{stage_num}.tscn" id="3_scene"]

[resource]
script = ExtResource("2_script")
stage_id = "stage_{stage_num}"
stage_name = "{stage["name"]}"
scene = ExtResource("3_scene")
icon = ExtResource("1_icon")
pack_id = "ash_march"
pack_name = "Ash March"
pack_order = 1
starting_energy = {stage["energy"]}
starting_lives = {stage["lives"]}
loadout_size = {stage["slots"]}
wave_data_file = "res://src/data/stages/waves/Stage{stage_num}.json"
'''
    path = ROOT / f"src/data/stages/stage_{stage_num:02d}.tres"
    path.write_text(text)


def main() -> None:
    import sys
    if "--force" not in sys.argv:
        raise SystemExit(
            "Refusing to overwrite Ash March. Stages 28, 32, and 33 were edited by hand. "
            "Pass --force to regenerate every stage from this script."
        )
    stages = build_maps()
    assert len(stages) == 20
    for i, stage in enumerate(stages):
        validate(stage)
        stage_num = 21 + i
        waves = build_waves(stage)
        # Every referenced spawner must exist, and every map spawner is used.
        used = {g["spawner_id"] for w in waves for g in w["spawns"]}
        expected = {SPAWNER_NAMES[ch] for ch in stage["open"]}
        if used != expected:
            raise SystemExit(f"{stage['name']} spawner mismatch {used} vs {expected}")
        wave_path = ROOT / f"src/data/stages/waves/Stage{stage_num}.json"
        wave_path.write_text(json.dumps(waves, indent=2) + "\n")
        scene_uid = make_uid(900_000 + stage_num)
        tres_uid = make_uid(910_000 + stage_num)
        icon_uid = make_uid(920_000 + stage_num)
        write_scene(stage_num, stage, scene_uid)
        write_preview(stage_num, stage, icon_uid)
        write_resource(stage_num, stage, tres_uid, scene_uid, icon_uid)
        print(f"stage {stage_num} {stage['name']} waves={len(waves)} slots={stage['slots']} {stage['grid'].w}x{stage['grid'].h}")
        print("\n".join(stage["grid"].rows()))
        print()


if __name__ == "__main__":
    main()
