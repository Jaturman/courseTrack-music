using Toybox.Application as App;
using Toybox.WatchUi;

class MusicApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        var view = new MusicView();
        return [ view, new MusicInputDelegate(view) ];
    }
}

function getApp() as MusicApp {
    return App.getApp() as MusicApp;
}

