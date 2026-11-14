import Toybox.Lang;
import Toybox.Math;

// Turns one minute of raw sensor readings into one MinuteSample.
// Pure logic: no Toybox sensor calls, so it is unit-tested with fake arrays.
//
// Activity = mean of |accel magnitude - 1000 mG| (a.k.a. ENMO-style). At
// rest the wrist reads ~1 g (gravity only), so a still minute is ~0-5 mG,
// fidgeting ~10-40 mG, walking > 100 mG.
class EpochAggregator {
    private var _absDevSum as Float = 0.0;
    private var _accN as Number = 0;
    private var _hrSum as Float = 0.0;
    private var _hrSqSum as Float = 0.0;
    private var _hrN as Number = 0;

    function initialize() {}

    // x, y, z in milli-g, same length.
    function addAccel(x as Array<Number>, y as Array<Number>, z as Array<Number>) as Void {
        var n = x.size();
        for (var i = 0; i < n; i++) {
            var fx = x[i].toFloat(); var fy = y[i].toFloat(); var fz = z[i].toFloat();
            var mag = Math.sqrt(fx * fx + fy * fy + fz * fz);
            var dev = mag - 1000.0;
            _absDevSum += (dev < 0 ? -dev : dev);
        }
        _accN += n;
    }

    function addHeartRate(bpm as Number or Null) as Void {
        if (bpm == null || bpm <= 0) { return; }
        var f = bpm.toFloat();
        _hrSum += f; _hrSqSum += f * f; _hrN++;
    }

    function sampleCount() as Number { return _accN; }

    // Close the current minute and start a new one.
    function flush(epochSec as Number) as MinuteSample {
        var activity = _accN > 0 ? (_absDevSum / _accN) : 0.0;
        var hrMean = null; var hrStd = null;
        if (_hrN > 0) {
            var m = _hrSum / _hrN;
            var v = _hrSqSum / _hrN - m * m;
            hrMean = m;
            hrStd = v > 0 ? Math.sqrt(v).toFloat() : 0.0;
        }
        _absDevSum = 0.0; _accN = 0; _hrSum = 0.0; _hrSqSum = 0.0; _hrN = 0;
        return new MinuteSample(epochSec, activity.toFloat(), hrMean, hrStd, null);
    }
}
