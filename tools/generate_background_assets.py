from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "backgrounds"

BACKDROP_LOW = (256, 90)
TILE_LOW = (64, 64)
DECAL_LOW = (128, 128)
FEATURE_LOW = (128, 96)


MAPS = [
    {
        "slug": "grassland",
        "label": "Grassland",
        "seed": 1001,
        "sky_top": (20, 35, 31),
        "sky_mid": (34, 58, 45),
        "sky_bottom": (58, 72, 44),
        "far": (32, 50, 31, 235),
        "mid": (22, 39, 29, 230),
        "accent": (112, 148, 83, 120),
        "glow": (170, 177, 97, 45),
        "ground": (24, 34, 24),
        "ground_dark": (18, 26, 20),
        "ground_light": (43, 59, 38),
        "line": (72, 97, 58, 100),
        "hot": (166, 185, 97, 125),
    },
    {
        "slug": "crystal_cave",
        "label": "Crystal Cave",
        "seed": 2002,
        "sky_top": (9, 15, 28),
        "sky_mid": (16, 31, 48),
        "sky_bottom": (27, 47, 68),
        "far": (15, 25, 45, 238),
        "mid": (20, 38, 58, 232),
        "accent": (89, 150, 185, 120),
        "glow": (94, 167, 210, 45),
        "ground": (13, 24, 39),
        "ground_dark": (9, 17, 30),
        "ground_light": (29, 52, 73),
        "line": (77, 113, 143, 105),
        "hot": (142, 219, 235, 150),
    },
    {
        "slug": "lava_ridge",
        "label": "Lava Ridge",
        "seed": 3003,
        "sky_top": (28, 13, 11),
        "sky_mid": (53, 20, 14),
        "sky_bottom": (82, 32, 20),
        "far": (47, 18, 15, 240),
        "mid": (25, 12, 11, 235),
        "accent": (184, 79, 30, 120),
        "glow": (216, 83, 29, 46),
        "ground": (42, 19, 15),
        "ground_dark": (25, 13, 12),
        "ground_light": (71, 32, 22),
        "line": (137, 54, 24, 110),
        "hot": (240, 108, 38, 145),
    },
    {
        "slug": "abyss_nursery",
        "label": "Abyss Nursery",
        "seed": 4004,
        "sky_top": (13, 10, 23),
        "sky_mid": (25, 16, 37),
        "sky_bottom": (43, 22, 56),
        "far": (28, 18, 42, 238),
        "mid": (38, 23, 50, 232),
        "accent": (148, 90, 172, 120),
        "glow": (164, 102, 196, 44),
        "ground": (31, 19, 39),
        "ground_dark": (20, 13, 28),
        "ground_light": (56, 34, 66),
        "line": (101, 56, 123, 108),
        "hot": (196, 129, 216, 135),
    },
]


def clamp(value: int) -> int:
    return max(0, min(255, value))


def mix(a: tuple[int, ...], b: tuple[int, ...], t: float) -> tuple[int, int, int, int]:
    aa = a[3] if len(a) > 3 else 255
    bb = b[3] if len(b) > 3 else 255
    return (
        clamp(round(a[0] + (b[0] - a[0]) * t)),
        clamp(round(a[1] + (b[1] - a[1]) * t)),
        clamp(round(a[2] + (b[2] - a[2]) * t)),
        clamp(round(aa + (bb - aa) * t)),
    )


def shade(c: tuple[int, ...], amount: int, alpha: int | None = None) -> tuple[int, int, int, int]:
    return (
        clamp(c[0] + amount),
        clamp(c[1] + amount),
        clamp(c[2] + amount),
        alpha if alpha is not None else (c[3] if len(c) > 3 else 255),
    )


def rgb(c: tuple[int, ...], alpha: int = 255) -> tuple[int, int, int, int]:
    return c[0], c[1], c[2], alpha if len(c) == 3 else c[3]


def polygon_wave(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    base_y: float,
    amp: float,
    step: int,
    color: tuple[int, int, int, int],
    phase: float,
    jagged: bool = False,
) -> None:
    pts = [(0, h)]
    x = -step
    while x <= w + step:
        wave = math.sin(x * 0.046 + phase) * amp + math.cos(x * 0.021 + phase * 1.7) * amp * 0.42
        if jagged:
            spike = math.sin(x * 0.13 + phase * 0.5) * amp * 0.48
            y = base_y + wave - abs(spike)
        else:
            y = base_y + wave
        pts.append((round(x), round(y)))
        x += step
    pts.append((w, h))
    draw.polygon(pts, fill=color)


def draw_gradient(img: Image.Image, top: tuple[int, int, int], mid: tuple[int, int, int], bottom: tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(img)
    w, h = img.size
    for y in range(h):
        t = y / max(1, h - 1)
        if t < 0.58:
            color = mix((*top, 255), (*mid, 255), t / 0.58)
        else:
            color = mix((*mid, 255), (*bottom, 255), (t - 0.58) / 0.42)
        draw.line((0, y, w, y), fill=color)


def add_pixel_dither(img: Image.Image, seed: int, strength: int = 5, alpha: int = 18) -> None:
    rnd = random.Random(seed)
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    w, h = img.size
    for _ in range(round(w * h * 0.055)):
        x = rnd.randrange(w)
        y = rnd.randrange(h)
        delta = rnd.randint(-strength, strength)
        if delta >= 0:
            draw.point((x, y), fill=(255, 255, 255, alpha))
        else:
            draw.point((x, y), fill=(0, 0, 0, alpha))
    img.alpha_composite(overlay)


def vignette(img: Image.Image, alpha: int = 58) -> None:
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    w, h = img.size
    for i in range(10):
        a = round(alpha * (1 - i / 10))
        draw.rectangle((0, i, w, i), fill=(0, 0, 0, a))
        draw.rectangle((0, h - 1 - i, w, h - 1 - i), fill=(0, 0, 0, a))
    for i in range(14):
        a = round(alpha * 0.75 * (1 - i / 14))
        draw.rectangle((i, 0, i, h), fill=(0, 0, 0, a))
        draw.rectangle((w - 1 - i, 0, w - 1 - i, h), fill=(0, 0, 0, a))
    img.alpha_composite(overlay)


def save_pixel_art(img: Image.Image, path: Path, scale: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = img.resize((img.width * scale, img.height * scale), Image.Resampling.NEAREST)
    out.save(path)


def force_opaque(img: Image.Image) -> Image.Image:
    out = img.convert("RGBA")
    out.putalpha(255)
    return out


def draw_crystal(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, color: tuple[int, int, int, int], dark: tuple[int, int, int, int]) -> None:
    pts = [(x, y - size), (x + size // 2, y), (x, y + size // 3), (x - size // 2, y)]
    draw.polygon(pts, fill=color)
    draw.polygon([(x, y - size), (x + size // 2, y), (x, y + size // 3)], fill=shade(color, 18, color[3]))
    draw.line((x, y - size + 1, x, y + size // 3), fill=dark, width=1)


def draw_egg(draw: ImageDraw.ImageDraw, x: int, y: int, rx: int, ry: int, fill: tuple[int, int, int, int], line: tuple[int, int, int, int]) -> None:
    draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=fill, outline=line)
    draw.arc((x - rx + 2, y - ry + 4, x + rx - 2, y + ry - 2), 200, 320, fill=shade(line, 22, line[3]), width=1)


def backdrop_far(spec: dict) -> Image.Image:
    w, h = BACKDROP_LOW
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw_gradient(img, spec["sky_top"], spec["sky_mid"], spec["sky_bottom"])
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    slug = spec["slug"]
    rnd = random.Random(spec["seed"])

    draw.ellipse((w * 0.32, h * 0.31, w * 0.68, h * 0.64), fill=spec["glow"])

    if slug == "grassland":
        draw.ellipse((w * 0.47, h * 0.22, w * 0.6, h * 0.45), fill=(230, 215, 130, 30))
        polygon_wave(draw, w, h, h * 0.61, 6, 10, spec["far"], 0.3)
        polygon_wave(draw, w, h, h * 0.72, 8, 9, shade(spec["far"], -14, 248), 1.8)
        for x in range(-10, w + 10, 24):
            y = h * 0.68 + math.sin(x * 0.09) * 3
            draw.rectangle((x + 8, y - 11, x + 10, y), fill=shade(spec["far"], -10, 210))
            draw.ellipse((x + 1, y - 19, x + 17, y - 7), fill=shade(spec["far"], 3, 210))
    elif slug == "crystal_cave":
        draw.ellipse((w * 0.34, h * 0.44, w * 0.66, h * 0.61), fill=spec["glow"])
        polygon_wave(draw, w, h, h * 0.7, 9, 8, shade(spec["far"], -4, 248), 2.2, jagged=True)
        for x in range(-8, w + 16, 22):
            size = rnd.randint(11, 22)
            draw.polygon([(x, 0), (x + 5, size), (x + 10, 0)], fill=shade(spec["far"], -9, 235))
            draw_crystal(draw, x + 12, round(h * 0.63), rnd.randint(10, 22), shade(spec["accent"], -28, 140), shade(spec["far"], 8, 160))
    elif slug == "lava_ridge":
        draw.ellipse((w * 0.53, h * 0.26, w * 0.67, h * 0.44), fill=(255, 132, 50, 26))
        polygon_wave(draw, w, h, h * 0.68, 18, 8, spec["far"], 1.0, jagged=True)
        polygon_wave(draw, w, h, h * 0.78, 21, 7, shade(spec["far"], -20, 252), 2.5, jagged=True)
        for x in range(10, w, 34):
            y = h * 0.66 + math.sin(x * 0.06) * 9
            draw.line((x, y, x + 16, h), fill=shade(spec["accent"], 8, 58), width=1)
    else:
        draw.ellipse((w * 0.34, h * 0.4, w * 0.66, h * 0.65), fill=spec["glow"])
        polygon_wave(draw, w, h, h * 0.67, 8, 8, spec["far"], 1.6)
        for x in range(-14, w + 28, 22):
            y = h * 0.66 + math.sin(x * 0.08) * 3
            draw.ellipse((x, y - 17, x + 24, y + 13), fill=shade(spec["far"], 2, 218))
            draw.arc((x - 6, y - 22, x + 32, y + 16), 205, 330, fill=shade(spec["accent"], -22, 70), width=1)

    img.alpha_composite(overlay)
    add_pixel_dither(img, spec["seed"] + 41)
    vignette(img, 42)
    return img


def backdrop_mid(spec: dict) -> Image.Image:
    w, h = BACKDROP_LOW
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    slug = spec["slug"]
    rnd = random.Random(spec["seed"] + 7)
    base = h * 0.68

    if slug == "grassland":
        polygon_wave(draw, w, h, base + 7, 7, 8, spec["mid"], 1.1)
        for x in range(-8, w + 18, 18):
            top = base - rnd.randint(11, 25)
            draw.rectangle((x + 8, top + 12, x + 10, base + 9), fill=shade(spec["mid"], -12, 222))
            draw.ellipse((x, top, x + 18, top + 18), fill=shade(spec["mid"], 2, 222))
        for x in range(5, w, 17):
            y = base + rnd.randint(1, 13)
            draw.line((x, y, x - 3, y - rnd.randint(5, 11)), fill=shade(spec["line"], 2, 130))
            draw.line((x, y, x + 3, y - rnd.randint(5, 11)), fill=shade(spec["line"], 2, 130))
    elif slug == "crystal_cave":
        polygon_wave(draw, w, h, base + 10, 7, 8, spec["mid"], 2.0, jagged=True)
        for x in range(-10, w + 10, 18):
            size = rnd.randint(16, 37)
            draw.polygon([(x, base + 14), (x + 6, base - size), (x + 13, base + 14)], fill=spec["mid"])
            if x % 36 == 0:
                draw.line((x + 6, base - size + 3, x + 6, base + 8), fill=shade(spec["accent"], 18, 72), width=1)
        for x in range(12, w, 42):
            draw_crystal(draw, x, round(base - 2), rnd.randint(9, 18), shade(spec["accent"], -15, 86), shade(spec["mid"], 22, 90))
    elif slug == "lava_ridge":
        polygon_wave(draw, w, h, base + 10, 17, 7, spec["mid"], 1.4, jagged=True)
        for x in range(-14, w + 24, 24):
            y = base + rnd.randint(-4, 11)
            draw.polygon([(x, h), (x + 5, y - rnd.randint(23, 45)), (x + 20, h)], fill=shade(spec["mid"], -8, 238))
            if rnd.random() < 0.45:
                draw.line((x + 7, y, x + 15, h), fill=shade(spec["hot"], -5, 76), width=1)
    else:
        polygon_wave(draw, w, h, base + 12, 9, 9, spec["mid"], 2.7)
        for x in range(-8, w + 16, 18):
            y = base + rnd.randint(-5, 10)
            draw.arc((x - 8, y - 27, x + 24, y + 15), 200, 350, fill=shade(spec["mid"], 10, 210), width=3)
            if rnd.random() < 0.55:
                draw_egg(draw, x + 7, y + 2, 5, 8, shade(spec["accent"], -34, 105), shade(spec["line"], 10, 90))

    add_pixel_dither(img, spec["seed"] + 77, strength=4, alpha=12)
    return img


def tileable_base(spec: dict) -> Image.Image:
    w, h = TILE_LOW
    img = Image.new("RGBA", (w, h), (*spec["ground"], 255))
    draw = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(spec["seed"] + 17)
    slug = spec["slug"]

    for y in range(h):
        for x in range(w):
            wave = (
                math.sin((x / w) * math.tau * 2.0 + 0.7)
                + math.cos((y / h) * math.tau * 2.0 + 1.9)
                + math.sin(((x + y) / w) * math.tau * 1.0 + 2.6) * 0.7
            )
            amount = round(wave * 4)
            color = shade(spec["ground"], amount, 255)
            draw.point((x, y), fill=color)

    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")

    for _ in range(120):
        x = rnd.randrange(w)
        y = rnd.randrange(h)
        color = shade(spec["ground_light"] if rnd.random() < 0.45 else spec["ground_dark"], rnd.randint(-4, 5), rnd.randint(46, 90))
        draw_wrapped_ellipse(draw, w, h, x, y, rnd.randint(1, 3), rnd.randint(1, 2), color)

    if slug == "grassland":
        for _ in range(42):
            x = rnd.randrange(w)
            y = rnd.randrange(h)
            draw_wrapped_line(draw, w, h, (x, y, x + rnd.choice([-2, 0, 2]), y - rnd.randint(3, 7)), spec["line"], 1)
    elif slug == "crystal_cave":
        for _ in range(34):
            x = rnd.randrange(w)
            y = rnd.randrange(h)
            draw_wrapped_polygon(draw, w, h, [(x, y - 4), (x + 3, y), (x, y + 3), (x - 3, y)], shade(spec["accent"], -24, 78))
    elif slug == "lava_ridge":
        for _ in range(22):
            x = rnd.randrange(w)
            y = rnd.randrange(h)
            draw_wrapped_line(draw, w, h, (x, y, x + rnd.randint(4, 10), y + rnd.randint(-3, 6)), shade(spec["hot"], -18, 76), 1)
            draw_wrapped_line(draw, w, h, (x + 1, y + 1, x + rnd.randint(3, 8), y + rnd.randint(-2, 5)), spec["ground_dark"], 1)
    else:
        for _ in range(30):
            x = rnd.randrange(w)
            y = rnd.randrange(h)
            draw_wrapped_arc(draw, w, h, (x - 5, y - 4, x + 9, y + 8), 190, 335, shade(spec["line"], 4, 82), 1)

    img.alpha_composite(overlay)
    return img


def draw_wrapped_ellipse(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    x: int,
    y: int,
    rx: int,
    ry: int,
    fill: tuple[int, int, int, int],
) -> None:
    for ox in (-w, 0, w):
        for oy in (-h, 0, h):
            if -rx <= x + ox <= w + rx and -ry <= y + oy <= h + ry:
                draw.ellipse((x + ox - rx, y + oy - ry, x + ox + rx, y + oy + ry), fill=fill)


def draw_wrapped_line(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    line: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    x1, y1, x2, y2 = line
    for ox in (-w, 0, w):
        for oy in (-h, 0, h):
            draw.line((x1 + ox, y1 + oy, x2 + ox, y2 + oy), fill=fill, width=width)


def draw_wrapped_polygon(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    pts: list[tuple[int, int]],
    fill: tuple[int, int, int, int],
) -> None:
    for ox in (-w, 0, w):
        for oy in (-h, 0, h):
            shifted = [(x + ox, y + oy) for x, y in pts]
            draw.polygon(shifted, fill=fill)


def draw_wrapped_arc(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    box: tuple[int, int, int, int],
    start: int,
    end: int,
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    x1, y1, x2, y2 = box
    for ox in (-w, 0, w):
        for oy in (-h, 0, h):
            draw.arc((x1 + ox, y1 + oy, x2 + ox, y2 + oy), start, end, fill=fill, width=width)


def decals(spec: dict) -> Image.Image:
    w, h = DECAL_LOW
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    slug = spec["slug"]
    cells = [(16, 18), (48, 18), (82, 18), (112, 20), (20, 58), (52, 60), (86, 61), (112, 60), (22, 102), (55, 102), (88, 102), (114, 101)]
    rnd = random.Random(spec["seed"] + 27)

    for i, (x, y) in enumerate(cells):
        if slug == "grassland":
            if i % 3 == 0:
                for blade in range(5):
                    bx = x + blade * 2 - 5
                    draw.line((bx, y + 8, bx + rnd.choice([-3, -1, 2, 3]), y - rnd.randint(4, 12)), fill=shade(spec["line"], 18, 185), width=1)
            elif i % 3 == 1:
                draw.ellipse((x - 10, y + 2, x + 10, y + 9), fill=shade(spec["ground_light"], 0, 145))
                draw.ellipse((x - 5, y - 2, x + 5, y + 7), fill=shade(spec["accent"], -20, 150))
            else:
                draw.ellipse((x - 8, y + 2, x + 6, y + 8), fill=shade(spec["ground_dark"], 20, 190))
                draw.ellipse((x + 4, y + 5, x + 12, y + 10), fill=shade(spec["ground_light"], 4, 170))
        elif slug == "crystal_cave":
            if i % 3 == 0:
                draw_crystal(draw, x, y + 6, rnd.randint(8, 15), shade(spec["accent"], -5, 170), shade(spec["mid"], 15, 160))
            elif i % 3 == 1:
                draw.polygon([(x - 11, y + 6), (x - 1, y), (x + 11, y + 8), (x + 2, y + 11)], fill=shade(spec["ground_light"], 5, 160))
                draw.line((x - 7, y + 6, x + 7, y + 8), fill=shade(spec["line"], 18, 130), width=1)
            else:
                draw.polygon([(x, y - 9), (x + 7, y), (x, y + 7), (x - 7, y)], fill=shade(spec["hot"], -10, 120))
                draw.polygon([(x + 2, y - 4), (x + 4, y), (x + 2, y + 3), (x, y)], fill=shade(spec["hot"], 22, 110))
        elif slug == "lava_ridge":
            if i % 3 == 0:
                draw.polygon([(x - 12, y + 9), (x - 4, y - 1), (x + 8, y + 2), (x + 13, y + 10)], fill=shade(spec["ground_dark"], 10, 200))
                draw.line((x - 4, y + 2, x + 8, y + 8), fill=shade(spec["hot"], 8, 135), width=1)
            elif i % 3 == 1:
                draw.line((x - 7, y + 8, x - 1, y + 1, x + 6, y + 7), fill=shade(spec["hot"], 8, 160), width=1)
                draw.point((x + 8, y + 1), fill=shade(spec["hot"], 25, 150))
            else:
                draw.ellipse((x - 9, y + 3, x + 7, y + 10), fill=shade(spec["ground_light"], -8, 150))
                draw.rectangle((x - 2, y - 2, x + 1, y + 5), fill=shade(spec["accent"], -14, 105))
        else:
            if i % 3 == 0:
                draw_egg(draw, x, y + 2, rnd.randint(5, 7), rnd.randint(8, 11), shade(spec["accent"], -30, 130), shade(spec["line"], 10, 115))
            elif i % 3 == 1:
                draw.arc((x - 12, y - 8, x + 14, y + 14), 200, 340, fill=shade(spec["line"], 6, 170), width=2)
                draw.arc((x - 8, y - 2, x + 10, y + 15), 200, 340, fill=shade(spec["mid"], 15, 150), width=1)
            else:
                draw.ellipse((x - 9, y + 3, x + 8, y + 9), fill=shade(spec["ground_light"], 0, 140))
                draw.line((x - 6, y + 6, x + 8, y + 5), fill=shade(spec["hot"], -10, 100), width=1)

    return img


def feature(spec: dict) -> Image.Image:
    w, h = FEATURE_LOW
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    slug = spec["slug"]
    shadow = (0, 0, 0, 55)
    draw.ellipse((22, 78, 106, 91), fill=shadow)

    if slug == "grassland":
        stone = shade(spec["ground_light"], -8, 230)
        dark = shade(spec["ground_dark"], 8, 235)
        draw.polygon([(31, 77), (43, 23), (54, 77)], fill=dark)
        draw.polygon([(75, 77), (88, 20), (99, 77)], fill=dark)
        draw.polygon([(41, 28), (52, 18), (86, 20), (94, 31), (88, 39), (50, 38)], fill=stone)
        draw.polygon([(47, 38), (88, 39), (84, 47), (50, 47)], fill=shade(stone, -12, 230))
        for x, y in [(43, 43), (84, 44), (61, 29), (72, 34)]:
            draw.ellipse((x - 3, y - 2, x + 5, y + 2), fill=shade(spec["accent"], -8, 128))
        for x in range(37, 96, 8):
            draw.line((x, 76, x - 3, 66), fill=shade(spec["line"], 26, 170), width=1)
            draw.line((x, 76, x + 4, 64), fill=shade(spec["line"], 18, 160), width=1)
    elif slug == "crystal_cave":
        base = shade(spec["ground_dark"], 8, 230)
        draw.polygon([(31, 82), (50, 55), (82, 56), (101, 82)], fill=base)
        for x, y, size in [(55, 72, 44), (76, 73, 35), (41, 76, 27), (91, 78, 24)]:
            draw_crystal(draw, x, y, size, shade(spec["accent"], -2, 205), shade(spec["mid"], 25, 185))
        draw.polygon([(54, 28), (65, 72), (55, 87), (45, 72)], fill=shade(spec["accent"], -32, 165))
        draw.line((55, 31, 56, 82), fill=shade(spec["hot"], 14, 130), width=1)
    elif slug == "lava_ridge":
        basalt = shade(spec["ground_dark"], 4, 240)
        draw.polygon([(18, 82), (35, 55), (44, 22), (55, 84)], fill=basalt)
        draw.polygon([(51, 84), (65, 36), (80, 18), (93, 84)], fill=shade(basalt, 8, 240))
        draw.polygon([(84, 84), (99, 48), (111, 83)], fill=basalt)
        draw.polygon([(34, 62), (58, 70), (83, 58), (101, 70), (111, 84), (24, 84)], fill=shade(spec["ground_light"], -10, 220))
        for pts in [
            [(63, 40), (66, 55), (61, 69), (67, 82)],
            [(42, 57), (51, 63), (47, 76)],
            [(86, 58), (80, 67), (90, 82)],
        ]:
            draw.line([tuple(p) for p in pts], fill=shade(spec["hot"], 18, 150), width=2)
            draw.line([tuple(p) for p in pts], fill=shade(spec["hot"], 36, 95), width=1)
    else:
        nest = shade(spec["ground_light"], -2, 215)
        root = shade(spec["mid"], 0, 225)
        for box, start, end, width in [
            ((20, 30, 108, 95), 190, 350, 6),
            ((15, 20, 83, 91), 205, 345, 5),
            ((46, 18, 116, 88), 195, 335, 5),
        ]:
            draw.arc(box, start, end, fill=root, width=width)
        draw.ellipse((33, 63, 95, 88), fill=nest)
        draw.arc((33, 61, 95, 88), 180, 355, fill=shade(spec["line"], 4, 190), width=2)
        draw_egg(draw, 58, 61, 14, 22, shade(spec["accent"], -34, 190), shade(spec["line"], 10, 150))
        draw_egg(draw, 77, 66, 11, 18, shade(spec["accent"], -22, 170), shade(spec["line"], 10, 135))
        draw_egg(draw, 43, 69, 9, 14, shade(spec["accent"], -28, 160), shade(spec["line"], 10, 125))

    return img


def write_assets() -> list[Path]:
    written: list[Path] = []
    for spec in MAPS:
        base = OUT / spec["slug"]
        assets = [
            ("backdrop_far.png", force_opaque(backdrop_far(spec)), 4),
            ("backdrop_mid.png", backdrop_mid(spec), 4),
            ("field_base_tile.png", force_opaque(tileable_base(spec)), 2),
            ("field_decal_set.png", decals(spec), 2),
            ("field_feature_01.png", feature(spec), 4),
        ]
        for name, img, scale in assets:
            path = base / name
            save_pixel_art(img, path, scale)
            written.append(path)
    return written


def composite_for_preview(path: Path, size: tuple[int, int]) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    scale = min(size[0] / img.width, size[1] / img.height)
    resized = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.Resampling.NEAREST)
    bg = Image.new("RGBA", size, (19, 22, 24, 255))
    draw = ImageDraw.Draw(bg)
    for y in range(0, size[1], 12):
        for x in range(0, size[0], 12):
            if (x // 12 + y // 12) % 2 == 0:
                draw.rectangle((x, y, x + 11, y + 11), fill=(27, 31, 33, 255))
    bg.alpha_composite(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return bg


def make_contact_sheet(paths: list[Path]) -> Path:
    cell_w, cell_h = 238, 150
    label_h = 25
    margin = 14
    names = ["backdrop_far", "backdrop_mid", "field_base_tile", "field_decal_set", "field_feature_01"]
    sheet = Image.new("RGBA", (margin * 2 + cell_w * 5, margin * 2 + (cell_h + label_h) * 4), (11, 14, 16, 255))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    by_slug = {spec["slug"]: spec for spec in MAPS}
    for row, spec in enumerate(MAPS):
        for col, name in enumerate(names):
            path = OUT / spec["slug"] / f"{name}.png"
            x = margin + col * cell_w
            y = margin + row * (cell_h + label_h)
            preview = composite_for_preview(path, (cell_w - 10, cell_h - 30))
            sheet.alpha_composite(preview, (x + 5, y + 21))
            draw.text((x + 6, y + 3), f"{by_slug[spec['slug']]['label']} / {name}", fill=(205, 212, 204, 255), font=font)
    path = OUT / "contact_sheet.png"
    sheet.save(path)
    return path


def main() -> None:
    written = write_assets()
    preview = make_contact_sheet(written)
    print(f"Wrote {len(written)} assets")
    for path in written:
        print(path.relative_to(ROOT))
    print(preview.relative_to(ROOT))


if __name__ == "__main__":
    main()
