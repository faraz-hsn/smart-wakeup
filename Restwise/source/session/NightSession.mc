import Toybox.Lang;
import Toybox.Timer;

// Runs one night: sensors -> engine -> wake decider -> alarm -> storage.
// Every dependency is passed in, so tests use fakes and the demo uses replay.
module SessionState {
    enum {
        IDLE       = 0,
        MONITORING = 1,   // night running, before the wake window
        IN_WINDOW  = 2,   // inside the wake window, waiting for a light moment
        ALARMING   = 3,
        DONE       = 4
    }
}

class NightSession {
    // If no minute arrives for this long, the watchdog decides on its own,
    // so the alarm still fires at the window end even if sensors stall.
    static const WATCHDOG_MS = 60 * 1000;
    static const STALE_SEC = 150;

    var state as Number = SessionState.IDLE;
    var engine as SleepStateEngine;
    var decider as WakeDecider or Null = null;
    var log as NightLog or Null = null;
    var lastSample as MinuteSample or Null = null;
    var minutes as Number = 0;

    private var _source as SensorSource;
    private var _clock as Clock;
    private var _alarm as AlarmDriver;
    private var _settings as WakeSettings;
    private var _persist as Boolean;
    private var _onChange as Method or Null;
    private var _watchdog as Timer.Timer or Null = null;
    private var _lastMinuteAt as Number = 0;

    function initialize(source as SensorSource, clock as Clock, alarm as AlarmDriver,
                        settings as WakeSettings, restingHr as Number or Null,
                        persist as Boolean, onChange as Method or Null) {
        _source = source; _clock = clock; _alarm = alarm; _settings = settings;
        _persist = persist; _onChange = onChange;
        engine = new SleepStateEngine(restingHr);
    }

    function isReplay() as Boolean { return _source.isReplay(); }

    function start() as Void {
        var now = _clock.nowSec();
        var nowMin = _clock.minuteOfDay(now);
        if (_settings.mode == WakeMode.GOAL) {
            var latest = WakeDecider.nextTimeOf(now, nowMin, _settings.latestMin);
            decider = new QualityGoalDecider(_settings.goalMin, latest);
            log = new NightLog(now, latest, latest);
            log.goalMin = _settings.goalMin;
        } else {
            var w = SmartWakeDecider.nextWindow(now, nowMin, _settings);
            decider = new SmartWakeDecider(w[0], w[1]);
            log = new NightLog(now, w[0], w[1]);
        }
        log.mode = _settings.mode;
        state = SessionState.MONITORING;
        _lastMinuteAt = now;
        _source.start(method(:onMinute));
        if (!_source.isReplay()) {
            _watchdog = new Timer.Timer();
            _watchdog.start(method(:onWatchdog), WATCHDOG_MS, true);
        }
        Log.d("Session", "start; mode " + _settings.mode + " window " + decider.windowStartSec + ".." + decider.windowEndSec);
        changed();
    }

    // One minute of data from the source.
    function onMinute(s as MinuteSample) as Void {
        if (state != SessionState.MONITORING && state != SessionState.IN_WINDOW) { return; }
        lastSample = s;
        minutes++;
        var st = engine.process(s);
        log.addMinute(st);
        _lastMinuteAt = _clock.nowSec();
        evaluate(s.epochSec + 60, st);
    }

    // Safety net: sensors silent for too long -> decide with what we have.
    function onWatchdog() as Void {
        var now = _clock.nowSec();
        if (now - _lastMinuteAt >= STALE_SEC) {
            evaluate(now, engine.lastState);
        }
    }

    private function evaluate(minuteEndSec as Number, st as Number) as Void {
        var fired = decider.onMinute(minuteEndSec, st);
        if (decider instanceof QualityGoalDecider) {
            log.bankedMin = (decider as QualityGoalDecider).bankedMin;
            log.windowStartSec = decider.windowStartSec;
            log.windowEndSec = decider.windowEndSec;
        }
        if (fired) {
            log.wakeSec = decider.firedAtSec;
            log.reason = decider.reason;
            state = SessionState.ALARMING;
            stopSensing();
            _alarm.start();
            save();
            Log.d("Session", "WAKE reason=" + decider.reason + " at " + decider.firedAtSec);
        } else if (minuteEndSec >= decider.windowStartSec) {
            state = SessionState.IN_WINDOW;
        }
        changed();
    }

    function dismiss() as Void {
        _alarm.dismiss();
        state = SessionState.DONE;
        save();
        changed();
    }

    function snooze() as Void {
        _alarm.snooze();
        changed();
    }

    // User stops the night early (BACK on the night screen, confirmed).
    function cancel() as Void {
        stopSensing();
        _alarm.dismiss();
        state = SessionState.DONE;
        save();
        changed();
    }

    private function stopSensing() as Void {
        _source.stop();
        if (_watchdog != null) { _watchdog.stop(); _watchdog = null; }
    }

    private function save() as Void {
        if (_persist && log != null) { Store.saveNight(log); }
    }

    private function changed() as Void {
        if (_onChange != null) { _onChange.invoke(); }
    }
}
