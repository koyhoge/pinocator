#!/usr/bin/env python3
"""Pinocator app icon: concentric rings converging on a cursor arrow,
on a dark navy squircle. Drawn at 3x and downscaled for anti-aliasing.

Usage: python3 make_icon.py [output.png] [highlight-style]
  highlight-style: inner (default, adopted design) | arcs | sheen | rim | gloss
"""
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 3                      # supersampling factor
W = 1024                   # final size
CW = W * S                 # canvas size while drawing

# Apple icon grid: the squircle body is 824/1024 of the canvas, centered.
BODY = 824 * S
MARGIN = (CW - BODY) // 2
RADIUS = int(185 * S)      # squircle corner radius

# Ring color from the app: (0.15, 0.55, 1.0)
ACCENT = (77, 163, 255)
ICE = (234, 244, 255)

RINGS = [  # (radius, width, color, alpha)
    (300, 30, ICE, 235),
    (212, 30, ACCENT, 255),
    (124, 30, ICE, 235),
]


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def squircle_mask():
    mask = Image.new("L", (CW, CW), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([MARGIN, MARGIN, MARGIN + BODY, MARGIN + BODY],
                         radius=RADIUS, fill=255)
    return mask


def make_background():
    """Diagonal navy gradient clipped to the squircle."""
    grad = Image.new("RGB", (CW, CW))
    gd = ImageDraw.Draw(grad)
    top = (18, 58, 122)
    bottom = (7, 24, 56)
    for y in range(CW):
        gd.line([(0, y), (CW, y)], fill=lerp(top, bottom, y / CW))
    img = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    img.paste(grad, (0, 0), squircle_mask())
    # faint top light on the squircle edge
    edge = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    ed = ImageDraw.Draw(edge)
    ed.rounded_rectangle([MARGIN + S, MARGIN + S, MARGIN + BODY - S, MARGIN + BODY - S],
                         radius=RADIUS - S, outline=(255, 255, 255, 70), width=2 * S)
    img.alpha_composite(edge)
    return img


def draw_ring(draw, center, r, width, color, alpha):
    x, y = center
    draw.ellipse([x - r, y - r, x + r, y + r],
                 outline=color + (alpha,), width=width)


def highlight_arcs(draw, center):
    """Current style: flat white arcs on the upper-left of each ring
    (PIL angles: 0 = east, clockwise because y is down)."""
    for r, w, _c, _a in RINGS:
        x, y = center
        rr, ww = r * S, w * S
        draw.arc([x - rr, y - rr, x + rr, y + rr], start=170, end=265,
                 fill=(255, 255, 255, 170), width=max(2, int(ww * 0.45)))


def highlight_rim(draw, center):
    """Tapered rim light: many small arc segments whose alpha follows a
    raised-cosine envelope, so the highlight fades in and out smoothly."""
    import math
    for r, w, _c, _a in RINGS:
        x, y = center
        rr, ww = r * S, int(w * S * 0.5)
        steps = 48
        for i in range(steps):
            frac = i / (steps - 1)
            ang = 168 + frac * 100
            alpha = int(235 * (math.sin(math.pi * frac) ** 1.5))
            if alpha <= 0:
                continue
            draw.arc([x - rr, y - rr, x + rr, y + rr],
                     start=ang, end=ang + 100 / steps + 0.6,
                     fill=(255, 255, 255, alpha), width=ww)


def apply_sheen(rings_layer):
    """Soft diagonal light that exists only where the rings are:
    a white gradient (strong at the top-left) masked by the rings."""
    # Build a small diagonal gradient and upscale it.
    small = Image.new("L", (256, 256), 0)
    sd = ImageDraw.Draw(small)
    for i in range(512):
        t = i / 512
        alpha = max(0, int(215 * (1 - t / 0.8))) if t < 0.8 else 0
        sd.line([(i, 0), (0, i)], fill=alpha)
    grad = small.resize((CW, CW), Image.BILINEAR)
    sheen_alpha = ImageChops.multiply(grad, rings_layer.split()[3])
    sheen = Image.new("RGBA", (CW, CW), (255, 255, 255, 255))
    sheen.putalpha(sheen_alpha)
    rings_layer.alpha_composite(sheen)


def make_inner_shadows(center):
    """A thin, faint shadow hugging the inside of each ring's band:
    width = 1/3 of the line width, placed just inside the inner edge
    (with a slight overlap under the band, so blur never leaks into
    the gaps between rings). Drawn under the rings."""
    layer = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = center
    for r, w, _c, _a in RINGS:
        sw = w / 3
        rr = (r - w / 2 - sw / 2 + 2) * S
        d.ellipse([x - rr, y - rr, x + rr, y + rr],
                  outline=(0, 0, 0, 150), width=int(sw * S))
    return layer.filter(ImageFilter.GaussianBlur(2 * S))


def make_gloss():
    """A broad soft light across the top-left of the squircle,
    like light falling on a glass plate."""
    layer = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([-int(CW * 0.25), -int(CW * 0.52), int(CW * 0.78), int(CW * 0.34)],
              fill=(255, 255, 255, 52))
    layer = layer.filter(ImageFilter.GaussianBlur(45 * S))
    out = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    out.paste(layer, (0, 0), squircle_mask())
    return out


def build(style):
    img = make_background()
    cx = MARGIN + BODY // 2
    cy = MARGIN + BODY // 2
    center = (cx, cy)

    # soft glow under the rings
    glow = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r, w, _c, _a in RINGS:
        draw_ring(gd, center, r * S, w * S * 2, ACCENT, 60)
    glow = glow.filter(ImageFilter.GaussianBlur(18 * S))
    img.alpha_composite(glow)

    if style == "inner":
        img.alpha_composite(make_inner_shadows(center))

    rings = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rings)
    for r, w, color, alpha in RINGS:
        draw_ring(rd, center, r * S, w * S, color, alpha)
    if style == "arcs":
        highlight_arcs(rd, center)
    elif style == "rim":
        highlight_rim(rd, center)
    elif style == "sheen":
        apply_sheen(rings)
    img.alpha_composite(rings)

    if style in ("gloss", "inner"):
        img.alpha_composite(make_gloss())

    # Cursor arrow with its tip at the convergence point.
    layer = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    ax, ay = cx, cy
    u = S * 1.6  # arrow unit (enlarged for legibility)
    arrow = [
        (ax, ay),
        (ax, ay + 92 * u),
        (ax + 26 * u, ay + 70 * u),
        (ax + 42 * u, ay + 108 * u),
        (ax + 58 * u, ay + 100 * u),
        (ax + 42 * u, ay + 64 * u),
        (ax + 72 * u, ay + 64 * u),
    ]
    shadow = Image.new("RGBA", (CW, CW), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon([(x + 4 * u, y + 6 * u) for x, y in arrow], fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(5 * S))
    layer.alpha_composite(shadow)
    d.polygon(arrow, fill=(255, 255, 255, 255), outline=(8, 26, 54, 255), width=5 * S)
    img.alpha_composite(layer)

    return img.resize((W, W), Image.LANCZOS)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pinocator-icon-1024.png"
    style = sys.argv[2] if len(sys.argv) > 2 else "inner"
    build(style).save(out)
    print(f"wrote {out} (style={style})")


if __name__ == "__main__":
    main()
