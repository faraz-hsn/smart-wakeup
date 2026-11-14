import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Time source. The session never calls Time.now() directly, so the demo can
// fast-forward a whole night without changing any logic.
class Clock {
    function initialize() {}

    // Seconds since 1970 (UTC).
    function nowSec() as Number {
        return Time.now().value();
    }

    // Minutes after LOCAL midnight for a given epoch second.
    function minuteOfDay(epochSec as Number) as Number {
        var info = Gregorian.info(new Time.Moment(epochSec), Time.FORMAT_SHORT);
        return (info.hour as Number) * 60 + (info.min as Number);
    }
}

// Demo clock: time is driven by the replayed data, not the wall clock.
// The replay source calls setNow() as it emits each minute.
class FastClock extends Clock {
    private var _now as Number;

    function initialize(startSec as Number) {
        Clock.initialize();
        _now = startSec;
    }

    function setNow(sec as Number) as Void { _now = sec; }

    function nowSec() as Number { return _now; }
}
