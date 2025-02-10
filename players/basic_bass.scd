(
// Set defaults (WARNING: this should be BEFORE waitForBoot!)
~tempo = 120;
~beatsPerBar = 4;
// How many bars it takes to change the tonic
~barsPerChange = 8;

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

    // Pattern events
    ~evnts = (
        motiff: Pbind(
            \instrument, \electricBass,
            \detune, Pwhite(1, 1.005),
            \amp, Pseq([1, Pwhite(0.55, 0.65, 4), 0]),
            \midinote, Plazy({Pseq(~tonic + [0, 5, 7], 2) }),
            \dur, Pseq(#[1, 0.5, 0.5, 0.5, 0.5]),
            \legato, Pseq([Pwrand([0.5, 1], [0.2, 0.8]), Pwhite(0.2, 0.6, 4)])
        ),
        rest: Pbind(
            \degree, Pseq([Rest(1)]),
            \dur, Pseq(#[1]),
        ),
        octave: Pmono(\electricBass,
            \midinote, Plazy({ Pseq(~tonic + [0, 12, 0]) }),
            \dur, Pseq([0.25, 0.25, 0.5]),
            \amp, 0.5,
            \detune, 1.005
        ),
        tritone: Pmono(\electricBass,
            // \midinote, Pseq([Pwrand([36, Rest(1)], #[0.7, 0.3], 1), 42, 41, 33]),
            \midinote, Plazy({ Pseq(~tonic + [3, 9, 8, 0]) }),
            \dur, Pseq([0.25, 0.25, 0.25, 0.25]),
            \amp, 0.5,
            \detune, 1.005
        ),
        dim: Pmono(\electricBass,
            // \midinote, Pseq([Pwrand([36, Rest(1)], #[0.7, 0.3], 1), 39, 36, 42]),
            \midinote, Plazy({ Pseq(~tonic + [0, 3, 0, 6]) }),
            \dur, Pseq([0.25, 0.25, 0.25, 0.25]),
            \amp, 0.5,
            \detune, 1.005
        )
    );

    ~players_patt = Pseq([
        ~evnts[\motiff],
        Pwrand(
            [
                ~evnts[\rest],
                ~evnts[\octave],
                ~evnts[\tritone],
                ~evnts[\dim]
            ],
            [5, 1, 1, 1].normalizeSum
        )
    ], inf)
});
)