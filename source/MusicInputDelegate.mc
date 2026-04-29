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

        // ENTER: inicia medición solo si no se está midiendo.
        if (k == WatchUi.KEY_ENTER) {
            if (_view != null && (_view has :isRecording) && !_view.isRecording()) {
                startRound();
            } else if (_view != null && !(_view has :isRecording)) {
                // Compatibilidad: si el método no existe, asumimos que no está midiendo.
                startRound();
            }
            return true;
        }

        // UP/DOWN: navegación secuencial 1→2→3→4→1; bloqueada durante los 5s.
        if (k == WatchUi.KEY_UP || k == WatchUi.KEY_DOWN) {
            if (_view != null && (_view has :isRecording) && _view.isRecording()) {
                return true; // bloquea navegación durante medición
            }

            if (k == WatchUi.KEY_UP) {
                WatchUi.pushView(new MyBestView(), new MyBestViewDelegate(), WatchUi.SLIDE_UP);
                return true;
            }

            // DOWN desde pantalla 1 -> pantalla 4 (Top50), manteniendo el stack esperado.
            WatchUi.pushView(new MyBestView(), new MyBestViewDelegate(), WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new PeriodBestView(), new PeriodBestViewDelegate(), WatchUi.SLIDE_IMMEDIATE);
            var v4 = new Top50View();
            WatchUi.pushView(v4, new Top50ViewDelegate(v4), WatchUi.SLIDE_UP);
            return true;
        }

        return false;
    }

    // Algunos dispositivos reportan mejor por pressed/released que por onKey.
    function onKeyPressed(keyEvent) {
        var k = keyEvent.getKey();

        // ENTER: iniciar medición.
        if (k == WatchUi.KEY_ENTER) {
            if (_view != null && (_view has :isRecording) && !_view.isRecording()) {
                startRound();
            } else if (_view != null && !(_view has :isRecording)) {
                startRound();
            }
            return true;
        }

        // UP/DOWN: no duplicamos aquí; onKey ya se encarga.
        return false;
    }
}

