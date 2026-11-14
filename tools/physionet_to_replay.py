"""Convert one PhysioNet sleep-accel night into Restwise replay rows, and check
our sleep engine against the sleep-lab labels.

Usage:  python -I tools/physionet_to_replay.py tools/data/physionet 46343 Restwise/resources/demo/demo_night.json

Input (Walch et al. 2019, https://physionet.org/content/sleep-accel/):
  <id>_acceleration.txt  "t x y z"  (seconds from PSG start, g units, ~50 Hz)
  <id>_heartrate.txt     "t,bpm"
  <id>_labeled_sleep.txt "t stage"  (30 s epochs; -1 n/a, 0 wake, 1-3 NREM, 5 REM)
Output JSON: {"rows": [[min, activity_mG, hrMean|-1, hrStd|-1, lab|-1], ...]}
  lab mapped to Restwise states: wake->0 AWAKE, N3->2 SETTLED, N1/N2/REM->1 RESTLESS.
"""
import json, math, sys, os

src, sid, out = sys.argv[1], sys.argv[2], sys.argv[3]
labels = {}
for line in open(os.path.join(src, f"{sid}_labeled_sleep.txt")):
    t, st = line.split()
    labels[int(float(t)) // 60 * 60 + 0] = labels.get(int(float(t)) // 60 * 60, []) + [int(st)]
t_end = max(labels) + 60
n_min = t_end // 60

acc_sum = [0.0] * n_min; acc_n = [0] * n_min
for line in open(os.path.join(src, f"{sid}_acceleration.txt")):
    p = line.split()
    t = float(p[0])
    if t < 0 or t >= t_end: continue
    x, y, z = float(p[1]), float(p[2]), float(p[3])
    m = int(t // 60)
    acc_sum[m] += abs(math.sqrt(x*x + y*y + z*z) - 1.0) * 1000.0
    acc_n[m] += 1

hr = [[] for _ in range(n_min)]
for line in open(os.path.join(src, f"{sid}_heartrate.txt")):
    t, b = line.strip().split(",")
    t = float(t)
    if 0 <= t < t_end: hr[int(t // 60)].append(float(b))

def lab_state(stages):
    s = [x for x in stages if x >= 0]
    if not s: return -1
    if 0 in s: return 0
    if all(x == 3 for x in s): return 2
    return 1

rows = []
for m in range(n_min):
    act = acc_sum[m] / acc_n[m] if acc_n[m] else 0.0
    h = hr[m]
    hm = sum(h) / len(h) if h else -1
    hs = math.sqrt(max(0.0, sum(v*v for v in h) / len(h) - hm*hm)) if h else -1
    rows.append([m, round(act, 1), round(hm, 1), round(hs, 1), lab_state(labels.get(m * 60, []))])

# ---- Python port of SleepStateEngine (must match source/core/SleepStateEngine.mc) ----
W = [106, 54, 58, 76, 230]; P = 1 / (524 * 10)
hist = [0.0] * 5; still = 0; asleep = False; base = None; ours = []
for m, act, hm, hs, lab in rows:
    hist = hist[1:] + [act]
    d = P * sum(w * a for w, a in zip(W, hist)); moving = d >= 1
    still = 0 if (moving or act >= 8) else still + 1
    if not asleep and still >= 10: asleep = True
    h = None if hm < 0 else hm
    if h is not None and not moving:
        if base is None: base = h
        elif asleep: base += (h - base) / 30
    if not asleep: st = 0
    else:
        hh = h is not None and base and h > base * 1.10
        vh = h is not None and base and h > base * 1.25
        nb = h is None or base is None or h <= base * 1.05
        steady = hs < 0 or hs <= 3
        if vh or (moving and (hh or act >= 100)): st = 0
        elif still >= 10 and nb and steady: st = 2
        else: st = 1
    ours.append(st)

pairs = [(o, r[4]) for o, r in zip(ours, rows) if r[4] >= 0]
sw = sum((o == 0) == (l == 0) for o, l in pairs) / len(pairs)
wake_lab = [o for o, l in pairs if l == 0]
sleep_lab = [o for o, l in pairs if l != 0]
print(f"minutes={len(rows)} labelled={len(pairs)}")
print(f"sleep/wake agreement: {sw:.1%}")
print(f"lab-wake minutes we called awake: {sum(o == 0 for o in wake_lab)}/{len(wake_lab)}")
print(f"lab-sleep minutes we called asleep: {sum(o != 0 for o in sleep_lab)}/{len(sleep_lab)}")
print("activity mG percentiles (labelled sleep):",
      sorted(r[1] for r in rows if r[4] > 0)[len(sleep_lab)//2], "median")
print("our label counts:", {k: ours.count(k) for k in (0, 1, 2)})

os.makedirs(os.path.dirname(out), exist_ok=True)
json.dump({"rows": rows}, open(out, "w"), separators=(",", ":"))
print("wrote", out, os.path.getsize(out), "bytes")
