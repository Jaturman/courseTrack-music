using Toybox.Graphics as Gfx;
using Toybox.WatchUi;
using Toybox.Communications as Communications;
using Toybox.Lang as Lang;

class Top50View extends WatchUi.View {
    private var _title;

    private static const BACKEND_BASE_URL = "http://localhost:8787";
    private var _loading;
    private var _pageIndex;
    private var _rows;
    private var _fetchInFlight;

    function initialize() {
        View.initialize();
        _title = "Top 50 (AT ALL)";
        _loading = false;
        _pageIndex = 0;
        _fetchInFlight = false;
        _rows = [
            "--",
            "--",
            "--",
            "--",
            "--",
            "--",
            "--",
            "--",
            "--",
            "--"
        ];
    }

    function onShow() {
        View.onShow();
        // Refresca al entrar: resetea a página 0.
        _pageIndex = 0;
        fetchPage();
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

        // 10 filas, una por línea.
        var y = 42;
        var lineH = 12;
        for (var i = 0; i < 10; i += 1) {
            dc.drawText(w / 2, y + (i * lineH), Gfx.FONT_TINY, _rows[i], Gfx.TEXT_JUSTIFY_CENTER);
        }

        // Indicador de página.
        dc.drawText(w / 2, h - 10, Gfx.FONT_TINY, "Pg " + (_pageIndex + 1).toString() + "/5", Gfx.TEXT_JUSTIFY_CENTER);
    }

    function nextPage() as Void {
        _pageIndex += 1;
        if (_pageIndex > 4) { _pageIndex = 0; }
        fetchPage();
    }

    function fetchPage() as Void {
        if (_fetchInFlight) { return; }
        _fetchInFlight = true;
        _loading = true;

        for (var i = 0; i < 10; i += 1) { _rows[i] = "--"; }

        WatchUi.requestUpdate();

        var offset = _pageIndex * 10;
        var url = BACKEND_BASE_URL + "/leaderboard/top50?offset=" + offset + "&limit=10";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, method(:onTop50Response));
    }

    function shortName(name as Lang.String) {
        if (name == null) { return ""; }
        if (name.length() <= 6) { return name; }
        return name.substring(0, 6);
    }

    function onTop50Response(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        _loading = false;
        _fetchInFlight = false;

        if (responseCode != 200 || data == null) {
            WatchUi.requestUpdate();
            return;
        }

        var entries = data["entries"];
        if (entries == null) {
            WatchUi.requestUpdate();
            return;
        }

        var offset = _pageIndex * 10;
        var n = entries.size();
        for (var i = 0; i < 10; i += 1) {
            if (i < n) {
                var e = entries[i];
                var nm = e["name"] as Lang.String;
                var val = e["value"];
                var short = shortName(nm);
                var pos = (offset + i + 1).toString();
                _rows[i] = pos + ". " + short + " " + val.toString();
            } else {
                _rows[i] = "--";
            }
        }

        WatchUi.requestUpdate();
    }
}

class Top50ViewDelegate extends WatchUi.InputDelegate {
    private var _view;

    function initialize(view) {
        WatchUi.InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent) {
        var k = keyEvent.getKey();

        // UP: ciclo hasta Measurement (pantalla 1).
        if (k == WatchUi.KEY_UP) {
            // Stack esperado: [Measurement, MyBest, PeriodBest, Top50]
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // Top50 -> PeriodBest
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // PeriodBest -> MyBest
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // MyBest -> Measurement
            return true;
        }

        // DOWN: volver a PeriodBest (pantalla 3)
        if (k == WatchUi.KEY_DOWN) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // Top50 -> PeriodBest
            return true;
        }

        // ENTER: siguiente página (10 por pantalla)
        if (k == WatchUi.KEY_ENTER) {
            if (_view != null && (_view has :nextPage)) {
                _view.nextPage();
            }
            return true;
        }

        return false;
    }
}

