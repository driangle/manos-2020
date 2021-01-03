DoscNodeArgument {
	var <oscArgument;
	var <nodeArgument;
	var <spec;

	* new {
		arg oscArgument, nodeArgument, spec = ControlSpec(0, 1);
		^super.newCopyArgs(oscArgument, nodeArgument, spec);
	}

	value {
		arg arguments;
		var preSpecValue = arguments[oscArgument];
		var postSpecValue = spec.map(preSpecValue);
		^[nodeArgument, postSpecValue];
	}


}