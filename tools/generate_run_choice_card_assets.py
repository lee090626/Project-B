from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "ui" / "cards"
CARD_WIDTH = 272
CARD_HEIGHT = 252

RARITY_PALETTES = {
    "common": {
        "fill": (0.08, 0.11, 0.11, 0.96),
        "inner": (0.12, 0.16, 0.16, 0.94),
        "line": (0.44, 0.84, 0.67, 0.96),
        "ribbon": (0.2, 0.45, 0.38, 0.96),
    },
    "rare": {
        "fill": (0.07, 0.1, 0.12, 0.96),
        "inner": (0.11, 0.16, 0.18, 0.94),
        "line": (0.49, 0.86, 0.92, 0.96),
        "ribbon": (0.2, 0.41, 0.52, 0.96),
    },
    "mythic": {
        "fill": (0.12, 0.08, 0.06, 0.97),
        "inner": (0.18, 0.12, 0.09, 0.95),
        "line": (0.96, 0.78, 0.43, 0.98),
        "ribbon": (0.64, 0.32, 0.12, 0.98),
    },
}


def rgba(color, alpha_mul=1.0):
    r, g, b, a = color
    return (
        round(r * 255),
        round(g * 255),
        round(b * 255),
        round(a * alpha_mul * 255),
    )


def draw_card_frame(palette):
    image = Image.new("RGBA", (CARD_WIDTH, CARD_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    line = palette["line"]
    draw.rounded_rectangle(
        (0, 0, CARD_WIDTH - 1, CARD_HEIGHT - 1),
        radius=14,
        fill=rgba(palette["fill"]),
        outline=rgba(line),
        width=2,
    )
    draw.rounded_rectangle(
        (8, 8, CARD_WIDTH - 9, CARD_HEIGHT - 9),
        radius=10,
        fill=rgba(palette["inner"], 0.72),
    )
    draw.rounded_rectangle(
        (3, 3, CARD_WIDTH - 4, CARD_HEIGHT - 4),
        radius=12,
        outline=rgba(line),
        width=1,
    )

    corner = 8
    accent = rgba(line, 0.9)
    draw.polygon(
        [(14, 8), (14 + corner, 14), (14, 20), (14 - corner, 14)],
        fill=accent,
    )
    draw.polygon(
        [
            (CARD_WIDTH - 14, 8),
            (CARD_WIDTH - 14 + corner, 14),
            (CARD_WIDTH - 14, 20),
            (CARD_WIDTH - 14 - corner, 14),
        ],
        fill=accent,
    )

    ribbon = rgba(palette["ribbon"])
    line_color = rgba(line)
    draw.rounded_rectangle((16, 16, CARD_WIDTH - 17, 43), radius=8, fill=ribbon)
    draw.rounded_rectangle((16, 16, CARD_WIDTH - 17, 43), radius=8, outline=line_color, width=2)

    button_y = CARD_HEIGHT - 46
    draw.rounded_rectangle((18, button_y, CARD_WIDTH - 19, button_y + 27), radius=10, fill=ribbon)
    draw.rounded_rectangle((18, button_y, CARD_WIDTH - 19, button_y + 27), radius=10, outline=line_color, width=2)

    return image


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for rarity, palette in RARITY_PALETTES.items():
        draw_card_frame(palette).save(OUT_DIR / f"run_choice_{rarity}.png")


if __name__ == "__main__":
    main()
