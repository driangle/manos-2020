(
// Computer Studio 2
s.options.inDevice_("SQ - Audio");
s.options.outDevice_("SQ - Audio");
s.options.numOutputBusChannels = 5;
s.options.maxLogins = 2;
// s.boot;
);

(
var translate = {
	arg dictionary, translations;
	var keyValuePairs = [];
	dictionary.keysValuesDo({
		arg key, value;
		var newKey = translations.atFail(key, key);
		keyValuePairs = keyValuePairs.add(newKey);
		keyValuePairs = keyValuePairs.add(value);
	});
	Dictionary.newFrom(keyValuePairs);
};
var sig_FBSineC = {
	arg input;
	var chaos = input.linlin(0.0, 1.0, 1.4, 2.0);
	Mix.ar([
		FBSineC.ar(
			freq:SampleRate.ir,
			im:0.1,
			fb:0,
			a:chaos,
			c:0.1
		),
		BrownNoise.ar * 0.0
	]);
};
var sig_Crackle = {
	arg params;
	var chaos = params.at(\friction).linlin(0.0, 1.0, 1.0, 2.0);
	Crackle.ar(chaosParam:chaos) * 0.08
};
var sig_PinkNoise = { PinkNoise.ar };
var sig_Dust_ar = {
	arg input;
	var density = input.linlin(0.0, 1.0, 500.0, 1000.0);
	Dust.ar(density);
};
var sig_Light_Rock = {
	arg params;
	var friction = params.at(\friction);
	var density = friction.linlin(0.0, 1.0, 0.1, 20.0);
	var sig = Dust.ar(density);
	var freq = WhiteNoise.kr()
	.range(500, 5000);
	// .range(800, 4000);

	// var decayTime = 0.01;
	var decayTime = 0.04;
	sig = Ringz.ar(sig, freq, decayTime);
	sig * 0.1;
};

var sig_PitchKick = {
	arg freq, decayTime = 1;
	var pitchEnv = EnvGen.ar(Env([freq, 50, 10], [0.01, 0.2 * decayTime]));
	SinOsc.ar(pitchEnv, phase:pi/2);
};

var sig_SineThenNoise = {
    arg out = 0, amp = 0.5, freq = 100, gate = 1, x = 0, y = 0, decayTime = 1, mix = 0;
    var shortEnv = EnvGen.kr(Env.adsr(decayTime:decayTime, sustainLevel:0, releaseTime:0), gate:gate);
    var longEnv = EnvGen.kr(Env.adsr(attackTime:decayTime * 2, decayTime:0, sustainLevel:1, releaseTime:1), gate:gate, doneAction:Done.freeSelf);
    var sig = SelectX.ar(
        mix.linlin(0.0, 1.0, 0.0, 0.5),
        [ SinOsc.ar(freq) * shortEnv, PinkNoise.ar * longEnv * 0.4]
    );

    // sig = sig * env;
    sig = Pan4.ar(sig, x, y);
    Out.ar(out, sig * amp);
};

var ugenGraphFunc_80sPluckSaw = {
    arg amp = 0.1, x = 0.0, y = 0.0, freq, cutoff = 500, gate = 1, decayTime = 1, releaseTime = 0.01;
    var ampEnv = EnvGen.ar(
        envelope: Env.adsr(attackTime:0.01, decayTime:decayTime, sustainLevel:0, releaseTime:releaseTime),
        gate: gate,
        doneAction: Done.freeSelf
    );
	var filterEnv = EnvGen.ar(
		Env.adsr(attackTime: 0.01, decayTime:decayTime / 2.0, sustainLevel:0, releaseTime:releaseTime).range(0.8, 1),
		gate: gate
	);
    var sig = Saw.ar(freq);
	sig = MoogFF.ar(sig, cutoff * filterEnv);
    sig = Pan4.ar(sig, x, y);
    Out.ar(0, sig * ampEnv * amp * 0.5);
};

var ugenGraphFunc_Sine = {
	arg out = 0, x = 0.0, y = 0.0, freq = 100, releaseTime = 0.1;
	var env = Env.perc(releaseTime:releaseTime).kr(doneAction:Done.freeSelf);
	var sig = SinOsc.ar(freq);
	sig = sig * env;
	sig = Pan4.ar(sig, x, y);
	Out.ar(out, sig * 0.5);
};

var state_Percussion = {
	arg name, sig_Source, oscPath = '/driangle/manos/perc', specs = Dictionary.newFrom([]);
	var defaultSpecs = Dictionary.newFrom([
		\x, ControlSpec(-1.0, 1.0),
		\y, ControlSpec(-1.0, 1.0),
		\freq, ControlSpec(50, 1000.0, \exp),
		\amp, ControlSpec(0.01, 1.0),
		\decayTime, ControlSpec(0.0, 2.0)
	]);
	var finalSpecs = defaultSpecs ++ specs;
	{
		var synthDefName = ("\Percussion_" ++ name ++ "_perc").asSymbol;
		// sounds
		SynthDef(synthDefName, {
			arg amp = 0.1, x = 0.0, y = 0.0, freq = 50, decayTime = 1;
			var ampEnv = EnvGen.ar(Env.perc(releaseTime:decayTime), doneAction:Done.freeSelf);
			var sig = sig_Source.value(freq, decayTime);
			sig = Pan4.ar(sig, x, y);
			Out.ar(0, sig * ampEnv * amp);
		}).add;
		// osc listeners
		Dosc.map(
			(oscPath ++ "/play").asSymbol,
			[
				{
					arg arguments;
					var id = arguments[0];
					var x = finalSpecs.at(\x).map(arguments[1]);
					var y = finalSpecs.at(\y).map(arguments[2]);
					var freq = finalSpecs.at(\freq).map(arguments[3]);
					var amp = finalSpecs.at(\amp).map(arguments[4]);
					var decayTime = finalSpecs.at(\decayTime).map(arguments[5]);
					Synth(synthDefName, [\x, x, \y, y, \freq, freq, \amp, amp, \decayTime, decayTime]);
				}
			]
		);
	}
};

var state_FrictionSpace = {
	arg name,
	    oscPath = '/driangle/manos/friction',
	    sig_Source,
	    specs = Dictionary.newFrom([]),
	    translations = Dictionary.newFrom([]);

	var defaultSpecs = Dictionary.newFrom([
		\x, ControlSpec(-1.0, 1.0),
		\y, ControlSpec(-1.0, 1.0),
		\amp, ControlSpec(0.01, 1.0, \exp),
		\releaseTime, ControlSpec(0.1, 2.0),
		\friction, ControlSpec(0.0, 1.0)
	]);
	var finalSpecs = defaultSpecs ++ specs;
    var synthDefName = ("FrictionSpace_" ++ name ++ "_friction").asSymbol;
	{
		// sounds
		SynthDef(synthDefName, {
			arg amp = 0.1, x = 0.0, y = 0.0, friction = 0.2, releaseTime = 0.5;
			var ampEnv = EnvGen.ar(Env.perc(releaseTime:releaseTime), doneAction:Done.freeSelf);
			var params = translate.value(Dictionary.newFrom([
				\friction, friction
			]), translations);
			var sig = sig_Source.value(params);
			sig = Pan4.ar(sig, x, y);
			sig = sig * ampEnv * amp;
			Out.ar(0, sig);
		}).add;
		// osc listeners
		Dosc.map(
			(oscPath ++ '/play').asSymbol,
			[
				{
					arg arguments; // [x, y, amp, releaseTime, chaos]
					var x = finalSpecs.at(\x).map(arguments[0]);
					var y = finalSpecs.at(\y).map(arguments[1]);
					var amp = finalSpecs.at(\amp).map(arguments[2]);
					var releaseTime = finalSpecs.at(\releaseTime).map(arguments[3]);
					var friction = finalSpecs.at(\friction).map(arguments[4]);
					Synth(synthDefName, [\x, x, \y, y, \amp, amp, \releaseTime, releaseTime, \friction, friction]);
				}
			]
		);
	}
};

var state_Point = {
	arg name,
	    sig_Source,
	    env_amp = { arg gate; Env.adsr(0.5, 0, 1, 0.5); },
	    oscPath = '/driangle/manos/point',
	    specs = Dictionary.newFrom([]),
      	translations = Dictionary.newFrom([]);
	var defaultSpecs = Dictionary.newFrom([
		\x, ControlSpec(-1.0, 1.0),
		\y, ControlSpec(-1.0, 1.0),
		\amp, ControlSpec(0.0, 1.0),
		\freq, ControlSpec(0.01, 100.0, \exp),
		\custom1, ControlSpec(0, 1),
		\custom2, ControlSpec(0, 1),
		\custom3, ControlSpec(0, 1),
		\custom4, ControlSpec(0, 1),
	]);
	var finalSpecs = defaultSpecs ++ specs;
	{
		var synthDefName = ("Point" ++ name ++ "_sound").asSymbol;
		var synths = Dictionary();
		// sounds
		SynthDef(synthDefName, {
			arg gate = 1, x = 0.0, y = 0.0, amp = 0.1, freq = 100.0, custom1 = 0, custom2 = 0, custom3 = 0, custom4 = 0;
		    var ampEnv = EnvGen.ar(env_amp.value(), gate:gate, doneAction:Done.freeSelf);
			var params = translate.value(Dictionary.newFrom([
				\x, x,
				\y, y,
				\freq, freq,
				\custom1, custom1,
				\custom2, custom2,
				\custom3, custom3,
				\custom4, custom4
			]), translations);
			var sig = sig_Source.value(params);
			sig = Pan4.ar(sig, x, y);
			Out.ar(0, sig * ampEnv * amp);
		}).add;
		// osc listeners
		Dosc.map(
			(oscPath ++ '/play').asSymbol,
			[
				{
					arg arguments; // [id, x, y, amp, freq, custom1, custom2, custom3, custom4]
					var id = arguments[0];
					var x = finalSpecs.at(\x).map(arguments[1]);
					var y = finalSpecs.at(\y).map(arguments[2]);
					var amp = finalSpecs.at(\amp).map(arguments[3]);
					var freq = finalSpecs.at(\freq).map(arguments[4]);
					var custom1 = finalSpecs.at(\custom1).map(arguments[5]);
					var custom2 = finalSpecs.at(\custom2).map(arguments[6]);
					var custom3 = finalSpecs.at(\custom3).map(arguments[7]);
					var custom4 = finalSpecs.at(\custom4).map(arguments[8]);
					synths.put(id, Synth(synthDefName, [
						\x, x,
						\y, y,
						\amp, amp,
						\freq, freq,
						\custom1, custom1,
						\custom2, custom2,
						\custom3, custom3,
						\custom4, custom4
					]));
				}
			]
		);
		Dosc.map(
			(oscPath ++ '/change').asSymbol,
			[
				{
					arg arguments; // [id, x, y, amp, freq, custom1, custom2, custom3, custom4]
					var id = arguments[0];
					var x = finalSpecs.at(\x).map(arguments[1]);
					var y = finalSpecs.at(\y).map(arguments[2]);
					var amp = finalSpecs.at(\amp).map(arguments[3]);
					var freq = finalSpecs.at(\freq).map(arguments[4]);
					var custom1 = finalSpecs.at(\custom1).map(arguments[5]);
					var custom2 = finalSpecs.at(\custom2).map(arguments[6]);
					var custom3 = finalSpecs.at(\custom3).map(arguments[7]);
					var custom4 = finalSpecs.at(\custom4).map(arguments[8]);
					var synth = synths.at(id);
					synth.set(
						\x, x,
						\y, y,
						\amp, amp,
						\freq, freq,
						\custom1, custom1,
						\custom2, custom2,
						\custom3, custom3,
						\custom4, custom4
					);
				}
			]
		);
		Dosc.map(
			(oscPath ++ '/stop').asSymbol,
			[
				{
					arg arguments; // [id]
					var id = arguments[0];
					var synth = synths.at(id);
					synth.set(\gate, 0);
					synths.removeAt(id);
				}
			]
		);
	}
};

var state_Point2 = {
	arg name,
     	ugen_graph_func,
	    synth_arguments,
	    osc_path = '/driangle/manos/point';
	var synthDefName = ("Point2" ++ name ++ "_sound").asSymbol;
	var synthCreate = Dosc.synthPlay(synthDefName, synth_arguments);
	var synths = Dictionary();
	{
		// sounds
		SynthDef(synthDefName, ugen_graph_func).add;
		// osc listeners
		Dosc.map(
			(osc_path ++ '/play').asSymbol,
			[
				{
					arg arguments; // [id, ...]
					var id = arguments[0];
					var synth = synthCreate.value(arguments[1..]);
					synths.put(id, synth);
				}
			]
		);
		Dosc.map(
			(osc_path ++ '/change').asSymbol,
			[
				{
					arg arguments; // [id, ...]
					var id = arguments[0];
					var synth = synths.at(id);
					synth_arguments.do({
						arg synthArg;
						var keyValue = synthArg.value(arguments[1..]);
						var key = keyValue[0];
						var value = keyValue[1];
						synth.set(key, value);
					});
				}
			]
		);
		Dosc.map(
			(osc_path ++ '/stop').asSymbol,
			[
				{
					arg arguments; // [id]
					var id = arguments[0];
					var synth = synths.at(id);
					("Stopping " + id).postln;
					synth.postln;
					synth.set(\gate, 0);
					synths.removeAt(id);
				}
			]
		);
	}
};

var state_Pattern = {
	arg name, ugenGraphFunc;
	{
		var leadSynthDef = ("Pattern_" ++ name ++ "_lead").asSymbol;
		var patterns = Dictionary();
		// var ampP = PatternProxy(0.1);
		// sounds
		SynthDef(leadSynthDef, ugenGraphFunc).add;
		// osc listeners
		Dosc.map(
			'/driangle/manos/point/play',
			[
				{
					arg arguments; // [id, x, y, amp]
					var id = arguments[0];
					var x = arguments[1].linlin(0.0, 1.0, -1.0, 1.0);
					var y = arguments[2].linlin(0.0, 1.0, -1.0, 1.0);
					var amp = arguments[3].linlin(0.0, 1.0, 0.0, 1.0);
					var freq = arguments[2].linlin(0.0, 1.0, 100, 500.0);
					var maxDur = arguments[3].linlin(0.0, 1.0, 0.1, 1.0);

					var pattern = DPattern(
						proxies: Dictionary.newFrom([
							\amp, PatternProxy(amp),
							\x, PatternProxy(x),
							\y, PatternProxy(y),
							\maxDur, PatternProxy(maxDur)
						]),
						pattern: {
							arg proxies;
							Pbind(
								\instrument, leadSynthDef,
                                \amp, proxies.at(\amp).asStream,
								\dur, Pexprand(0.5, proxies.at(\maxDur)),
								\scale, Scale.at(\minor),
								\degree, Pwhite(0, 8) * 3, // Pseq(Array.fill(16, {rrand(0, 8)}), inf),
								\octave, 3,
								\x, proxies.at(\x).asStream,
								\y, proxies.at(\y).asStream,
								\cutoff, 1000,
								\decayTime, 10,
								\releaseTime, 0.05
							)
						}
					).play;
					patterns.put(id, pattern);
				}
			]
		);
		Dosc.map(
			'/driangle/manos/point/change',
			[
				{
					arg arguments; // [id, x, y, amp]
					var id = arguments[0];
					var x = arguments[1].linlin(0.0, 1.0, -1.0, 1.0);
					var y = arguments[2].linlin(0.0, 1.0, -1.0, 1.0);
					var amp = arguments[3].linlin(0.0, 1.0, 0.0, 1.0);
					var freq = arguments[2].linlin(0.0, 1.0, 100, 500.0);
					var maxDur = arguments[3].linlin(0.0, 1.0, 2.0, 0.1);
					var pattern = patterns.at(id);
					// pattern.set(\x, x, \y, y, \amp, amp, \maxDur,  maxDur);
					pattern.set(\x, x, \y, y, \maxDur,  maxDur);
				}
			]
		);
		Dosc.map(
			'/driangle/manos/point/stop',
			[
				{
					arg arguments; // [id]
					var id = arguments[0];
					var pattern = patterns.at(id);
					pattern.stop;
					patterns.removeAt(id);
				}
			]
		);
	}
};

var state_StrikeThenShape = {
	arg name, ugenGraphFunc;
	{
		var synthDefName = ("StrikeThenShape_" ++ name ++ "_sound").asSymbol;
		var synths = Dictionary();
		SynthDef(synthDefName, ugenGraphFunc).add;
		Dosc.map(
			'/driangle/manos/strike/play',
			[
				{
					arg arguments; // [id, x, y, freq]
					var id = arguments[0];
					var x = arguments[1].linlin(0.0, 1.0, -1.0, 1.0);
					var y = arguments[2].linlin(0.0, 1.0, -1.0, 1.0);
					var freq = arguments[3].linlin(0.0, 1.0, 0.0, 100.0);
					var decayTime = arguments[4].linlin(0.0, 1.0, 1.0, 2.0);
					synths.put(id, Synth(synthDefName, [\x, x, \y, y, \freq, freq, \decayTime, decayTime]));
				}
			]
		);
		Dosc.map(
			'/driangle/manos/strike/shape',
			[
				{
					arg arguments; // [id, x, y, freq]
					var id = arguments[0];
					var x = arguments[1].linlin(0.0, 1.0, -1.0, 1.0);
					var y = arguments[2].linlin(0.0, 1.0, -1.0, 1.0);
					var mix = arguments[3].linlin(0.0, 1.0, 0.0, 1.0);
					var synth = synths.at(id);
					synth.set(\x, x, \y, y, \mix, mix);
				}
			]
		);
		Dosc.map(
			'/driangle/manos/strike/stop',
			[
				{
					arg arguments; // [id, x, y, freq]
					var id = arguments[0];
					var synth = synths.at(id);
					synth.set(\gate, 0);
				}
			]
		);
	}
};

var state_Percussion_Kick = state_Percussion.value(
	name: 'kick',
	oscPath: '/driangle/manos/perc/kick',
	sig_Source: sig_PitchKick
);
var state_Percussion_Sine = state_Percussion.value(
    name: 'sine',
    oscPath: '/driangle/manos/perc/sine',
    specs: Dictionary.newFrom([
        \freq, ScaleSpec(0, Scale.major, 24, 96, \exp).midicps,
        \decayTime, ControlSpec(0.5, 3)
    ]),
    sig_Source: {
        arg freq, decayTime;
        var sig = SinOsc.ar(freq);
        sig = LPF.ar(sig, freq / 2.0);
        sig
    }
);
var state_Percussion_Klank = state_Percussion.value(
    name: 'klank',
    oscPath: '/driangle/manos/perc',
    specs: Dictionary.newFrom([
        \x, FunctionSpec({rrand(-1.0, 1.0)}),
        \y, FunctionSpec({rrand(-1.0, 1.0)}),
        \freq, ControlSpec(100, 1000, \exp),
        \decayTime, ControlSpec(0.5, 1, \exp)
    ]),
    sig_Source: {
        arg freq, decayTime;
        var sig = Klang.ar(`[ Array.rand(2, freq / 2, freq), nil, nil ], 1, 0);
        sig = LPF.ar(sig, 800);
        sig * 0.2;
    }
);

var state_Point_Pulse = state_Point.value(
    name: 'sq',
    oscPath: '/driangle/manos/point',
	sig_Source: {
		arg params;
		LFPulse.ar(params.at(\freq));
	},
    env_amp: {Env.adsr(0.5, 0, 1, 2); },
    specs: Dictionary.newFrom([
        \freq, ControlSpec(0.5, 100, \exp)
    ])
);
var state_Point_PulseRing = state_Point.value(
    name: 'sq',
    oscPath: '/driangle/manos/point',
	sig_Source: {
		arg params;
		var freq = params.at(\freq);
		var decayTime = params.at(\custom2);
		var sig = LFPulse.ar(freq);
		Ringz.ar(sig, 50, decayTime) * 0.01;
	},
    env_amp: {Env.adsr(0.5, 0, 1, 2); },
    specs: Dictionary.newFrom([
        \freq, ControlSpec(0.5, 100, \exp),
		\custom2, ControlSpec(0.01, 1.0)
    ])
);
var state_Point_Noise = state_Point.value(
    name: 'noise',
    oscPath: '/driangle/manos/point',
    sig_Source: {
        PinkNoise.ar * 0.8;
    }
);
var state_Point_Fire = state_Point.value(
    name: 'fire',
    oscPath: '/driangle/manos/point',
	translations: Dictionary.newFrom([
		\freq, \friction
	]),
    sig_Source: sig_Crackle
);
var state_Point_SinThresh = state_Point2.value(
    name: 'sinThresh',
    osc_path: '/driangle/manos/point',
	ugen_graph_func: {
		arg gate = 1, amp, freq, mFreq;
		// sound cool but has odd clicks when using SinOsc.ar().thresh(LFPulse.ar())
        var env = Env.adsr(1, 0, 1, 2).kr(gate:gate, doneAction:Done.freeSelf);
		var thresh = LFPulse.ar(mFreq);
		var sig = SinOsc.ar(freq).thresh(thresh);
		sig = Pan4.ar(sig, 0, 0);
		Out.ar(0, sig * env * amp * 0.2);
	},
	synth_arguments: [
		Dosc.namedNodeArgument(\amp, \amp, ControlSpec(0, 1)),
		Dosc.namedNodeArgument(\freq, \freq, ControlSpec(20, 500)),
		Dosc.namedNodeArgument(\pitch, \mFreq, ControlSpec(20, 500))
	]
);
var state_Point_SinScaleNeg = state_Point2.value(
    name: 'sinScaleNeg',
    osc_path: '/driangle/manos/point',
	ugen_graph_func: {
		arg gate = 1, amp, freq, mFreq;
		var env = Env.adsr(1, 0, 1, 2).kr(gate:gate, doneAction:Done.freeSelf);
		var modulator = SinOsc.ar(mFreq);
		var sig = SinOsc.ar(freq).scaleneg(modulator);
		sig = Pan4.ar(sig, 0, 0);
		Out.ar(0, sig * env * amp * 0.3);
	},
	synth_arguments: [
		Dosc.namedNodeArgument(\amp, \amp, ControlSpec(0, 1)),
		Dosc.namedNodeArgument(\freq, \freq, ControlSpec(0, 500)),
		Dosc.namedNodeArgument(\pitch, \mFreq, ControlSpec(0, 500))
	]
);
var state_Point_PulseThreshSin = state_Point.value(
    name: 'pulseThreshSin',
    osc_path: '/driangle/manos/point',
	synth_arguments:[
		// Dosc.namedNodeArgument(\z, \amp, ControlSpec(0, 1)),
		Dosc.namedNodeArgument(\x, \freq, ControlSpec(10, 500, \exp)),
        Dosc.namedNodeArgument(\y, \mfreq, ControlSpec(10, 500))
	],
	ugen_graph_func: {
		arg gate = 1, amp = 1, freq, mfreq;
		var env = Env.adsr(1, 0, 1, 2).kr(gate:gate, doneAction:Done.freeSelf);
		var modulator = SinOsc.ar(mfreq);
		var sig = LPF.ar(Pulse.ar(freq), 2000).scaleneg(modulator);
		sig = space_Pan4Brown.value(sig);
		Out.ar(0, sig * env * amp * 0.1);
	}
);
//{ Pulse.ar(MouseX.kr(10, 500)).thresh(SinOsc.ar(MouseY.kr(10, 500))) * 0.1 ! 2}.play;
var state_FrictionSpace_LightRocks = state_FrictionSpace.value(
	name: 'earth',
	oscPath:'/driangle/manos/friction',
	sig_Source: sig_Light_Rock
);
var state_FrictionSpace_Fire = state_FrictionSpace.value(
	name: 'fire',
	oscPath:'/driangle/manos/friction',
	sig_Source: sig_Crackle
);

s.waitForBoot({
	var states = [
		// state_Percussion_Klank, [7]
		// state_Point_Noise
		// state_Point_Fire
		// state_FrictionSpace_LightRocks
		// state_FrictionSpace_Fire
		// state_Point_Pulse
		// state_Point_PulseRing
		// state_Point_SinThresh
		// state_Point_SinScaleNeg // [7]
		// state_Point_PulseThreshSin

		// state_Percussion.value('fire', sig_Crackle)
		// state_Pattern.value('pattern', ugenGraphFunc_Sine)
		// state_StrikeThenShape.value('bang', sig_SineThenNoise)
	];
	fork {
		states.do({
			arg state;
			state.value();
		});

		"Starting Performance...".postln;
		/*state_FrictionSpace_LightRocks.value();

		3.wait;
		Dosc.clear();

		state_FrictionSpace_Fire.value();*/
	};
});
)


(
// s.options.numOutputBusChannels = 4;
s.waitForBoot({
	SynthDef(\sine, {
		Out.ar(0, SinOsc.ar * 0.3);
	}).play;
});
)