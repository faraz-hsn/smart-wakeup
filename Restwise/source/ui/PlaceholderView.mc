import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Temporary screen for step 0; replaced by SetupView in step 9.
class PlaceholderView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.AppName) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
