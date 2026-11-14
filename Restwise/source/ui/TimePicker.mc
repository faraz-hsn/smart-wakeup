import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Number column for the time picker: values start, start+step, ... < limit.
class StepFactory extends WatchUi.PickerFactory {
    private var _start as Number;
    private var _step as Number;
    private var _limit as Number;
    private var _fmt as String;

    function initialize(start as Number, limit as Number, step as Number, fmt as String) {
        PickerFactory.initialize();
        _start = start; _limit = limit; _step = step; _fmt = fmt;
    }

    function getSize() as Number { return (_limit - _start + _step - 1) / _step; }

    function getValue(index as Number) as Object or Null { return _start + index * _step; }

    function indexOf(value as Number) as Number {
        var i = (value - _start) / _step;
        return i < 0 ? 0 : (i >= getSize() ? getSize() - 1 : i);
    }

    function getDrawable(index as Number, selected as Boolean) as WatchUi.Drawable or Null {
        return new WatchUi.Text({
            :text => (getValue(index) as Number).format(_fmt),
            :color => selected ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY,
            :font => Graphics.FONT_NUMBER_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}

// Hour : minute picker (minutes in 5-minute steps, your choice).
class TimePicker extends WatchUi.Picker {
    static const MINUTE_STEP = 5;

    function initialize(title as String, minOfDay as Number) {
        var hours = new StepFactory(0, 24, 1, "%d");
        var mins = new StepFactory(0, 60, MINUTE_STEP, "%02d");
        var colon = new WatchUi.Text({ :text => ":", :font => Graphics.FONT_NUMBER_MEDIUM,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_CENTER,
            :color => Graphics.COLOR_WHITE });
        var titleText = new WatchUi.Text({ :text => title, :font => Graphics.FONT_SMALL,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color => Graphics.COLOR_WHITE });
        Picker.initialize({
            :title => titleText,
            :pattern => [hours, colon, mins],
            :defaults => [hours.indexOf(minOfDay / 60), 0, mins.indexOf(minOfDay % 60)]
        });
    }
}

// Returns the chosen minute-of-day to a callback.
class TimePickerDelegate extends WatchUi.PickerDelegate {
    private var _onPicked as Method;

    function initialize(onPicked as Method) {
        PickerDelegate.initialize();
        _onPicked = onPicked;
    }

    function onAccept(values as Array) as Boolean {
        _onPicked.invoke((values[0] as Number) * 60 + (values[2] as Number));
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
