using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.WatchUi;

class MusicView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onLayout(dc) {
    }

    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.drawText(w / 2, 24, Gfx.FONT_LARGE, Rez.Strings.HelloTitle, Gfx.TEXT_JUSTIFY_CENTER);

        var app = App.getApp();
        var counter = app.getProperty("counter");
        if (counter == null) { counter = 0; }
        var playing = app.getProperty("playing");
        if (playing == null) { playing = false; }

        var line1 = "Estado: " + (playing ? "PLAY" : "PAUSE");
        var line2 = "Counter: " + counter;

        dc.drawText(w / 2, h / 2 - 10, Gfx.FONT_MEDIUM, line1, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h / 2 + 18, Gfx.FONT_SMALL, line2, Gfx.TEXT_JUSTIFY_CENTER);

        dc.drawText(w / 2, h - 28, Gfx.FONT_XTINY, Rez.Strings.HelloHint, Gfx.TEXT_JUSTIFY_CENTER);
    }
}

