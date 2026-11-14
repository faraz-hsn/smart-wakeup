import Toybox.Lang;

// Feature 1: decides, minute by minute, whether to wake the user now.
// Pure logic, unit-tested in test/WakeTests.mc.
//
// Rules inside the user's window [windowStartSec, windowEndSec):
//   * RESTLESS minute (light sleep / stirring)  -> wake now (LIGHT_SLEEP)
//   * AWAKE minute (already awake in bed)        -> wake now (ALREADY_AWAKE)
//   * SETTLED minute                             -> keep waiting
// At or after windowEndSec                      -> wake now (WINDOW_END)
// It fires at most once per night.
module WakeReason {
    enum {
        NONE          = 0,
        LIGHT_SLEEP   = 1,
        ALREADY_AWAKE = 2,
        WINDOW_END    = 3
    }
}

class SmartWakeDecider {
    var windowStartSec as Number;
    var windowEndSec as Number;
    var fired as Boolean = false;
    var reason as Number = WakeReason.NONE;
    var firedAtSec as Number = 0;

    function initialize(windowStartSec as Number, windowEndSec as Number) {
        self.windowStartSec = windowStartSec;
        self.windowEndSec = windowEndSec;
    }

    // Absolute window for the NEXT occurrence of the user's start time, as seen
    // from "now". nowMinOfDay is the local minute-of-day of nowSec (from Clock),
    // which keeps this function free of time-zone code and easy to test.
    static function nextWindow(nowSec as Number, nowMinOfDay as Number,
                               settings as WakeSettings) as Array<Number> {
        var minuteStart = nowSec - (nowSec % 60);
        var minsUntil = (settings.windowStartMin - nowMinOfDay + 1440) % 1440;
        var ws = minuteStart + minsUntil * 60;
        var we = ws + (settings.windowEndMin - settings.windowStartMin) * 60;
        return [ws, we];
    }

    // Called once per minute with that minute's label. minuteEndSec = the time
    // the minute finished. Returns true exactly once, when it is time to wake.
    function onMinute(minuteEndSec as Number, state as Number) as Boolean {
        if (fired || minuteEndSec < windowStartSec) { return false; }
        if (minuteEndSec >= windowEndSec) {
            fire(minuteEndSec, WakeReason.WINDOW_END);
        } else if (state == SleepState.RESTLESS) {
            fire(minuteEndSec, WakeReason.LIGHT_SLEEP);
        } else if (state == SleepState.AWAKE) {
            fire(minuteEndSec, WakeReason.ALREADY_AWAKE);
        }
        return fired;
    }

    private function fire(t as Number, r as Number) as Void {
        fired = true; reason = r; firedAtSec = t;
    }
}
