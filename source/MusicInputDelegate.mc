using Toybox.Attention;
using Toybox.WatchUi;

class MusicInputDelegate extends WatchUi.InputDelegate {
    private var _view;

    function initialize(view) {
        WatchUi.InputDelegate.initialize();
        _view = view;
    }

    function startRound() as Void {
        // Feedback inmediato para confirmar que el botón se recibió (útil en físico).
        if (Attention has :vibrate) {
            try { Attention.vibrate([ new Attention.VibeProfile(25, 50) ]); } catch (e) {}
        }
        if (_view != null && (_view has :requestStartRound)) {
            _view.requestStartRound();
        }
        WatchUi.requestUpdate();
    }

    function onKey(keyEvent) {
        var k = keyEvent.getKey();
        // En algunos dispositivos el botón “enter” físico llega como START.
        if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_START) {
            startRound();
            return true;
        }
        return false;
    }

    // Algunos dispositivos reportan mejor por pressed/released que por onKey.
    function onKeyPressed(keyEvent) {
        var k = keyEvent.getKey();
        if (k == WatchUi.KEY_ENTER || k == WatchUi.KEY_START) {
            startRound();
            return true;
        }
        return false;
    }
}

