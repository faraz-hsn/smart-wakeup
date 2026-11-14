import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Entry point. Creates the controller and shows the home (setup) menu.
class RestwiseApp extends Application.AppBase {
    var controller as RestwiseController or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        controller = new RestwiseController();
        return controller.homeView();
    }
}
