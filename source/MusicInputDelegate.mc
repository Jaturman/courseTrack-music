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

        if (key == WatchUi.KEY_ENTER) {
            feedback();
            // Arranca una nueva ronda (5s) de captura de pico.
            app.setProperty("startRound", true);
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }
}

