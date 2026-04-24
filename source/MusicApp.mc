using Toybox.Application as App;
using Toybox.WatchUi;

class MusicApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
        setProperty("counter", 0);
        setProperty("playing", false);
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [ new MusicView(), new MusicInputDelegate() ];
    }
}

function getApp() as MusicApp {
    return App.getApp() as MusicApp;
}

