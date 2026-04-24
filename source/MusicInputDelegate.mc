using Toybox.Attention;
using Toybox.WatchUi;

class MusicInputDelegate extends WatchUi.InputDelegate {
    function initialize() {
        WatchUi.InputDelegate.initialize();
    }

    function feedback() as Void {
        if (Attention has :playTone) {
            try {
                Attention.playTone(Attention.TONE_KEY);
                return;
            } catch (e) {
            }
        }
        if (Attention has :vibrate) {
            try {
                Attention.vibrate([ new Attention.VibeProfile(40, 80) ]);
            } catch (e2) {
            }
        }
    }

    function onKey(keyEvent) {
        var key = keyEvent.getKey();
        var app = getApp();

        var counter = app.getProperty("counter");
        if (counter == null) { counter = 0; }
        var playing = app.getProperty("playing");
        if (playing == null) { playing = false; }

        if (key == WatchUi.KEY_UP) {
            feedback();
            app.setProperty("counter", counter + 1);
            WatchUi.requestUpdate();
            return true;
        }

        if (key == WatchUi.KEY_DOWN) {
            feedback();
            app.setProperty("counter", counter - 1);
            WatchUi.requestUpdate();
            return true;
        }

        if (key == WatchUi.KEY_ENTER) {
            feedback();
            app.setProperty("playing", !playing);
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }
}

