import Toybox.Lang;
import Toybox.Timer;

// Demo source: replays a recorded night (one row per minute) at high speed.
// Data rows: [minuteOffset, activity_mG, hrMean_or_-1, hrStd_or_-1, labLabel_or_-1]
// The FastClock is advanced so every layer above sees "real" night time.
class ReplaySensorSource extends SensorSource {
    private var _rows as Array;
    private var _startSec as Number;
    private var _clock as FastClock;
    private var _msPerMinute as Number;
    private var _i as Number = 0;
    private var _timer as Timer.Timer or Null = null;

    // startSec: epoch second of the first replayed minute (e.g. 23:00 local).
    function initialize(rows as Array, startSec as Number, clock as FastClock, msPerMinute as Number) {
        SensorSource.initialize();
        _rows = rows;
        _startSec = startSec;
        _clock = clock;
        _msPerMinute = msPerMinute;
    }

    function isReplay() as Boolean { return true; }

    function start(listener as Method) as Void {
        SensorSource.start(listener);
        _i = 0;
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), _msPerMinute, true);
        Log.d("Replay", "started, " + _rows.size() + " minutes");
    }

    function stop() as Void {
        if (_timer != null) { _timer.stop(); _timer = null; }
        SensorSource.stop();
    }

    function onTick() as Void {
        if (_i >= _rows.size()) { stop(); return; }
        var r = _rows[_i] as Array;
        _i++;
        var t = _startSec + (r[0] as Number) * 60;
        _clock.setNow(t + 59);   // end of this minute
        emit(new MinuteSample(t, (r[1] as Number).toFloat(),
            neg1ToNull(r[2]), neg1ToNull(r[3]),
            (r[4] as Number) < 0 ? null : r[4] as Number));
    }

    private function neg1ToNull(v) as Float or Null {
        return (v as Number) < 0 ? null : (v as Number).toFloat();
    }
}
