(
// Computer Studio 2
s.options.inDevice_("SQ - Audio");
s.options.outDevice_("SQ - Audio");
s.options.numOutputBusChannels = 5;
s.options.maxLogins = 2;
);

(
// Built-in Output
s.options.inDevice_("Built-in Microph");
s.options.outDevice_("Built-in Output");
s.options.numOutputBusChannels = 2;
);

(
// Focusrite
s.options.inDevice_("Focusrite Thunderbolt");
s.options.outDevice_("Focusrite Thunderbolt");
s.options.numOutputBusChannels = 4;
);

(
/* Space */
var space_Pan4 = {
	arg sig, x = 0.0, y = 0.0;
	Pan4.ar(sig, x, y);
};
var space_Stereo = {
	arg sig, x = 0.0, y = 0.0;
	Splay.ar(Pan4.ar(sig, x, y));
};
var space_StereoBrown = {
	arg sig, step = 0.01;
	sig = space_Pan4Brown.value(sig, step);
	Splay.ar(sig);
};
var space_Middle = {
	arg sig;
	Pan4.ar(sig, 0, 0);
};
var space_Pan4Brown = {
	arg sig, step = 0.01;
	var trig = Impulse.kr(0.1);
	var x = Demand.kr(trig, 0, Dbrown(-1, 1, step));
	var y = Demand.kr(trig, 0, Dbrown(-1, 1, step));
	Pan4.ar(sig, x, y);
};
var spaces = if (s.options.numOutputBusChannels == 2, {
	[space_Stereo, space_StereoBrown];
}, {
	[space_Pan4, space_Pan4Brown];
});
var space = spaces[0];
var space_Brown = spaces[1];

/* States */
/*var state_FrictionSpace = {
	arg name,
	    osc_path = '/driangle/manos/friction',
	    ugen_graph_func,
	    synth_arguments = [];
    var synthDefName = ("FrictionSpace_" ++ name).asSymbol;
	var synthCreate = Dosc.synthPlay(synthDefName, synth_arguments);
	{
		// sounds
		SynthDef(synthDefName, ugen_graph_func).add;
		// osc listeners
		Dosc.map(
			(osc_path ++ '/play').asSymbol,
			[
				{
					arg arguments;
					synthCreate.value(arguments[1..]);
				}
			]
		);
	}
};*/

/* State Instances */
var state_Percussion_Sine = {
	arg cratio = 1, maxDecay = 4.0, maxMamp = 1000;
	PercussionPlayer(
		name: 'sine',
		osc_path: '/driangle/manos/perc/sine',
		synth_arguments: [
			Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.8, 1)),
			Dosc.namedNodeArgument(\velocity, \decay, ControlSpec(1.0, maxDecay)),
			Dosc.namedNodeArgument(\x, \freq, ControlSpec(80, 160)),
			Dosc.namedNodeArgument(\y, \mamp, ControlSpec(0.0, maxMamp)),
		],
		ugen_graph_func: {
			arg out = 0, amp = 1, x = 0, y = 0, freq = 100, attack = 0.01, decay = 1, mamp = 0.0;
			var mratio = 2;
			var mfreq = freq * mratio;
			var env = Env.perc(
				attackTime: attack,
				releaseTime: decay
			).kr(doneAction:Done.freeSelf);
			var modulator = SinOsc.ar(mfreq, mul:Line.kr(0, mamp, decay / 2.0));
			var sig = SinOsc.ar((freq * cratio) + modulator);
			sig = space_Brown.value(sig, x, y);
			Out.ar(out, sig * env * amp * 0.3);
		}
	);
};
var state_Point_Flutter = {
	arg release = 2, maxAmp = 1.0, hpf = 300;
	PointPlayer(
		name: 'noise',
		osc_path: '/driangle/manos/point/flutter',
		synth_arguments: [
			Dosc.namedNodeArgument(\x, \freq, ControlSpec(160, 320)),
			Dosc.namedNodeArgument(\y, \fratio, ControlSpec(1, 4)),
			Dosc.namedNodeArgument(\z, \mfreq, ControlSpec(1, 30, \exp)),
		],
		ugen_graph_func: {
			arg out = 0, gate = 1, x = 0, y = 0, amp = 1.0, freq = 100, mfreq = 1, fratio = 1;
			var env = Env.adsr(1, 0, 1, release).kr(gate:gate, doneAction:Done.freeSelf);
			var sig = LFSaw.ar(freq * fratio.round());
			sig = LPF.ar(LPF.ar(sig, 500 * LFSaw.ar(mfreq).range(0, 1), 1), 5000);
			sig = if (hpf > 0, { HPF.ar(sig, hpf); }, {sig });
			sig = space_Brown.value(sig, x, y);
			Out.ar(out, sig * env * amp * maxAmp * 0.4);
		}
	)
};
var state_FrictionSpace_Noise = {
	arg maxAmp = 1.0, hpf = 100;
	PercussionPlayer(
		name:'noise',
		osc_path:'/driangle/manos/friction',
		synth_arguments: [
			Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, maxAmp)),
			Dosc.namedNodeArgument(\x, \x, ControlSpec(-1, 1)),
			Dosc.namedNodeArgument(\y, \y, ControlSpec(-1, 1)),
			Dosc.namedNodeArgument(\z, \friction, ControlSpec(0, 1000)),
			Dosc.namedNodeArgument(\velocity, \releaseTime, ControlSpec(0.2, 1.5))
		],
		ugen_graph_func: {
			arg out = 0, amp = 0.1, x = 0, y = 0, friction = 0.2, releaseTime = 0.5;
			var env = EnvGen.ar(Env.perc(releaseTime:releaseTime), doneAction:Done.freeSelf);
			var sig = BrownNoise.ar;
			sig = HPF.ar(sig, hpf + friction);
			sig = space.value(sig, x, y);
			Out.ar(out, sig * env * amp * 0.05);
		}
	);
};
var state_Percussion_Boom = {
	arg maxDecay = 5.0;
	PercussionPlayer(
		name: 'boom',
		osc_path: '/driangle/manos/perc/boom',
		synth_arguments: [
			Dosc.namedNodeArgument(\z, \freq, ControlSpec(50.0, 200.0)),
			Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.5, 1.0)),
			Dosc.namedNodeArgument(\velocity, \decayTime, ControlSpec(2.0, maxDecay))
		],
		ugen_graph_func: {
			arg amp = 1, x = 0.0, y = 0.0, freq = 50, decayTime = 1;
			var ampEnv = EnvGen.ar(Env.perc(releaseTime:decayTime), doneAction:Done.freeSelf);
			var pitchEnv = EnvGen.ar(Env([freq, 50, 10], [0.01, 0.6 * decayTime]));
			var sig = SinOsc.ar(pitchEnv, phase:pi/2);
			sig = space.value(sig, x, y);
			Out.ar(0, sig * ampEnv * amp * 0.3);
		}
	);
};
var player_Percussion_Kick = PercussionPlayer(
	name: 'kick',
	osc_path: '/driangle/manos/perc/kick',
	synth_arguments: [
		Dosc.namedNodeArgument(\z, \freq, ControlSpec(50.0, 1000.0)),
		Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.5, 1.0)),
		Dosc.namedNodeArgument(\velocity, \decayTime, ControlSpec(0.05, 1.0)),
/*		Dosc.namedNodeArgument(\x, \x, ControlSpec(-1.0, 1.0)),
		Dosc.namedNodeArgument(\y, \y, ControlSpec(-1.0, 1.0)),*/
	],
	ugen_graph_func: {
		arg amp = 1, x = 0.0, y = 0.0, freq = 50, decayTime = 1;
		var ampEnv = EnvGen.ar(Env.perc(releaseTime:decayTime), doneAction:Done.freeSelf);
		var pitchEnv = EnvGen.ar(Env([freq, 50, 10], [0.01, 0.2 * decayTime]));
		var sig = SinOsc.ar(pitchEnv, phase:pi/2);
		sig = space.value(sig, x, y);
		Out.ar(0, sig * ampEnv * amp * 0.5);
	}
);
var state_Pattern_Kick = PatternPlayer(
	name:'kick',
    osc_path: '/driangle/manos/pattern/kick',
    pattern_arguments: [
		Dosc.namedNodeArgument(\z, \freq, ControlSpec(50.0, 1000.0)),
		Dosc.namedNodeArgument(\x, \x, ControlSpec(-1.0, 1.0)),
		Dosc.namedNodeArgument(\y, \y, ControlSpec(-1.0, 1.0)),
		Dosc.namedNodeArgument(\z, \decayTime, ControlSpec(0.1, 3.0, \exp)),
	],
    user_pattern: {
		arg id, synthDefName, proxies;
		Pbind(
			\instrument, synthDefName,
			\freq, proxies.at(\freq),
			// \dur, Pn(Prand([~, 1/8, 1/16], 8)) * proxies.at(\dur),
			\dur, Pseq(Array.fill(8, {
				[1/8, 1/16].wchoose([0.4, 0.6].normalizeSum)
			}),inf) * 2.0,
			\x, proxies.at(\x),
			\y, proxies.at(\y),
			\decayTime, proxies.at(\decayTime),
			\amp, 1.0
		)
	},
	ugen_graph_func: {
		arg out = 0, amp = 1, x = 0.0, y = 0.0, freq = 50, decayTime = 1;
		var ampEnv = EnvGen.ar(Env.perc(releaseTime:decayTime), doneAction:Done.freeSelf);
		var pitchEnv = EnvGen.ar(Env([freq, 50, 10], [0.01, 0.2 * decayTime]));
		var sig = SinOsc.ar(pitchEnv, phase:pi/2);
		sig = space.value(sig, x, y);
		Out.ar(out, sig * ampEnv * amp * 0.5);
	}
);

var state_Point_Pad =  PointPlayer(
	name:'pad',
	osc_path: '/driangle/manos/point/pad',
	synth_arguments: [
		Dosc.namedNodeArgument(\x, \x, ControlSpec(-1.0, 1.0)),
		Dosc.namedNodeArgument(\y, \y, ControlSpec(-1.0, 1.0)),
		Dosc.namedNodeArgument(\z, \freq, ControlSpec(50.0, 200.0)),
		Dosc.namedNodeArgument(\roll, \distortion, ControlSpec(200, 15))
	],
	ugen_graph_func: {
		arg out = 0, gate = 1, x = 0, y = 0, amp = 1, freq = 100, distortion;
		var env = Env.adsr(0.1, 0, 1, 2).kr(gate:gate, doneAction:Done.freeSelf);
		var sig = SinOsc.ar(freq);
		sig = sig.fold2(LPF.ar(LFPulse.ar(distortion, mul:1), 200));
		/*sig = SelectX.ar(
			which: distortion,
			array:[
				sig,
				// Disintegrator.ar(sig, multiplier:0.0)
				sig.fold2(LFNoise1.ar(20))
			]
		);*/
		sig = space.value(sig, x, y);
		Out.ar(out, sig * env * amp * 0.2);
	}
);
var state_Point_SinScaleNeg = PointPlayer(
    name: 'sinScaleNeg',
    osc_path: '/driangle/manos/point',
	synth_arguments: [
		Dosc.namedNodeArgument(\z, \amp, ControlSpec(0, 1)),
		Dosc.namedNodeArgument(\x, \freq, ControlSpec(0, 500)),
		Dosc.namedNodeArgument(\roll, \mfreq, ControlSpec(0, 500))
	],
	ugen_graph_func: {
		arg gate = 1, amp, freq, mfreq;
		var env = Env.adsr(1, 0, 1, 2).kr(gate:gate, doneAction:Done.freeSelf);
		var modulator = SinOsc.ar(mfreq);
		var sig = SinOsc.ar(freq).scaleneg(modulator);
		sig = space_Brown.value(sig);
		Out.ar(0, sig * env * amp * 0.3);
	}
);
var state_Pattern_SineFMArp = PatternPlayer(
	name:'arp',
    osc_path: '/driangle/manos/pattern/sinefm',
    pattern_arguments: [
		Dosc.namedNodeArgument(\z, \dur, ControlSpec(2, 1/16, \exp)),
		Dosc.namedNodeArgument(\x, \mfreq, ControlSpec(50, 2000, \exp)),
		Dosc.namedNodeArgument(\sphereRadius, \decay, ControlSpec(0.5, 2, \exp)),
		Dosc.namedNodeArgument(\roll, \detune, ControlSpec(-100, 100)),
	],
    user_pattern: {
		arg id, synthDefName, proxies;
		var scale = Scale.ahirbhairav;
		var octave = 5;
		var noteCount = 5; // thematic: number of fingers
		var range = 3;
		var x = if (id == 'left', {
			Pbrown(-1, 0)
		}, {
			Pbrown(0, 1)
		});
		Pbind(
			\instrument, synthDefName,
			\scale, scale,
			\octave, octave,
			\degree, Pseq(Array.rand(noteCount, 0, scale.degrees.size * range), inf),
			\dur, proxies.at(\dur),
			\mfreq, proxies.at(\mfreq),
			\decay, proxies.at(\decay),
			\detune, proxies.at(\detune),
			\x, x,
			\y, Pbrown(-1, 1),
			\mamp, Pbrown(0, 1000)
		)
	},
	ugen_graph_func: {
		arg amp = 1.0, x = 0.0, y = 0.0, freq = 50, mfreq = 100, mamp = 200, attack = 0.01, decay = 1;
		var ampEnv = Env.perc(
			attackTime: attack,
			releaseTime: decay
		).kr(doneAction:Done.freeSelf);
		var sig = SinOsc.ar(freq + (SinOsc.ar(mfreq, mul:mamp)));
		sig = space.value(sig, x, y);
		Out.ar(0, sig * ampEnv * amp * 0.8);
	}
);
var state_Percussion_SineFM = {
	arg maxDecay = 2, maxAmp = 1.0;
	PercussionPlayer(
		name: 'sinefm',
		osc_path: '/driangle/manos/perc/sinefm',
		synth_arguments: [
			Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, maxAmp)),
			Dosc.namedNodeArgument(\x, \mfreq, ControlSpec(50, 2000, \exp)),
			Dosc.namedNodeArgument(\y, \mamp, ControlSpec(1000, 50, \exp)),
			Dosc.namedNodeArgument(\z, \freq, ControlSpec(50, 2000, \exp)),
			Dosc.namedNodeArgument(\velocity, \decay, ControlSpec(0.1, maxDecay)),
		],
		ugen_graph_func: {
			arg out = 0, amp = 1, x = 0, y = 0, freq = 100, mfreq = 100, mamp = 500, attack = 0.01, decay = 1;
			var env = Env.perc(
				attackTime: attack,
				releaseTime: decay
			).kr(doneAction:Done.freeSelf);
			var sig = SinOsc.ar(freq + (SinOsc.ar(mfreq, mul:mamp)));
			sig = space.value(sig, x, y);
			Out.ar(out, sig * env * amp * 0.2);
		}
	);
};
var player_Point_SineFM = PointPlayer(
	name: 'sinefm',
	osc_path: '/driangle/manos/point/sinefm',
	synth_arguments: [
		// Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, 1)),
		Dosc.namedNodeArgument(\x, \mfreq, ControlSpec(10, 500, \exp)),
		Dosc.namedNodeArgument(\y, \mamp, ControlSpec(1000, 50, \exp)),
		Dosc.namedNodeArgument(\z, \freq, ControlSpec(10, 1000, \exp)),
	],
	ugen_graph_func: {
		arg out = 0, gate = 1, amp = 1, x = 0.0, y = 0.0, freq = 100, mfreq = 100, mamp = 500;
		var env = Env.adsr(
			attackTime:0.1,
			decayTime:0,
			sustainLevel:1,
			releaseTime:0.25
		).kr(gate:gate, doneAction:Done.freeSelf);
		var modulator = SinOsc.ar(mfreq.lag(0.05), mul:mamp.lag(0.05));
		var sig = SinOsc.ar(freq.lag(0.05) + modulator);
		sig = space_Brown.value(sig, 0.1);
		Out.ar(out, sig * env * amp * 0.1);
	}
);
var player_Point_LightRocks = PercussionPlayer(
    name:'lightrocks',
    osc_path:'/driangle/manos/friction',
    synth_arguments: [
        Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, 1)),
        Dosc.namedNodeArgument(\x, \x, ControlSpec(-1, 1)),
        Dosc.namedNodeArgument(\y, \y, ControlSpec(-1, 1)),
        Dosc.namedNodeArgument(\z, \friction, ControlSpec(0, 20)),
        Dosc.namedNodeArgument(\velocity, \releaseTime, ControlSpec(0.2, 1.5))
    ],
    ugen_graph_func: {
        arg out = 0, amp = 0.1, x = 0, y = 0, friction = 0.2, releaseTime = 0.1;
        var env = EnvGen.ar(Env.perc(releaseTime:releaseTime), doneAction:Done.freeSelf);
        var sig = {
            var sig = Dust.ar(friction);
            var freq = WhiteNoise.kr()
            .range(500, 5000);
            // .range(800, 4000);

            // var decayTime = 0.01;
            var decayTime = 0.04;
            sig = Ringz.ar(sig, freq, decayTime);
            sig;
        }.value;
        sig = HPF.ar(sig, 1000 + friction);
        sig = space.value(sig, x, y);
        Out.ar(out, sig * env * amp * 0.1);
    }
);

var player_Pattern_SineScaleNeg = PatternPlayer(
    name: 'sinescaleneg',
    osc_path: '/driangle/manos/pattern/sinescaleneg',
    pattern_arguments: [
        // Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, 1)),
        Dosc.namedNodeArgument(\x, \low, ControlSpec(-1.0, 1.0)),
        Dosc.namedNodeArgument(\y, \high, ControlSpec(-1.0, 1.0)),
        Dosc.namedNodeArgument(\z, \dur, ControlSpec(0.1, 2, \exp)),
        Dosc.namedNodeArgument(\roll, \mfreq, ControlSpec(30, 0.1)),

    ],
    ugen_graph_func: {
        arg out = 0, gate = 1, amp = 1, x = 0.0, y = 0.0, freq = 100, mfreq = 10, decay = 0.5, release = 2;
        var env = Env.adsr(
            attackTime:0.01,
            decayTime:decay,
            sustainLevel:0.5,
            releaseTime:release
        ).kr(gate: gate, doneAction:Done.freeSelf);
		var fenv = Env.perc(releaseTime:(decay + release) * 0.1).kr();
        var sig = SinOsc.ar(freq).scaleneg(LFTri.ar(mfreq));
		sig = LPF.ar(sig, (2000 * fenv)  + 3000);
        sig = space.value(sig, x, y);
		Out.ar(out, sig * env * amp * 0.2);
    },
    user_pattern: {
        arg id, synthDefName, proxies;
        var scale = [
            Scale.major,
            Scale.iwato,
            Scale.minor,
            Scale.lydian,
            Scale.mixolydian
        ].choose;
        var octave = 5;
        var noteCount = 5; // thematic: number of fingers
        var range = 3;
        var low = proxies.at(\low);
        var high = proxies.at(\high);
        Pbind(
            \instrument, synthDefName,
			\amp, 1.0,
            // \root, 0,
            \scale, scale,
            \degree, Pbrown(low, high, step:5) * 12,
            \octave, octave,
            // \freq, Pwhite(proxies.at(\low), proxies.at(\high)),
            \dur, proxies.at(\dur),
            \decay, proxies.at(\dur) * 4,
            \release, proxies.at(\dur) * 4,
            // \release, proxies.at(\release),
            \x, Pbrown(-1, 1),
            \y, Pbrown(-1, 1),
            \mfreq, proxies.at(\mfreq),
        )
    }
);

var player_Point_Blip = PointPlayer(
    name: 'blip',
    osc_path: '/driangle/manos/point',
    synth_arguments: [
        Dosc.namedNodeArgument(\x, \harmonics, ControlSpec(1, 100, \exp)),
        Dosc.namedNodeArgument(\z, \freq, ControlSpec(20, 100, \exp)),
    ],
    ugen_graph_func: {
        arg out = 0, gate = 1, amp = 1, x = 0.0, y = 0.0, freq = 100, harmonics;
        var env = Env.adsr(
            attackTime:0.1,
            decayTime:0,
            sustainLevel:1,
            releaseTime:0.25
        ).kr(gate:gate, doneAction:Done.freeSelf);
        var sig = Blip.ar(freq, harmonics);
        sig = space_Brown.value(sig);
        Out.ar(out, sig * env * amp * 0.3);
    }
);

var release_DefaultGroup = {
	Server.default.defaultGroup.set(\gate, 0);
};
var reset = {
	Dosc.clear();
	release_DefaultGroup.value();
};

var wait_with_countdown = {
	arg amount, countdown = 5;
	(amount - countdown).wait;
	"... Done in ...".postln;≥
	countdown.do({
		arg index;
		var next = countdown - index;
		next.postln;
		1.wait;
	});
};
var final_performance = {
	var player_Point_Flutter = state_Point_Flutter.value(release:3),
	    player_Percussion_Boom = state_Percussion_Boom.value(),
	    player_Percussion_Sine = state_Percussion_Sine.value(cratio:1, maxDecay:4, maxMamp:100),
	    player_Percussion_SineFM = state_Percussion_SineFM.value(maxDecay:5),
	    player_FrictionSpace_Noise = state_FrictionSpace_Noise.value(),
	    player_Point_SinScaleNeg = state_Point_SinScaleNeg;

	var timeline = PerformanceTimeline();
	// timeline.advance(minutes:5, seconds:30);
	// timeline.advance(minutes:7, seconds:00);

	timeline.at(minutes:0, seconds:0, action: {
		player_FrictionSpace_Noise.start();
		"Gestures: Friction\n".postln;
	});


	timeline.at(minutes:0, seconds:30, action: {
		player_Point_LightRocks.start();
		"Gestures: Friction\n".postln;
	});


	timeline.at(minutes:1, seconds:0, action: {
		player_Percussion_Boom.start();
		"Gestures: Friction, Boom".postln;
	});

	timeline.at(minutes:1, seconds:30, action: {
		player_Percussion_Boom.stop();

		player_Percussion_Sine.start();
		"Gestures: Friction, Strike\n".postln;
	});

	timeline.at(minutes:1, seconds:35, action: {
		player_FrictionSpace_Noise.stop();
		player_Point_LightRocks.stop();
		"Gestures: Strike\n".postln;
	});

	timeline.at(minutes:2, seconds:0, action: {
		player_Percussion_Sine.stop();

		player_Percussion_Sine = state_Percussion_Sine.value(cratio:2, maxDecay:6, maxMamp:1000);

		player_Percussion_Sine.start();
		player_Point_Flutter.start();
		"Gestures: Strike, Flutter\n".postln;
	});

	timeline.at(minutes:3, seconds:00, action: {
		player_Percussion_Sine.stop();
		player_Point_Flutter.stop();

		state_Pattern_SineFMArp.start();
		"Gestures: PatternArp\n".postln;
	});

	timeline.at(minutes:3, seconds:45, action: {
		state_Pattern_SineFMArp.stop();

		player_Percussion_SineFM.start();
		"Gestures: Strike\n".postln;
	});


	timeline.at(minutes:4, seconds:00, action: {
		state_Pattern_SineFMArp.start();
		"Gestures: Strike, PatternArp\n".postln;
	});

	timeline.at(minutes:4, seconds:30, action: {
		state_Pattern_SineFMArp.stop();

		player_Point_SineFM.start();
		"Gestures: Strike, ClosedFist\n".postln;
	});

	timeline.at(minutes:5, seconds:00, action: {
		state_Pattern_SineFMArp.start();
		"Gestures: Strike, ClosedFist, PatternArp\n".postln;
	});

	timeline.at(minutes:5, seconds:30, action: {
		player_Percussion_SineFM.stop();
		player_Point_SineFM.stop();
		state_Pattern_SineFMArp.stop();

		player_Percussion_SineFM = state_Percussion_SineFM.value(maxDecay:8, maxAmp:0.6);

		player_Percussion_SineFM.start();
		player_Pattern_SineScaleNeg.start();
		"Gestures: Strike, PatternArp\n".postln;
	});

	timeline.at(minutes:6, seconds:30, action: {
		player_FrictionSpace_Noise = state_FrictionSpace_Noise.value(maxAmp:0.1, hpf:800);
		player_FrictionSpace_Noise.start();
		"Gestures: Strike, PatternArp, Friction\n".postln;
	});

	timeline.at(minutes:7, seconds:00, action: {
		player_Pattern_SineScaleNeg.stop();
		player_Point_Flutter = state_Point_Flutter.value(release:10, hpf:1000);
		player_Point_Flutter.start();
		"Gestures: Strike, Friction, Flutter\n".postln;
	});

	timeline.at(minutes:7, seconds:30, action: {
		player_Point_SineFM.start();
		"Gestures: Strike, Friction, Flutter, ClosedFist\n".postln;
	});

	timeline.at(minutes:8, seconds:00, action: {
		player_Percussion_Boom = state_Percussion_Boom.value(maxDecay:10);
		player_Percussion_Boom.start();
		"Gestures: Strike, Friction, Flutter, ClosedFist, Boom\n".postln;
	});


	// 8 mins = 480

	timeline.fork();

};

s.waitForBoot({
	final_performance.value();
});
)

(
SynthDef(\sine, {
	Out.ar(3, PinkNoise.ar * 0.1);
}).play
)

// modulate number of harmonics
{ Blip.ar(200,Line.kr(1,100,20),0.2) }.scope(1);