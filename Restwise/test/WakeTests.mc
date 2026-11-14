import Toybox.Lang;
import Toybox.Test;

// Window 6:30-7:00. "Day" starts at epoch 0 for simplicity; 6:30 = 23400 s.
const RW_WS = 23400;
const RW_WE = 25200;

(:test)
function wakeNothingBeforeWindow(logger as Test.Logger) as Boolean {
    var d = new SmartWakeDecider(RW_WS, RW_WE);
    Test.assert(!d.onMinute(RW_WS - 60, SleepState.RESTLESS));
    Test.assert(!d.onMinute(RW_WS - 60, SleepState.AWAKE));
    return true;
}

(:test)
function wakeOnFirstRestlessInWindow(logger as Test.Logger) as Boolean {
    var d = new SmartWakeDecider(RW_WS, RW_WE);
    Test.assert(!d.onMinute(RW_WS + 60, SleepState.SETTLED));
    Test.assert(d.onMinute(RW_WS + 600, SleepState.RESTLESS));
    Test.assertEqual(WakeReason.LIGHT_SLEEP, d.reason);
    Test.assertEqual(RW_WS + 600, d.firedAtSec);
    return true;
}

(:test)
function wakeIfAlreadyAwakeInWindow(logger as Test.Logger) as Boolean {
    var d = new SmartWakeDecider(RW_WS, RW_WE);
    Test.assert(d.onMinute(RW_WS + 120, SleepState.AWAKE));
    Test.assertEqual(WakeReason.ALREADY_AWAKE, d.reason);
    return true;
}

(:test)
function wakeAtWindowEndIfAlwaysSettled(logger as Test.Logger) as Boolean {
    var d = new SmartWakeDecider(RW_WS, RW_WE);
    for (var t = RW_WS; t < RW_WE; t += 60) { Test.assert(!d.onMinute(t, SleepState.SETTLED)); }
    Test.assert(d.onMinute(RW_WE, SleepState.SETTLED));
    Test.assertEqual(WakeReason.WINDOW_END, d.reason);
    return true;
}

(:test)
function wakeFiresOnlyOnce(logger as Test.Logger) as Boolean {
    var d = new SmartWakeDecider(RW_WS, RW_WE);
    Test.assert(d.onMinute(RW_WS + 60, SleepState.RESTLESS));
    Test.assert(!d.onMinute(RW_WS + 120, SleepState.AWAKE));    // no second trigger
    Test.assertEqual(WakeReason.LIGHT_SLEEP, d.reason);
    Test.assertEqual(RW_WS + 60, d.firedAtSec);
    return true;
}

(:test)
function windowComputedForTomorrowMorning(logger as Test.Logger) as Boolean {
    // Now = 23:00 (minute 1380) at epoch 82800; window 6:30-7:00 -> 7.5 h later.
    var w = SmartWakeDecider.nextWindow(82800, 1380, new WakeSettings(390, 420));
    Test.assertEqual(82800 + 450 * 60, w[0]);
    Test.assertEqual(82800 + 480 * 60, w[1]);
    return true;
}

(:test)
function windowComputedAfterMidnight(logger as Test.Logger) as Boolean {
    // Now = 01:15 (minute 75); window 6:30 -> 315 min later, 30 min long.
    var w = SmartWakeDecider.nextWindow(4500, 75, new WakeSettings(390, 420));
    Test.assertEqual(4500 + 315 * 60, w[0]);
    Test.assertEqual(w[0] + 1800, w[1]);
    return true;
}

(:test)
function nightLogCountsAndRoundTrips(logger as Test.Logger) as Boolean {
    var n = new NightLog(0, RW_WS, RW_WE);
    n.addMinute(SleepState.AWAKE); n.addMinute(SleepState.SETTLED); n.addMinute(SleepState.SETTLED);
    n.wakeSec = RW_WS + 60; n.reason = WakeReason.LIGHT_SLEEP;
    var m = NightLog.fromDict(n.toDict());
    Test.assertEqual("022", m.states);
    Test.assertEqual(2, m.count(SleepState.SETTLED));
    Test.assertEqual(WakeReason.LIGHT_SLEEP, m.reason);
    return true;
}
