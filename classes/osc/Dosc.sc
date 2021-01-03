Dosc {

	classvar oscDefs;

	*initClass {
		oscDefs = List();
		CmdPeriod.add({
			Dosc.clear();
		});
    }

	* map {
		arg path, actions;
		var def = OSCdef("OscHandler.map" ++ path, {
			arg msg;
			var arguments = msg[1..];
			actions.do {
				arg action;
				action.value(arguments);
			}
		}, path).enable;
		// ("Dosc.map : " + path).postln;
		oscDefs.add(def);
	}

	* clear {
		oscDefs.do({
			arg def;
			// ("Disabling OSCDef [" ++ def.key ++ "]").postln;
			def.free;
		});
		oscDefs = List();
	}

	* nodeSet {
		arg node, oscArgument, nodeArgument, transform = {arg v; v};
		^DoscNodeSet(node, oscArgument, nodeArgument, transform);
	}

	* nodeArgument {
		arg oscArgument, nodeArgument, spec = ControlSpec(0, 1);
		// ^DoscNodeArgument(oscArgument, nodeArgument, spec);
		^{
			arg arguments;
			var preSpecValue = arguments[oscArgument];
			if (preSpecValue.isNil, {
				[]
			}, {
				var postSpecValue = spec.map(preSpecValue);
				[nodeArgument, postSpecValue];
			});
		}
	}

	* namedNodeArgument {
		arg oscArgumentName, nodeArgument, spec = ControlSpec(0, 1);
		^{
			arg arguments;
			var argumentDict = Dictionary.newFrom(arguments);
			var preSpecValue = argumentDict.at(oscArgumentName);
			// var printWarning = if (preSpecValue.isNil, { "Missing value for argument [" ++ oscArgumentName ++ "]".postln});

			if (preSpecValue.isNil, {
				[];
			}, {
				var postSpecValue = spec.map(preSpecValue);
				[nodeArgument, postSpecValue];
			});
		};
	}

	* synthPlay {
		arg synth, synthArguments = [], group = nil;
		^{
			arg arguments;
			Synth(synth, synthArguments.collect({
				arg argumentGetter;
				argumentGetter.value(arguments);
			}).flat, group);
		}
	}

	* remove {
		arg path;
		var key = "OscHandler.map" ++ path;
		var indexToRemove = -1;
		oscDefs.do({
			arg def, index;
			// def.key.postln;
			if (def.key == key, {
				def.free;
				indexToRemove = index;
			});
		});
		if (indexToRemove >= 0, {
			oscDefs.removeAt(indexToRemove);
		});

	}
}