(
// Set defaults for the pattern
~tempo = 90;
~beatsPerBar = 4;
// How many bars it takes to change the tonic
~barsPerChange = 8;


//init/cleanup
s.newBusAllocators;
~vbus = Bus.audio(s, 2);
s.freeAll;
s.waitForBoot({

    //fm synth
    SynthDef(\fm, {
        arg freq=500, mRatio=1, cRatio=1,
        index=1, iScale=5, cAtk=4, cRel=(-4),
        amp=0.2, atk=0.01, rel=3, pan=0,
        out=0, fx=0, fxsend=(-25);
        var car, mod, env, iEnv;

        //index of modulation
        iEnv = EnvGen.kr(
            Env(
                [index, index*iScale, index],
                [atk, rel],
                [cAtk, cRel]
            )
        );

        //amplitude envelope
        env = EnvGen.kr(Env.perc(atk,rel,curve:[cAtk,cRel]),doneAction:2);

        //modulator/carrier
        mod = SinOsc.ar(freq * mRatio, mul:freq * mRatio * iEnv);
        car = SinOsc.ar(freq * cRatio + mod) * env * amp;

        car = Pan2.ar(car, pan);

        //direct out/reverb send
        Out.ar(out, car);
        Out.ar(fx, car * fxsend.dbamp);
    }).add;

    //reverb
    SynthDef(\reverb, {
        arg in=0, out=0, dec=4, lpf=1500;
        var sig;
        sig = In.ar(in, 2).sum;
        sig = DelayN.ar(sig, 0.03, 0.03);
        sig = CombN.ar(sig, 0.1, {Rand(0.01,0.099)}!32, dec);
        sig = SplayAz.ar(2, sig);
        sig = LPF.ar(sig, lpf);
        5.do{sig = AllpassN.ar(sig, 0.1, {Rand(0.01,0.099)}!2, 3)};
        sig = LPF.ar(sig, lpf);
        sig = LeakDC.ar(sig);
        Out.ar(out, sig);
    }).add;

    s.sync;

    Synth(\reverb, [\in, ~vbus]);

    s.sync;

    //array of sequencers
    ~players = [

        //bass
        Pbind(
            \instrument, \fm,
            \dur, 1/4,
            \midinote,Pseq([
                Pseq([ Plazy({[~tonic,   ~tonic+12]}) ], 32),
                Pseq([ Plazy({[~tonic,   ~tonic+ 8]}) ], 24),
                Pseq([ Plazy({[~tonic+5, ~tonic+17]}) ], 8),
            ], inf)
            + Pwrand([0, 12], [0.9, 0.1], inf),
            \mRatio, 2,
            \index, 1.5,
            \iScale, Pseq([3,2.5,2,1],inf),
            \atk, 0,
            \rel, Pexprand(0.2,0.4,inf),
            \amp, Pseq([Pgeom(0.28,-3.dbamp,4)],inf),
            \pan, Pseq([-0.25,0.25],inf),
            \out, 0,
            \fx, ~vbus,
            \fxsend, -20,
        ),

        //lead
        Pbind(
            \instrument, \fm,
            \dur, 1/4,
            \midinote, Pseq([Pfin(
                40,
                Plazy({~tonic + Pseq([12, 15, 17, 19, 22, 24], inf)})
            )], inf),
            \mRatio, Pwrand([0.5, 1.5, 2, 3], [1, 3, 6, 25].normalizeSum, inf),
            \index, Pexprand(2, 2.5),
            \iScale, Pseq([Pgeom(1.2, 1.2, 6)], inf),
            \atk, Pwrand([0, Pexprand(0.02, 0.1, 1)], [0.99, 0.01], inf),
            \rel, Pseq(Array.interpolation(64, 0.03, 0.25).mirror2, inf),
            \cAtk, 1,
            \cRel, Pseq(Array.interpolation(64, -4, 3).mirror2, inf),
            \amp, Pseq([Pfin(54, Pseq([Pgeom(0.13, -5.dbamp, 7)], inf))], inf),
            \pan, Pseq(Array.interpolation(64, 0, 1).lincurve(0, 1, 0, 1, 8), inf) * Pseq([1, -1], inf),
            \out, 0,
            \fx, ~vbus,
            \fxsend, -15,
        ),

        //pad
        Pbind(
            \instrument, \fm,
            \dur, 1/4 * 24,
            \midinote, Pseq([
                Plazy({~tonic + [ 0, 12, 17, 19, 22]}),
                Plazy({~tonic + [ 0, 15, 17, 19, 24]}),
                Plazy({~tonic + [ 0, 12, 17, 19, 22]}),
                Plazy({~tonic + [-7,  5, 17, 19, 24]}),
            ], inf),
            \mRatio, 1,
            \index, 1.5,
            \iScale, Pseq([2,4],inf),
            \atk, 1/6 * 16,
            \rel, 1/6 * 24,
            \cAtk, 0,
            \cRel, 0,
            \amp, 0.027,
            \out, 0,
            \fx, ~vbus,
            \fxsend, -10,
        ),

        //snare
        Pbind(
            \instrument, \fm,
            \dur, 1/4,
            \freq, Pseq([
                \,\,\,\,1,\,\,\,
                \,\,\,\,1,\,\,\,
                \,\,\,\,1,\,\,\,
                \,\,\,\,1,\,\,1,
                \,\,\,\,1,\,\,\,
                \,\,\,\,1,\,\,\,
                \,\,\,\,1,\,\,\,
                \,\,\,\,1,1,1,1,
            ],inf) * 411,
            \cRatio, 45.9,
            \mRatio, 1.5,
            \index, 100,
            \iScale, 1,
            \atk, 0,
            \rel, 0.1,
            \cRel, -8,
            \amp, Pseq([0.18,0.04,0.18,0.1],inf),
            \pan, 0,
            \out, 0,
            \fx, ~vbus,
            \fxsend, -12,
        ),

        //kick
        Pbind(
            \instrument, \fm,
            \dur, 1/4,
            \freq, 25,
            \mRatio, 0.4,
            \index, 2,
            \iScale, 8,
            \atk, 0,
            \rel, 0.08,
            \amp, Pseq([Pgeom(0.8,-2.dbamp,8)],inf),
            \pan, Pseq([0.3,-0.3],inf),
            \out, 0,
            \fx, ~vbus,
            \fxsend, -16,
        )
    ];

    ~players_patt = Ppar(~players);
});
)