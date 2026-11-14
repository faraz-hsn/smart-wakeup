import Toybox.Lang;

// Why the alarm fired (stored in the night log, explained on the morning screen).
module WakeReason {
    enum {
        NONE           = 0,
        LIGHT_SLEEP    = 1,   // F1: light/restless moment inside the window
        ALREADY_AWAKE  = 2,   // F1/F2: user already awake when waking was allowed
        WINDOW_END     = 3,   // F1: deep sleep all window -> end of window
        GOAL_LIGHT     = 4,   // F2: goal banked, woke on a light moment
        GOAL_WAIT_OVER = 5,   // F2: goal banked, no light moment within max wait
        LATEST_TIME    = 6    // F2: goal not reached by the latest wake time
    }
}

// Shared contract for the two alarm modes. The session only talks to this.
//   onMinute(minuteEndSec, state) -> true exactly once, when it is time to wake
//   windowStartSec / windowEndSec -> the "looking for a light moment" phase
//     (F1: the user's window; F2: from goal reached until max wait / latest)
class WakeDecider {
    var windowStartSec as Number;
    var windowEndSec as Number;
    var fired as Boolean = false;
    var reason as Number = WakeReason.NONE;
    var firedAtSec as Number = 0;

    function initialize(windowStartSec as Number, windowEndSec as Number) {
        self.windowStartSec = windowStartSec;
        self.windowEndSec = windowEndSec;
    }

    function onMinute(minuteEndSec as Number, state as Number) as Boolean { return false; }

    // Called by the session's watchdog when sensors have been silent. Default:
    // treat it like a minute with the last known state.
    function onStale(nowSec as Number, lastState as Number) as Boolean {
        return onMinute(nowSec, lastState);
    }

    // Next occurrence of a local minute-of-day, as epoch seconds. "Next" is
    // strictly in the future: if we are inside that very minute, it means
    // tomorrow (starting a night at 6:30 must not target 6:30 today).
    static function nextTimeOf(nowSec as Number, nowMinOfDay as Number, minOfDay as Number) as Number {
        var minuteStart = nowSec - (nowSec % 60);
        var mins = (minOfDay - nowMinOfDay + 1440) % 1440;
        if (mins == 0) { mins = 1440; }
        return minuteStart + mins * 60;
    }

    protected function fire(t as Number, r as Number) as Void {
        fired = true; reason = r; firedAtSec = t;
    }
}
