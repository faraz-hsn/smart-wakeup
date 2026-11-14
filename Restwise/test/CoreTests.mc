import Toybox.Lang;
import Toybox.Test;

// ---- helpers --------------------------------------------------------------
function rwSample(t as Number, act as Float, hr as Float or Null) as MinuteSample {
    return new MinuteSample(t * 60, act, hr, hr == null ? null : 1.0, null);
}

// Feed n identical minutes, return last state.
function rwFeed(e as SleepStateEngine, n as Number, act as Float, hr as Float or Null) as Number {
    var s = SleepState.AWAKE;
    for (var i = 0; i < n; i++) { s = e.process(rwSample(i, act, hr)); }
    return s;
}

// ---- EpochAggregator -----------------------------------------------------
(:test)
function aggStillWristIsNearZero(logger as Test.Logger) as Boolean {
    var a = new EpochAggregator();
    a.addAccel([0, 0, 0], [0, 0, 0], [1000, 1000, 1000]);   // gravity only
    a.addHeartRate(55); a.addHeartRate(57);
    var s = a.flush(0);
    Test.assert(s.activity < 0.5);
    Test.assertEqual(56.0, s.hrMean);
    return true;
}

(:test)
function aggMovementRaisesActivity(logger as Test.Logger) as Boolean {
    var a = new EpochAggregator();
    a.addAccel([300, -300], [0, 0], [1000, 1000]);   // |(300,0,1000)| = 1044 -> 44 mG
    var s = a.flush(0);
    Test.assert(s.activity > 40.0 && s.activity < 50.0);
    Test.assert(s.hrMean == null);
    return true;
}

(:test)
function aggFlushResets(logger as Test.Logger) as Boolean {
    var a = new EpochAggregator();
    a.addAccel([500], [0], [1000]);
    a.flush(0);
    Test.assertEqual(0, a.sampleCount());
    Test.assertEqual(0.0, a.flush(60).activity);
    return true;
}

// ---- SleepStateEngine ----------------------------------------------------
(:test)
function engineAwakeBeforeOnset(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    Test.assertEqual(SleepState.AWAKE, rwFeed(e, 5, 1.0, 60.0));   // still, but < 10 min
    Test.assert(!e.isAsleep());
    return true;
}

(:test)
function engineSettlesAfterLongStillness(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    Test.assertEqual(SleepState.SETTLED, rwFeed(e, 25, 1.0, 58.0));
    Test.assert(e.isAsleep());
    return true;
}

(:test)
function engineStirIsRestless(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    rwFeed(e, 25, 1.0, 58.0);                                   // asleep, settled
    var s = e.process(rwSample(30, 30.0, 60.0));                // small movement, HR normal
    Test.assertEqual(SleepState.RESTLESS, s);
    return true;
}

(:test)
function engineWalkingIsAwake(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    rwFeed(e, 25, 1.0, 58.0);
    var s = e.process(rwSample(30, 150.0, 85.0));               // walking, HR up
    Test.assertEqual(SleepState.AWAKE, s);
    return true;
}

(:test)
function engineHrSpikeAloneIsAwake(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    rwFeed(e, 25, 1.0, 58.0);
    var s = e.process(rwSample(30, 1.0, 80.0));                 // lying still, HR +35%
    Test.assertEqual(SleepState.AWAKE, s);
    return true;
}

(:test)
function engineNeedsStillnessToResettle(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    rwFeed(e, 25, 1.0, 58.0);
    e.process(rwSample(30, 150.0, 85.0));                       // got up
    var s = SleepState.AWAKE;
    for (var i = 31; i < 36; i++) { s = e.process(rwSample(i, 1.0, 59.0)); }
    Test.assertEqual(SleepState.RESTLESS, s);                   // only 5 still minutes
    return true;
}

(:test)
function engineSmallStirBreaksSettled(logger as Test.Logger) as Boolean {
    var e = new SleepStateEngine(60);
    rwFeed(e, 25, 1.0, 58.0);                                   // settled
    var s = e.process(rwSample(30, 12.0, 58.0));                // turning over: 12 mG
    Test.assertEqual(SleepState.RESTLESS, s);
    return true;
}
