(
// Set defaults (WARNING: this should be BEFORE waitForBoot!)
~tempo = 40;
~beatsPerBar = 4;
// How many bars it takes to change the tonic
//
// Warning: actually 12, but we use dur=1/4 in the pattern,
// which with beatsPerBar=4 makes:
// - a single note dur in the pattern 1/16
// - beats per bar = 3 = 12 / 4
~barsPerChange = 3;

//init/cleanup
s.newBusAllocators;
s.freeAll;
s.waitForBoot({

    // TODO: check the following:
    // OSC 1 is set to something like 10%sine-90% triangle
    // OSC is set to sine (i shape it to be triangle to have more
    // harmonic but it lose the real guitare bass feeling)
    // Osc mix set to someting like 40% of osc 1 and 60% of osc 2
    // I very slightly overload the pream of the mixer and it work
    // just fine to make some bass sound (mostly for Dub).


    //Electric bass guitar
    SynthDef(\electricBass, {
        arg freq=440, detune=1.005, ffreq=1100, width=0.15,
        preAmpOsc1=0.1, preAmpOsc2=0.5,
        atk=0.05, dec=0.2, slev=0.4, rel=0.3;

        var osc1, osc2, sub, noise, sig, env, frq;

        env = Env.adsr(atk, dec, slev, rel).ar(Done.freeSelf, \gate.kr(1));

        frq = Lag.kr(freq, \dur.kr(0.17));
        frq = [frq, frq * detune];

        osc1 = Mix(SinOsc.ar(frq, 0, preAmpOsc1));
        osc2 = Mix(VarSaw.ar(frq, 0, width, preAmpOsc2));

        // Sub-oscillator one octave down
        sub = Mix(SinOsc.ar(frq * 0.5)) * \subLevel.kr(0.3);

        // String noise component
        noise = LPF.ar(WhiteNoise.ar, ffreq) * EnvGen.kr(
            Env.perc(0.05, 1, \noiseLevel.kr(0.15), -6)
        );

        // Mix it up!
        sig = Mix([
            osc1,
            osc2,
            sub,
            noise
        ]);
        sig = LPF.ar(sig, ffreq);
        sig = Pan2.ar(sig, \pan.kr(0), \amp.kr(0.5));
        sig = sig * env;
        Out.ar(\out.kr(0), sig)
    }).add;

    s.sync;

    //array of sequencers
    ~players = [
        Pbind(
            \instrument, \electricBass,
            \dur, 1/4,
            \midinote, Pseq([
                Plazy({~tonic     + Pseq([0, 5, 8, 5], 4)}), // A
                Plazy({(~tonic+5) + Pseq([0, 5, 8, 5], 2)}), // D
                Plazy({~tonic     + Pseq([0, 5, 8, 5], 2)}), // A
                Plazy({(~tonic-5) + Pseq([0, 5, 8, 5], 1)}), // E
                Plazy({(~tonic+5) + Pseq([0, 5, 8, 5], 1)}), // D
                Plazy({~tonic     + Pseq([0, 5, 8, 5], 1)}), // A
                Plazy({(~tonic-5) + Pseq([0, 5, 8, 5], 1)}) // E
            ], inf),
            \amp, Pseq([Pgeom(0.28,-3.dbamp, 4)], inf)
        ),
    ];

    ~players_patt = Ppar(~players);
});
)