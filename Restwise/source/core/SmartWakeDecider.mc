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
class SmartWakeDecider extends WakeDecider {

    function initialize(windowStartSec as Number, windowEndSec as Number) {
        WakeDecider.initialize(windowStartSec, windowEndSec);
    }

    // Absolute window for the NEXT occurrence of the user's start time.
    static function nextWindow(nowSec as Number, nowMinOfDay as Number,
                               settings as WakeSettings) as Array<Number> {
        var ws = WakeDecider.nextTimeOf(nowSec, nowMinOfDay, settings.windowStartMin);
        var we = ws + (settings.windowEndMin - settings.windowStartMin) * 60;
        return [ws, we];
    }

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
}
