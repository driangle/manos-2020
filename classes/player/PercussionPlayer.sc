PercussionPlayer {
	var name;
	var osc_path;
	var synth_arguments;
	var ugen_graph_func;

	* new {
		arg name, osc_path, synth_arguments, ugen_graph_func;
		^super.newCopyArgs(name, osc_path, synth_arguments, ugen_graph_func);
	}

	start {
		var synthDefName = ("\Percussion_" ++ name).asSymbol;
		var synthCreate = Dosc.synthPlay(synthDefName, synth_arguments);

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

	stop {
		Dosc.remove((osc_path ++ '/play').asSymbol);
	}

}