using Toybox.Graphics as Gfx;
using Toybox.WatchUi;

class MusicView extends WatchUi.View {
    private var _title;

    function initialize() {
        View.initialize();
        _title = "";
    }

    function onLayout(dc) {
        // `Rez.Strings.*` es un id numérico; hay que resolverlo a texto.
        _title = WatchUi.loadResource(Rez.Strings.HelloWorld);
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(w / 2, h / 2, Gfx.FONT_LARGE, _title, Gfx.TEXT_JUSTIFY_CENTER);
    }
}

