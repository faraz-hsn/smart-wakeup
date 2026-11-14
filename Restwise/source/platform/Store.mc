import Toybox.Application;
import Toybox.Lang;

// Persistent storage on the watch (survives app restarts).
//   "settings"  -> WakeSettings as a dictionary
//   "lastNight" -> NightLog as a dictionary (only the most recent night for now)
module Store {
    const KEY_SETTINGS = "settings";
    const KEY_LAST_NIGHT = "lastNight";

    function loadSettings() as WakeSettings {
        return WakeSettings.fromDict(Application.Storage.getValue(KEY_SETTINGS) as Dictionary or Null);
    }

    function saveSettings(s as WakeSettings) as Void {
        Application.Storage.setValue(KEY_SETTINGS, s.toDict());
    }

    function saveNight(n as NightLog) as Void {
        Application.Storage.setValue(KEY_LAST_NIGHT, n.toDict());
    }

    function loadLastNight() as NightLog or Null {
        var d = Application.Storage.getValue(KEY_LAST_NIGHT);
        return d == null ? null : NightLog.fromDict(d as Dictionary);
    }
}

// What we remember about one night: one character per minute ("0" awake,
// "1" restless, "2" settled), plus the wake decision and why.
class NightLog {
    var startSec as Number;
    var windowStartSec as Number;
    var windowEndSec as Number;
    var states as String = "";
    var wakeSec as Number = 0;
    var reason as Number = WakeReason.NONE;
    var mode as Number = WakeMode.WINDOW;
    var goalMin as Number = 0;          // F2 only
    var bankedMin as Number = 0;        // F2 only: quality minutes banked

    function initialize(startSec as Number, ws as Number, we as Number) {
        self.startSec = startSec; windowStartSec = ws; windowEndSec = we;
    }

    function addMinute(state as Number) as Void { states = states + state.toString(); }

    function count(state as Number) as Number {
        var c = 0; var ch = state.toString().toCharArray()[0];
        var arr = states.toCharArray();
        for (var i = 0; i < arr.size(); i++) { if (arr[i] == ch) { c++; } }
        return c;
    }

    function toDict() as Dictionary {
        return { "st" => startSec, "ws" => windowStartSec, "we" => windowEndSec,
                 "s" => states, "w" => wakeSec, "r" => reason,
                 "m" => mode, "g" => goalMin, "b" => bankedMin };
    }

    static function fromDict(d as Dictionary) as NightLog {
        var n = new NightLog(d["st"] as Number, d["ws"] as Number, d["we"] as Number);
        n.states = d["s"] as String; n.wakeSec = d["w"] as Number; n.reason = d["r"] as Number;
        if (d["m"] != null) { n.mode = d["m"] as Number; n.goalMin = d["g"] as Number; n.bankedMin = d["b"] as Number; }
        return n;
    }
}
