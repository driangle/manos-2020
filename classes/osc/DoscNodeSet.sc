DoscNodeSet {
	var <node;
	var <oscArgument;
	var <nodeArgument;
	var <transform;

	* new {
		arg node, oscArgument, nodeArgument, transform = {arg v; v};
		^super.newCopyArgs(node, oscArgument, nodeArgument, transform);
	}

	value {
		arg arguments;
		var preTransformValue = if (oscArgument.notNil, {
			arguments[oscArgument]
		}, { nil });
		var postTransformValue = transform.value(preTransformValue);
		node.set(nodeArgument, postTransformValue);
	}


}