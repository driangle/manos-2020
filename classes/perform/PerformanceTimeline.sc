PerformanceTimeline {

	var currentTime = 0;
	var points;
	var countdown = 5;

	* new {
		^super.new.init();
	}

	init {
		points = [];
	}

	at {
		arg seconds, minutes = 0, action;
		var time = (minutes * 60) + seconds;
		points = points.add(TimelinePoint(time, action));
	}

	delta {
		arg seconds, minutes = 0, action;
		var delta = (minutes * 60) + seconds;
		var time = if (points.size == 0, {
			delta
		}, {
			points.at(points.size - 1).time + delta;
		});
		points = points.add(TimelinePoint(time, action));
	}

	advance {
		arg seconds, minutes = 0;
		var time = (minutes * 60) + seconds;
		currentTime = time;
	}

	fork {
		fork {
			points.do({
				arg point;
				if (point.time > currentTime, {
					if (point.time > 0, {
						var waitTime = point.time - currentTime;
						currentTime = point.time;
						("Waiting [" ++ waitTime ++ "] seconds until [" ++ point.time ++ "].").postln;
						(waitTime - countdown).wait;
						"\n... Done in ...".postln;
						countdown.do({
							arg index;
							var next = countdown - index;
							next.postln;
							1.wait;
						});
					});
					point.action.value();
					("Timeline @ " ++ currentTime.asString).postln;
				}, {
					if (point.time == currentTime, {
						point.action.value();
						("Timeline @ " ++ currentTime.asString).postln;
					});
				});
			});
		}
	}

}