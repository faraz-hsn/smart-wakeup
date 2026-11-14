# Sleep app: architecture and build plan (Feature 1 first)

Status: **DRAFT, waiting for your approval.** Nothing gets built until you approve.

## 1. Guiding rules

1. **Layers, built from the bottom up.** Each layer only talks to the layer directly below it, through a small, defined set of functions. Example: the sleep engine never touches the watch's sensors directly.
2. **The core logic is pure.** The code that decides "awake / restless / settled" and "wake now?" has no screens, sensors or clock calls inside. That lets us test it with fake data on the laptop, in seconds, before any watch is involved.
3. **Every data source can be swapped.** The app reads sensors through one shared contract. "Live watch sensors", "replayed recorded night" and "test data" all fulfil the same contract, so the same app runs on a real wrist, in the demo and in tests.
4. **One step at a time.** Each step ends with: it compiles, its tests pass, I show you the result, and **you approve before the next step.**
5. **You decide product questions.** When a choice changes what the user sees, how it behaves, or how we pitch it, I stop and ask. I only decide pure plumbing (file names, variable names, internal structure inside a layer), and I list those decisions in `docs/DECISIONS.md` so you can see and overrule them.

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ 5. UI layer (what the user sees and presses)                 │
│    SetupView · NightView · AlarmView · MorningView           │
│    + their button handlers ("delegates")                     │
├──────────────────────────────────────────────────────────────┤
│ 4. Session layer (runs one night from start to finish)       │
│    NightSession: IDLE → MONITORING → IN_WINDOW → ALARMING →  │
│                  DONE                                        │
│    connects sensors → engine → wake logic → alarm → storage  │
├──────────────────────────────────────────────────────────────┤
│ 3. Core logic (pure, fully unit-tested)                      │
│    EpochAggregator   raw motion → 1 number per minute        │
│    SleepStateEngine  minute → AWAKE / RESTLESS / SETTLED     │
│    SmartWakeDecider  "wake now?" + the reason why            │
├──────────────────────────────────────────────────────────────┤
│ 2. Platform layer (the only code that touches the watch)     │
│    SensorSource  ← LiveSensorSource | ReplaySensorSource     │
│    AlarmDriver   (ramping vibration, tone, snooze)           │
│    Clock         ← RealClock | FastClock (demo fast-forward) │
│    Store         (settings + night log in watch storage)     │
├──────────────────────────────────────────────────────────────┤
│ 1. Foundation                                                │
│    constants, enums, settings model, logging helper          │
└──────────────────────────────────────────────────────────────┘
```

**How data flows during a night:**
1. The **SensorSource** delivers motion (25 readings a second) and heart rate (once a second).
2. The **EpochAggregator** turns each minute of motion into one activity number.
3. The **SleepStateEngine** labels that minute AWAKE, RESTLESS or SETTLED, using motion plus heart rate against tonight's baseline.
4. The **SmartWakeDecider** looks at the label and the time. Before the window: keep sleeping. In the window and restless: wake now. At the window end: wake now.
5. When it decides to wake, it records the reason, and the **AlarmDriver** starts the ramping alarm.
6. The **Store** saves every minute's label and the wake reason. The **MorningView** shows "Woke you at 6:41 because…".

## 3. Folder structure

```
Garmin/
  SleepApp/                      ← the Connect IQ project
    manifest.xml                 app id, permissions, Fenix 7 Pro
    monkey.jungle                build config (app build + test build)
    source/
      foundation/                Constants.mc, Types.mc, Log.mc, Settings.mc
      platform/                  SensorSource.mc, LiveSensorSource.mc,
                                 ReplaySensorSource.mc, AlarmDriver.mc,
                                 Clock.mc, Store.mc
      core/                      EpochAggregator.mc, SleepStateEngine.mc,
                                 SmartWakeDecider.mc
      session/                   NightSession.mc
      ui/                        SetupView.mc, NightView.mc, AlarmView.mc,
                                 MorningView.mc, *Delegate.mc
      App.mc                     entry point
    test/                        unit tests for core/ (Toybox.Test)
    resources/                   strings, icons, layouts, app settings
    resources-demo/              replay night data (demo build only)
  tools/                         Python: PhysioNet → replay data,
                                 offline engine check, log viewer
  scripts/                       build.ps1, run-sim.ps1, test.ps1
  docs/                          PLAN.md (this), DECISIONS.md, ARCHITECTURE.md
```

We use **git** from step 0 (one commit per approved step), so any step can be undone. The developer key stays outside the project and is never committed.

## 4. Step-by-step plan for Feature 1 (Smart Wake Window)

| Step | What gets built | How we check it | You approve |
|---|---|---|---|
| **0. Project setup** | Folder, git, manifest (Fenix 7 Pro, permissions), build/run/test scripts, an empty app that launches | App opens in simulator; `test.ps1` runs | ✔ |
| **1. Foundation** | Enums (AWAKE/RESTLESS/SETTLED, session states), settings model (window start/end, alarm style), logging helper | Compiles; tiny tests | ✔ |
| **2. Platform: sensors + clock** | `SensorSource` contract, `LiveSensorSource` (motion 25 Hz, HR, beat intervals), `ReplaySensorSource`, `RealClock`/`FastClock` | Debug screen in simulator showing live numbers; replay feeds the same numbers from a file | ✔ |
| **3. Core: EpochAggregator** | Raw motion → one activity number per minute | Unit tests with synthetic motion (still / fidget / walking) | ✔ |
| **4. Core: SleepStateEngine** | Cole-Kripke + heart-rate rescoring + "settled" rule → label per minute | Unit tests; plus a Python check on one real PhysioNet night comparing our labels with the sleep lab's | ✔ |
| **5. Core: SmartWakeDecider** | Window logic + reason text | Unit tests for every case (restless early in window, never restless, window already passed, etc.) | ✔ |
| **6. Platform: AlarmDriver** | Ramping vibration → tone, repeat until dismissed, snooze | Run in simulator, feel the pattern on a real watch if available | ✔ |
| **7. Platform: Store** | Save settings and the night log (one label per minute + wake reason) | Write/read test; survives app restart | ✔ |
| **8. Session layer** | `NightSession` state machine wiring it all together | Fast-forward replay night in simulator: watch the states change and the alarm fire at the right minute | ✔ |
| **9. UI** | Setup screen, dark night screen, alarm screen, morning "why I woke you" screen | Click through in simulator; screenshots to you | ✔ |
| **10. Demo mode + hardening** | Fast-forward replay of a real night, memory check, crash guards, real-watch checklist | Full demo run end to end | ✔ |

Feature 2 (Quality Sleep Goal) reuses steps 1–4 and 6–7 almost unchanged. It adds a second "decider" next to `SmartWakeDecider`. Features 3 and 4 add a background service and more screens later.

## 5. Decisions made by you (14 Nov 2026)

| Decision | Your choice |
|---|---|
| App name | **Restwise** (project folder becomes `Restwise/` instead of `SleepApp/`) |
| How the user sets the wake window | **Start time and end time**, set separately |
| Screen during the night | **Dark + tiny status** (small clock + window). Live sleep state only in demo mode |
| Demo data | **Real PhysioNet night**, fast-forwarded, with our labels next to the sleep lab's |
