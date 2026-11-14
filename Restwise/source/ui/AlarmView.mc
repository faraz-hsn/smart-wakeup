import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Ringing screen. START = Dismiss, BACK = Snooze 5 min (your choices).
class AlarmView extends WatchUi.View {
    function initialize() { View.initialize(); }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth(); var h = dc.getHeight(); var cx = w / 2;
        var s = getController().session;
        var when = (s != null && s.log != null) ? WakeText.clock((s.log as NightLog).wakeSec) : "";
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.25, Graphics.FONT_MEDIUM, "Good morning", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.45, Graphics.FONT_NUMBER_MEDIUM, when, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.68, Graphics.FONT_XTINY, "START  stop alarm", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, h * 0.78, Graphics.FONT_XTINY, "BACK  snooze 5 min", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class AlarmDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }

    function onSelect() as Boolean {          // START
        var s = getController().session;
        if (s != null) { s.dismiss(); }
        return true;
    }

    function onBack() as Boolean {            // BACK
        var s = getController().session;
        if (s != null) { s.snooze(); }
        return true;
    }
}
