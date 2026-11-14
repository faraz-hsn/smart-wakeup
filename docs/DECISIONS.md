# Technical decisions log

Small technical choices made inside a layer. Product decisions are in PLAN.md section 5. Overrule anything here.

| # | Step | Decision | Why |
|---|---|---|---|
| 1 | 0 | One git repo at `Garmin/` (code, docs, reports, scripts, tools); SDK Manager and research notes excluded | Docs and reports are versioned with the code |
| 2 | 0 | Developer key stays at `%USERPROFILE%\.connectiq\developer_key.der`, never committed | Signing key must not leak |
| 3 | 0 | Unit tests in `Restwise/test/`, compiled only in the test build (`rw.ps1 test`) | Keeps tests out of the shipped app |
| 4 | 0 | `Background` permission removed until Feature 3 needs it | Avoids loading the whole app as a background process |
| 5 | 0 | Target device list: only `fenix7pro` for now | Hackathon device; others added later if wanted |
| 6 | A | Activity per minute = mean of \|accel magnitude − 1 g\| in milli-g (ENMO-style), accel at 25 Hz | Device-independent, works for live watch and PhysioNet replay alike |
| 7 | A | Cole-Kripke made *causal* (only current + 4 past minutes); scale P so steady 10 mG ⇒ D = 1 | Smart wake must decide in real time, can't wait for future minutes. On PhysioNet 46343: 90.6% sleep/wake agreement with the lab |
| 8 | A | SETTLED needs 10+ still minutes, HR ≤ baseline +5%, HR std ≤ 3 bpm; AWAKE if moving with HR +10% or walking, or HR +25% alone | Rules from the report (section 2.0) |
| 9 | A | HR baseline: resting HR from the user profile, then slow average over still minutes (~30 min memory) | Adapts to each night |
| 10 | A | Replay data = per-minute rows in a JSON resource (~6 KB for a night) | Raw 50 Hz data (45 MB) would not fit on the watch |
