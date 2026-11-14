import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Entry point. Owns nothing but wiring: it creates the first screen.
// Later steps add the NightSession here.
class RestwiseApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new PlaceholderView()];
    }
}
