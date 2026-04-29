using Toybox.Graphics as Gfx;
using Toybox.WatchUi;
using Toybox.Application as App;
using Toybox.Communications as Communications;
using Toybox.Lang as Lang;

class MyBestView extends WatchUi.View {
    private var _title;

    private static const NAME_STORAGE_KEY = "g-snap_name";
    private static const BACKEND_BASE_URL = "http://localhost:8787";

    private var _loading;
    private var _meName;
    private var _meBestValue;
    private var _meRankGlobal;
    private var _winnersDayName;
    private var _winnersMonthName;
    private var _winnersYearName;

    function initialize() {
        View.initialize();
        _title = "Mis mejores marcas";
        _loading = false;
        _meName = null;
        _meBestValue = null;
        _meRankGlobal = null;
        _winnersDayName = "--";
        _winnersMonthName = "--";
        _winnersYearName = "--";
    }

    function onShow() {
        View.onShow();
        // Refresca al entrar.
        loadAndFetch();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(w / 2, 18, Gfx.FONT_SMALL, _title, Gfx.TEXT_JUSTIFY_CENTER);

        var y = 45;
        if (_loading) {
            dc.drawText(w / 2, h / 2, Gfx.FONT_MEDIUM, "Cargando...", Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        if (_meName == null) {
            dc.drawText(w / 2, h / 2, Gfx.FONT_MEDIUM, "Sin datos", Gfx.TEXT_JUSTIFY_CENTER);
            return;
        }

        dc.drawText(w / 2, y, Gfx.FONT_MEDIUM, "Mi mejor: " + _meBestValue.toString() + " mg", Gfx.TEXT_JUSTIFY_CENTER);
        y += 28;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Global: #" + _meRankGlobal.toString(), Gfx.TEXT_JUSTIFY_CENTER);
        y += 22;

        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Hoy: " + _winnersDayName, Gfx.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Mes: " + _winnersMonthName, Gfx.TEXT_JUSTIFY_CENTER);
        y += 18;
        dc.drawText(w / 2, y, Gfx.FONT_SMALL, "Anio: " + _winnersYearName, Gfx.TEXT_JUSTIFY_CENTER);
    }

    function loadAndFetch() as Void {
        // Reset de estado.
        _loading = true;
        _meName = null;
        _meBestValue = null;
        _meRankGlobal = null;
        _winnersDayName = "--";
        _winnersMonthName = "--";
        _winnersYearName = "--";

        WatchUi.requestUpdate();

        var stored = null;
        try {
            if (App has :Storage) {
                stored = App.Storage.getValue(NAME_STORAGE_KEY);
            }
        } catch (e) {
            stored = null;
        }

        if (stored == null) {
            _loading = false;
            _meName = null;
            WatchUi.requestUpdate();
            return;
        }

        // Se asume que name no incluye caracteres especiales (máx 8 caracteres).
        var name = stored as Lang.String;
        var url = BACKEND_BASE_URL + "/leaderboard/summary?name=" + name;

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, method(:onSummaryResponse));
    }

    function onSummaryResponse(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        _loading = false;

        if (responseCode != 200) {
            WatchUi.requestUpdate();
            return;
        }

        if (data == null) {
            WatchUi.requestUpdate();
            return;
        }

        var period = data["period"];
        if (period != null) {
            var day = period["day"];
            var month = period["month"];
            var year = period["year"];
            _winnersDayName = (day != null) ? day["name"] : "--";
            _winnersMonthName = (month != null) ? month["name"] : "--";
            _winnersYearName = (year != null) ? year["name"] : "--";
        }

        var meObj = data["me"];
        if (meObj == null) {
            _meName = null;
            WatchUi.requestUpdate();
            return;
        }

        _meName = meObj["name"];
        _meBestValue = meObj["bestValue"];
        _meRankGlobal = meObj["rankGlobal"];

        WatchUi.requestUpdate();
    }
}

class MyBestViewDelegate extends WatchUi.InputDelegate {
    function initialize() {
        WatchUi.InputDelegate.initialize();
    }

    function onKey(keyEvent) {
        var k = keyEvent.getKey();

        // UP: pasar a PeriodBest (pantalla 3)
        if (k == WatchUi.KEY_UP) {
            WatchUi.pushView(new PeriodBestView(), new PeriodBestViewDelegate(), WatchUi.SLIDE_UP);
            return true;
        }

        // DOWN: volver a Measurement (pantalla 1)
        if (k == WatchUi.KEY_DOWN) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            return true;
        }

        return false;
    }
}

