# Restwise: how to test, run and demo

## 1. Show the automated tests (about 1 minute)

Open a PowerShell terminal in `C:\Users\farta\Desktop\Garmin` and run:

```
powershell -ExecutionPolicy Bypass -File .\scripts\rw.ps1 test
```

The simulator opens (if it isn't already) and prints every test with PASS/FAIL, ending with
`Ran 44 tests  PASSED (passed=44, failed=0, errors=0)`.

What the 44 tests cover:

| File | What it proves |
|---|---|
| `Restwise/test/CoreTests.mc` | Movement → per-minute number; sleep labels: still → settled, small stir → restless, walking / heart-rate spike → awake |
| `Restwise/test/WakeTests.mc` | Feature 1: no alarm before the window, wake on first light moment, wake if already awake, wake at window end, fires once, works across midnight; night log saves/loads |
| `Restwise/test/SessionTests.mc` | A whole night: monitoring → in window → alarm; snooze/dismiss; safety timer still rings if sensors stop; "Stop tonight" |
| `Restwise/test/GoalTests.mc` | Feature 2: awake minutes don't count, 15-min margin, wake on light moment after goal, 20-min max wait, latest time always wins |
| `Restwise/test/GoalSessionTests.mc` | Feature 2 through a whole night; older saved settings still load |
| `Restwise/test/UiLogicTests.mc` | Window edit rules, 5-minute picker, morning screen texts |

Good line for the pitch: "Every rule of the alarm is covered by an automated test. Here are 44 of them passing."

## 2. Run the app and the live demo

```
powershell -ExecutionPolicy Bypass -File .\scripts\rw.ps1 run
```

Watch buttons in the simulator. **Click the buttons on the watch picture with the mouse**; keyboard keys are unreliable:

| Watch button | Where on the picture | Does |
|---|---|---|
| START | top right | select / stop alarm |
| BACK | bottom right | back / snooze |
| UP | middle left | move up / raise a number |
| DOWN | bottom left | move down / lower a number |

**Demo, Feature 1 (Smart Wake Window):**
1. Home menu: check **Mode = Smart window** and "Wake 6:30–7:00".
2. Press DOWN until **Demo night**, then press START.
3. A real lab-recorded night plays in about 45 s. The screen shows the time, "Restwise: settled/restless/awake" and the sleep lab's own label.
4. At 6:30 it switches to "In window – waiting for light sleep". At **6:43** the alarm fires on a light moment.
5. Press START. The morning screen shows "Woke you at 6:43 · You were in a light, restless phase · 17 min before deadline", plus the night timeline.

**Demo, Feature 2 (Quality Sleep Goal):**
1. Home menu: select **Mode** (START) to switch to **Sleep goal**.
2. Select **Demo night**. The demo uses a 3 h goal so it completes on stage.
3. The night screen shows "Banked 1h 38m…" climbing. The alarm fires at **8:58** after the goal is banked.
4. Press START. "Goal banked, light sleep moment · Banked 3h 27m of 3h 00m".

## 3. Ten-second videos for the slides

Both are animated GIFs, which play automatically in PowerPoint and Google Slides (Insert → Image):

- `demo/Restwise_Feature1_SmartWindow.gif`: menu → night fast-forward → 6:43 alarm → "why I woke you"
- `demo/Restwise_Feature2_SleepGoal.gif`: goal mode → bank filling → 8:58 alarm → "Banked 3h 27m of 3h 00m"

To re-record after changes: `scripts/simrec.ps1` captures frames and `tools/make_demo_gif.py` builds the GIF. The exact commands are at the top of each file.

## 4. Known limits (say these honestly if asked)

- Shown in the simulator with a **real recorded night** (PhysioNet, Walch 2019). It has not been worn overnight on a real watch yet.
- Vibration and tone can only be felt and heard on a real watch.
- Sleep labels are our own estimate from movement and heart rate (Garmin doesn't give apps its sleep stages). They agree with the sleep lab 90.6% for asleep vs awake.
