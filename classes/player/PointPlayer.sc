PointPlayer {

	var name;
	var osc_path;
	var synth_arguments;
    var ugen_graph_func;
	var synths;

	* new {
		arg name, osc_path, synth_arguments, ugen_graph_func;
		^super.newCopyArgs(name, osc_path, synth_arguments, ugen_graph_func);
	}

	start {
		var synthDefName = ("Point_" ++ name).asSymbol;
		var synthCreate = Dosc.synthPlay(synthDefName, synth_arguments);
		synths = Dictionary();
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
						if (keyValue.size == 2, {
							var key = keyValue[0];
							var value = keyValue[1];
							synth.set(key, value);
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
					var synth = synths.at(id);
					synth.set(\gate, 0);
					synths.removeAt(id);
				}
			]
		);

	}

	stop {
		synths.do({
			arg synth;
			synth.set(\gate, 0);
		});
		Dosc.remove((osc_path ++ '/play').asSymbol);
		Dosc.remove((osc_path ++ '/change').asSymbol);
		Dosc.remove((osc_path ++ '/stop').asSymbol);
	}
}