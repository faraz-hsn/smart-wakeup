import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Morning screen: when and WHY Restwise woke you, plus a night timeline.
class MorningView extends WatchUi.View {
    private var _log as NightLog;

    function initialize(log as NightLog) {
        View.initialize();
        _log = log;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth(); var h = dc.getHeight(); var cx = w / 2;
        var j = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var n = _log;

        dc.drawText(cx, h * 0.14, Graphics.FONT_XTINY, "Woke you at", j);
        dc.drawText(cx, h * 0.27, Graphics.FONT_NUMBER_MILD, n.wakeSec > 0 ? WakeText.clock(n.wakeSec) : "--", j);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.41, Graphics.FONT_XTINY, WakeText.reason(n.reason), j);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (n.wakeSec > 0) {
            dc.drawText(cx, h * 0.50, Graphics.FONT_XTINY, WakeText.earliness(n.wakeSec, n.windowEndSec), j);
        }

        // Timeline: one thin bar per minute, colour = state, height = depth.
        var states = n.states.toCharArray();
        var total = states.size();
        var left = w * 0.15; var width = w * 0.70; var base = h * 0.72;
        for (var i = 0; i < total; i++) {
            var st = states[i].toNumber() - 48;   // '0'..'2' -> 0..2
            var bh = st == SleepState.SETTLED ? 22 : (st == SleepState.RESTLESS ? 12 : 4);
            dc.setColor(NightView.stateColor(st), Graphics.COLOR_TRANSPARENT);
            var x = left + (i * width / (total > 0 ? total : 1));
            var bw = width / (total > 0 ? total : 1) + 1;
            dc.fillRectangle(x, base - bh, bw < 1 ? 1 : bw, bh);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.82, Graphics.FONT_XTINY,
            "Settled " + WakeText.duration(n.count(SleepState.SETTLED)) + "  Awake " + n.count(SleepState.AWAKE) + "m", j);
    }
}

class MorningDelegate extends WatchUi.BehaviorDelegate {
    function initialize() { BehaviorDelegate.initialize(); }
    function onBack() as Boolean { getController().goHome(); return true; }
    function onSelect() as Boolean { getController().goHome(); return true; }
}
