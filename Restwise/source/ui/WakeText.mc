import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Plain-language text for the morning screen. Pure functions, unit-tested.
module WakeText {

    function clock(epochSec as Number) as String {
        var i = Gregorian.info(new Time.Moment(epochSec), Time.FORMAT_SHORT);
        return (i.hour as Number).format("%d") + ":" + (i.min as Number).format("%02d");
    }

    // One short line explaining why the alarm fired when it did.
    function reason(r as Number) as String {
        if (r == WakeReason.LIGHT_SLEEP)   { return "You were in a light, restless phase"; }
        if (r == WakeReason.ALREADY_AWAKE) { return "You were already awake"; }
        if (r == WakeReason.WINDOW_END)    { return "Deep sleep all window - end of window"; }
        if (r == WakeReason.GOAL_LIGHT)    { return "Goal banked, light sleep moment"; }
        if (r == WakeReason.GOAL_WAIT_OVER){ return "Goal banked, 20 min max wait over"; }
        if (r == WakeReason.LATEST_TIME)   { return "Latest wake time reached"; }
        return "Night stopped early";
    }

    // "12 min early" / "at the deadline"
    function earliness(wakeSec as Number, windowEndSec as Number) as String {
        var m = (windowEndSec - wakeSec) / 60;
        if (m <= 0) { return "at your deadline"; }
        return m.format("%d") + " min before deadline";
    }

    // "Banked 3h12m of 3h00m goal"
    function banked(bankedMin as Number, goalMin as Number) as String {
        return "Banked " + duration(bankedMin) + " of " + duration(goalMin);
    }

    // "5h 42m"
    function duration(minutes as Number) as String {
        return (minutes / 60).format("%d") + "h " + (minutes % 60).format("%02d") + "m";
    }
}
