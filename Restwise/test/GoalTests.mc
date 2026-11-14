import Toybox.Lang;
import Toybox.Test;

// Goal 60 min (target 75 with margin), latest wake at t = 10 000 min.
const RW_LATEST = 600000;

function rwGoalFeed(d as QualityGoalDecider, fromMin as Number, n as Number, st as Number) as Boolean {
    var any = false;
    for (var i = 0; i < n; i++) {
        if (d.onMinute((fromMin + i + 1) * 60, st)) { any = true; }
    }
    return any;
}

(:test)
function goalAwakeMinutesDontCount(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, RW_LATEST);
    rwGoalFeed(d, 0, 30, SleepState.AWAKE);
    rwGoalFeed(d, 30, 20, SleepState.SETTLED);
    rwGoalFeed(d, 50, 10, SleepState.RESTLESS);
    Test.assertEqual(30, d.bankedMin);                  // 20 settled + 10 restless
    Test.assert(!d.fired);
    return true;
}

(:test)
function goalNotBeforeMargin(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, RW_LATEST);
    // 74 quality minutes, last ones restless: still under goal + 15
    Test.assert(!rwGoalFeed(d, 0, 70, SleepState.SETTLED));
    Test.assert(!rwGoalFeed(d, 70, 4, SleepState.RESTLESS));
    Test.assertEqual(74, d.bankedMin);
    return true;
}

(:test)
function goalWakesOnFirstLightMomentAfterBank(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, RW_LATEST);
    rwGoalFeed(d, 0, 75, SleepState.SETTLED);           // target reached at minute 75, deep
    Test.assert(!d.fired);
    Test.assertEqual(75 * 60, d.goalMetAtSec);
    Test.assert(!rwGoalFeed(d, 75, 5, SleepState.SETTLED));
    Test.assert(d.onMinute(81 * 60, SleepState.RESTLESS));
    Test.assertEqual(WakeReason.GOAL_LIGHT, d.reason);
    Test.assertEqual(81 * 60, d.firedAtSec);
    return true;
}

(:test)
function goalWaitsAtMostTwentyMinutes(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, RW_LATEST);
    rwGoalFeed(d, 0, 75, SleepState.SETTLED);
    Test.assert(rwGoalFeed(d, 75, 25, SleepState.SETTLED));
    Test.assertEqual(WakeReason.GOAL_WAIT_OVER, d.reason);
    Test.assertEqual(95 * 60, d.firedAtSec);            // 75 + 20 min
    return true;
}

(:test)
function goalLatestTimeAlwaysWins(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(600, 40 * 60);       // 10 h goal, latest at minute 40
    Test.assert(rwGoalFeed(d, 0, 45, SleepState.SETTLED));
    Test.assertEqual(WakeReason.LATEST_TIME, d.reason);
    Test.assertEqual(40 * 60, d.firedAtSec);
    Test.assertEqual(40, d.bankedMin);
    return true;
}

(:test)
function goalWaitCappedByLatestTime(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, 85 * 60);        // latest only 10 min after target
    rwGoalFeed(d, 0, 75, SleepState.SETTLED);
    Test.assertEqual(85 * 60, d.windowEndSec);
    Test.assert(rwGoalFeed(d, 75, 15, SleepState.SETTLED));
    Test.assertEqual(85 * 60, d.firedAtSec);
    return true;
}

(:test)
function goalAwakeAfterBankWakesNow(logger as Test.Logger) as Boolean {
    var d = new QualityGoalDecider(60, RW_LATEST);
    rwGoalFeed(d, 0, 75, SleepState.SETTLED);
    Test.assert(d.onMinute(76 * 60, SleepState.AWAKE));
    Test.assertEqual(WakeReason.ALREADY_AWAKE, d.reason);
    return true;
}

(:test)
function nextTimeOfWrapsMidnight(logger as Test.Logger) as Boolean {
    // now 23:00 (1380) -> 9:00 (540) is 10 h later
    Test.assertEqual(82800 + 600 * 60, WakeDecider.nextTimeOf(82800, 1380, 540));
    return true;
}
