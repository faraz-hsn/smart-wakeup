import Toybox.Lang;

// Shared vocabulary for every layer.

// What one minute of the night looked like.
module SleepState {
    enum {
        AWAKE    = 0,
        RESTLESS = 1,   // light / stirring sleep: a good moment to wake someone
        SETTLED  = 2    // deep / stable sleep: avoid waking here
    }

    function name(s as Number) as String {
        if (s == AWAKE)    { return "awake"; }
        if (s == RESTLESS) { return "restless"; }
        return "settled";
    }
}

// One minute of summarised sensor data. Produced by EpochAggregator (live)
// or ReplaySensorSource (demo). Everything above the platform layer only
// ever sees MinuteSamples, never raw sensor callbacks.
class MinuteSample {
    var epochSec as Number;          // start of the minute, seconds since 1970 (UTC)
    var activity as Float;           // mean |accel magnitude - 1 g| over the minute, in milli-g
    var hrMean as Float or Null;     // mean heart rate (bpm); null if no reading this minute
    var hrStd as Float or Null;      // heart-rate standard deviation within the minute
    var labLabel as Number or Null;  // demo only: sleep-lab label (SleepState) for comparison

    function initialize(epochSec as Number, activity as Float, hrMean as Float or Null,
                        hrStd as Float or Null, labLabel as Number or Null) {
        self.epochSec = epochSec;
        self.activity = activity;
        self.hrMean = hrMean;
        self.hrStd = hrStd;
        self.labLabel = labLabel;
    }
}
