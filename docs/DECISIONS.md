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
| 11 | B | In the window, an AWAKE minute also triggers the alarm (reason "already awake") | No point waiting if the user is already up |
| 12 | B | Wake window computed as absolute times at bedtime: next occurrence of the start time | Handles going to bed before or after midnight |
| 13 | B | Alarm ramp: pulses every 10 s at 25→50→75→100% strength, tone added after 60 s (your choice), snooze 5 min (your choice) | Report F5 |
| 14 | B | Night log stored as one character per minute ("0/1/2"), only the last night kept | ~600 bytes per night; history comes with Feature 4 |
| 15 | C1 | Sensors switch off as soon as the alarm starts | Saves battery; the night's decision is already made |
| 16 | C1 | Live-mode watchdog: if no minute arrives for 2.5 min, the decider runs on the last known state every minute | An alarm app must still ring at window end if sensors stall |
| 17 | C1 | Your choices: START = Dismiss, BACK = Snooze; time picker in 5-min steps | Product decisions (asked) |
| 18 | C | Window edit rules: start moved past end → end = start + 30 min; end moved before start → start = end − 30 min; minimum window 10 min | Never lets the user save an impossible window |
| 19 | C | Home = menu: Go to sleep / Wake from / Wake by / Last night (when one exists) | Standard Garmin menu style, 2 presses to start a night |
| 20 | C | BACK during the night asks "Stop tonight?" before ending | Avoids ending the night by an accidental press |
| 21 | C | Demo screen extras (our label, lab label, HR) only when the source is a replay | Your choice: dark night screen in real use |
| 22 | D | Engine: a single minute ≥ 8 mG ("stir", e.g. turning over) breaks stillness → RESTLESS | Real-night check showed lone stirs were missed; sleep/wake agreement unchanged at 90.6% |
| 23 | D | Demo aligns data minute 225 with the user's window start; after the data ends it pads quiet minutes | Window covers the night's last hour; long windows still reach their end |
| 24 | D | Your choices: visible "Demo night" menu item, ~45 s night (150 ms/minute), 10 s snooze in demo | Product decisions (asked) |
| 25 | D | Time picker: 2 columns (hour, ":mm"), blue/grey text, smaller font | 3 columns overflowed the round screen; white text vanished on the white picker background |
