import Toybox.Lang;

// User's wake-window choice. Times are minutes after local midnight
// (e.g. 6:30 -> 390). The window may cross midnight only in theory; for
// Feature 1 we assume start < end (morning window), validated in isValid().
module WakeMode {
    enum { WINDOW = 0, GOAL = 1 }
}

class WakeSettings {
    var windowStartMin as Number;
    var windowEndMin as Number;
    // Feature 2 (Quality Sleep Goal)
    var mode as Number = WakeMode.WINDOW;
    var goalMin as Number = 7 * 60;        // quality sleep wanted (default 7 h)
    var latestMin as Number = 10 * 60;     // latest wake time (default 10:00)

    function initialize(windowStartMin as Number, windowEndMin as Number) {
        self.windowStartMin = windowStartMin;
        self.windowEndMin = windowEndMin;
    }

    function isValid() as Boolean {
        return windowStartMin >= 0 && windowEndMin <= 24 * 60
            && windowStartMin < windowEndMin;
    }

    static const MIN_WINDOW = 10;       // minutes
    static const DEFAULT_WINDOW = 30;   // used when an edit makes the window invalid

    // Edit the start; if it is now at/after the end, push the end 30 min later.
    function setStart(m as Number) as Void {
        windowStartMin = clampDay(m);
        if (windowEndMin - windowStartMin < MIN_WINDOW) {
            windowEndMin = clampDay(windowStartMin + DEFAULT_WINDOW);
            if (windowEndMin - windowStartMin < MIN_WINDOW) { windowStartMin = windowEndMin - DEFAULT_WINDOW; }
        }
    }

    // Edit the end; if it is now at/before the start, pull the start 30 min earlier.
    function setEnd(m as Number) as Void {
        windowEndMin = clampDay(m);
        if (windowEndMin - windowStartMin < MIN_WINDOW) {
            windowStartMin = windowEndMin - DEFAULT_WINDOW;
            if (windowStartMin < 0) { windowStartMin = 0; windowEndMin = DEFAULT_WINDOW; }
        }
    }

    private function clampDay(m as Number) as Number {
        return m < 0 ? 0 : (m > 1440 ? 1440 : m);
    }

    function toDict() as Dictionary {
        return { "s" => windowStartMin, "e" => windowEndMin,
                 "m" => mode, "g" => goalMin, "l" => latestMin };
    }

    // Older saved settings (Feature 1 only) have no m/g/l keys -> defaults.
    static function fromDict(d as Dictionary or Null) as WakeSettings {
        if (d == null) { return WakeSettings.defaults(); }
        var w = new WakeSettings(d["s"] as Number, d["e"] as Number);
        if (d["m"] != null) { w.mode = d["m"] as Number; }
        if (d["g"] != null) { w.goalMin = d["g"] as Number; }
        if (d["l"] != null) { w.latestMin = d["l"] as Number; }
        return w;
    }

    function copy() as WakeSettings { return WakeSettings.fromDict(toDict()); }

    // Goal between 1 h and 12 h.
    function setGoal(m as Number) as Void {
        goalMin = m < 60 ? 60 : (m > 720 ? 720 : m);
    }

    static function defaults() as WakeSettings {
        return new WakeSettings(6 * 60 + 30, 7 * 60);   // 6:30 - 7:00
    }

    static function fmt(minOfDay as Number) as String {
        return (minOfDay / 60).format("%d") + ":" + (minOfDay % 60).format("%02d");
    }
}
