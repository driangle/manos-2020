(
var state_PolyPoint = {
	arg name,
     	ugen_graph_func,
	    synth_arguments,
	    osc_path = '/driangle/manos/poly',
	    size;
	var synthDefName = ("PolyPoint_" ++ name).asSymbol;
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
					var synthCreate = {
						var polyCount = if (size.isKindOf(Number), { size }, {
							size.value(arguments[1..])[1]
						});
						var polySynthGroup = [];
						polyCount.do({
							arg index;
							var synth = Dosc.synthPlay(synthDefName, synth_arguments.value(index)).value(arguments[1..]);
							polySynthGroup = polySynthGroup.add(synth);
						});
						synths.put(id, polySynthGroup);
					}.value;
				}
			]
		);
		Dosc.map(
			(osc_path ++ '/change').asSymbol,
			[
				{
					arg arguments; // [id, ...]
					var id = arguments[0];
					var polySynthGroup = synths.at(id);
					polySynthGroup.do({
						arg synth, index;
						synth_arguments.value(index).do({
							arg synthArg;
							var keyValue = synthArg.value(arguments[1..]);
							if (keyValue.size == 2, {
								var key = keyValue[0];
								var value = keyValue[1];
								synth.set(key, value);
							});
						});
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
					var polySynthGroup = synths.at(id);
					polySynthGroup.do({
						arg synth;
						synth.set(\gate, 0);
					});
					synths.removeAt(id);
				}
			]
		);
	}
};
var state_Point_Sub = state_Point.value(
	name: 'sub',
	osc_path: '/driangle/manos/point',
	synth_arguments: [
		// Dosc.namedNodeArgument(\z, \amp, ControlSpec(0.1, 1)),
		Dosc.namedNodeArgument(\z, \freq, ControlSpec(50, 200)),
		// Dosc.namedNodeArgument(\pitch, \mix, ControlSpec(0, 1))
	],
	ugen_graph_func: {
		arg out = 0, gate = 1, amp = 1.0, freq = 200;
		var env = Env.adsr(
			attackTime:0.01,
			decayTime:0,
			sustainLevel:1,
			releaseTime:0.5
		).kr(gate:gate, doneAction:Done.freeSelf);
		var sig = SinOsc.ar(freq);
		// sig = sig * Env.adsr(0.0, 2, 1, 0).kr(gate:Impulse.kr(trigFreq));
		// sig = sig * SinOsc.kr(tremoloFreq).range(0, tremoloAmount);
		sig = space.value(sig);
		Out.ar(out, sig * env * amp * 0.3);
	}
);

var state_Point_Pad = state_Point.value(
	name: 'sinepad',
	osc_path: '/driangle/manos/point/pad',
	synth_arguments: [
		// Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, 1)),
		Dosc.namedNodeArgument(\z, \freq, ControlSpec(10, 500, \exp)),
		Dosc.namedNodeArgument(\index, \index, ControlSpec())
	],
	ugen_graph_func: {
		arg out = 0, gate = 1, amp = 1, x = 0.0, y = 0.0, freq = 100, index = 1;
		var env = Env.adsr(
			attackTime:0.1,
			decayTime:0,
			sustainLevel:1,
			releaseTime:0.25
		).kr(gate:gate, doneAction:Done.freeSelf);
		var sig = SinOsc.ar(freq * (index * 1.5 + 1));
		sig = space.value(sig, x, y);
		Out.ar(out, sig * env * amp * 0.3);
	}
);
var state_FrictionSpace_Crackle = state_FrictionSpace.value(
	name:'crackle',
	osc_path:'/driangle/manos/friction/crackle',
	synth_arguments: [
		Dosc.namedNodeArgument(\velocity, \amp, ControlSpec(0.1, 1)),
		Dosc.namedNodeArgument(\x, \x, ControlSpec(-1, 1)),
		Dosc.namedNodeArgument(\y, \y, ControlSpec(-1, 1)),
		Dosc.namedNodeArgument(\z, \friction, ControlSpec(1.8, 2.0)),
		Dosc.namedNodeArgument(\velocity, \releaseTime, ControlSpec(0.2, 3.0))
	],
	ugen_graph_func: {
		arg out = 0, amp = 0.1, x = 0, y = 0, friction = 0.2, releaseTime = 0.5;
		var env = EnvGen.ar(Env.perc(releaseTime:releaseTime), doneAction:Done.freeSelf);
		var sig = Crackle.ar(chaosParam:friction);
		sig = LPF.ar(sig, 5000);
		sig = space.value(sig, x, y);
		Out.ar(out, sig * env * amp * 0.05);
	}
);
);