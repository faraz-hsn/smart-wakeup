import Toybox.Lang;

// Contract every data source fulfils. The session calls start(listener) and
// receives one MinuteSample per minute via listener.invoke(sample).
// Implementations: LiveSensorSource (real watch), ReplaySensorSource (demo).
class SensorSource {
    protected var _listener as Method or Null = null;

    function initialize() {}

    function start(listener as Method) as Void { _listener = listener; }

    function stop() as Void { _listener = null; }

    // True for the demo source; lets the UI show demo-only extras.
    function isReplay() as Boolean { return false; }

    protected function emit(s as MinuteSample) as Void {
        if (_listener != null) { _listener.invoke(s); }
    }
}
