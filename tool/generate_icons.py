"""Generates the Seerati launcher icons and launch-screen marks.

Run from the repo root:  python3 tool/generate_icons.py   (needs Pillow)

The mark is a resume page (photo + text lines) with a folded corner, drawn
right-to-left to match the app's Arabic-first layout.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SS = 4  # supersampling factor

TEAL = (0, 105, 109)
TEAL_TOP = (13, 138, 142)
TEAL_BOTTOM = (0, 79, 82)
FOLD = (178, 223, 219)
LINE = (197, 217, 216)
WHITE = (255, 255, 255)


def _gradient(size):
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        color = tuple(round(a + (b - a) * t) for a, b in zip(TEAL_TOP, TEAL_BOTTOM))
        draw.line([(0, y), (size, y)], fill=color)
    return img


def _mark(size, scale, monochrome=False):
    """Page mark on a transparent canvas. [scale] = page size relative to the
    full icon (1.0 = page is 50% wide, 62% tall of the canvas)."""
    n = size * SS

    def p(x, y):  # unit coords around the centre → pixels
        return (n / 2 + (x - 0.5) * scale * n, n / 2 + (y - 0.5) * scale * n)

    def box(x1, y1, x2, y2):
        return [*p(x1, y1), *p(x2, y2)]

    x1, y1, x2, y2 = 0.25, 0.19, 0.75, 0.81
    fold = 0.14

    page = Image.new("L", (n, n), 0)
    pd = ImageDraw.Draw(page)
    pd.rounded_rectangle(box(x1, y1, x2, y2), radius=0.05 * scale * n, fill=255)
    pd.polygon([p(x2 - fold, y1 - 0.01), p(x2 + 0.01, y1 - 0.01), p(x2 + 0.01, y1 + fold)], fill=0)

    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    img.paste(Image.new("RGBA", (n, n), (*WHITE, 255)), (0, 0), page)
    d = ImageDraw.Draw(img)

    # Folded corner.
    d.polygon([p(x2 - fold, y1), p(x2 - fold, y1 + fold), p(x2, y1 + fold)],
              fill=(*(WHITE if monochrome else FOLD), 255))

    ink = (0, 0, 0, 0) if monochrome else None  # monochrome: punch holes

    def bar(xa, xb, y, h, color):
        d.rounded_rectangle(box(xa, y - h / 2, xb, y + h / 2),
                            radius=h / 2 * scale * n, fill=ink or (*color, 255))

    r = 0.058
    d.ellipse(box(0.355 - r, 0.33 - r, 0.355 + r, 0.33 + r), fill=ink or (*TEAL, 255))
    bar(0.45, 0.58, 0.30, 0.036, TEAL)
    bar(0.45, 0.56, 0.365, 0.026, LINE)
    bar(0.31, 0.45, 0.49, 0.032, TEAL)
    for y, end in ((0.56, 0.69), (0.625, 0.69), (0.69, 0.69), (0.755, 0.56)):
        bar(0.31, end, y, 0.026, LINE)

    # Right-to-left: photo on the right, fold on the left.
    img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return img.resize((size, size), Image.Resampling.LANCZOS)


def full_icon(size, rounded):
    """Background + mark. [rounded] → transparent rounded-square corners."""
    n = size * SS
    bg = _gradient(n).convert("RGBA")
    if rounded:
        margin = 0.04 * n
        mask = Image.new("L", (n, n), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [margin, margin, n - margin, n - margin], radius=0.2 * n, fill=255)
        bg.putalpha(mask)
    bg = bg.resize((size, size), Image.Resampling.LANCZOS)
    bg.alpha_composite(_mark(size, 1.0 if not rounded else 0.92))
    return bg


def main():
    res = ROOT / "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, f in densities.items():
        folder = res / f"mipmap-{name}"
        full_icon(round(48 * f), rounded=True).save(folder / "ic_launcher.png")
        # Adaptive layers are 108dp; the mark must stay inside the 66dp safe zone.
        _mark(round(108 * f), 0.66).save(folder / "ic_launcher_foreground.png")
        _mark(round(108 * f), 0.66, monochrome=True).save(folder / "ic_launcher_monochrome.png")
        splash = res / f"drawable-{name}"
        splash.mkdir(exist_ok=True)
        _mark(round(160 * f), 1.0).save(splash / "launch_image.png")

    ios = ROOT / "ios/Runner/Assets.xcassets"
    for path in (ios / "AppIcon.appiconset").glob("Icon-App-*.png"):
        base, _, mult = path.stem.removeprefix("Icon-App-").partition("@")
        px = round(float(base.split("x")[0]) * int(mult.rstrip("x")))
        # App Store rejects icons with an alpha channel.
        full_icon(px, rounded=False).convert("RGB").save(path)
    for mult, suffix in ((1, ""), (2, "@2x"), (3, "@3x")):
        _mark(160 * mult, 1.0).save(ios / f"LaunchImage.imageset/LaunchImage{suffix}.png")


if __name__ == "__main__":
    main()
