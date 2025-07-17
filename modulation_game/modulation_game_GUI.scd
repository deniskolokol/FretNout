// WARNING: every player file should include ~players_patt env var
//          which is structure holder for a pattern.
//          Play/Pause/Stop is managed in the GUI.

(
// GUI variables
var win;
var transportCtrlGroup, volCtrlGroup, tempoCtrlGroup, patternsGroup;
var startButton, stopButton, pauseButton;
var noteText, pattList, volumeSlider, tempoSlider;
var patternsList=Array.new;
var isPlaying = false, isPaused = false;
var currentVolume = 0.5;
var margin = 10;

// Pattern variables
var bpm = 80;
var beatsPerBar = 4;
var barsPerChange = 8;
var tClock, task;

var dirCurrent = thisProcess.nowExecutingPath.dirname;
var dirPlayers = PathName(dirCurrent +/+ "players");


// -- ENVIRONMENT --
~tonic = "a 1".notemidi.asInteger;
~srvVol = Server.default.volume.volume;

// -- GUI --
// Create the window with FlowLayout
win = Window("Modulation Game", Rect(35, 1090, 370, 520))
    .front
    .background_(Color.grey(0.9));
win.view.decorator = FlowLayout(win.bounds, margin@margin, margin@margin);

// Note display
noteText = StaticText(win, 350@100)
    .string_(~tonic.midiname)
    .font_(Font("Arial", 72))
    .align_(\center)
    .background_(Color.grey(0.85));

win.view.decorator.nextLine;

// Tempo control group
tempoCtrlGroup = CompositeView(win, 350@40)
.background_(Color.grey(0.85))
.decorator_(FlowLayout(Rect(0, 0, 350, 40), margin@margin, margin@margin));

tempoSlider = EZSlider(
    tempoCtrlGroup, 320@20, "Tempo ", [1, 300, \lin, 1, 80, "bpm"].asSpec,
    initVal: 80,
    unitWidth: 40,
    labelWidth: 60,
    numberWidth: 40,
);
win.view.decorator.nextLine;

// Volume control group
volCtrlGroup = CompositeView(win, 350@40)
.background_(Color.grey(0.85))
.decorator_(FlowLayout(Rect(0, 0, 350, 40), margin@margin, margin@margin));

volumeSlider = EZSlider(
    volCtrlGroup, 320@20, "Volume", \db.asSpec,
    initVal: s.volume.volume.dbamp,
    unitWidth: 40,
    labelWidth: 60,
    numberWidth: 40,
);
win.view.decorator.nextLine;

// Patterns list group
patternsGroup = CompositeView(win, 350@220)
.background_(Color.grey(0.85))
.decorator_(FlowLayout(Rect(0, 0, 350, 230), margin@margin, margin@margin));

pattList = EZListView(
    patternsGroup, 300@200,
    "Patterns:",
    initVal: 2,
    initAction: true,
    labelWidth: 120,
    labelHeight: 16,
    layout: \vert,
    gap: 2@2
);
// Read all pattern files
if (dirPlayers.isFolder) {
    "Adding players".postln;
    dirPlayers.filesDo { |file|
        if (file.extension == "scd") {
            postf("> %\n", file.fileName);
            pattList.addItem(
                file.fileName.replace(".scd", "").asSymbol,
                { |pl|
                    file.fullPath.load;
                    tempoSlider.valueAction_(~tempo);
                }
            )
        }
    }
} {
    postf(
        "Warning: 'players' directory not found at path:%\n", dirPlayers.fullPath
    );
};
win.view.decorator.nextLine;

// Transport controls group
transportCtrlGroup = CompositeView(win, 350@50)
.background_(Color.grey(0.85))
.decorator_(FlowLayout(Rect(0, 0, 350, 50), margin@margin, margin@margin));

startButton = Button(transportCtrlGroup, 80@30)
.states_([
    ["Start", Color.black, Color.green(0.7)],
    ["Pause", Color.black, Color.yellow(0.7)]
]);

pauseButton = Button(transportCtrlGroup, 80@30)
.states_([["Pause", Color.black, Color.yellow(0.7)]]);

stopButton = Button(transportCtrlGroup, 80@30)
.states_([["Stop", Color.white, Color.red(0.7)]]);

// Task that changes pitch every barsPerChange bars.
task = Task({
    inf.do({ |i|
        // Play notes for ~barsPerChange
		~tonic = rrand("e 1".notemidi.asInteger, "g 2".notemidi.asInteger);
        postf("% - %\n", ~tonic, ~tonic.midiname);
        { noteText.string_(~tonic.midiname) }.defer;
        (~barsPerChange * ~beatsPerBar).wait;
    });
}
);

tClock = TempoClock.new;

// -- ACTIONS --
// Warning: server must be running!
s.waitForBoot({
    // GUI elements actions.
    startButton.action_({ |bt|
        var startPlaying = {
            task.start(tClock);
            ~mod_player = ~players_patt.play(tClock);
        };
        var resumePlaying = {
            task.resume(tClock);
            ~mod_player.resume(tClock);
        };

        if (bt.value == 1) {
            // (re)start the task and the pattern
            if (~mod_player.isNil) {
                startPlaying.()
            } {
                if (~mod_player.isPlaying.not) {
                    startPlaying.()
                } {
                    resumePlaying.()
                }
            }
        } {
            // pause
            task.pause;
            if (~mod_player.isNil.not) { ~mod_player.pause };
        }
    });

    stopButton.action_({
        task.stop;
        task.reset;
        if (~mod_player.isNil.not) {
            ~mod_player.stop;
            ~mod_player.reset;
        };
        startButton.value = 0;
    });

    volumeSlider.action_({ |sl|
        Server.default.volume.volume = sl.value
    });

    tempoSlider.action_({ |sl|
        tClock.schedAbs(tClock.nextBar, { tClock.tempo_(sl.value/60) })
    })
});

// -- CLEANUP --
win.onClose_({
    task.stop;
    ~mod_player.stop;
    tClock.stop;
    Server.default.volume.volume = ~srvVol;
});

CmdPeriod.doOnce({
    win.close;
});
)