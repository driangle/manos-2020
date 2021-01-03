PatternPlayer {
	var name;
	var pattern_arguments;
	var ugen_graph_func;
	var osc_path;
	var user_pattern;
	var patterns;


	* new {
		arg name, pattern_arguments, ugen_graph_func, osc_path, user_pattern;
		^super.newCopyArgs(name, pattern_arguments, ugen_graph_func, osc_path, user_pattern);
	}

	start {
		var synthDefName = ("Pattern_" ++ name ++ "_lead").asSymbol;
		patterns = Dictionary();

		SynthDef(synthDefName, ugen_graph_func).add;
		// osc listeners
		Dosc.map(
			(osc_path ++ '/play').asSymbol,
			[
				{
					arg arguments; // [id, ...]
					var id = arguments[0];
					var pattern = DPattern(
						proxies: Dictionary.newFrom(pattern_arguments.collect({
							arg patternArg;
							var argumentKeyValue = patternArg.value(arguments[1..]);
							if (argumentKeyValue.size == 2, {
								var key = argumentKeyValue[0];
								var value = argumentKeyValue[1];
								[key, PatternProxy(value)]
							}, {
								[]
							});
						}).flat),
						pattern: {
							arg proxies;
							user_pattern.value(id, synthDefName, proxies);
						}
					).play;
					patterns.put(id, pattern);
				}
			]
		);
		Dosc.map(
			(osc_path ++ '/change').asSymbol,
			[
				{
					arg arguments; // [id, ...]
					var id = arguments[0];
					var pattern = patterns.at(id);
					pattern_arguments.do({
						arg patternArg;
						var argumentKeyValue = patternArg.value(arguments[1..]);
						if (argumentKeyValue.size == 2, {
							var key = argumentKeyValue[0];
							var value = argumentKeyValue[1];
							pattern.set(key, value);
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
					var pattern = patterns.at(id);
					pattern.stop;
					patterns.removeAt(id);
				}
			]
		);

	}

	stop {
		patterns.do({
			arg pattern;
			pattern.stop;
		});
		Dosc.remove((osc_path ++ '/play').asSymbol);
		Dosc.remove((osc_path ++ '/change').asSymbol);
		Dosc.remove((osc_path ++ '/stop').asSymbol);
	}

}