TimelinePoint {
	var <time;
	var <action;

	* new {
		arg time, action;
		^super.newCopyArgs(time, action);
	}
}