using Toybox.Graphics as Gfx;
using Toybox.WatchUi;
using Toybox.Communications as Communications;
using Toybox.Lang as Lang;

class PeriodBestView extends WatchUi.View {
    private var _title;

    private static const BACKEND_BASE_URL = "http://localhost:8787";
    private var _loading;
    private var _dayName;
    private var _monthName;
    private var _yearName;
    private var _dayValue;
    private var _monthValue;
    private var _yearValue;

    function initialize() {
        View.initialize();
        _title = "Mejor día/mes/año";
        _loading = false;
        _dayName = "--";
        _monthName = "--";
        _yearName = "--";
        _dayValue = null;
        _monthValue = null;
        _yearValue = null;
    }

    function onShow() {
        View.onShow();
        loadAndFetch();
    }

    function loadAndFetch() as Void {
        _loading = true;
        _dayName = "--";
        _monthName = "--";
        _yearName = "--";
        _dayValue = null;
        _monthValue = null;
        _yearValue = null;

        WatchUi.requestUpdate();

        var url = BACKEND_BASE_URL + "/leaderboard/period";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, method(:onPeriodResponse));
    }

    function onPeriodResponse(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        _loading = false;

        if (responseCode != 200 || data == null) {
            WatchUi.requestUpdate();
            return;
        }

        var day = data["day"];
        var month = data["month"];
        var year = data["year"];

        if (day != null) {
            _dayName = day["name"];
            _dayValue = day["value"];
        }

        if (month != null) {
            _monthName = month["name"];
            _monthValue = month["value"];
        }

        if (year != null) {
            _yearName = year["name"];
            _yearValue = year["value"];
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(w / 2, 18, Gfx.FONT_SMALL, _title, Gfx.TEXT_JUSTIFY_CENTER);

        if (_loading) {
            dc.drawText(w / 2, h / 2, Gfx.FONT_MEDIUM, "Cargando...", Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        var y = 45;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Dia: " + _dayName, Gfx.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Valor: " + ((_dayValue == null) ? "--" : _dayValue.toString()) + " mg", Gfx.TEXT_JUSTIFY_CENTER);
        y += 24;

        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Mes: " + _monthName, Gfx.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Valor: " + ((_monthValue == null) ? "--" : _monthValue.toString()) + " mg", Gfx.TEXT_JUSTIFY_CENTER);
        y += 24;

        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Anio: " + _yearName, Gfx.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Valor: " + ((_yearValue == null) ? "--" : _yearValue.toString()) + " mg", Gfx.TEXT_JUSTIFY_CENTER);
    }
}

class PeriodBestViewDelegate extends WatchUi.InputDelegate {
    function initialize() {
        WatchUi.InputDelegate.initialize();
    }

    function onKey(keyEvent) {
        var k = keyEvent.getKey();

        // UP: pasar a Top50 (pantalla 4)
        if (k == WatchUi.KEY_UP) {
            var v = new Top50View();
            WatchUi.pushView(v, new Top50ViewDelegate(v), WatchUi.SLIDE_UP);
            return true;
        }

        // DOWN: volver a MyBest (pantalla 2)
        if (k == WatchUi.KEY_DOWN) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }

        return false;
    }
}

