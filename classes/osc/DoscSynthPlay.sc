DoscSynthPlay {
	var <synth;
	var <synthArguments;

	* new {
		arg synth, synthArguments = [];
		^super.newCopyArgs(synth, synthArguments);
	}

	value {
		arg arguments;
		Synth(synth, synthArguments.collect({
			arg argumentGetter;
			argumentGetter.get(arguments);
		}).flat);
	}
}