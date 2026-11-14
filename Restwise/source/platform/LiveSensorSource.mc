import Toybox.Lang;
import Toybox.Sensor;

// Real watch sensors -> EpochAggregator -> one MinuteSample per minute.
// Motion: accelerometer at 25 Hz, delivered once per second in batches.
// Heart rate: 1 Hz from Sensor.Info.
class LiveSensorSource extends SensorSource {
    static const ACCEL_HZ = 25;

    private var _agg as EpochAggregator;
    private var _clock as Clock;
    private var _minuteStart as Number = 0;

    function initialize(clock as Clock) {
        SensorSource.initialize();
        _agg = new EpochAggregator();
        _clock = clock;
    }

    function start(listener as Method) as Void {
        SensorSource.start(listener);
        _minuteStart = _clock.nowSec() - (_clock.nowSec() % 60);
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensorInfo));
        Sensor.registerSensorDataListener(method(:onSensorData), {
            :period => 1,
            :accelerometer => { :enabled => true, :sampleRate => ACCEL_HZ }
        });
        Log.d("Live", "started");
    }

    function stop() as Void {
        Sensor.unregisterSensorDataListener();
        Sensor.enableSensorEvents(null);
        Sensor.setEnabledSensors([]);
        SensorSource.stop();
    }

    function onSensorInfo(info as Sensor.Info) as Void {
        checkMinute();
        _agg.addHeartRate(info.heartRate);
    }

    function onSensorData(data as Sensor.SensorData) as Void {
        checkMinute();
        var a = data.accelerometerData;
        if (a != null) { _agg.addAccel(a.x, a.y, a.z); }
    }

    // Emit when the wall-clock minute rolls over.
    private function checkMinute() as Void {
        var now = _clock.nowSec();
        if (now - _minuteStart >= 60) {
            var s = _agg.flush(_minuteStart);
            _minuteStart = now - (now % 60);
            emit(s);
        }
    }
}
