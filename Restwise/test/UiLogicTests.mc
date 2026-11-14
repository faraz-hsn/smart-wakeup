import Toybox.Lang;
import Toybox.Test;

// ---- WakeSettings edit rules --------------------------------------------
(:test)
function settingsStartAfterEndPushesEnd(logger as Test.Logger) as Boolean {
    var s = new WakeSettings(390, 420);          // 6:30-7:00
    s.setStart(450);                             // 7:30 > end
    Test.assertEqual(450, s.windowStartMin);
    Test.assertEqual(480, s.windowEndMin);       // pushed to 8:00
    return true;
}

(:test)
function settingsEndBeforeStartPullsStart(logger as Test.Logger) as Boolean {
    var s = new WakeSettings(390, 420);
    s.setEnd(360);                               // 6:00 < start
    Test.assertEqual(330, s.windowStartMin);     // pulled to 5:30
    Test.assertEqual(360, s.windowEndMin);
    return true;
}

(:test)
function settingsValidEditUntouched(logger as Test.Logger) as Boolean {
    var s = new WakeSettings(390, 420);
    s.setStart(360);
    Test.assertEqual(360, s.windowStartMin);
    Test.assertEqual(420, s.windowEndMin);       // 6:00-7:00, 1 h window kept
    Test.assert(s.isValid());
    return true;
}

(:test)
function settingsEdgeOfDay(logger as Test.Logger) as Boolean {
    var s = new WakeSettings(390, 420);
    s.setStart(1435);                            // 23:55
    Test.assert(s.windowEndMin <= 1440 && s.windowEndMin - s.windowStartMin >= 10);
    var t = new WakeSettings(390, 420);
    t.setEnd(5);                                 // 0:05
    Test.assert(t.windowStartMin >= 0 && t.windowEndMin - t.windowStartMin >= 10);
    return true;
}

// ---- Picker column -------------------------------------------------------
(:test)
function minutePickerHasFiveMinuteSteps(logger as Test.Logger) as Boolean {
    var f = new StepFactory(0, 60, 5, "%02d");
    Test.assertEqual(12, f.getSize());
    Test.assertEqual(55, f.getValue(11));
    Test.assertEqual(6, f.indexOf(30));
    Test.assertEqual(6, f.indexOf(33));          // 33 rounds down to 30
    var hrs = new StepFactory(0, 24, 1, "%d");
    Test.assertEqual(24, hrs.getSize());
    return true;
}

// ---- Morning text ----------------------------------------------------------
(:test)
function morningTextReasonsAndDurations(logger as Test.Logger) as Boolean {
    Test.assertEqual("You were already awake", WakeText.reason(WakeReason.ALREADY_AWAKE));
    Test.assertEqual("12 min before deadline", WakeText.earliness(1000, 1000 + 12 * 60));
    Test.assertEqual("at your deadline", WakeText.earliness(1000, 1000));
    Test.assertEqual("5h 07m", WakeText.duration(307));
    return true;
}

(:test)
function goalTextsAndSummary(logger as Test.Logger) as Boolean {
    Test.assertEqual("Banked 3h 12m of 3h 00m", WakeText.banked(192, 180));
    Test.assertEqual("Latest wake time reached", WakeText.reason(WakeReason.LATEST_TIME));
    var s = new WakeSettings(390, 420);
    Test.assertEqual("Wake 6:30-7:00", SetupMenu.summary(s));
    s.mode = WakeMode.GOAL; s.goalMin = 420; s.latestMin = 600;
    Test.assertEqual("Goal 7h 00m, by 10:00", SetupMenu.summary(s));
    return true;
}
