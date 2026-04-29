using Toybox.Graphics as Gfx;
using Toybox.Attention;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Sensor as Sensor;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.WatchUi;

class MusicView extends WatchUi.View {
    private var _tick;
    private var _countdownTick;
    private var _listening;

    private var _recording;
    private var _startMs;
    private var _maxDynMg;
    private var _hasResult;
    private var _resultDynMg;
    private var _recordDynMg;
    private var _pendingStart;

    function initialize() {
        View.initialize();
        _tick = new Timer.Timer();
        _countdownTick = null;
        _listening = false;
        _recording = false;
        _startMs = 0;
        _maxDynMg = 0;
        _hasResult = false;
        _resultDynMg = 0;
        _recordDynMg = 0;
        _pendingStart = false;
    }

    function onLayout(dc) {
    }

    function onShow() {
        View.onShow();

        if (_tick != null) {
            // En algunos dispositivos intervalos muy bajos se limitan/rompen; 250ms es suficiente para el countdown.
            _tick.stop();
            _tick.start(method(:onTick), 250, true);
        }

        if (_countdownTick == null) { _countdownTick = new Timer.Timer(); }
        // Si el usuario pulsó ENTER antes de que la vista se mostrase, asegúrate de refrescar el countdown.
        if (_recording && _countdownTick != null) {
            _countdownTick.stop();
            _countdownTick.start(method(:onCountdownTick), 200, true);
        }

        if (!_listening) {
            _listening = true;

            var maxRate = null;
            if (Sensor has :getMaxSampleRateForSensorType) {
                maxRate = Sensor.getMaxSampleRateForSensorType(:accelerometer);
            }

            var desiredRate = 100;
            var rate = (maxRate == null) ? desiredRate : maxRate;
            if (maxRate != null && rate > maxRate) { rate = maxRate; }

            try {
                Sensor.registerSensorDataListener(method(:onSensorData), {
                    :period => 1,
                    :accelerometer => {
                        :enabled => true,
                        :sampleRate => rate
                    }
                });
            } catch (e) {
                Sensor.registerSensorDataListener(method(:onSensorData), {
                    :period => 1,
                    :accelerometer => {
                        :enabled => true,
                        :sampleRate => 25
                    }
                });
            }
        }
    }

    function onHide() {
        View.onHide();

        if (_tick != null) {
            _tick.stop();
        }

        if (_countdownTick != null) {
            _countdownTick.stop();
        }

        if (_listening) {
            _listening = false;
            Sensor.unregisterSensorDataListener();
        }
    }

    function playBeep(isEnd, isNewRecord) as Void {
        // Vibra siempre (si está disponible) además del sonido.
        if (Attention has :vibrate) {
            try {
                // Inicio: pulso corto. Fin: doble pulso.
                if (isEnd) {
                    Attention.vibrate([
                        new Attention.VibeProfile(40, 60),
                        new Attention.VibeProfile(40, 60)
                    ]);
                } else {
                    Attention.vibrate([ new Attention.VibeProfile(40, 80) ]);
                }
            } catch (eV) {
            }
        }

        if (Attention has :playTone) {
            try {
                // Inicio: beep simple. Fin: melodía según si hay nuevo récord.
                var tone = Attention.TONE_KEY;
                if (isEnd) {
                    tone = isNewRecord ? Attention.TONE_SUCCESS : Attention.TONE_INTERVAL_ALERT;
                }
                Attention.playTone(tone);
            } catch (e) {
            }
        }
    }

    function processRoundState() as Void {
        // Arranque pedido desde el InputDelegate.
        if (_pendingStart && !_recording) {
            _pendingStart = false;
            _recording = true;
            _startMs = Sys.getTimer();
            _maxDynMg = 0;
            _hasResult = false;
            playBeep(false, false);

            // Timer dedicado para forzar repintado durante el countdown en físico.
            if (_countdownTick != null) {
                _countdownTick.stop();
                _countdownTick.start(method(:onCountdownTick), 200, true);
            }
        }

        if (_recording) {
            var elapsed = Sys.getTimer() - _startMs;
            if (elapsed >= 5000) {
                _recording = false;
                _resultDynMg = _maxDynMg;
                _hasResult = true;
                var prevRecord = _recordDynMg;
                var isNewRecord = (prevRecord > 0) && (_resultDynMg > prevRecord);
                if (_resultDynMg > _recordDynMg) { _recordDynMg = _resultDynMg; }
                playBeep(true, isNewRecord);

                if (_countdownTick != null) {
                    _countdownTick.stop();
                }
            }
        }
    }

    function onTick() as Void {
        processRoundState();

        WatchUi.requestUpdate();
    }

    function onCountdownTick() as Void {
        // Solo fuerza repintado; la lógica de tiempo vive en processRoundState/onUpdate.
        if (_recording) {
            WatchUi.requestUpdate();
        } else if (_countdownTick != null) {
            _countdownTick.stop();
        }
    }

    function requestStartRound() as Void {
        // Puede ser llamado por el InputDelegate.
        if (!_recording) {
            _pendingStart = true;
            // Intenta arrancar ya, sin depender del próximo tick/update.
            processRoundState();
            // Si aún no se ha llamado a onShow, crea el timer del countdown igualmente.
            if (_countdownTick == null) { _countdownTick = new Timer.Timer(); }
            if (_recording && _countdownTick != null) {
                _countdownTick.stop();
                _countdownTick.start(method(:onCountdownTick), 200, true);
            }
            WatchUi.requestUpdate();
        }
    }

    function onSensorData(data as Sensor.SensorData) as Void {
        if (!_recording) { return; }
        if (data == null || data.accelerometerData == null) { return; }

        var ad = data.accelerometerData;
        if (ad.x == null || ad.y == null || ad.z == null) { return; }

        var n = ad.x.size();
        if (n <= 0) { return; }

        // Procesa todas las muestras del batch y guarda el pico.
        for (var i = 0; i < n; i += 1) {
            var ax = ad.x[i];
            var ay = ad.y[i];
            var az = ad.z[i];

            var mag2 = ax * ax + ay * ay + az * az;
            var mag = Math.sqrt(mag2);
            var dyn = mag - 1000;
            if (dyn < 0) { dyn = 0; }

            // Deadband para que en reposo sea 0 visualmente.
            if (dyn < 30) { dyn = 0; }

            if (dyn > _maxDynMg) { _maxDynMg = dyn; }
        }
    }

    function fmtMg(mg) {
        return mg.toString();
    }

    function fmtG(mg) {
        // 1000 milli-g = 1 g
        return (mg / 1000.0).format("%.2f");
    }

    function bigNumberFont() {
        if (Gfx has :FONT_NUMBER_THAI_HOT) { return Gfx.FONT_NUMBER_THAI_HOT; }
        if (Gfx has :FONT_NUMBER_HOT) { return Gfx.FONT_NUMBER_HOT; }
        return Gfx.FONT_LARGE;
    }

    function biggerNumberFont(baseFont) {
        // Intenta subir un escalón respecto a la fuente actual.
        if (baseFont == Gfx.FONT_LARGE && (Gfx has :FONT_NUMBER_HOT)) { return Gfx.FONT_NUMBER_HOT; }
        if (baseFont == Gfx.FONT_NUMBER_HOT && (Gfx has :FONT_NUMBER_THAI_HOT)) { return Gfx.FONT_NUMBER_THAI_HOT; }
        return baseFont;
    }

    function splitFixed2(text) {
        var dot = text.find(".");
        if (dot == null || dot < 0) { return [text, ""]; }
        // substring(start, end)
        return [text.substring(0, dot), text.substring(dot, text.length())]; // incluye el punto en la parte fraccional
    }

    function onUpdate(dc) {
        // Arranca el intervalo incluso si el timer de UI está capado en el dispositivo.
        processRoundState();

        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        // Récord pequeño en el "círculo" superior (Instinct2).
        // Se resetea a 0 al reiniciar la app.
        var recordText = fmtG(_recordDynMg);
        var recordFont = Gfx.FONT_SMALL;
        var rfh = dc.getFontHeight(recordFont);

        // Centro aproximado del subdial superior del Instinct2 (simulador).
        // Ajuste más marcado para que el texto quede centrado en el círculo.
        var cx = w - 34;
        var cy = 28;
        var rx = cx;
        if (dc has :getTextWidth) {
            // Firma: getTextWidth(text, font)
            var rtw = dc.getTextWidth(recordText, recordFont);
            // Evita que el texto se salga por los lados de la pantalla.
            var minCenterX = (rtw / 2) + 2;
            var maxCenterX = w - (rtw / 2) - 2;
            if (rx < minCenterX) { rx = minCenterX; }
            if (rx > maxCenterX) { rx = maxCenterX; }
        }
        dc.drawText(rx, cy - (rfh / 2), recordFont, recordText, Gfx.TEXT_JUSTIFY_CENTER);

        // Prompt fijo, pequeño, en inglés, abajo.
        dc.drawText(w / 2, h - 18, Gfx.FONT_SMALL, "Press Enter", Gfx.TEXT_JUSTIFY_CENTER);

        if (_recording) {
            // Durante los 5s no se muestra el valor registrado.
            var remaining = 5000 - (Sys.getTimer() - _startMs);
            if (remaining < 0) { remaining = 0; }
            // Redondeo hacia arriba para que empiece en 5s.
            var secs = (remaining + 999) / 1000;
            dc.drawText(w / 2, h / 2, Gfx.FONT_MEDIUM, secs.toString() + "s", Gfx.TEXT_JUSTIFY_CENTER);
            // En físico puede que el Timer no dispare; fuerza repintado mientras cuenta.
            WatchUi.requestUpdate();
            return;
        }

        // Justo después del 2º pitido (fin de los 5s), se muestra el valor grande y centrado.
        // Las fuentes numéricas grandes suelen no incluir letras (p.ej. 'g'), así que
        // pintamos el número grande y la unidad con una fuente normal.
        var numText = _hasResult ? fmtG(_resultDynMg) : "--";
        // Mantén el borde superior "enrasado" con la posición actual, pero haz el número visualmente mucho mayor:
        // usa la fuente numérica más grande disponible.
        var baseFont = bigNumberFont();
        var baseFh = dc.getFontHeight(baseFont);
        var topY = (h / 2) - (baseFh / 2);

        var numFont = (Gfx has :FONT_NUMBER_THAI_HOT) ? Gfx.FONT_NUMBER_THAI_HOT : baseFont;
        var numFh = dc.getFontHeight(numFont);
        var y = topY; // enrasado arriba

        // Número máximo tamaño (x.xx) centrado.
        dc.drawText(w / 2, y, numFont, numText, Gfx.TEXT_JUSTIFY_CENTER);

        // Unidad "g" siempre visible cuando hay resultado, colocada según el ancho real del número.
        if (_hasResult) {
            var unitFont = Gfx.FONT_MEDIUM;
            var pad = 6;
            var tw = null;
            if (dc has :getTextWidth) {
                // Firma: getTextWidth(text, font)
                tw = dc.getTextWidth(numText, numFont);
            }
            var ux = (tw == null) ? ((w / 2) + 52) : ((w / 2) + (tw / 2) + pad);
            var uy = y + ((numFh - dc.getFontHeight(unitFont)) / 2);
            dc.drawText(ux, uy, unitFont, "g", Gfx.TEXT_JUSTIFY_LEFT);
        }
    }
}

