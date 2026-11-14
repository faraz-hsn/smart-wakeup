import Toybox.Lang;
import Toybox.Test;

// ---- fakes ----------------------------------------------------------------
class RwFakeSource extends SensorSource {
    var started as Boolean = false;
    function initialize() { SensorSource.initialize(); }
    function start(l as Method) as Void { SensorSource.start(l); started = true; }
    function stop() as Void { SensorSource.stop(); started = false; }
    function isReplay() as Boolean { return true; }      // no watchdog timer in tests
    function push(s as MinuteSample) as Void { emit(s); }
}

class RwFakeAlarm extends AlarmDriver {
    var starts as Number = 0; var dismisses as Number = 0; var snoozes as Number = 0;
    function initialize() { AlarmDriver.initialize(1000); }
    function start() as Void { starts++; ringing = true; }
    function dismiss() as Void { dismisses++; ringing = false; }
    function snooze() as Void { snoozes++; ringing = false; }
}

// Builds a session whose window starts 60 minutes after "now".
class RwSessionRig {
    var clock as FastClock; var src as RwFakeSource; var alarm as RwFakeAlarm;
    var session as NightSession; var t as Number;
    function initialize() {
        t = 1700000000 - (1700000000 % 60);
        clock = new FastClock(t);
        var nowMin = clock.minuteOfDay(t);
        var s = (nowMin + 60) % 1440;
        if (s > 1380) { s = 30; }               // keep start+30 within the day
        src = new RwFakeSource();
        alarm = new RwFakeAlarm();
        session = new NightSession(src, clock, alarm, new WakeSettings(s, s + 30), 60, false, null);
        session.start();
    }
    // Push one minute and advance the clock.
    function minute(act as Float, hr as Float) as Void {
        src.push(new MinuteSample(t, act, hr, 1.0, null));
        t += 60;
        clock.setNow(t);
    }
}

// ---- tests ----------------------------------------------------------------
(:test)
function sessionStartsMonitoring(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    Test.assertEqual(SessionState.MONITORING, r.session.state);
    Test.assert(r.src.started);
    Test.assertEqual(r.session.decider.windowStartSec + 1800, r.session.decider.windowEndSec);
    return true;
}

(:test)
function sessionNoAlarmBeforeWindowEvenIfRestless(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    for (var i = 0; i < 20; i++) { r.minute(1.0, 55.0); }
    r.minute(30.0, 58.0);                                   // a stir at minute 21
    Test.assertEqual(0, r.alarm.starts);
    Test.assertEqual(SessionState.MONITORING, r.session.state);
    return true;
}

(:test)
function sessionWakesOnStirInWindow(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    while (r.t + 60 <= r.session.decider.windowStartSec + 300) { r.minute(1.0, 55.0); }
    Test.assertEqual(SessionState.IN_WINDOW, r.session.state);
    r.minute(30.0, 58.0);                                   // stir 5+ min into window
    Test.assertEqual(SessionState.ALARMING, r.session.state);
    Test.assertEqual(1, r.alarm.starts);
    Test.assertEqual(WakeReason.LIGHT_SLEEP, r.session.log.reason);
    Test.assert(!r.src.started);                            // sensors off while ringing
    return true;
}

(:test)
function sessionWakesAtWindowEnd(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    var guard = 0;
    while (r.session.state != SessionState.ALARMING && guard < 200) { r.minute(1.0, 55.0); guard++; }
    Test.assertEqual(WakeReason.WINDOW_END, r.session.log.reason);
    Test.assertEqual(r.session.decider.windowEndSec, r.session.log.wakeSec);
    return true;
}

(:test)
function sessionDismissAndSnooze(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    while (r.session.state != SessionState.ALARMING) { r.minute(1.0, 55.0); }
    r.session.snooze();
    Test.assertEqual(1, r.alarm.snoozes);
    Test.assertEqual(SessionState.ALARMING, r.session.state);
    r.session.dismiss();
    Test.assertEqual(SessionState.DONE, r.session.state);
    Test.assertEqual(1, r.alarm.dismisses);
    return true;
}

(:test)
function sessionWatchdogFiresAtWindowEndWithoutData(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    r.clock.setNow(r.session.decider.windowEndSec + 10);    // sensors went silent all night
    r.session.onWatchdog();
    Test.assertEqual(SessionState.ALARMING, r.session.state);
    Test.assertEqual(WakeReason.WINDOW_END, r.session.log.reason);
    return true;
}

(:test)
function sessionCancelStopsEverything(logger as Test.Logger) as Boolean {
    var r = new RwSessionRig();
    r.minute(1.0, 55.0);
    r.session.cancel();
    Test.assertEqual(SessionState.DONE, r.session.state);
    Test.assert(!r.src.started);
    r.minute(30.0, 60.0);                                    // late data ignored
    Test.assertEqual(0, r.alarm.starts);
    return true;
}
