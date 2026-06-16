#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Resources" / "Assets.xcassets"
APPICON = ASSETS / "AppIcon.appiconset"
SYMBOL = ASSETS / "LauncherSymbol.imageset"
SOURCE = ASSETS / "MacPlayIconSource.imageset"


def rounded_rectangle_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def make_background(size: int) -> Image.Image:
    top = (24, 49, 74)
    bottom = (12, 91, 92)
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        for x in range(size):
            radial = 1 - min(1, math.hypot((x - size * 0.35) / size, (y - size * 0.25) / size) * 1.65)
            color = tuple(
                int(top[i] * (1 - t) + bottom[i] * t + 26 * radial)
                for i in range(3)
            )
            pixels[x, y] = (*color, 255)
    return image


def draw_icon(size: int, include_background: bool = True) -> Image.Image:
    scale = size / 1024
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    if include_background:
        background = make_background(size)
        mask = rounded_rectangle_mask(size, int(224 * scale))
        shadow = mask.filter(ImageFilter.GaussianBlur(int(22 * scale)))
        shadow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 95))
        canvas.alpha_composite(Image.composite(shadow_layer, Image.new("RGBA", (size, size)), shadow))
        canvas.alpha_composite(Image.composite(background, Image.new("RGBA", (size, size)), mask))

    draw = ImageDraw.Draw(canvas)

    # Soft glow behind the launch glyph.
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (
            int(174 * scale),
            int(166 * scale),
            int(850 * scale),
            int(842 * scale),
        ),
        fill=(255, 183, 77, 54),
    )
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(int(38 * scale))))

    # Minimal Mac window.
    window = (
        int(206 * scale),
        int(256 * scale),
        int(818 * scale),
        int(724 * scale),
    )
    draw.rounded_rectangle(window, radius=int(64 * scale), fill=(235, 244, 246, 238))
    draw.rounded_rectangle(
        (
            window[0] + int(24 * scale),
            window[1] + int(76 * scale),
            window[2] - int(24 * scale),
            window[3] - int(24 * scale),
        ),
        radius=int(42 * scale),
        fill=(16, 36, 54, 245),
    )
    for index, color in enumerate(((255, 95, 86), (255, 189, 46), (39, 201, 63))):
        x = window[0] + int((54 + index * 44) * scale)
        y = window[1] + int(42 * scale)
        draw.ellipse(
            (x - int(12 * scale), y - int(12 * scale), x + int(12 * scale), y + int(12 * scale)),
            fill=color,
        )

    # Play triangle.
    triangle = [
        (int(438 * scale), int(374 * scale)),
        (int(438 * scale), int(610 * scale)),
        (int(642 * scale), int(492 * scale)),
    ]
    draw.polygon(triangle, fill=(255, 184, 67, 255))

    # Controller-inspired dots keep the mark game-related without text.
    draw.ellipse(
        (
            int(312 * scale),
            int(616 * scale),
            int(382 * scale),
            int(686 * scale),
        ),
        fill=(51, 201, 184, 245),
    )
    draw.ellipse(
        (
            int(648 * scale),
            int(616 * scale),
            int(718 * scale),
            int(686 * scale),
        ),
        fill=(255, 105, 96, 245),
    )

    # Front base line gives the mark a launcher/dock feel.
    draw.rounded_rectangle(
        (
            int(292 * scale),
            int(760 * scale),
            int(732 * scale),
            int(814 * scale),
        ),
        radius=int(27 * scale),
        fill=(224, 238, 239, 230),
    )

    return canvas


def save_png(image: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(path)


def write_app_icon() -> None:
    APPICON.mkdir(parents=True, exist_ok=True)
    source = draw_icon(1024, include_background=True)
    entries = [
        ("16x16", "1x", 16),
        ("16x16", "2x", 32),
        ("32x32", "1x", 32),
        ("32x32", "2x", 64),
        ("128x128", "1x", 128),
        ("128x128", "2x", 256),
        ("256x256", "1x", 256),
        ("256x256", "2x", 512),
        ("512x512", "1x", 512),
        ("512x512", "2x", 1024),
    ]
    images = []
    for logical_size, scale, pixels in entries:
        filename = f"app-icon-{pixels}.png"
        save_png(source, APPICON / filename, pixels)
        images.append(
            {
                "filename": filename,
                "idiom": "mac",
                "scale": scale,
                "size": logical_size,
            }
        )
    (APPICON / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n",
        encoding="utf-8",
    )


def write_symbol_sets() -> None:
    transparent = draw_icon(1024, include_background=False)
    source = draw_icon(1024, include_background=True)

    for folder, image, name in (
        (SYMBOL, transparent, "launcher-symbol.png"),
        (SOURCE, source, "macplay-icon-source.png"),
    ):
        folder.mkdir(parents=True, exist_ok=True)
        save_png(image, folder / name, 1024)
        (folder / "Contents.json").write_text(
            json.dumps(
                {
                    "images": [
                        {
                            "filename": name,
                            "idiom": "universal",
                            "scale": "1x",
                        }
                    ],
                    "info": {"author": "xcode", "version": 1},
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )


def main() -> None:
    write_app_icon()
    write_symbol_sets()
    print(f"Generated app icons in {APPICON}")
    print(f"Generated reusable symbol in {SYMBOL}")


if __name__ == "__main__":
    main()
