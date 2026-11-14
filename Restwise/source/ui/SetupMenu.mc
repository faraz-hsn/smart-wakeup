import Toybox.Lang;
import Toybox.WatchUi;

// Home screen. Items depend on the mode (your choice: a Mode item in the menu).
//   Window mode: Go to sleep / Mode / Wake from / Wake by / Last night / Demo night
//   Goal mode:   Go to sleep / Mode / Sleep goal / Latest wake / Last night / Demo night
class SetupMenu extends WatchUi.Menu2 {
    function initialize(s as WakeSettings, hasLastNight as Boolean) {
        Menu2.initialize({ :title => "Restwise" });
        addItem(new WatchUi.MenuItem("Go to sleep", summary(s), :sleep, {}));
        addItem(new WatchUi.MenuItem("Mode", modeName(s.mode), :mode, {}));
        if (s.mode == WakeMode.GOAL) {
            addItem(new WatchUi.MenuItem("Sleep goal", WakeText.duration(s.goalMin), :goal, {}));
            addItem(new WatchUi.MenuItem("Latest wake", WakeSettings.fmt(s.latestMin), :latest, {}));
        } else {
            addItem(new WatchUi.MenuItem("Wake from", WakeSettings.fmt(s.windowStartMin), :start, {}));
            addItem(new WatchUi.MenuItem("Wake by", WakeSettings.fmt(s.windowEndMin), :end, {}));
        }
        if (hasLastNight) {
            addItem(new WatchUi.MenuItem("Last night", null, :last, {}));
        }
        addItem(new WatchUi.MenuItem("Demo night", "Real recorded night", :demo, {}));
    }

    static function modeName(m as Number) as String {
        return m == WakeMode.GOAL ? "Sleep goal" : "Smart window";
    }

    static function windowText(s as WakeSettings) as String {
        return WakeSettings.fmt(s.windowStartMin) + "-" + WakeSettings.fmt(s.windowEndMin);
    }

    // One line under "Go to sleep" (and on the night screen).
    static function summary(s as WakeSettings) as String {
        if (s.mode == WakeMode.GOAL) {
            return "Goal " + WakeText.duration(s.goalMin) + ", by " + WakeSettings.fmt(s.latestMin);
        }
        return "Wake " + windowText(s);
    }
}

class SetupMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize(menu as SetupMenu) {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var c = getController();
        var s = c.settings;
        var id = item.getId();
        if (id == :sleep) {
            c.startNight();
        } else if (id == :mode) {
            s.mode = s.mode == WakeMode.GOAL ? WakeMode.WINDOW : WakeMode.GOAL;
            saveAndRebuild();
        } else if (id == :start) {
            pick("Wake from", s.windowStartMin, method(:onStartPicked));
        } else if (id == :end) {
            pick("Wake by", s.windowEndMin, method(:onEndPicked));
        } else if (id == :goal) {
            pick("Sleep goal", s.goalMin, method(:onGoalPicked));
        } else if (id == :latest) {
            pick("Latest wake", s.latestMin, method(:onLatestPicked));
        } else if (id == :demo) {
            c.startDemo();
        } else if (id == :last) {
            c.showLastNight();
        }
    }

    private function pick(title as String, value as Number, cb as Method) as Void {
        WatchUi.pushView(new TimePicker(title, value), new TimePickerDelegate(cb), WatchUi.SLIDE_LEFT);
    }

    function onStartPicked(m as Number) as Void { getController().settings.setStart(m); saveAndRebuild(); }
    function onEndPicked(m as Number) as Void { getController().settings.setEnd(m); saveAndRebuild(); }
    function onGoalPicked(m as Number) as Void { getController().settings.setGoal(m); saveAndRebuild(); }
    function onLatestPicked(m as Number) as Void { getController().settings.latestMin = m; saveAndRebuild(); }

    // Rebuild the menu so labels (and mode-specific items) are always current.
    private function saveAndRebuild() as Void {
        var c = getController();
        Store.saveSettings(c.settings);
        c.refreshHome();
    }
}
