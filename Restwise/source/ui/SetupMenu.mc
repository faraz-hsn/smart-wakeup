import Toybox.Lang;
import Toybox.WatchUi;

// Home screen: set the window, go to sleep, see last night.
class SetupMenu extends WatchUi.Menu2 {
    function initialize(s as WakeSettings, hasLastNight as Boolean) {
        Menu2.initialize({ :title => "Restwise" });
        addItem(new WatchUi.MenuItem("Go to sleep", "Wake " + windowText(s), :sleep, {}));
        addItem(new WatchUi.MenuItem("Wake from", WakeSettings.fmt(s.windowStartMin), :start, {}));
        addItem(new WatchUi.MenuItem("Wake by", WakeSettings.fmt(s.windowEndMin), :end, {}));
        if (hasLastNight) {
            addItem(new WatchUi.MenuItem("Last night", null, :last, {}));
        }
    }

    static function windowText(s as WakeSettings) as String {
        return WakeSettings.fmt(s.windowStartMin) + "-" + WakeSettings.fmt(s.windowEndMin);
    }

    // Refresh the labels after an edit.
    function refresh(s as WakeSettings) as Void {
        (getItem(findItemById(:sleep)) as WatchUi.MenuItem).setSubLabel("Wake " + windowText(s));
        (getItem(findItemById(:start)) as WatchUi.MenuItem).setSubLabel(WakeSettings.fmt(s.windowStartMin));
        (getItem(findItemById(:end)) as WatchUi.MenuItem).setSubLabel(WakeSettings.fmt(s.windowEndMin));
        WatchUi.requestUpdate();
    }
}

class SetupMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _menu as SetupMenu;

    function initialize(menu as SetupMenu) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var c = getController();
        var id = item.getId();
        if (id == :sleep) {
            c.startNight();
        } else if (id == :start) {
            WatchUi.pushView(new TimePicker("Wake from", c.settings.windowStartMin),
                new TimePickerDelegate(method(:onStartPicked)), WatchUi.SLIDE_LEFT);
        } else if (id == :end) {
            WatchUi.pushView(new TimePicker("Wake by", c.settings.windowEndMin),
                new TimePickerDelegate(method(:onEndPicked)), WatchUi.SLIDE_LEFT);
        } else if (id == :last) {
            c.showLastNight();
        }
    }

    function onStartPicked(m as Number) as Void {
        var c = getController();
        c.settings.setStart(m); Store.saveSettings(c.settings); _menu.refresh(c.settings);
    }

    function onEndPicked(m as Number) as Void {
        var c = getController();
        c.settings.setEnd(m); Store.saveSettings(c.settings); _menu.refresh(c.settings);
    }
}
