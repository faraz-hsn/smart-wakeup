# Sleep app for the Fenix 7 Pro: features, sensors and build plan

**What this is.** A Connect IQ watch app for people whose sleep matters to them. It has two kinds of user. **Group A** has to be up by a certain time, and wants to be woken at the gentlest moment inside a window they choose, for example 6:30–7:00. **Group B** has no fixed alarm (weekends, shift workers, people between jobs) but wants a full tank: "wake me once I've had 7 hours of *good* sleep", even if that takes 8 or 9 hours in bed. Both groups get a morning report of their night. The report includes the moments they woke, got up or walked around (bathroom, a glass of water), and it flags walking they may not remember, a possible sign of sleepwalking.

**Bottom line of the checks.**
- **Feature 2 (quality-sleep goal wake) and feature 3 (night events and sleepwalking report) exist on no Garmin watch.** That includes the Fenix 7 Pro, the Fenix 8 and the new Fenix 9.
- **Feature 1 (smart wake window) is missing on the Fenix 7, 7 Pro and Epix**, but newer Garmins have a fixed 30-minute version that users complain rarely works.
- The closest competitor to feature 2 is WHOOP, which needs its own band and a subscription. It counts plain hours, not quality hours, and only fires inside a fixed 1-hour window.
- Every piece of data the app needs is available to a Connect IQ app on the Fenix 7 Pro. We confirmed this by running a test app in the simulator (section 4).
- One hard limit shapes the design: **Garmin does not let apps read its own sleep stages.** The app works out sleep state itself from movement and heart rate, which is how all the published methods we rely on work.

---

## 1. The features

| # | Feature | Who it's for | One line |
|---|---|---|---|
| F1 | **Smart Wake Window** | Group A | You pick the window (any length, e.g. 6:30–7:00). The watch wakes you at your lightest moment in it, or at the end at the latest. |
| F2 | **Quality Sleep Goal** | Group B | You pick a goal (e.g. 7 h of quality sleep) and a latest-possible time. The watch counts only *good* sleep minutes and wakes you, in a light moment, once the goal is banked. |
| F3 | **Night Events and Sleepwalking Check** | Everyone | The watch logs each time you woke, got out of bed or walked during the night: when, how long, how many steps, whether you changed floors or went outside. Walking that started straight out of deep sleep is flagged as "Do you remember this?" |
| F4 | **Morning Sleep Report** | Everyone | One screen that explains your night: quality hours vs time in bed, sleep efficiency, awakenings, a timeline, heart rate and temperature through the night, blood-oxygen trend, Body Battery recharge, and *why* the alarm fired when it did. |
| F5 | **Gentle, insistent alarm** | Groups A and B | Vibration that starts soft and ramps up, keeps going until you dismiss it, and has a snooze. This fixes the most common complaint about existing smart alarms. |

F1 and F2 are two modes of the same alarm: you choose "Window" or "Goal" at bedtime. F3 and F4 run every night in both modes.

---

## 2. Each feature: what it does, which sensors (bonus points), how we build it

Two terms are used throughout:
- **Epoch:** a 1-minute block of time. The app scores every minute of the night as *awake*, *restless* (light) or *settled* (deep/stable).
- **Sleep-state engine:** the shared code that does that scoring. F1, F2, F3 and F4 all sit on top of it.

### 2.0 The shared sleep-state engine (the core of the app)

**What it does.** For every minute of the night it decides whether you are awake, sleeping lightly or sleeping deeply/stably. Each decision is based on how much your wrist moved, your heart rate compared with your own baseline that night, and how steady your heartbeat is.

**Why we can't just ask Garmin.** Connect IQ apps cannot read Garmin's sleep stages; Garmin calculates them mostly after the watch syncs. The Garmin developer forums confirm this ([forum](https://forums.garmin.com/developer/connect-iq/f/app-ideas/390116/new-sleep-management-and-smart-alarm-app); [forum](https://forums.garmin.com/developer/fit-sdk/f/discussion/371792/does-garmin-have-sleep-api-that-can-provide-when-someone-is-in-deep-rem-sleep-for-alarm-clock)). So the app does its own scoring, using published methods.

**How (algorithm).**
1. **Movement → sleep/wake.** Every minute, the app converts the raw accelerometer stream into an "activity count" and applies the **Cole-Kripke formula**: a weighted sum of the last few minutes of activity. Under the threshold the minute is sleep, over it the minute is wake (Cole et al. 1992, *Sleep* 15:461–469). A second check from van Hees (2015) treats less than 5° of wrist-angle change over 5 minutes as stable sleep.
2. **Heart rate corrects movement's blind spot.** Lying still while awake fools a movement-only method. So a minute is re-scored as *awake* if heart rate is more than about 10% above that night's baseline, or if heart rate is jumpy and the wrist is moving.
3. **Light vs deep/stable.** A minute counts as *settled* when the wrist has been still for 10+ minutes, heart rate is near the night's lowest, and the heartbeat is steady (low variation between beats). Otherwise it counts as *restless/light*.

**Expected accuracy, honestly stated.** Research using the same signals (Apple Watch movement and heart rate) gets about **90% of minutes right for sleep vs wake**. Detecting true wake is weaker, at about 60% ([Walch et al. 2019, SLEEP](https://pmc.ncbi.nlm.nih.gov/articles/PMC6930135)). Light vs deep from movement and heart rate is roughly **60–70%** at best. Consumer devices, Garmin included, are all imperfect at this ([Chinoy et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8120339)). We present results as "settled/restless/awake", not as lab-grade sleep stages.

**Sensors (bonus points):** accelerometer, gyroscope (wrist rotation helps catch turning over), optical heart rate and beat-to-beat intervals.

### F1. Smart Wake Window (Group A)

**What it does.**
- At bedtime you set a window, for example 6:30–7:00 or 6:00–7:00 if you like.
- Inside the window, the watch wakes you at the **first restless/light moment**, such as a stir, a turn or a heart-rate rise.
- If no such moment comes, it wakes you at the end of the window.
- In the morning it tells you why: "Woke you at 6:41 because you turned over and your heart rate rose; you were in a restless phase."

**Why it's worth building.**
- **Waking out of deep sleep makes people groggier for longer** (sleep inertia, usually 15–30 minutes) than waking from light sleep (Tassi & Muzet 2000, *Sleep Medicine Reviews*; [Trotti 2017](https://pubmed.ncbi.nlm.nih.gov/27692973/)). We pitch it as a **gentler wake-up**, not a proven performance boost: a 2024 trial of a bedroom smart alarm found no measurable benefit ([2024 study](https://pmc.ncbi.nlm.nih.gov/articles/PMC10969141)).
- **The Fenix 7 / 7 Pro / Epix do not have Smart Wake.** Owners have asked for it for years ([Fenix 7 forum](https://forums.garmin.com/outdoor-recreation/outdoor-recreation/f/fenix-7-series/352090/feature-request-smart-wake-up-alarm); ["why is there no sleep-cycle alarm"](https://forums.garmin.com/outdoor-recreation/outdoor-recreation/f/fenix-7-series/366954/fenix-7-pro-why-is-there-no-sleepcycle-alarm)). The Fenix 7 Pro now gets bug fixes only, so Garmin won't add it.
- **On newer Garmins** the built-in version has a fixed 30-minute window you can't change ([Garmin manual](https://www8.garmin.com/manuals/webhelp/GUID-2CF5620C-E585-4E0A-9CC3-9565533EEE4D/EN-US/GUID-5F030BAF-DBBA-4201-A99C-5F3E1C16CC4D.html)). Users report it **never goes off early**, and the early buzz is faint and stops if ignored ([Forerunner 970 thread](https://forums.garmin.com/sports-fitness/running-multisport/f/forerunner-970/430203/smart-wake-alarm-has-never-gone-off-early)). Our window length is yours to choose, the alarm is insistent, and the explanation of why it fired is unique.

**How we build it.**
- The engine runs from bedtime.
- From the window start, every new minute is checked: is it restless/light, with movement and a heart-rate uptick? If yes, start the alarm (F5).
- At the window end, start the alarm regardless.

**Sensors:** accelerometer and gyroscope (the stir), heart rate (the uptick), vibration motor (the alarm itself; an actuator, not a bonus sensor).

### F2. Quality Sleep Goal (Group B)

**What it does.**
- You set a goal such as "7 h of quality sleep" plus a safety *latest* time such as 10:30.
- Only *settled* and normal *light* minutes count toward the goal. Awake minutes and very restless minutes don't.
- When the bank reaches 7 h, the watch waits for the next light moment and wakes you.
- If the goal can't be met by the latest time, it wakes you then and says why: "You banked 6 h 20 m; you were awake 52 minutes between 2:00 and 3:30."

**Why it's worth building.**
- **Sleep scientists recommend 7+ hours of actual sleep, not time in bed** (AASM/SRS consensus, Watson et al. 2015). People don't notice their own sleep debt: after two weeks of 6-hour nights, people performed as badly as after up to two nights with no sleep, yet barely felt sleepier (Van Dongen 2003).
- **Nothing on Garmin does this on any model.** Garmin's Sleep Coach calculates how much sleep you need (7–9 h) but never sets an alarm from it ([Garmin blog](https://www.garmin.com/en-SG/blog/fitness/five-factors-garmin-sleep-coach-uses-to-find-your-sleep-needs/)). Fenix 7 owners asked for exactly that link ([forum](https://forums.garmin.com/outdoor-recreation/outdoor-recreation/f/fenix-7-series/356904/feature-request-sleep-coach-sleep-notification-and-alarm-clock)).
- **WHOOP is the closest product, and users complain about it** ([WHOOP](https://www.whoop.com/thelocker/new-whoop-4-0-feature-sleep-coach-with-haptic-alerts)):
  - It only fires within a fixed 1-hour window before your latest wake time ([user request, 2026](https://www.community.whoop.com/t/feature-request-whoop-sleep-goal-alarm-with-unbounded-time-window/14636)).
  - It isn't sleep-stage aware ([request](https://www.community.whoop.com/t/feature-request-sleep-stage-aware-smart-wake-alarm/14612)).
  - Its vibration doesn't ramp up ([request](https://www.community.whoop.com/t/feature-request-progressive-adjustable-haptic-alarm-intensity/15054)).
  - It counts plain hours.
  - It needs WHOOP hardware and a subscription.
- A few small phone or Apple Watch apps wake you after a set *duration*, such as Sleepest and AwakeSync. **We found nothing anywhere that counts only *quality* sleep.**

**How we build it.**
- Running total: `bank += 1 minute` for each settled or light epoch after sleep onset. Awake and very restless epochs don't count.
- Trackers tend to miss short awakenings and over-count sleep by roughly 10–30 minutes, so we add a small safety margin (e.g. +15 min).
- Once `bank ≥ goal + margin`, wake at the next light moment, or within 20 minutes at the latest.
- Hard stop at the latest time.

**Sensors:** accelerometer, gyroscope, heart rate and beat intervals (via the engine), vibration motor.

### F3. Night Events and Sleepwalking Check (everyone)

**What it does.** In the morning:
- A list of night events, for example "02:47 – awake 6 min, got up, walked 38 steps (likely bathroom)" or "04:10 – awake 3 min in bed".
- For each walking episode: start time, duration, steps, whether you went down or up a floor, and whether you left the house.
- If a walking episode started straight out of settled sleep, with no awake minutes before it and no button pressed on the watch, the app asks: **"You walked for 4 min at 1:12 and seemed asleep just before. Do you remember this?"** If you say no, it's logged as possible unrecalled walking. Over time this builds a picture you could show a doctor.

**Why it's worth building.**
- **Night-time bathroom trips (nocturia) are very common**, especially after 40, and are one of the main causes of broken sleep.
- **Garmin handles them badly.** Users complain that getting up for the bathroom ends their recorded sleep or wipes hours of it, and Garmin staff called that "working as designed" ([Venu 3 thread](https://forums.garmin.com/sports-fitness/healthandwellness/f/venu-3-series/419021/venu-3-cutting-off-sleep); [Forerunner 70](https://forums.garmin.com/sports-fitness/running-multisport/f/forerunner-70/439743/sleep-stages-not-being-recorded-correctly)).
- **Garmin shows no list of out-of-bed or walking events on any model, and has no sleepwalking feature.** On its Index sleep armband, Garmin staff said night steps were not intended ([forum](https://forums.garmin.com/sports-fitness/healthandwellness/f/index-sleep-monitor/417663/steps-missing-from-sleep-monitor)).
- **Sleepwalking is more common than people think:**
  - About **3.6% of US adults sleepwalked in the past year**, and some don't know they do, especially people who live alone ([Ohayon 2012, Neurology](https://pmc.ncbi.nlm.nih.gov/articles/PMC3467644); [Stanford](https://med.stanford.edu/news/all-news/2012/05/sleepwalking-more-prevalent-among-u-s-adults-than-previously-suspected-researcher-says.html)).
  - In a clinic study of 100 adult sleepwalkers, 58% had violent episodes and 17% had injuries needing medical care ([Lopez 2013](https://pubmed.ncbi.nlm.nih.gov/23450499/)).
- **What exists elsewhere:** a couple of new Apple Watch apps that *sound an alarm* on unusual night movement, and medical bed-exit mats. None gives a morning report of night walks with times and durations ([Sleepwalk Guard](https://apps.apple.com/app/id6760451524); [NightBell](https://apps.apple.com/us/app/nightbell/id6449867229), which reviewers say gives false alarms).

**Honest limit.** No watch can medically prove sleepwalking; no study validates that. We **flag and ask**, never diagnose.

**How we build it.**
1. **Walking episode detection:**
   - Watch the step counter and accelerometer cadence.
   - An episode starts at 5 or more steps within a minute and ends after 2 still minutes.
   - Record start, end, steps and heart rate.
2. **Floor change:** compare barometric pressure at the start and end of the episode. About 0.35–0.4 hPa equals one floor; research shows barometers detect floor *changes* very reliably.
3. **Left the house?**
   - Only when an episode lasts longer than about 2 minutes, the app switches GPS on briefly.
   - A fix more than about 30 m from the bedtime fix means you went outside.
   - GPS doesn't work well indoors, so it is not used to see bathroom trips. It's used only for "did you go outside?", which is a real safety question for sleepwalkers.
4. **"Do you remember?" flag:** all of these must be true:
   - the episode started from settled sleep (no awake minutes in the 3 minutes before)
   - no button presses
   - it happened in the first half of the night, when sleepwalking typically happens
   - it lasted at least 1 minute
5. **Morning prompt:** Yes/No, saved to the watch's storage.

**Sensors (bonus points):** accelerometer and step counter (walking), barometer (floor change), GPS (left the house, only when triggered), heart rate (awake vs asleep before the walk), gyroscope.

### F4. Morning Sleep Report (everyone)

**What it does.** One screen, then a scrollable detail view:
- **Headline:** quality hours vs time in bed, e.g. "6 h 52 m quality sleep in 7 h 40 m in bed – 89% efficient".
- **Score against the National Sleep Foundation's quality markers** (Ohayon et al. 2017, *Sleep Health*): fell asleep within 30 min, efficiency ≥ 85%, ≤ 20 min awake after first falling asleep, ≤ 1 awakening longer than 5 min. Each is a green tick or a red cross with the real number.
- **Night timeline:** awake / restless / settled bars, with F3 events marked.
- **Body signals overnight:** lowest and average heart rate, skin-temperature curve, blood-oxygen trend (flagged as "possible dips", never "apnea"; wrist SpO2 has about 3% error), and Body Battery recharge.
- **Alarm explanation** from F1/F2.

**Why it's worth building.** Users say Garmin gives them numbers without explaining them. Our report is built around plain-language reasons.

**How we build it.** The engine's per-minute results are stored on the watch. The overnight signals come from the watch's own stored histories, which we verified exist (section 4). The report is drawn with the standard Connect IQ drawing API.

**Sensors (bonus points):** heart rate, skin temperature, Pulse Ox (SpO2), accelerometer, plus the derived stress and Body Battery histories.

### F5. Gentle, insistent alarm (part of F1 and F2)

**What it does.** Soft vibration pulses that get stronger and longer every 20 seconds, then a tone. It repeats until you press a button, and a snooze is available.

**Why.** It fixes named complaints: Garmin's early buzz is faint and stops if ignored, and WHOOP's vibration doesn't ramp up (sources in F1/F2).

**How.** `Attention.vibrate` with a list of vibration steps of rising strength, plus `Attention.playTone`, in a loop until a button press. Confirmed available in the simulator (section 4).

### Sensor scorecard

| Sensor | Real job in the app | Feature(s) |
|---|---|---|
| **Accelerometer** | Movement per minute (sleep/wake), stirs (smart wake), steps and walking episodes | Engine, F1, F2, F3 |
| **Gyroscope** | Wrist rotation: turning over (light sleep), more robust stillness | Engine, F1, F3 |
| **Optical heart rate** | Night baseline, arousal upticks, awake confirmation, overnight curve | Engine, F1, F2, F3, F4 |
| **Beat-to-beat intervals (HRV)** | Steady heartbeat = settled sleep | Engine, F4 |
| **Skin temperature** | Overnight temperature curve, sleep-onset cue (wrist warms as you fall asleep) | F4 |
| **Pulse Ox (SpO2)** | Overnight oxygen trend, possible dips | F4 |
| **Barometer** | Floor change during night walks | F3 |
| **GPS** | Did you leave the house during a night walk (only switched on when one is detected) | F3 |
| *(Vibration motor)* | The alarm. An actuator, so we don't claim it as a sensor | F1, F2, F5 |

That's **8 genuine sensor uses**, each answering a specific question. We deliberately leave out the **compass**: it has no honest job in a sleep app, and judges can tell when a sensor is decorative.

---

## 3. Does it already exist? (checked as of 14 Nov 2026)

### On Garmin, by model

| Model | F1 Smart wake window | F2 Quality-sleep goal wake | F3 Night events / sleepwalking | Note |
|---|---|---|---|---|
| **Fenix 7 / 7 Pro / Epix (Gen 2, Pro)** | **No** | **No** | **No** | Bug-fix-only now, so Garmin won't add them. **Our app adds all three.** |
| Fenix 8 / 8 Pro | Fixed 30 min | No | No | Smart Wake since Aug 2025 (software 17.28) |
| Fenix E, Enduro 3 | Fixed 30 min | No | No | Fenix 8-family update |
| **Fenix 9** (Aug 2026) | Fixed 30 min (retailer listings; Garmin's own list not verified) | **No** | **No** | Also has Evening Report and Sleep Alignment, neither an alarm |
| Forerunner 970 / 570 | Fixed 30 min | No | No | Complaints it never fires early |
| Venu 4, vívoactive 6 | Fixed 30 min | No | No | vívoactive 6 had it first (2025) |
| Instinct 3 | Fixed 30 min | No | No | Added early 2026, with bug fixes since |
| Index Sleep Monitor (armband) | Fixed 30 min | No | No | Doesn't count night steps |

Sources: [Garmin Venu 4 manual](https://www8.garmin.com/manuals/webhelp/GUID-2CF5620C-E585-4E0A-9CC3-9565533EEE4D/EN-US/GUID-5F030BAF-DBBA-4201-A99C-5F3E1C16CC4D.html), [vívoactive 6 manual](https://www8.garmin.com/manuals/webhelp/GUID-8C2C402F-55AC-431F-9CF2-1442B89CE149/EN-US/GUID-5F030BAF-DBBA-4201-A99C-5F3E1C16CC4D.html), [Garmin update blog](https://www.garmin.com/en-AU/blog/garmin-rolls-out-new-feature-updates-for-select-smartwatches-and-cycling-computers/), [the5krunner on Fenix 9](https://the5krunner.com/2026/08/26/garmin-fenix-9-all-you-need-to-know/), [Notebookcheck on Instinct](https://www.notebookcheck.net/Garmin-fixes-Smart-Wake-alarm-issue-in-new-beta-update.1225427.0.html), [Garmin sleep-score blog](https://www.garmin.com/en-US/blog/fitness/how-garmin-watches-track-your-sleep-calculate-sleep-score/).

**What this means:**
- **On the Fenix 7 Pro all three features are new.**
- **On the Fenix 8, Fenix 9 and every other current Garmin, F2 and F3 are still new.** F1 adds a window you choose and an alarm that actually insists.
- The app is useful across the range, not just on an older watch.

### Existing apps and what they do badly

| Product | F1 | F2 | F3 | Main problems users report | Can we fix it? |
|---|---|---|---|---|---|
| SmartWake PRO (Connect IQ, paid) | Yes | No | No | Must start manually each night, no recurring alarm, drains battery, its own description warns it breaks Body Battery | **Yes:** one-tap start with saved schedules; we don't record an activity session (the likely cause of the Body Battery damage); low sample rates |
| Sleep Cycle – wake up relaxed (Connect IQ) | Yes | No | No | Rated 1.5★ (100+ downloads) | Yes, with a better engine and transparency |
| Sleep as Android + Garmin add-on | Yes (via phone) | No | No | Needs the phone and three apps, Bluetooth drops, alarm sometimes doesn't fire or won't dismiss | **Yes:** runs entirely on the watch |
| Nap till rested (Connect IQ) | No | Naps only (wakes on a Body Battery/stress target) | No | Naps only | n/a (different use) |
| Fitbit / Pixel Smart Wake | Fixed 30 min | No | No | Wakes exactly 30 min early every time for some users | Yes, by explaining every wake |
| **WHOOP** | No | **Yes, plain hours** | No | 1-hour window cap, not sleep-stage aware, non-ramping vibration, needs a subscription | **Yes:** any window, quality hours, ramping alarm, no extra hardware |
| Sleepest, SnorLabs, AwakeSync, Sleep Hours Alarm | Some | Duration only | No | Phone-based or Apple-only, plain duration | Yes: quality hours on a Garmin |
| Sleepwalk Guard, SleepWalking Shield, NightBell | – | – | Alarm-style | Night alarms, false alarms, Apple/iPhone only | Yes: report-and-ask by default, thresholds |
| Apple Watch, Oura, Samsung | No stage-based smart wake natively (Apple, Oura); Samsung unverified | No | Awake segments only | – | – |

Sources: [SmartWake PRO forum](https://forums.garmin.com/sports-fitness/healthandwellness/f/vivoactive-4-series/262297/does-the-garmin-third-party-app-smartwake-pro-work-well), [Sleep Cycle CIQ listing](https://apps.garmin.com/en-US/apps/4c8224d3-1442-4c26-b253-22f624f38e33), [Garmin alarms comparison thread](https://forums.garmin.com/apps-software/mobile-apps-web/f/garmin-connect-mobile-andriod/219075/sleep-track-smart-alarm-native-garmin-connect-vs-sleep-as-android-vs-smartwake), [Nap till rested](https://forums.garmin.com/developer/connect-iq/f/showcase/323051/nap-till-rested-a-power-nap-app/1585656), [Fitbit Smart Wake](https://support.google.com/fitbit/answer/14226604?hl=en-AU), [Fitbit complaint](https://community.fitbit.com/t5/Charge-5/Smart-Wake-isn-t-working-properly-on-my-Charge-5/td-p/5465347), [Sleepest](https://vanthomiy.github.io/Sleepest), [SnorLabs](https://github.com/TheBowlCut/SnorLabs), [Oura](https://gadgetsandwearables.com/2026/03/06/oura-smart-alarm/).

**Verdict.**
- **F2 (counting *quality* sleep) and F3 (morning report of night walks, with a sleepwalking check) are not done by anyone we could find.**
- F1 exists elsewhere and is weak, but on the Fenix 7 Pro it is missing entirely.
- The existing Garmin apps fail for fixable reasons: manual start, phone dependency, battery, and broken Body Battery.
- One gap we can't close: no Connect IQ app can read Garmin's own sleep stages. We use our own engine, as every competitor on Garmin has to.

---

## 4. Do we have the data? Simulator test results

We wrote a small **probe app** that asks the Fenix 7 Pro for every piece of data the features need. We built it with SDK 9.1.0 and ran it in the Connect IQ simulator set to Fenix 7 Pro.

### What the probe confirmed

| Data | Result in simulator | Used by |
|---|---|---|
| **Stored heart rate (no app running)** | ✅ 360 samples, **1 per minute, last 6 hours** | F4, engine backfill |
| **Stored skin temperature** | ✅ 180 samples, **every 2 min, last 6 hours** | F4 |
| **Stored barometric pressure** | ✅ 180 samples, every 2 min, last 6 hours | F3 |
| **Stored elevation** | ✅ 180 samples, every 2 min, last 6 hours | F3 |
| **Stored blood oxygen (SpO2)** | ✅ 192 samples, **1 per hour, about 8 days** | F4 |
| **Stored stress** | ✅ 480 samples, **1 per minute, about 8 hours** | F4 |
| **Stored Body Battery** | ✅ 480 samples, 1 per minute, about 8 hours | F4 |
| **Step counter, floors up/down** | ✅ available (ActivityMonitor) | F3 |
| **Live stress score, respiration rate, recovery time** | ✅ available (simulated values 30 / 10 / 5) | F4 |
| **User's bedtime and wake time** (from Garmin Connect profile) | ✅ 22:00 / 08:00 in simulator | Default window, auto-detect bedtime |
| **Resting heart rate** | ✅ available | Engine baseline |
| **Accelerometer + gyroscope + beat-to-beat stream** | ✅ **streaming**: over ~2.5 min the app received 3,475 accelerometer and 3,475 gyroscope samples (25 per second, as requested; device supports up to **100 Hz**) and 631 beat-to-beat intervals. At rest the accelerometer read ~1,000 mG (1 g), as expected | Engine |
| **Live heart rate, temperature, SpO2, pressure, altitude** | ✅ **streaming once per second** with sensor playback on (e.g. HR 147–157, temperature 21–26 °C, SpO2 95–99%, pressure ~59,300 Pa) | Engine, F3, F4 |
| **GPS** | ✅ **streaming** position fixes once per second (simulated route) | F3 |
| **Vibration** | ✅ `Attention.vibrate` works | F5 |
| **Background service every 5 min, with no app open** | ✅ **ran, and read steps, floors and the latest heart rate** | F3, battery saving |
| **Sleep/wake time events** (`registerForSleepEvent` / `registerForWakeEvent`) | ✅ present | Auto start/stop |
| **Notifications from the app** (API 5.1) | ✅ module present (needs its own permission; on-watch behaviour to test) | Morning "do you remember?" prompt |

### What this means for the design

1. **We don't need to generate our own data.**
   - The watch already keeps 6–8 hours of heart rate, temperature, pressure, stress and Body Battery, and 8 days of SpO2.
   - A **background service that wakes every 5 minutes** can copy those histories plus the step and floor counters into app storage. That gives a full-night record of signals and night walks **without keeping the app open all night**.
2. **The alarm (F1/F2) does need the app open in the morning stretch.** Connect IQ background code is not allowed to vibrate. So at bedtime the user starts the app with one tap, the screen stays dark, and it samples the accelerometer at a low rate and heart rate once a second. That's the battery trade-off. It must be measured on a real watch, and we report the number.
3. **For building and demoing the sleep-state engine, there is a free public dataset of real nights.** It is the one behind the Walch 2019 study, with wrist accelerometer and heart rate from an Apple Watch, labelled by a lab sleep study (polysomnography) ([PhysioNet sleep-accel](https://www.physionet.org/content/sleep-accel/)). We can tune the engine on it, and replay one real night in fast-forward on stage as the demo, instead of recording our own nights.

### Still to confirm

| Check | Where | Why it matters |
|---|---|---|
| Beat-to-beat intervals on a real Fenix 7 Pro | Real watch | A known Garmin bug stopped them on some Fenix 7 Pro firmware. If they fail, the engine uses heart-rate variation instead |
| Battery use overnight with the app open | Real watch, one night | The figure the judges will ask about |
| Garmin's own sleep tracking and Body Battery still work while our app is open | Real watch | Competitors broke this by recording an activity; we don't record one |
| Notification from background shows *and* vibrates | Real watch | For the morning prompt |
| SpO2 overnight values present | Real watch with Pulse Ox "during sleep" turned on | F4 |

---

## 5. How it fits together (architecture)

**At bedtime (one tap):**
- The user picks **Window** (F1) or **Goal** (F2). Saved schedules (weekday/weekend) are pre-filled from the Garmin profile bedtime.
- The app goes to a dark screen and turns on the motion sensors and heart rate at a low rate.

**All night:**
- The **sleep-state engine** scores each minute.
- The **walking-episode detector** watches steps and cadence. When it fires, the app reads the barometer and, if the walk is long enough, briefly turns on GPS.
- A **background service** every 5 minutes snapshots the history buffers. It's a safety net if the app is closed by accident.

**Wake time:** F1/F2 logic fires the **ramping alarm** (F5).

**Morning:** the **report** (F4) plus the **night events** list and any "Do you remember?" questions (F3).

---

## 6. Risks and how we handle them

| Risk | Handling |
|---|---|
| Our sleep scoring is less accurate than a sleep lab | Use published methods, say "restless/settled" rather than "REM/deep", show how the decision was made, and tune on the PhysioNet dataset |
| Battery drain overnight | Low sample rates, dark screen, background service for history; measure and publish the drain |
| Breaking Garmin's own sleep/Body Battery | Never record a FIT activity session at night; check on the real watch |
| Calling something sleepwalking when it isn't | Ask, don't diagnose; flag only walks that start from settled sleep with no wake period first |
| GPS indoors doesn't work | GPS used only for "left the house"; indoor movement comes from accelerometer, steps and barometer |
| The judges' Fenix 8 has Smart Wake | Lead with F2 and F3, which no Garmin has. F1 is the bonus for Fenix 7-class owners and a better version for everyone else |

---

## 7. Demo plan (2–3 minute pitch)

1. **Problem (20 s):** "Your Garmin tells you how you slept *afterwards*. It can't wake you after *enough good* sleep, and it can't tell you that you walked around at 1 a.m. and don't remember it."
2. **Live on the watch (60 s):** start the app in demo mode, which replays a real recorded night (PhysioNet) at high speed. The audience watches minutes turn awake → restless → settled. A 2:47 bathroom walk appears with steps and a floor change. The goal bank fills to 7 h and the watch **ramps up its vibration** in a light moment.
3. **Morning report (40 s):** quality hours vs time in bed, the NSF ticks, the night-events list, and the question "You walked for 4 min at 1:12 — do you remember?"
4. **Why us (20 s):** no Garmin, Fenix 9 included, does F2 or F3. Fenix 7 owners also get a smart wake. Eight sensors, each with a job.
