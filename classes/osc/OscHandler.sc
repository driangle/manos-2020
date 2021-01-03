OscHandler {

	* synthSet {
		arg synth, path, argument, transform = {arg x; x};
		("OscHandler.synthSet : " + path + "," + argument).postln;
		OSCdef("OscHandler.synthSet" ++ path, {
			arg msg;
			var value = transform.value(msg[1]);
			synth.set(argument, value);
		}, path).enable;
	}

	* synthMultiSet {
		arg synth, path, transform;
		("OscHandler.synthMultiSet : " + path).postln;
		OSCdef("OscHandler.synthMultiSet" ++ path, {
			arg msg;
			var synthArgs = transform.value(msg[1..]);
			synth.set(synthArgs);
		}, path).enable;
	}
}