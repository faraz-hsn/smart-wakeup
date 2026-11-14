import Toybox.Lang;
import Toybox.Test;

// Session in GOAL mode: goal 60 min (target 75), latest wake 5 h after "now".
class RwGoalRig {
    var clock as FastClock; var src as RwFakeSource; var alarm as RwFakeAlarm;
    var session as NightSession; var t as Number;
    function initialize(goalMin as Number, latestAfterMin as Number) {
        t = 1700000000 - (1700000000 % 60);
        clock = new FastClock(t);
        var s = new WakeSettings(390, 420);
        s.mode = WakeMode.GOAL;
        s.goalMin = goalMin;
        s.latestMin = (clock.minuteOfDay(t) + latestAfterMin) % 1440;
        src = new RwFakeSource(); alarm = new RwFakeAlarm();
        session = new NightSession(src, clock, alarm, s, 60, false, null);
        session.start();
    }
    function minute(act as Float, hr as Float) as Void {
        src.push(new MinuteSample(t, act, hr, 1.0, null));
        t += 60; clock.setNow(t);
    }
}

(:test)
function goalSessionDeepSleepWakesAfterMaxWait(logger as Test.Logger) as Boolean {
    var r = new RwGoalRig(60, 300);
    // 10 min to fall asleep (awake, not banked) + settled sleep until target
    var guard = 0;
    while (r.session.decider.fired == false && guard < 200) { r.minute(1.0, 55.0); guard++; }
    // settled all the way: should NOT have fired before goal + margin + 20 min wait
    Test.assertEqual(SessionState.ALARMING, r.session.state);
    Test.assertEqual(WakeReason.GOAL_WAIT_OVER, r.session.log.reason);
    Test.assert(r.session.log.bankedMin >= 75);
    Test.assertEqual(WakeMode.GOAL, r.session.log.mode);
    return true;
}

(:test)
function goalSessionInWindowAfterBank(logger as Test.Logger) as Boolean {
    var r = new RwGoalRig(60, 300);
    var guard = 0;
    while ((r.session.decider as QualityGoalDecider).goalMetAtSec == 0 && guard < 120) { r.minute(1.0, 55.0); guard++; }
    Test.assertEqual(SessionState.IN_WINDOW, r.session.state);   // looking for a light moment
    r.minute(30.0, 58.0);                                         // stir
    Test.assertEqual(SessionState.ALARMING, r.session.state);
    Test.assertEqual(WakeReason.GOAL_LIGHT, r.session.log.reason);
    Test.assertEqual(1, r.alarm.starts);
    return true;
}

(:test)
function goalSessionLatestTimeStop(logger as Test.Logger) as Boolean {
    var r = new RwGoalRig(600, 60);                               // 10 h goal, latest in 1 h
    var guard = 0;
    while (r.session.state != SessionState.ALARMING && guard < 120) { r.minute(1.0, 55.0); guard++; }
    Test.assertEqual(WakeReason.LATEST_TIME, r.session.log.reason);
    Test.assert(r.session.log.bankedMin < 600);
    return true;
}

(:test)
function settingsGoalFieldsRoundTripAndOldFormat(logger as Test.Logger) as Boolean {
    var s = new WakeSettings(390, 420);
    s.mode = WakeMode.GOAL; s.setGoal(450); s.latestMin = 570;
    var c = WakeSettings.fromDict(s.toDict());
    Test.assertEqual(WakeMode.GOAL, c.mode);
    Test.assertEqual(450, c.goalMin);
    Test.assertEqual(570, c.latestMin);
    var old = WakeSettings.fromDict({ "s" => 390, "e" => 420 });  // saved by Feature-1 build
    Test.assertEqual(WakeMode.WINDOW, old.mode);
    Test.assertEqual(420, old.goalMin);
    s.setGoal(10); Test.assertEqual(60, s.goalMin);               // clamped to 1 h
    return true;
}

// Review fix: a sensor stall must not bank invented sleep in goal mode.
(:test)
function goalStallDoesNotBankSleep(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, 100 * 60);
    for (var i = 0; i < 30; i++) { d.onStale((i + 1) * 60, SleepState.SETTLED); }
    Test.assertEqual(0, d.bankedMin);
    Test.assert(!d.fired);
    Test.assert(d.onStale(100 * 60, SleepState.SETTLED));      // only the deadline fires
    Test.assertEqual(WakeReason.LATEST_TIME, d.reason);
    return true;
}

// Review fix: starting inside the window-start minute targets TOMORROW.
(:test)
function nextTimeOfSameMinuteMeansTomorrow(logger as Test.Logger) as Boolean {
    Test.assertEqual(23400 + 1440 * 60, WakeDecider.nextTimeOf(23420, 390, 390));
    return true;
}

// Review fix: DST-safe nextLocal lands on the requested local minute.
(:test)
function nextLocalLandsOnRequestedLocalMinute(logger as Test.Logger) as Boolean {
    var c = new FastClock(1700000000);
    var t = NightSession.nextLocal(c, 1700000000, 390);
    Test.assertEqual(390, c.minuteOfDay(t));
    Test.assert(t > 1700000000 && t - 1700000000 <= 1440 * 60);
    return true;
}
