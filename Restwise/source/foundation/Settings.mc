import Toybox.Lang;

// User's wake-window choice. Times are minutes after local midnight
// (e.g. 6:30 -> 390). The window may cross midnight only in theory; for
// Feature 1 we assume start < end (morning window), validated in isValid().
class WakeSettings {
    var windowStartMin as Number;
    var windowEndMin as Number;

    function initialize(windowStartMin as Number, windowEndMin as Number) {
        self.windowStartMin = windowStartMin;
        self.windowEndMin = windowEndMin;
    }

    function isValid() as Boolean {
        return windowStartMin >= 0 && windowEndMin <= 24 * 60
            && windowStartMin < windowEndMin;
    }

    function toDict() as Dictionary {
        return { "s" => windowStartMin, "e" => windowEndMin };
    }

    static function fromDict(d as Dictionary or Null) as WakeSettings {
        if (d == null) { return WakeSettings.defaults(); }
        return new WakeSettings(d["s"] as Number, d["e"] as Number);
    }

    static function defaults() as WakeSettings {
        return new WakeSettings(6 * 60 + 30, 7 * 60);   // 6:30 - 7:00
    }

    static function fmt(minOfDay as Number) as String {
        return (minOfDay / 60).format("%d") + ":" + (minOfDay % 60).format("%02d");
    }
}
