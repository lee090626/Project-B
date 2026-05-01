from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "ui" / "cards"
CARD_WIDTH = 272
CARD_HEIGHT = 360
GRID = 4

RARITY_PALETTES = {
    "common": {
        "fill": (0.08, 0.11, 0.11, 0.96),
        "inner": (0.12, 0.16, 0.16, 0.94),
        "line": (0.44, 0.84, 0.67, 0.96),
        "ribbon": (0.2, 0.45, 0.38, 0.96),
        "ribbon_dark": (0.12, 0.27, 0.23, 0.98),
        "sigil": (0.5, 0.95, 0.77, 0.7),
        "shadow": (0.02, 0.04, 0.04, 0.82),
        "spark": (0.76, 1.0, 0.84, 0.9),
    },
    "rare": {
        "fill": (0.07, 0.1, 0.12, 0.96),
        "inner": (0.11, 0.16, 0.18, 0.94),
        "line": (0.49, 0.86, 0.92, 0.96),
        "ribbon": (0.2, 0.41, 0.52, 0.96),
        "ribbon_dark": (0.1, 0.22, 0.31, 0.98),
        "sigil": (0.58, 0.93, 1.0, 0.72),
        "shadow": (0.02, 0.04, 0.06, 0.84),
        "spark": (0.79, 0.98, 1.0, 0.92),
    },
    "mythic": {
        "fill": (0.12, 0.08, 0.06, 0.97),
        "inner": (0.18, 0.12, 0.09, 0.95),
        "line": (0.96, 0.78, 0.43, 0.98),
        "ribbon": (0.64, 0.32, 0.12, 0.98),
        "ribbon_dark": (0.34, 0.14, 0.06, 0.99),
        "sigil": (1.0, 0.72, 0.32, 0.78),
        "shadow": (0.04, 0.02, 0.01, 0.86),
        "spark": (1.0, 0.91, 0.58, 0.94),
    },
}


def clamp(value):
    return max(0.0, min(1.0, value))


def mix(a, b, amount):
    return tuple(a[i] * (1 - amount) + b[i] * amount for i in range(4))


def shade(color, amount):
    target = (1, 1, 1, color[3]) if amount > 0 else (0, 0, 0, color[3])
    return mix(color, target, abs(amount))


def rgba(color, alpha_mul=1.0):
    r, g, b, a = color
    return (
        round(clamp(r) * 255),
        round(clamp(g) * 255),
        round(clamp(b) * 255),
        round(clamp(a * alpha_mul) * 255),
    )


def diamond(cx, cy, radius):
    return [(cx, cy - radius), (cx + radius, cy), (cx, cy + radius), (cx - radius, cy)]


def draw_stepped_rect(draw, box, top_color, bottom_color, step=GRID):
    x0, y0, x1, y1 = box
    height = max(1, y1 - y0)

    for y in range(y0, y1, step):
        t = (y - y0) / height
        color = mix(top_color, bottom_color, t)
        draw.rectangle((x0, y, x1, min(y + step - 1, y1)), fill=rgba(color))


def draw_pixel_texture(draw, palette, rarity):
    seed = {"common": 5, "rare": 11, "mythic": 17}[rarity]
    line = palette["line"]

    for y in range(54, CARD_HEIGHT - 54, GRID):
        for x in range(16, CARD_WIDTH - 16, GRID):
            value = (x * 7 + y * 13 + seed * 19) % 37
            if value in (0, 5):
                draw.rectangle((x, y, x + 1, y + 1), fill=rgba(line, 0.18))
            elif value == 19:
                draw.point((x + 2, y + 2), fill=rgba(palette["spark"], 0.18))


def draw_scale_pattern(draw, palette, rarity):
    line = palette["line"]
    offset = {"common": 0, "rare": 6, "mythic": 3}[rarity]

    for row, y in enumerate(range(68, CARD_HEIGHT - 56, 16)):
        shift = 8 if row % 2 == 0 else 0
        for x in range(28 + shift + offset, CARD_WIDTH - 26, 24):
            draw.arc((x - 8, y - 6, x + 8, y + 10), 200, 340, fill=rgba(line, 0.18), width=1)


def draw_corner_plate(draw, palette, x, y, flip_x, flip_y):
    line = palette["line"]
    spark = palette["spark"]
    sx = -1 if flip_x else 1
    sy = -1 if flip_y else 1
    pts = [
        (x, y),
        (x + sx * 18, y),
        (x + sx * 22, y + sy * 5),
        (x + sx * 5, y + sy * 22),
        (x, y + sy * 18),
    ]
    draw.polygon(pts, fill=rgba(palette["shadow"], 0.72), outline=rgba(line, 0.9))
    draw.line((x + sx * 5, y + sy * 6, x + sx * 14, y + sy * 6), fill=rgba(spark, 0.75), width=1)


def draw_center_sigil(draw, palette, rarity):
    cx = CARD_WIDTH // 2
    cy = CARD_HEIGHT // 2
    line = palette["sigil"]
    spark = palette["spark"]

    draw.ellipse((cx - 48, cy - 48, cx + 48, cy + 48), outline=rgba(line, 0.23), width=2)
    draw.ellipse((cx - 36, cy - 36, cx + 36, cy + 36), outline=rgba(line, 0.24), width=1)
    draw.polygon(diamond(cx, cy, 42), outline=rgba(line, 0.36))
    draw.polygon(diamond(cx, cy, 24), outline=rgba(line, 0.45))

    for dx in (-28, 28):
        draw.arc((cx + dx - 22, cy - 20, cx + dx + 22, cy + 20), 300 if dx < 0 else 120, 60 if dx < 0 else 240, fill=rgba(line, 0.5), width=2)
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=rgba(spark, 0.4))

    if rarity == "rare":
        for y in (104, 116, 148, 160):
            draw.line((cx - 34, y, cx - 22, y - 4, cx - 10, y), fill=rgba(spark, 0.32), width=1)
            draw.line((cx + 10, y, cx + 22, y - 4, cx + 34, y), fill=rgba(spark, 0.32), width=1)
    elif rarity == "mythic":
        for pts in (
            ((cx - 43, cy - 12), (cx - 26, cy - 16), (cx - 35, cy - 2)),
            ((cx + 43, cy - 12), (cx + 26, cy - 16), (cx + 35, cy - 2)),
            ((cx - 30, cy + 29), (cx - 16, cy + 20), (cx - 20, cy + 36)),
            ((cx + 30, cy + 29), (cx + 16, cy + 20), (cx + 20, cy + 36)),
        ):
            draw.line(pts, fill=rgba(spark, 0.4), width=1)


def draw_ribbon(draw, palette, box, radius):
    x0, y0, x1, y1 = box
    ribbon = palette["ribbon"]
    dark = palette["ribbon_dark"]
    line = palette["line"]

    draw.rounded_rectangle((x0 + 1, y0 + 2, x1 + 1, y1 + 2), radius=radius, fill=rgba(palette["shadow"], 0.45))
    draw.rounded_rectangle(box, radius=radius, fill=rgba(dark), outline=rgba(line), width=2)
    draw_stepped_rect(draw, (x0 + 3, y0 + 3, x1 - 3, y1 - 3), shade(ribbon, 0.18), shade(ribbon, -0.13), step=3)
    draw.rounded_rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), radius=max(2, radius - 3), outline=rgba(line, 0.28), width=1)
    draw.line((x0 + 12, y0 + 6, x1 - 12, y0 + 6), fill=rgba(palette["spark"], 0.42), width=1)


def draw_rarity_marks(draw, palette, rarity):
    line = palette["line"]
    spark = palette["spark"]
    count = {"common": 1, "rare": 2, "mythic": 3}[rarity]
    start_x = 35

    for index in range(count):
        cx = start_x + index * 12
        cy = 30
        draw.polygon(diamond(cx, cy, 4), fill=rgba(spark, 0.5), outline=rgba(line, 0.86))


def draw_card_frame(rarity, palette):
    image = Image.new("RGBA", (CARD_WIDTH, CARD_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    line = palette["line"]
    glow = rgba(line, 0.22)
    draw.rounded_rectangle((2, 2, CARD_WIDTH - 3, CARD_HEIGHT - 3), radius=15, outline=glow, width=6)
    draw.rounded_rectangle(
        (0, 0, CARD_WIDTH - 1, CARD_HEIGHT - 1),
        radius=14,
        fill=rgba(palette["fill"]),
        outline=rgba(line),
        width=3,
    )

    draw_stepped_rect(draw, (9, 9, CARD_WIDTH - 10, CARD_HEIGHT - 10), shade(palette["inner"], 0.1), shade(palette["inner"], -0.18))
    draw.rounded_rectangle(
        (8, 8, CARD_WIDTH - 9, CARD_HEIGHT - 9),
        radius=10,
        outline=rgba(line, 0.36),
        width=1,
    )
    draw.rounded_rectangle(
        (3, 3, CARD_WIDTH - 4, CARD_HEIGHT - 4),
        radius=12,
        outline=rgba(line, 0.72),
        width=1,
    )

    draw_pixel_texture(draw, palette, rarity)
    draw_scale_pattern(draw, palette, rarity)
    draw_center_sigil(draw, palette, rarity)
    draw_corner_plate(draw, palette, 8, 8, False, False)
    draw_corner_plate(draw, palette, CARD_WIDTH - 9, 8, True, False)
    draw_corner_plate(draw, palette, 8, CARD_HEIGHT - 9, False, True)
    draw_corner_plate(draw, palette, CARD_WIDTH - 9, CARD_HEIGHT - 9, True, True)

    draw.line((14, 49, CARD_WIDTH - 15, 49), fill=rgba(line, 0.26), width=1)
    draw.line((18, CARD_HEIGHT - 54, CARD_WIDTH - 19, CARD_HEIGHT - 54), fill=rgba(line, 0.22), width=1)

    draw_ribbon(draw, palette, (16, 16, CARD_WIDTH - 17, 43), 8)
    draw_rarity_marks(draw, palette, rarity)

    button_y = CARD_HEIGHT - 46
    draw_ribbon(draw, palette, (18, button_y, CARD_WIDTH - 19, button_y + 27), 10)

    return image


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for rarity, palette in RARITY_PALETTES.items():
        draw_card_frame(rarity, palette).save(OUT_DIR / f"run_choice_{rarity}.png")


if __name__ == "__main__":
    main()
