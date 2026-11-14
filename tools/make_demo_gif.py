"""Turn simulator frames (from scripts/simrec.ps1) into a ~10 s demo GIF.

Usage: python -I tools/make_demo_gif.py <framesDir> <out.gif> "<caption>"
       python    tools/make_demo_gif.py <framesDir> <out.mp4> "<caption>"   (MP4 needs imageio-ffmpeg)

Phases are detected from the screen itself:
  menu    : before the night screen appears
  night   : dark screen with the blue/yellow "Restwise: ..." label (fast-forwarded)
  alarm   : orange "Good morning", no timeline bars
  morning : orange reason line + coloured timeline bars
Each phase gets a fixed share of the 10 seconds.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

src, out, caption = sys.argv[1], sys.argv[2], sys.argv[3]
CROP = (40, 150, 420, 540)          # watch face + bezel from the simulator window
BUDGET = {"menu": 1.4, "night": 4.6, "alarm": 1.6, "morning": 2.4}   # seconds
FPS = 12

files = sorted(f for f in os.listdir(src) if f.endswith(".png"))
frames = [Image.open(os.path.join(src, f)).convert("RGB").crop(CROP) for f in files]

def count(img, box, test):
    c = 0
    sub = img.crop(box).resize((60, 60))
    for p in sub.get_flattened_data():
        if test(p): c += 1
    return c

orange = lambda p: p[0] > 200 and 120 < p[1] < 200 and p[2] < 80
bluebar = lambda p: p[2] > 180 and p[0] < 80
W, H = frames[0].size

gray = lambda p: abs(p[0] - p[1]) < 8 and abs(p[1] - p[2]) < 8 and 70 < p[0] < 100

def band(img, x0, x1, y0, y1, test):
    return count(img, (int(W*x0), int(H*y0), int(W*x1), int(H*y1)), test)

# Thresholds calibrated on recorded frames (60x60 resample of each band):
#   morning: timeline bars  -> blue in y .60-.65  ~1500 (else 0-170)
#   alarm  : "Good morning" -> orange in y .30-.40 ~600 (else 0)
#   night  : grey clock     -> grey in y .35-.40  ~750 (menu < 70)
def phase(img):
    if band(img, .3, .7, .60, .65, bluebar) > 500: return "morning"
    if band(img, .3, .7, .30, .40, orange) > 300: return "alarm"
    if band(img, .35, .65, .35, .40, gray) > 400: return "night"
    return "menu"

ph = [phase(f) for f in frames]
# phases must be in order; anything after the first night frame can't be "menu"
seen_night = False
for i, p in enumerate(ph):
    if p == "night": seen_night = True
    if seen_night and p == "menu": ph[i] = "night"
groups = {k: [f for f, p in zip(frames, ph) if p == k] for k in BUDGET}
print({k: len(v) for k, v in groups.items()})

font = ImageFont.load_default()
try:
    font = ImageFont.truetype("arialbd.ttf", 18)
except OSError:
    pass

out_frames = []
for k in ("menu", "night", "alarm", "morning"):
    g = groups[k]
    if not g: continue
    n = max(1, int(BUDGET[k] * FPS))
    for i in range(n):
        im = g[min(len(g) - 1, int(i * len(g) / n))].copy()
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, W, 26), fill=(20, 30, 80))
        d.text((10, 4), caption, fill=(255, 255, 255), font=font)
        if k == "night":
            d.rectangle((0, H - 24, W, H), fill=(20, 30, 80))
            d.text((10, H - 22), "Real lab-recorded night, fast-forwarded", fill=(244, 211, 94), font=font)
        out_frames.append(im if out.lower().endswith(".mp4") else im.quantize(colors=128))

if out.lower().endswith(".mp4"):
    # MP4 (H.264, plays in PowerPoint/Keynote/Slides). Needs: pip install --user imageio imageio-ffmpeg
    # Run this script WITHOUT python -I so the user-installed package is found.
    import imageio.v2 as imageio
    import numpy as np
    with imageio.get_writer(out, fps=FPS, codec="libx264", quality=9,
                            pixelformat="yuv420p", macro_block_size=2) as wr:
        for im in out_frames:
            big = im.convert("RGB").resize((W * 2, H * 2), Image.LANCZOS)
            wr.append_data(np.asarray(big))
else:
    out_frames[0].save(out, save_all=True, append_images=out_frames[1:], duration=int(1000 / FPS), loop=0, optimize=True)
print("wrote", out, len(out_frames), "frames,", round(len(out_frames) / FPS, 1), "s,", os.path.getsize(out) // 1024, "KB")
