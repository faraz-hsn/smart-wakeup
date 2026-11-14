import Toybox.Lang;
import Toybox.System;

// Tiny logging helper. Output appears in the simulator console / monkeydo.
// Set ENABLED to false for a release build.
module Log {
    const ENABLED = true;

    function d(tag as String, msg as String) as Void {
        if (ENABLED) { System.println("[" + tag + "] " + msg); }
    }
}
