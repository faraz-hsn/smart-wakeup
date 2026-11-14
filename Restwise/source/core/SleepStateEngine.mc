import Toybox.Lang;

// Labels each minute AWAKE / RESTLESS / SETTLED from movement + heart rate.
// Pure logic, unit-tested in test/SleepStateEngineTest.mc.
//
// 1. Movement score: a *causal* Cole-Kripke-style weighted sum of the last
//    5 minutes of activity (we cannot use future minutes in real time):
//        D = P * (106*A[-4] + 54*A[-3] + 58*A[-2] + 76*A[-1] + 230*A[0])
//    D >= 1 means "moving like someone awake". P is scaled so that a steady
//    ~10 mG of activity gives D = 1 (see DECISIONS.md).
// 2. Sleep onset: first run of ONSET_STILL_MIN consecutive still minutes.
//    Everything before onset is AWAKE.
// 3. Heart-rate baseline: slow average of HR during still minutes after onset
//    (seeded from the user's resting HR if known).
// 4. Label after onset:
//    AWAKE    - moving (D >= 1) AND (HR > baseline * 1.10 or activity >= WALK_MG),
//               or HR > baseline * 1.25 on its own
//    SETTLED  - still for >= SETTLED_STILL_MIN minutes, HR <= baseline * 1.05,
//               and steady HR (std <= STEADY_HR_STD)
//    RESTLESS - everything else (stirring, recently moved, HR slightly up)
class SleepStateEngine {
    static const WEIGHTS = [106.0, 54.0, 58.0, 76.0, 230.0];   // oldest .. current
    static const P = 1.0 / (524.0 * 10.0);                     // 10 mG steady -> D = 1
    static const ONSET_STILL_MIN = 10;
    static const SETTLED_STILL_MIN = 10;
    static const WALK_MG = 100.0;
    static const STEADY_HR_STD = 3.0;
    static const STIR_MG = 8.0;          // a single small movement (turning over)

    private var _hist as Array<Float> = [0.0, 0.0, 0.0, 0.0, 0.0];
    private var _stillRun as Number = 0;
    private var _asleep as Boolean = false;
    private var _baseline as Float or Null = null;

    // Last result, exposed for the session / UI / wake decider.
    var lastState as Number = SleepState.AWAKE;
    var lastD as Float = 0.0;

    function initialize(restingHr as Number or Null) {
        if (restingHr != null && restingHr > 30) { _baseline = restingHr.toFloat(); }
    }

    function isAsleep() as Boolean { return _asleep; }
    function baselineHr() as Float or Null { return _baseline; }

    function process(s as MinuteSample) as Number {
        // shift activity history
        _hist = [_hist[1], _hist[2], _hist[3], _hist[4], s.activity];
        var sum = 0.0;
        for (var i = 0; i < 5; i++) { sum += WEIGHTS[i] * _hist[i]; }
        var d = P * sum;
        lastD = d.toFloat();
        var moving = d >= 1.0;

        // A stir (below "awake-like" movement) still breaks stillness -> RESTLESS.
        var stir = s.activity >= STIR_MG;
        _stillRun = (moving || stir) ? 0 : _stillRun + 1;
        if (!_asleep && _stillRun >= ONSET_STILL_MIN) { _asleep = true; }

        var hr = s.hrMean;
        // Baseline learns only from still minutes, slowly (about 30-minute memory).
        if (hr != null && !moving) {
            if (_baseline == null) { _baseline = hr; }
            else if (_asleep) { _baseline = _baseline + (hr - _baseline) / 30.0; }
        }

        var state;
        if (!_asleep) {
            state = SleepState.AWAKE;
        } else {
            var hrHigh = false; var hrVeryHigh = false; var hrNearBase = true;
            if (hr != null && _baseline != null) {
                hrHigh = hr > _baseline * 1.10;
                hrVeryHigh = hr > _baseline * 1.25;
                hrNearBase = hr <= _baseline * 1.05;
            }
            var steady = (s.hrStd == null) || (s.hrStd <= STEADY_HR_STD);

            if (hrVeryHigh || (moving && (hrHigh || s.activity >= WALK_MG))) {
                state = SleepState.AWAKE;
            } else if (_stillRun >= SETTLED_STILL_MIN && hrNearBase && steady) {
                state = SleepState.SETTLED;
            } else {
                state = SleepState.RESTLESS;
            }
        }
        lastState = state;
        return state;
    }
}
