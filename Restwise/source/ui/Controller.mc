import Toybox.Application;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.WatchUi;

// Glue between screens and the session. Owns the settings and the current
// night. Screens call it; it switches screens when the session changes state.
class RestwiseController {
    var settings as WakeSettings;
    var session as NightSession or Null = null;

    function initialize() {
        settings = Store.loadSettings();
    }

    function homeView() as [WatchUi.Views, WatchUi.InputDelegates] {
        var menu = new SetupMenu(settings, Store.loadLastNight() != null);
        return [menu, new SetupMenuDelegate(menu)];
    }

    // "Go to sleep" from the setup menu.
    function startNight() as Void {
        var clock = new Clock();
        startWith(new LiveSensorSource(clock), clock, new AlarmDriver(null));
    }

    // Demo: replay the real PhysioNet night at high speed (your choices:
    // ~45 s per night, 10 s snooze). Data minute DEMO_ALIGN_MIN is placed at the
    // start of the user's wake window, so the window covers the night's last hour.
    static const DEMO_ALIGN_MIN = 225;
    static const DEMO_MS_PER_MINUTE = 150;      // 284 min x 150 ms = ~43 s
    static const DEMO_SNOOZE_MS = 10000;

    function startDemo() as Void {
        var data = WatchUi.loadResource(Rez.JsonData.DemoNight) as Dictionary;
        var rows = data["rows"] as Array;
        var real = new Clock();
        var now = real.nowSec();
        var w = SmartWakeDecider.nextWindow(now, real.minuteOfDay(now), settings);
        var startSec = w[0] - DEMO_ALIGN_MIN * 60;
        var clock = new FastClock(startSec);
        startWith(new ReplaySensorSource(rows, startSec, clock, DEMO_MS_PER_MINUTE),
            clock, new AlarmDriver(DEMO_SNOOZE_MS));
    }

    // Shared by live and demo nights.
    function startWith(source as SensorSource, clock as Clock, alarm as AlarmDriver) as Void {
        Store.saveSettings(settings);
        var resting = UserProfile.getProfile().restingHeartRate;
        session = new NightSession(source, clock, alarm, settings, resting, true, method(:onSessionChanged));
        WatchUi.switchToView(new NightView(), new NightDelegate(), WatchUi.SLIDE_LEFT);
        session.start();
    }

    // Called by the session after every minute / state change.
    function onSessionChanged() as Void {
        var s = session;
        if (s == null) { return; }
        if (s.state == SessionState.ALARMING && !(WatchUi.getCurrentView()[0] instanceof AlarmView)) {
            WatchUi.switchToView(new AlarmView(), new AlarmDelegate(), WatchUi.SLIDE_UP);
        } else if (s.state == SessionState.DONE) {
            var log = s.log;
            session = null;
            if (log != null && log.reason != WakeReason.NONE) {
                WatchUi.switchToView(new MorningView(log), new MorningDelegate(), WatchUi.SLIDE_UP);
            } else {
                var home = homeView();
                WatchUi.switchToView(home[0], home[1], WatchUi.SLIDE_RIGHT);
            }
        }
        WatchUi.requestUpdate();
    }

    function showLastNight() as Void {
        var log = Store.loadLastNight();
        if (log != null) {
            WatchUi.pushView(new MorningView(log), new MorningDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    function goHome() as Void {
        var home = homeView();
        WatchUi.switchToView(home[0], home[1], WatchUi.SLIDE_RIGHT);
    }
}

function getController() as RestwiseController {
    return (Application.getApp() as RestwiseApp).controller;
}
