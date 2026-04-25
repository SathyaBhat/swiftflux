import os
import math
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
PADDING = 120

def create_icon():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw rounded rect background (macOS icon shape)
    radius = SIZE * 0.225
    rect = [0, 0, SIZE, SIZE]
    draw.rounded_rectangle(rect, radius=radius, fill=(37, 99, 235, 255))  # blue-600

    # Subtle inner highlight
    inner_rect = [8, 8, SIZE-8, SIZE-8]
    draw.rounded_rectangle(inner_rect, radius=radius-8, fill=(59, 130, 246, 255))  # blue-500

    # Draw a simple RSS / reader icon: a stylized document/page with RSS symbol
    cx, cy = SIZE // 2, SIZE // 2
    scale = SIZE / 1024.0

    # Document shape
    doc_w = int(420 * scale)
    doc_h = int(540 * scale)
    doc_x = cx - doc_w // 2
    doc_y = cy - doc_h // 2 + int(20 * scale)

    # Paper background
    draw.rounded_rectangle(
        [doc_x, doc_y, doc_x + doc_w, doc_y + doc_h],
        radius=int(24 * scale),
        fill=(255, 255, 255, 255)
    )

    # Folded corner
    fold = int(80 * scale)
    draw.polygon([
        (doc_x + doc_w - fold, doc_y),
        (doc_x + doc_w, doc_y),
        (doc_x + doc_w, doc_y + fold),
    ], fill=(226, 232, 240, 255))

    # Draw lines of text
    line_h = int(28 * scale)
    text_y = doc_y + int(60 * scale)
    text_left = doc_x + int(40 * scale)
    text_right = doc_x + doc_w - int(40 * scale)
    line_count = 10
    for i in range(line_count):
        width = text_right - text_left - (0 if i % 3 != 2 else int(120 * scale))
        draw.rounded_rectangle(
            [text_left, text_y, text_left + width, text_y + line_h],
            radius=int(6 * scale),
            fill=(203, 213, 225, 255)
        )
        text_y += line_h + int(14 * scale)

    # RSS circle on the bottom right of the document
    rss_r = int(70 * scale)
    rss_cx = doc_x + doc_w - int(60 * scale)
    rss_cy = doc_y + doc_h - int(60 * scale)
    draw.ellipse(
        [rss_cx - rss_r, rss_cy - rss_r, rss_cx + rss_r, rss_cy + rss_r],
        fill=(37, 99, 235, 255)
    )

    # RSS dot
    dot_r = int(12 * scale)
    draw.ellipse(
        [rss_cx - int(30*scale) - dot_r, rss_cy + int(20*scale) - dot_r,
         rss_cx - int(30*scale) + dot_r, rss_cy + int(20*scale) + dot_r],
        fill=(255, 255, 255, 255)
    )

    # RSS arcs
    for arc_r in [int(22*scale), int(38*scale)]:
        # Draw arc as a partial ellipse
        bbox = [rss_cx - arc_r, rss_cy - arc_r, rss_cx + arc_r, rss_cy + arc_r]
        arc_thick = int(6 * scale)
        draw.arc(bbox, start=200, end=340, fill=(255, 255, 255, 255), width=arc_thick)

    return img

def main():
    os.makedirs('Resources/Icon.iconset', exist_ok=True)
    icon = create_icon()
    icon.save('Resources/Icon.iconset/icon_512x512@2x.png')

    sizes = [
        (16, 'icon_16x16.png'),
        (32, 'icon_16x16@2x.png'),
        (32, 'icon_32x32.png'),
        (64, 'icon_32x32@2x.png'),
        (128, 'icon_128x128.png'),
        (256, 'icon_128x128@2x.png'),
        (256, 'icon_256x256.png'),
        (512, 'icon_256x256@2x.png'),
        (512, 'icon_512x512.png'),
        (1024, 'icon_512x512@2x.png'),
    ]

    for s, name in sizes:
        resized = icon.resize((s, s), Image.LANCZOS)
        resized.save(f'Resources/Icon.iconset/{name}')

    print('Icon generated in Resources/Icon.iconset/')

if __name__ == '__main__':
    main()
