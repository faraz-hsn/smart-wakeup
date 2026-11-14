import Toybox.Lang;
import Toybox.Test;

// Proves the unit-test pipeline works. Real tests arrive with each core layer.
(:test)
function smokeTest(logger as Test.Logger) as Boolean {
    Test.assertEqual(2, 1 + 1);
    return true;
}
