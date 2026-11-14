import Toybox.Lang;

// Feature 2: wake the user once they have banked their quality-sleep goal.
// Pure logic, unit-tested in test/GoalTests.mc. Your choices:
//   * quality minutes = SETTLED + RESTLESS (AWAKE never counts)
//   * target = goal + 15 min safety margin (trackers over-count sleep)
//   * after the target is banked: wake on the next RESTLESS (or AWAKE) minute,
//     or after 20 minutes at most
//   * hard stop at the user's latest wake time, whatever the bank says
class QualityGoalDecider extends WakeDecider {
    static const MARGIN_MIN = 15;
    static const MAX_WAIT_MIN = 20;

    var goalMin as Number;
    var latestSec as Number;
    var bankedMin as Number = 0;
    var goalMetAtSec as Number = 0;

    function initialize(goalMin as Number, latestSec as Number) {
        // Until the goal is banked, the "looking for a light moment" phase is
        // unknown, so it is parked at the latest wake time.
        WakeDecider.initialize(latestSec, latestSec);
        self.goalMin = goalMin;
        self.latestSec = latestSec;
    }

    function targetMin() as Number { return goalMin + MARGIN_MIN; }

    // Sensors silent: never bank invented sleep. Only the latest-time
    // deadline can still fire.
    function onStale(nowSec as Number, lastState as Number) as Boolean {
        if (fired || nowSec < latestSec) { return false; }
        fire(nowSec, WakeReason.LATEST_TIME);
        return true;
    }

    function onMinute(minuteEndSec as Number, state as Number) as Boolean {
        if (fired) { return false; }
        if (state != SleepState.AWAKE) { bankedMin++; }

        if (minuteEndSec >= latestSec) {
            fire(minuteEndSec, WakeReason.LATEST_TIME);
            return true;
        }
        if (bankedMin < targetMin()) { return false; }

        if (goalMetAtSec == 0) {
            goalMetAtSec = minuteEndSec;
            windowStartSec = minuteEndSec;
            var waitEnd = minuteEndSec + MAX_WAIT_MIN * 60;
            windowEndSec = waitEnd < latestSec ? waitEnd : latestSec;
        }
        if (state == SleepState.RESTLESS) {
            fire(minuteEndSec, WakeReason.GOAL_LIGHT);
        } else if (state == SleepState.AWAKE) {
            fire(minuteEndSec, WakeReason.ALREADY_AWAKE);
        } else if (minuteEndSec >= windowEndSec) {
            fire(minuteEndSec, WakeReason.GOAL_WAIT_OVER);
        }
        return fired;
    }
}
