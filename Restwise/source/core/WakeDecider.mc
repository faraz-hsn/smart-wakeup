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

    // Next occurrence of a local minute-of-day, as epoch seconds.
    static function nextTimeOf(nowSec as Number, nowMinOfDay as Number, minOfDay as Number) as Number {
        var minuteStart = nowSec - (nowSec % 60);
        return minuteStart + ((minOfDay - nowMinOfDay + 1440) % 1440) * 60;
    }

    protected function fire(t as Number, r as Number) as Void {
        fired = true; reason = r; firedAtSec = t;
    }
}
