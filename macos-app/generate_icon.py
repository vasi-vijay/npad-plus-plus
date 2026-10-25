#!/usr/bin/env python3
"""
Generate professional Apple macOS application icon (.icns and .iconset) for CodePad++.
Features:
- Premium macOS dark squircle container with metallic bevel and ambient shadow
- Dark obsidian code editor document sheet with macOS traffic light controls
- Subtle { } code brackets in electric cyan (#8BD5CA)
- Recognizable, bold, glowing ++ element in vibrant emerald green (#A6DA95 -> #50FA7B)
- Multi-resolution super-sampled rendering (16x16 up to 1024x1024)
- Generates full AppIcon.iconset and standalone AppIcon.icns
"""

import math
import os
import struct
import zlib
from pathlib import Path

def create_png(width, height, rgba_data):
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    
    header = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    
    raw = bytearray()
    row_bytes = width * 4
    for y in range(height):
        raw.append(0)  # filter type 0 (None)
        raw.extend(rgba_data[y * row_bytes : (y + 1) * row_bytes])
    
    idat = zlib.compress(bytes(raw), 9)
    return header + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')

def dist_to_segment(px, py, x1, y1, x2, y2):
    """Calculates distance from point (px, py) to line segment (x1, y1)-(x2, y2)."""
    dx = x2 - x1
    dy = y2 - y1
    seg_len_sq = dx * dx + dy * dy
    if seg_len_sq == 0.0:
        return math.hypot(px - x1, py - y1)
    t = max(0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / seg_len_sq))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy
    return math.hypot(px - proj_x, py - proj_y)

def dist_to_left_brace(px, py, cx, cy, scale):
    """Calculates distance from (px, py) to left curly brace '{'."""
    # Scale dimensions
    h = 44.0 * scale
    w = 18.0 * scale
    
    # 4 segments forming curly brace:
    # 1. Top hook: from (cx, cy - h) to (cx - w*0.5, cy - h*0.8)
    # 2. Upper stem: from (cx - w*0.5, cy - h*0.8) to (cx - w, cy)
    # 3. Lower stem: from (cx - w, cy) to (cx - w*0.5, cy + h*0.8)
    # 4. Bottom hook: from (cx - w*0.5, cy + h*0.8) to (cx, cy + h)
    s1 = dist_to_segment(px, py, cx, cy - h, cx - w * 0.45, cy - h * 0.85)
    s2 = dist_to_segment(px, py, cx - w * 0.45, cy - h * 0.85, cx - w * 0.5, cy - h * 0.2)
    s3 = dist_to_segment(px, py, cx - w * 0.5, cy - h * 0.2, cx - w * 1.1, cy)
    s4 = dist_to_segment(px, py, cx - w * 1.1, cy, cx - w * 0.5, cy + h * 0.2)
    s5 = dist_to_segment(px, py, cx - w * 0.5, cy + h * 0.2, cx - w * 0.45, cy + h * 0.85)
    s6 = dist_to_segment(px, py, cx - w * 0.45, cy + h * 0.85, cx, cy + h)
    return min(s1, s2, s3, s4, s5, s6)

def dist_to_right_brace(px, py, cx, cy, scale):
    """Calculates distance from (px, py) to right curly brace '}'."""
    h = 44.0 * scale
    w = 18.0 * scale
    s1 = dist_to_segment(px, py, cx, cy - h, cx + w * 0.45, cy - h * 0.85)
    s2 = dist_to_segment(px, py, cx + w * 0.45, cy - h * 0.85, cx + w * 0.5, cy - h * 0.2)
    s3 = dist_to_segment(px, py, cx + w * 0.5, cy - h * 0.2, cx + w * 1.1, cy)
    s4 = dist_to_segment(px, py, cx + w * 1.1, cy, cx + w * 0.5, cy + h * 0.2)
    s5 = dist_to_segment(px, py, cx + w * 0.5, cy + h * 0.2, cx + w * 0.45, cy + h * 0.85)
    s6 = dist_to_segment(px, py, cx + w * 0.45, cy + h * 0.85, cx, cy + h)
    return min(s1, s2, s3, s4, s5, s6)

def dist_to_plus_sign(px, py, pcx, pcy, half_arm, half_thick):
    """Calculates distance from (px, py) to plus sign '+' composed of two intersecting rounded rects."""
    dx = abs(px - pcx)
    dy = abs(py - pcy)
    
    # Horizontal bar
    hx = max(0.0, dx - half_arm)
    hy = max(0.0, dy - half_thick)
    dist_h = math.hypot(hx, hy)
    
    # Vertical bar
    vx = max(0.0, dx - half_thick)
    vy = max(0.0, dy - half_arm)
    dist_v = math.hypot(vx, vy)
    
    return min(dist_h, dist_v)

def render_icon(size):
    """Render CodePad++ icon at arbitrary resolution (16 to 1024)."""
    rgba = bytearray(size * size * 4)
    scale = size / 512.0

    cx, cy = size / 2.0, size / 2.0
    corner_radius = 100.0 * scale
    half_w = 210.0 * scale
    half_h = 210.0 * scale

    # Clamp minimum stroke widths for small resolutions (16x16, 32x32)
    brace_stroke = max(1.2, 5.0 * scale)
    plus_arm = max(3.0, 18.0 * scale)
    plus_thick = max(1.1, 5.0 * scale)

    # Positions for braces and plus signs
    emblem_cy = cy + 32.0 * scale
    brace_left_cx = cx - 78.0 * scale
    brace_right_cx = cx + 78.0 * scale
    
    plus1_cx = cx - 20.0 * scale
    plus2_cx = cx + 20.0 * scale

    for y in range(size):
        for x in range(size):
            idx = (y * size + x) * 4

            coverage = 0.0
            r_acc, g_acc, b_acc = 0.0, 0.0, 0.0

            # 2x2 super-sampling
            for sy in (-0.25, 0.25):
                for sx in (-0.25, 0.25):
                    px = x + 0.5 + sx
                    py = y + 0.5 + sy

                    dx = abs(px - cx)
                    dy = abs(py - cy)

                    # Squircle rounded rect bounds
                    qx = max(0.0, dx - (half_w - corner_radius))
                    qy = max(0.0, dy - (half_h - corner_radius))
                    dist = math.sqrt(qx * qx + qy * qy)

                    if dist <= corner_radius:
                        coverage += 0.25
                        # Base gradient: midnight dark blue-slate (#181926 to #24273A)
                        t = (py - (cy - half_h)) / (2.0 * half_h)
                        t = max(0.0, min(1.0, t))
                        br = 24.0 + t * 16.0
                        bg = 26.0 + t * 18.0
                        bb = 42.0 + t * 24.0

                        # Rim highlight (inner bevel)
                        edge_dist = corner_radius - dist
                        if dx >= (half_w - corner_radius) or dy >= (half_h - corner_radius):
                            if edge_dist < 4.0 * scale:
                                factor = (4.0 * scale - edge_dist) / (4.0 * scale)
                                br += factor * 50.0
                                bg += factor * 70.0
                                bb += factor * 100.0

                        # Inner editor sheet canvas
                        page_w = 152.0 * scale
                        page_h = 146.0 * scale
                        p_rad = 18.0 * scale
                        pdx = abs(px - cx)
                        pdy = abs(py - cy)
                        pqx = max(0.0, pdx - (page_w - p_rad))
                        pqy = max(0.0, pdy - (page_h - p_rad))
                        pdist = math.sqrt(pqx * pqx + pqy * pqy)

                        if pdist <= p_rad:
                            # Code canvas: deep obsidian editor background (#1E1E2E)
                            br = 30.0 + t * 8.0
                            bg = 30.0 + t * 8.0
                            bb = 46.0 + t * 10.0

                            # Titlebar of mini editor
                            if py < (cy - page_h + 30.0 * scale):
                                br = 36.0; bg = 38.0; bb = 54.0
                                # 3 window traffic lights: Red, Yellow, Green
                                for dot_idx, (dot_r, dot_g, dot_b) in enumerate([
                                    (237, 106, 94), (245, 189, 79), (98, 197, 84)
                                ]):
                                    dot_x = cx - page_w + (20.0 + dot_idx * 16.0) * scale
                                    dot_y = cy - page_h + 15.0 * scale
                                    if (px - dot_x)**2 + (py - dot_y)**2 <= (5.0 * scale)**2:
                                        br = dot_r; bg = dot_g; bb = dot_b

                            # Syntax code lines on the upper section
                            # Line 1: Cyan keyword + white variable
                            l1_y = cy - page_h + 48.0 * scale
                            if abs(py - l1_y) <= 3.0 * scale:
                                if (cx - page_w + 18.0 * scale) <= px <= (cx - page_w + 64.0 * scale):
                                    br = 139; bg = 213; bb = 202  # Cyan
                                elif (cx - page_w + 72.0 * scale) <= px <= (cx - page_w + 140.0 * scale):
                                    br = 202; bg = 211; bb = 245  # Off-white

                            # Line 2: Indented peach string
                            l2_y = cy - page_h + 62.0 * scale
                            if abs(py - l2_y) <= 3.0 * scale:
                                if (cx - page_w + 32.0 * scale) <= px <= (cx - page_w + 130.0 * scale):
                                    br = 245; bg = 169; bb = 127  # Peach

                            # Line 3: Indented emerald function
                            l3_y = cy - page_h + 76.0 * scale
                            if abs(py - l3_y) <= 3.0 * scale:
                                if (cx - page_w + 32.0 * scale) <= px <= (cx - page_w + 105.0 * scale):
                                    br = 166; bg = 218; bb = 149  # Emerald

                            # --- CODEPAD++ CENTRAL EMBLEM: { ++ } ---

                            # 1. Subtle Left Bracket '{' in Electric Cyan
                            d_b1 = dist_to_left_brace(px, py, brace_left_cx, emblem_cy, scale)
                            if d_b1 <= brace_stroke:
                                alpha_b = min(1.0, max(0.0, (brace_stroke - d_b1) / (0.8 * scale if scale > 0.5 else 0.5)))
                                # Subtle glowing cyan: #91D7E3
                                br = br * (1.0 - alpha_b) + 145.0 * alpha_b
                                bg = bg * (1.0 - alpha_b) + 215.0 * alpha_b
                                bb = bb * (1.0 - alpha_b) + 227.0 * alpha_b

                            # 2. Subtle Right Bracket '}' in Electric Cyan
                            d_b2 = dist_to_right_brace(px, py, brace_right_cx, emblem_cy, scale)
                            if d_b2 <= brace_stroke:
                                alpha_b = min(1.0, max(0.0, (brace_stroke - d_b2) / (0.8 * scale if scale > 0.5 else 0.5)))
                                br = br * (1.0 - alpha_b) + 145.0 * alpha_b
                                bg = bg * (1.0 - alpha_b) + 215.0 * alpha_b
                                bb = bb * (1.0 - alpha_b) + 227.0 * alpha_b

                            # 3. Bold, Glowing '++' Element
                            # Plus 1
                            d_p1 = dist_to_plus_sign(px, py, plus1_cx, emblem_cy, plus_arm, plus_thick)
                            # Plus 2
                            d_p2 = dist_to_plus_sign(px, py, plus2_cx, emblem_cy, plus_arm, plus_thick)
                            d_plus = min(d_p1, d_p2)

                            # Outer soft emerald glow
                            glow_radius = plus_thick + 6.0 * scale
                            if d_plus <= glow_radius:
                                glow_factor = (glow_radius - d_plus) / (6.0 * scale)
                                glow_factor = max(0.0, min(1.0, glow_factor)) * 0.4
                                br = br * (1.0 - glow_factor) + 80.0 * glow_factor
                                bg = bg * (1.0 - glow_factor) + 250.0 * glow_factor
                                bb = glow_factor * 123.0 + bb * (1.0 - glow_factor)

                            # Core '+' solid glyph with high-visibility vibrant emerald (#50FA7B / #A6DA95)
                            if d_plus <= 0.5 * scale:
                                br = 240.0; bg = 255.0; bb = 245.0  # Core highlight
                            elif d_plus <= plus_thick:
                                alpha_p = min(1.0, max(0.0, (plus_thick - d_plus) / (0.8 * scale if scale > 0.5 else 0.5)))
                                # Top to bottom subtle gradient on plus signs
                                pt = (py - (emblem_cy - plus_arm)) / (2.0 * plus_arm)
                                pr = 100.0 + pt * 66.0   # 100 -> 166
                                pg = 240.0 - pt * 22.0   # 240 -> 218
                                pb = 140.0 + pt * 9.0    # 140 -> 149
                                br = br * (1.0 - alpha_p) + pr * alpha_p
                                bg = bg * (1.0 - alpha_p) + pg * alpha_p
                                bb = bb * (1.0 - alpha_p) + pb * alpha_p

                        r_acc += br
                        g_acc += bg
                        b_acc += bb

            if coverage > 0.0:
                samples = coverage * 4.0
                rgba[idx] = int(min(255.0, r_acc / samples))
                rgba[idx + 1] = int(min(255.0, g_acc / samples))
                rgba[idx + 2] = int(min(255.0, b_acc / samples))
                rgba[idx + 3] = int(min(255.0, coverage * 255.0))
            else:
                rgba[idx + 3] = 0

    return bytes(rgba)

def generate_assets():
    res_dir = Path("macos-app/Sources/NotepadPlusMac/Resources")
    if not res_dir.exists():
        res_dir = Path("Sources/NotepadPlusMac/Resources")
    iconset_dir = res_dir / "AppIcon.iconset"
    iconset_dir.mkdir(parents=True, exist_ok=True)

    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    png_cache = {}
    for filename, sz in sizes:
        print(f"Rendering CodePad++ icon asset: {sz}x{sz} -> {filename}")
        if sz not in png_cache:
            rgba = render_icon(sz)
            png_cache[sz] = create_png(sz, sz, rgba)
        (iconset_dir / filename).write_bytes(png_cache[sz])

    # Build standalone AppIcon.icns
    icns_types = [
        (b'ic07', 128),
        (b'ic08', 256),
        (b'ic09', 512),
        (b'ic10', 1024),
        (b'ic11', 32),
        (b'ic12', 64),
        (b'ic13', 256),
        (b'ic14', 512),
    ]

    body = bytearray()
    for tag, sz in icns_types:
        png_data = png_cache[sz]
        chunk_len = len(png_data) + 8
        body.extend(tag)
        body.extend(struct.pack('>I', chunk_len))
        body.extend(png_data)

    icns_file = res_dir / "AppIcon.icns"
    total_len = len(body) + 8
    header = b'icns' + struct.pack('>I', total_len)
    icns_file.write_bytes(header + body)
    print(f"Generated standalone CodePad++ ICNS: {icns_file} ({len(header + body)} bytes)")

if __name__ == "__main__":
    generate_assets()
