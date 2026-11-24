"""Build the Isaac-style room(s) from ASCII blockouts in _tools/rooms/room_N.txt.
(Adapted from the sword game's build_chambers.py: same ts_ground art pass, same props and decor.)

    python3 _tools/build_room.py        (save + close GameMaker first, Reload after)

Each map cell is 32x32 px:
    #  void (invisible wall; the island's edge and any holes)
    .  floor
    B  cover block (solid, drawn as a gray box)
    L  landmark (solid, tall blue box: statues, shrines...)
    S  enemy spawn point (floor)
    E  entrance: player starts at the centre of the E cells
    X  exit door: solid until every wave in the room is cleared
Lines starting with "# " (hash + space) are comments.
Writes rooms/rm_chamber_N, the blockout objects if missing, and the room order (chambers first).

Art pass (Cursed Land pack): the map becomes ts_ground tile layers (floor, cliff faces under the island
edges, spiky back edges, cobble daises), B/L cells get props on the "Props" layer (obj_game turns them
into solid, depth-sorted obj_prop), small plants/bones go on the flat "Decor" layer, and dark trees
frame the bottom and sides in the void. The invisible obj_wall / obj_block collision is unchanged.
Previews: _tools/preview/chamber_N_art.png
"""
import os, re, json, uuid, glob

TOOLS = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(TOOLS)
CELL = 32
CLIFF_H = 20
VIEW = (640, 352)          # camera size = the whole room (20x9 cells + 2 void rows); scaled 2x into 1280x704
VOID_COLOUR = 0xFF140F0C   # ABGR: rgb(12, 15, 20)


def load_yy(p):
    return json.loads(re.sub(r",(\s*[}\]])", r"\1", open(p).read()))


def dump_yy(o, p):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(json.dumps(o, indent=2))


def uid():
    return uuid.uuid4().hex[:8].upper()


def rects(cells):
    """Greedy merge of a set of (col,row) cells into rectangles (c, r, w, h)."""
    cells, out = set(cells), []
    todo = sorted(cells, key=lambda c: (c[1], c[0]))
    used = set()
    for c, r in todo:
        if (c, r) in used:
            continue
        w = 1
        while (c + w, r) in cells and (c + w, r) not in used:
            w += 1
        h = 1
        while all((c + i, r + h) in cells and (c + i, r + h) not in used for i in range(w)):
            h += 1
        for i in range(w):
            for j in range(h):
                used.add((c + i, r + j))
        out.append((c, r, w, h))
    return out


def inst(obj, x, y, sx=1.0, sy=1.0):
    n = "inst_" + uid()
    return {"$GMRInstance": "v4", "%Name": n, "colour": 4294967295, "frozen": False, "hasCreationCode": False,
            "ignore": False, "imageIndex": 0, "imageSpeed": 1.0, "inheritCode": False, "inheritedItemId": None,
            "inheritItemSettings": False, "isDnd": False, "name": n,   # room instances: isDnd (lowercase d)
            "objectId": {"name": obj, "path": f"objects/{obj}/{obj}.yy"}, "properties": [],
            "resourceType": "GMRInstance", "resourceVersion": "2.0", "rotation": 0.0,
            "scaleX": float(sx), "scaleY": float(sy), "x": float(x), "y": float(y)}


def rect_inst(obj, c, r, w, h, y_off=0, px_h=None):
    """spr_wall is 64x64 with a Top Left origin, so scale it to cover the cells."""
    hh = px_h if px_h is not None else h * CELL
    return inst(obj, c * CELL, r * CELL + y_off, w * CELL / 64, hh / 64)



def layer_common(kind, name, depth):
    return {f"$GMR{kind}Layer": "", "%Name": name, "depth": depth, "effectEnabled": True, "effectType": None,
            "gridX": 16, "gridY": 16, "hierarchyFrozen": False, "inheritLayerDepth": False,
            "inheritLayerSettings": False, "inheritSubLayers": True, "inheritVisibility": True, "layers": [],
            "name": name, "properties": [], "resourceType": f"GMR{kind}Layer", "resourceVersion": "2.0",
            "userdefinedDepth": False, "visible": True}


def rle(cells):
    out, i = [], 0
    while i < len(cells):
        j = i
        while j < len(cells) and cells[j] == cells[i]:
            j += 1
        if j - i >= 2:
            out += [-(j - i), cells[i]]
            i = j
        else:
            lit = []
            while i < len(cells) and (i + 1 >= len(cells) or cells[i + 1] != cells[i]):
                lit.append(cells[i])
                i += 1
            out += [len(lit)] + lit
    return out


def tile_layer(name, depth, grid, ts="ts_cursed"):
    L = layer_common("Tile", name, depth)
    L["tiles"] = {"SerialiseHeight": len(grid), "SerialiseWidth": len(grid[0]),
                  "TileCompressedData": rle([c for row in grid for c in row]), "TileDataFormat": 1}
    L["tilesetId"] = {"name": ts, "path": f"tilesets/{ts}/{ts}.yy"}
    L["x"] = L["y"] = 0
    return L


def asset_layer(name, depth, items):
    L = layer_common("Asset", name, depth)
    L["assets"] = []
    for spr, x, y, sx, col in sorted(items, key=lambda it: it[2]):
        g = "graphic_" + uid()
        L["assets"].append({"$GMRSpriteGraphic": "v1", "%Name": g, "animationSpeed": 1.0, "colour": col,
                            "frozen": False, "headPosition": 0.0, "ignore": False, "inheritedItemId": None,
                            "inheritItemSettings": False, "name": g, "resourceType": "GMRSpriteGraphic",
                            "resourceVersion": "2.0", "rotation": 0.0, "scaleX": float(sx), "scaleY": 1.0,
                            "spriteId": {"name": spr, "path": f"sprites/{spr}/{spr}.yy"},
                            "x": float(x), "y": float(y)})
    return L



import random
from PIL import Image, ImageDraw
EMPTY = -2147483648
COLS = 45
T = lambda c, r: r * COLS + c
SPR = {}
for p in glob.glob(os.path.join(PROJ, "sprites", "spr_*", "spr_*.yy")):
    s = load_yy(p); SPR[s["name"]] = s
def ok(n): return n in SPR

def sheet(n): return Image.open(os.path.join(PROJ, "sprites", n, SPR[n]["frames"][0]["name"] + ".png")).convert("RGBA")
def solid_tiles(img, cols, minfill):
    out = []
    for i in range(cols * (img.height // 16)):
        t = img.crop(((i % cols) * 16, (i // cols) * 16, (i % cols) * 16 + 16, (i // cols) * 16 + 16))
        a = t.split()[3]; n = sum(1 for v in a.getdata() if v > 40)
        if n >= minfill: out.append(i)
    return out
IMG = {n: sheet("spr_" + n) for n in ("ts_cursed", "ts_spots", "ts_details")}
COLS_OF = {n: IMG[n].width // 16 for n in IMG}
SPOT_T = solid_tiles(IMG["ts_spots"], COLS_OF["ts_spots"], 30)
DET_T = solid_tiles(IMG["ts_details"], COLS_OF["ts_details"], 40)

def first(*names):
    for n in names:
        if ok(n): return n
PROP64 = [n for n in ("spr_rock1_2", "spr_rock1_3", "spr_rock_eyes_2", "spr_ruins_4", "spr_ruins_5", "spr_rock3_4", "spr_rock3_5") if ok(n)]
PROP32 = [n for n in ("spr_rock1_4", "spr_rock1_5", "spr_rock_eyes_3", "spr_pustules_2") if ok(n)]
LM_FIRE = first("spr_meat_flower_2", "spr_meat_flower_3")
LM_WATER = first("spr_tentacle_plant_3", "spr_tentacle_plant_2")
DECOR = [n for n in ("spr_bones_7", "spr_pustules_3", "spr_eye_plant_3", "spr_tubular_plant_3", "spr_fetus_3", "spr_bones_2") if ok(n)]
FLANK = first("spr_many_eyes_plant_2", "spr_many_eyes_plant_3")

_frames = {}
def frame0(name):
    if name not in _frames:
        _frames[name] = sheet(name)
    return _frames[name]

def preview(path, W, H, layers, decor, props, player):
    im = Image.new("RGBA", (W, H), (12, 15, 20, 255))
    for ts, grid in layers:
        cols = COLS_OF[ts]
        for r, row in enumerate(grid):
            for c, t in enumerate(row):
                if t != EMPTY:
                    tc, tr = t % cols, t // cols
                    im.alpha_composite(IMG[ts].crop((tc * 16, tr * 16, tc * 16 + 16, tr * 16 + 16)), (c * 16, r * 16))
    def put(spr, x, y, sx, col):
        f = frame0(spr)
        if sx < 0: f = f.transpose(Image.FLIP_LEFT_RIGHT)
        s = SPR[spr]
        xo = s["sequence"]["xorigin"] if sx > 0 else s["width"] - s["sequence"]["xorigin"]
        ox, oy = int(x - xo), int(y - s["sequence"]["yorigin"])
        if ox < W and oy < H and ox + f.width > 0 and oy + f.height > 0:
            im.alpha_composite(f, (max(0, ox), max(0, oy)), (max(0, -ox), max(0, -oy)))
    for d in decor: put(*d)
    dr = ImageDraw.Draw(im)
    things = [(p[2], p) for p in props] + [(player[1], None)]
    for _, p in sorted(things, key=lambda t: t[0]):
        if p is None: dr.ellipse([player[0] - 6, player[1] - 14, player[0] + 6, player[1] + 10], fill=(220, 60, 50))
        else: put(*p)
    im.convert("RGB").save(path)

# ------------------------------------------------------------------ objects
yyp_path = os.path.join(PROJ, "limbgame.yyp")
yyp = load_yy(yyp_path)
res = {r["id"]["name"] for r in yyp["resources"]}
EV = {"create": (0, 0), "step": (0, 3), "draw": (0, 8), "gui": (64, 8)}
OBJECTS = {}
_UNUSED = {
    "obj_floor": (None, True, ["create", "draw"]),
    "obj_cliff": (None, True, ["create", "draw"]),
    "obj_block": ("obj_wall", True, ["create", "draw"]),
    "obj_landmark": ("obj_block", True, ["create"]),
    "obj_door": ("obj_wall", True, ["create", "step", "draw"]),
}
for name, (parent, visible, events) in OBJECTS.items():
    if name in res:
        continue
    o = load_yy(os.path.join(PROJ, "objects", "obj_game", "obj_game.yy"))
    o["%Name"] = o["name"] = name
    o["spriteId"] = {"name": "spr_wall", "path": "sprites/spr_wall/spr_wall.yy"}
    o["parentObjectId"] = {"name": parent, "path": f"objects/{parent}/{parent}.yy"} if parent else None
    o["visible"] = visible
    o["eventList"] = [{"$GMEvent": "v1", "%Name": "", "collisionObjectId": None, "eventNum": EV[e][0],
                       "eventType": EV[e][1], "isDnD": False, "name": "", "resourceType": "GMEvent",
                       "resourceVersion": "2.0"} for e in events]
    dump_yy(o, os.path.join(PROJ, "objects", name, name + ".yy"))
    yyp["resources"].append({"id": {"name": name, "path": f"objects/{name}/{name}.yy"}})


# ------------------------------------------------------------------ rooms
template = load_yy(os.path.join(TOOLS, "rm_level_template.yy"))
chamber_rooms = []
maps = [(p, int(re.search(r"(\d+)", os.path.basename(p)).group(1))) for p in glob.glob(os.path.join(TOOLS, "rooms", "room_*.txt"))]
maps = [(p, n, f"rm_room_{n}") for p, n in sorted(maps, key=lambda m: m[1])]
for path, n, rname in maps:
    lines = [l.rstrip("\n") for l in open(path) if not l.startswith("# ")]
    lines = [l for l in lines if l.strip()]
    W = max(len(l) for l in lines)
    g = [l.ljust(W, "#") for l in lines] + ["#" * W] * 2
    H = len(g)
    at = lambda c, r: g[r][c] if 0 <= r < H and 0 <= c < W else "#"
    cells = lambda ch: [(c, r) for r in range(H) for c in range(W) if g[r][c] in ch]
    bad = set("".join(g)) - set("#.BLSEX")
    assert not bad, f"{rname}: unknown characters {bad}"
    E = cells("E"); assert E, "no entrance"
    seen, todo = {E[0]}, [E[0]]
    while todo:
        c, r = todo.pop()
        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (c + d[0], r + d[1])
            if q not in seen and at(*q) in ".SEX":
                seen.add(q); todo.append(q)
    for need in cells("SX"): assert need in seen, f"unreachable {need}"
    ex = sum(c for c, _ in E) / len(E) * CELL + CELL / 2
    ey = sum(r for _, r in E) / len(E) * CELL + CELL / 2
    random.seed(n * 101)
    insts = [inst("obj_game", 16, 16), inst("obj_player", ex, ey)]
    insts += [rect_inst("obj_wall", *rc) for rc in rects(cells("#"))]
    insts += [rect_inst("obj_block", *rc) for rc in rects(cells("B"))]
    insts += [rect_inst("obj_landmark", *rc) for rc in rects(cells("L"))]
    insts += [rect_inst("obj_door", *rc) for rc in rects(cells("X"))]
    insts += [inst("obj_spawn", c * CELL + CELL / 2, r * CELL + CELL / 2) for c, r in cells("S")]

    # ---- tiles (16px): the non-# area must be one rectangle -> a Cursed Land plateau floating in the void
    TW, TH = W * 2, H * 2
    fl = [(c, r) for r in range(TH) for c in range(TW) if at(c // 2, r // 2) != "#"]
    c0, c1 = min(c for c, _ in fl), max(c for c, _ in fl)
    r0, r1 = min(r for _, r in fl), max(r for _, r in fl)
    assert len(fl) == (c1 - c0 + 1) * (r1 - r0 + 1), "floor must be a rectangle"
    grid = lambda: [[EMPTY] * TW for _ in range(TH)]
    ground, cliffs, spots, details = grid(), grid(), grid(), grid()
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            first_row = r == r0
            if c == c0: t = T(2, 1 if first_row else 2)
            elif c == c1: t = T(5, 1 if first_row else 2)
            elif first_row: t = T(3 + (c % 2), 1)
            else: t = T(3, 2)
            ground[r][c] = t
    for c in range(c0, c1 + 1):                      # rim above the first floor row
        ground[r0 - 1][c] = T(2, 0) if c == c0 else T(5, 0) if c == c1 else T(3 + (c % 2), 0)
    for k in range(5):                               # cliff face under the front edge
        r = r1 + 1 + k
        for c in range(c0, c1 + 1):
            cliffs[r][c] = T(2, 3 + k) if c == c0 else T(5, 3 + k) if c == c1 else T(3 + (c % 2), 3 + k)
        cliffs[r][c0 - 1] = T(1, 3 + k); cliffs[r][c1 + 1] = T(6, 3 + k)
    # decals on the floor, away from spawns / door / entrance
    clear = set()
    for c, r in cells("SXE"):
        for dc in range(-2, 3):
            for dr in range(-2, 3): clear.add((c + dc, r + dr))
    fcells = [(c // 2, r // 2) for r in range(r0 + 1, r1) for c in range(c0 + 1, c1) if (c // 2, r // 2) not in clear and at(c // 2, r // 2) == "."]
    tiles_free = [(c, r) for r in range(r0 + 1, r1) for c in range(c0 + 1, c1) if (c // 2, r // 2) not in clear and at(c // 2, r // 2) in ".S"]
    for c, r in random.sample(tiles_free, min(40, len(tiles_free))):
        if SPOT_T: spots[r][c] = random.choice(SPOT_T)
    for c, r in random.sample(tiles_free, min(24, len(tiles_free))):
        if DET_T and spots[r][c] == EMPTY: details[r][c] = random.choice(DET_T)

    WHITE = 4294967295
    props, decor = [], []
    def P(name, x, y, flip=1, col=WHITE):
        if name: props.append((name, x, y, flip, col))
    used = set()
    for cc0, rr0, w, h in rects(cells("B")):
        cl = {(cc0 + i, rr0 + j) for i in range(w) for j in range(h)}
        for j in range(0, h - 1, 2):
            for i in range(0, w - 1, 2):
                c, r = cc0 + i, rr0 + j
                P(random.choice(PROP64), (c + 1) * CELL, (r + 2) * CELL - 4, random.choice([1, -1]))
                cl -= {(c, r), (c + 1, r), (c, r + 1), (c + 1, r + 1)}
        for c, r in sorted(cl, key=lambda q: q[1]):
            P(random.choice(PROP32), c * CELL + 16, (r + 1) * CELL - 2, random.choice([1, -1]))
        used |= {(cc0 + i, rr0 + j) for i in range(w) for j in range(h)}
    for cc0, rr0, w, h in rects(cells("L")):
        left = cc0 < W / 2
        P(LM_FIRE if left else LM_WATER, (cc0 + w / 2) * CELL, (rr0 + h) * CELL - 2, 1 if left else -1)
        used |= {(cc0 + i, rr0 + j) for i in range(w) for j in range(h)}
    doors = []
    for cc0, rr0, w, h in rects(cells("X")):
        x1, y2 = cc0 * CELL, (rr0 + h) * CELL
        doors.append((x1, rr0 * CELL, (cc0 + w) * CELL, y2))
        P(FLANK, x1 - 18, y2 + 6, 1); P(FLANK, (cc0 + w) * CELL + 18, y2 + 6, -1)
    for c, r in random.sample(fcells, min(14, len(fcells))):
        if (c, r) in used: continue
        decor.append((random.choice(DECOR), c * CELL + random.randint(8, 24), r * CELL + random.randint(16, 30), random.choice([1, -1]), WHITE))
    # door sprite is drawn by obj_door itself (it opens); preview it here
    door_spr = first("spr_rock3_1")
    for x1, y1, x2, y2 in doors:
        props.append((door_spr, (x1 + x2) / 2, y2 + 16, 1, WHITE))
    decor = [d for d in decor if d[0]]
    props = [p for p in props if p[0]]
    game_props = [p for p in props if p[0] != door_spr]

    room = json.loads(json.dumps(template))
    room["%Name"] = room["name"] = rname
    il = next(L for L in room["layers"] if L["resourceType"] == "GMRInstanceLayer")
    bg = next(L for L in room["layers"] if L["resourceType"] == "GMRBackgroundLayer")
    il["instances"], il["depth"] = insts, 0
    bg["colour"], bg["depth"], bg["spriteId"] = VOID_COLOUR, 1000, None
    room["layers"] = [il,
                      asset_layer("Props", 100, game_props),          # converted to obj_prop at room start
                      asset_layer("Decor", 600, decor),
                      tile_layer("Details", 770, details, "ts_details"),
                      tile_layer("Spots", 780, spots, "ts_spots"),
                      tile_layer("Cliffs", 790, cliffs),
                      tile_layer("Ground", 800, ground),
                      bg]
    room["instanceCreationOrder"] = [{"name": i["name"], "path": f"rooms/{rname}/{rname}.yy"} for i in insts]
    preview(os.path.join(TOOLS, "preview", rname.replace("rm_", "") + "_art.png"), W * CELL, H * CELL,
            [("ts_cursed", cliffs), ("ts_cursed", ground), ("ts_spots", spots), ("ts_details", details)], decor, props, (ex, ey))
    room["roomSettings"]["Width"], room["roomSettings"]["Height"] = W * CELL, H * CELL
    v = room["views"][0]
    v["wview"], v["hview"], v["wport"], v["hport"] = VIEW[0], VIEW[1], 1280, 704
    dump_yy(room, os.path.join(PROJ, "rooms", rname, rname + ".yy"))
    if rname not in res:
        yyp["resources"].append({"id": {"name": rname, "path": f"rooms/{rname}/{rname}.yy"}})
    chamber_rooms.append(rname)
    print(f"{rname}: {W*CELL}x{H*CELL}px, {len(insts)} instances, {len(game_props)} props, {len(decor)} decor, "
          f"{len(cells('S'))} spawns, {len(rects(cells('X')))} doors")

# chambers first in the room order (the game starts in rm_chamber_1), everything else after
others = [n for n in yyp["RoomOrderNodes"] if n["roomId"]["name"] not in chamber_rooms]
yyp["RoomOrderNodes"] = [{"roomId": {"name": r, "path": f"rooms/{r}/{r}.yy"}} for r in chamber_rooms] + others
yyp["resources"].sort(key=lambda r: r["id"]["path"])
dump_yy(yyp, yyp_path)
print("room order:", [n["roomId"]["name"] for n in yyp["RoomOrderNodes"]])
