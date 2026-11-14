import Toybox.Attention;
import Toybox.Lang;
import Toybox.Timer;

// Gentle, insistent alarm (report F5; your choices: vibrate then tone,
// 5-minute snooze).
//   0-60 s : vibration pulses every 10 s, getting stronger and longer
//   60 s + : strongest vibration + alarm tone every 10 s, until dismissed
// snooze(): silence, then restart from the gentle stage after snoozeMs.
class AlarmDriver {
    static const STEP_MS = 10000;
    static const TONE_AFTER_STEPS = 6;          // 6 x 10 s = 60 s
    static const SNOOZE_MS = 5 * 60 * 1000;     // 5 minutes

    private var _timer as Timer.Timer or Null = null;
    private var _step as Number = 0;
    private var _snoozeMs as Number;
    var ringing as Boolean = false;
    var snoozeCount as Number = 0;

    // snoozeMs is a parameter so the demo can shorten the 5 minutes.
    function initialize(snoozeMs as Number or Null) {
        _snoozeMs = snoozeMs != null ? snoozeMs : SNOOZE_MS;
    }

    function start() as Void {
        stopTimer();
        ringing = true;
        _step = 0;
        pulse();
        _timer = new Timer.Timer();
        _timer.start(method(:pulse), STEP_MS, true);
    }

    function dismiss() as Void {
        stopTimer();
        ringing = false;
    }

    function snooze() as Void {
        stopTimer();
        ringing = false;
        snoozeCount++;
        _timer = new Timer.Timer();
        _timer.start(method(:start), _snoozeMs, false);
    }

    function pulse() as Void {
        var level = _step < 4 ? 25 + _step * 25 : 100;      // 25, 50, 75, 100 %
        var len = _step < 4 ? 300 + _step * 200 : 1000;     // 0.3 s .. 1 s
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(level, len),
                new Attention.VibeProfile(0, 300),
                new Attention.VibeProfile(level, len)
            ]);
        }
        if (Attention has :backlight) {
            try { Attention.backlight(true); } catch (e) { }
        }
        if (_step >= TONE_AFTER_STEPS && Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALARM);
        }
        _step++;
    }

    private function stopTimer() as Void {
        if (_timer != null) { _timer.stop(); _timer = null; }
    }
}
