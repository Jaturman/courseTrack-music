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
    private var _listening;

    private var _recording;
    private var _startMs;
    private var _maxDynMg;

    function initialize() {
        View.initialize();
        _tick = null;
        _listening = false;
        _recording = false;
        _startMs = 0;
        _maxDynMg = 0;
    }

    function onLayout(dc) {
    }

    function onShow() {
        View.onShow();

        if (_tick == null) {
            _tick = new Timer.Timer();
            _tick.start(method(:onTick), 33, true); // ~30 Hz UI
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
            _tick = null;
        }

        if (_listening) {
            _listening = false;
            Sensor.unregisterSensorDataListener();
        }
    }

    function playBeep() as Void {
        if (Attention has :playTone) {
            try {
                Attention.playTone(Attention.TONE_KEY);
            } catch (e) {
            }
        } else if (Attention has :vibrate) {
            try {
                Attention.vibrate([ new Attention.VibeProfile(40, 80) ]);
            } catch (e2) {
            }
        }
    }

    function onTick() as Void {
        // InputDelegate deja una flag en propiedades para arrancar ronda.
        var app = getApp();
        var startRound = app.getProperty("startRound");
        if (startRound == true && !_recording) {
            app.setProperty("startRound", false);
            _recording = true;
            _startMs = Sys.getTimer();
            _maxDynMg = 0;
            playBeep();
        }

        if (_recording) {
            var elapsed = Sys.getTimer() - _startMs;
            if (elapsed >= 5000) {
                _recording = false;
                playBeep();
            }
        }

        WatchUi.requestUpdate();
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

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        if (_recording) {
            var remaining = 5000 - (Sys.getTimer() - _startMs);
            if (remaining < 0) { remaining = 0; }
            dc.drawText(w / 2, h / 2 - 25, Gfx.FONT_MEDIUM, "GO! " + (remaining / 1000).toString() + "s", Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(w / 2, h / 2 - 25, Gfx.FONT_MEDIUM, "Pulsa ENTER", Gfx.TEXT_JUSTIFY_CENTER);
        }

        dc.drawText(w / 2, h / 2 + 5, Gfx.FONT_LARGE, "MAX", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h / 2 + 35, Gfx.FONT_LARGE, fmtG(_maxDynMg) + " g", Gfx.TEXT_JUSTIFY_CENTER);
    }
}

