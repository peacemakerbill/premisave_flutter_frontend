#!/usr/bin/env python3
"""Redraws the Linux window icons in linux/runner/icons from assets/brand/app_icon_foreground.png.

The full app icon has a lot of padding, so at 16 to 32 pixels the house is a speck. These icons put the house on a
rounded green tile and enlarge it as the size gets smaller. Run it from the project folder after the brand art changes:

    python3 tool/linux_icons.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FOREGROUND = ROOT / "assets" / "brand" / "app_icon_foreground.png"
OUT = ROOT / "linux" / "runner" / "icons"
TILE = (14, 59, 47, 255)
SIZES = (16, 24, 32, 48, 64, 128, 256, 512)


def house_share(size: int) -> float:
    """How much of the tile the house fills: more on small icons, where detail is lost anyway."""
    if size <= 24:
        return 0.78
    if size <= 48:
        return 0.70
    return 0.62


def draw(size: int, house: Image.Image) -> Image.Image:
    scale = 4  # draw big, then shrink, for smooth edges
    big = size * scale
    tile = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * 0.22), fill=TILE)
    target = int(big * house_share(size))
    w, h = house.size
    ratio = min(target / w, target / h)
    sized = house.resize((max(1, int(w * ratio)), max(1, int(h * ratio))), Image.LANCZOS)
    tile.alpha_composite(sized, ((big - sized.width) // 2, (big - sized.height) // 2))
    return tile.resize((size, size), Image.LANCZOS)


def main() -> None:
    art = Image.open(FOREGROUND).convert("RGBA")
    house = art.crop(art.getbbox())
    OUT.mkdir(parents=True, exist_ok=True)
    for size in SIZES:
        draw(size, house).save(OUT / f"premisave_{size}.png", optimize=True)
        print("wrote", OUT / f"premisave_{size}.png")


if __name__ == "__main__":
    main()
