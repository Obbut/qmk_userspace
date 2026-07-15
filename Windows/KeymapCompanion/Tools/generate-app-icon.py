"""Generate the Windows application icon from the Kyria-left tray geometry."""

from pathlib import Path

from PIL import Image, ImageDraw


CANVAS_SIZE = 64
SUPERSAMPLING_SCALE = 16
ICON_SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)
KYRIA_OUTLINE = (
    (4, 12),
    (44, 7),
    (50, 29),
    (61, 38),
    (52, 56),
    (39, 45),
    (27, 56),
    (16, 51),
    (4, 50),
)
COLUMN_OFFSETS = (3, 1, 0, 1, 3, 5)
ACCENT_COLOR = (0, 120, 215, 255)
OUTLINE_COLOR = (22, 25, 34, 255)


def scaled(value: int) -> int:
    """Scale a tray-coordinate value for antialiased rendering."""
    return value * SUPERSAMPLING_SCALE


def rounded_rectangle(
    drawing: ImageDraw.ImageDraw,
    bounds: tuple[int, int, int, int],
) -> None:
    """Cut a rounded key opening from the keyboard plate."""
    drawing.rounded_rectangle(
        tuple(scaled(value) for value in bounds),
        radius=scaled(2),
        fill=(0, 0, 0, 0),
    )


def make_icon() -> Image.Image:
    """Render a high-resolution Kyria-left icon master."""
    size = scaled(CANVAS_SIZE)
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(image)
    outline = tuple((scaled(x), scaled(y)) for x, y in KYRIA_OUTLINE)
    drawing.polygon(outline, fill=ACCENT_COLOR)
    drawing.line(
        (*outline, outline[0]),
        fill=OUTLINE_COLOR,
        width=scaled(3),
        joint="curve",
    )

    for column, offset in enumerate(COLUMN_OFFSETS):
        for row in range(3):
            left = 7 + column * 8
            top = 14 + row * 10 + offset
            rounded_rectangle(drawing, (left, top, left + 6, top + 7))
    rounded_rectangle(drawing, (31, 45, 38, 52))
    rounded_rectangle(drawing, (39, 48, 47, 55))
    return image


def main() -> None:
    """Write the multi-resolution ICO and a local preview image."""
    package_root = Path(__file__).resolve().parent.parent
    assets = package_root / "Assets"
    assets.mkdir(parents=True, exist_ok=True)
    master = make_icon()
    master.save(
        assets / "KeymapCompanion.ico",
        format="ICO",
        sizes=tuple((size, size) for size in ICON_SIZES),
    )

    preview = master.resize((256, 256), Image.Resampling.LANCZOS)
    preview_root = package_root / ".build"
    preview_root.mkdir(parents=True, exist_ok=True)
    preview.save(preview_root / "KeymapCompanionIconPreview.png")


if __name__ == "__main__":
    main()
