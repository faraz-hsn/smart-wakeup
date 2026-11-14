import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Night screen: dark, small clock + window (your choice). In demo/replay mode
// it also shows the live label, the sleep lab's label and heart rate.
class NightView extends WatchUi.View {
    function initialize() { View.initialize(); }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var c = getController();
        var s = c.session;
        var w = dc.getWidth(); var h = dc.getHeight();
        var cx = w / 2;

        // time: real clock live, simulated night time in demo
        var timeText;
        if (s != null && s.isReplay() && s.lastSample != null) {
            timeText = WakeText.clock((s.lastSample as MinuteSample).epochSec + 60);
        } else {
            var t = System.getClockTime();
            timeText = t.hour.format("%d") + ":" + t.min.format("%02d");
        }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.30, Graphics.FONT_NUMBER_MILD, timeText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h * 0.50, Graphics.FONT_XTINY, "Wake " + SetupMenu.windowText(c.settings),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (s == null) { return; }
        var status = s.state == SessionState.IN_WINDOW ? "In window - waiting for light sleep" : "Sleep well";
        dc.drawText(cx, h * 0.60, Graphics.FONT_XTINY, status, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Demo only: live label vs sleep lab
        if (s.isReplay() && s.lastSample != null) {
            var smp = s.lastSample as MinuteSample;
            var ours = s.engine.lastState;
            dc.setColor(stateColor(ours), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.72, Graphics.FONT_SMALL, "Restwise: " + SleepState.name(ours),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            var lab = smp.labLabel == null ? "-" : SleepState.name(smp.labLabel as Number);
            var hr = smp.hrMean == null ? "--" : (smp.hrMean as Float).format("%d");
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.83, Graphics.FONT_XTINY, "Lab: " + lab + "   HR " + hr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    static function stateColor(st as Number) as Number {
        if (st == SleepState.AWAKE) { return Graphics.COLOR_ORANGE; }
        if (st == SleepState.RESTLESS) { return Graphics.COLOR_YELLOW; }
        return Graphics.COLOR_BLUE;
    }
}

class NightDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }

    // BACK asks before ending the night (so it isn't ended by accident).
    function onBack() as Boolean {
        WatchUi.pushView(new WatchUi.Confirmation("Stop tonight?"), new StopConfirmDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

class StopConfirmDelegate extends WatchUi.ConfirmationDelegate {
    private var _timer as Timer.Timer or Null = null;

    function initialize() { ConfirmationDelegate.initialize(); }

    // The confirmation pops itself AFTER onResponse returns. Ending the night
    // here would switch screens underneath it, and the pop would then remove
    // the home menu. So end the night a moment later, once it has closed.
    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _timer = new Timer.Timer();
            _timer.start(method(:endNight), 100, false);
        }
        return true;
    }

    function endNight() as Void {
        var s = getController().session;
        if (s != null) { s.cancel(); }
    }
}
