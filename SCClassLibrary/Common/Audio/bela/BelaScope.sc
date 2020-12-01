BelaScope {

	classvar <serverScopes;
	var <server, <bus, <node;

	// public interface

	*scope { |channelOffset, signals|

		var ugens = this.prInputAsAudioRateUGens(signals);

		ugens !? {
			BelaScopeOut.ar(channelOffset, ugens);
		};

		^signals;
	}

	*monitorBus { |channelOffset, busindex, numChannels, target, rate = \audio|
		var server, belaScope;
		target = target.asTarget;
		server = target.server;
		if(rate == \audio) {
			^SynthDef(\belaScope_monitor_ar_bus) {
				BelaScopeOut.ar(channelOffset, InFeedback.ar(busindex, numChannels))
			}.play(target, addAction: \addAfter)
		} {
			^SynthDef(\belaScope_monitor_kr_bus) {
				BelaScopeOut.ar(channelOffset, K2A.ar(In.kr(busindex, numChannels)))
			}.play(target, addAction: \addAfter)
		}
	}

	// scope input checks

	*prInputAsAudioRateUGens { |signals|
		var arUGens = signals.asArray.collect{ |item|
			switch(item.rate)
				{ \audio }{ item } // pass
				{ \control }{ K2A.ar(item) } // convert kr to ar
				{ \scalar }{
					// convert numbers to ar UGens
					if(item.isNumber) { DC.ar(item) } { nil }
				}
				{ nil }
		};

		if(arUGens.every(_.isUGen)) {
			^arUGens;
		} {
			warn(
				"BelaScope: can't scope this signal, because not all of its elements are UGens.\nSignal: %"
				.format(signals)
			);
			^nil;
		}
	}

}

+ UGen {
	belaScope { |scopeChannel|
		^BelaScope.scope(scopeChannel, this)
	}
}

+ Array {
	belaScope { |scopeChannel, server|
		^BelaScope.scope(scopeChannel, this)
	}
}

+ Bus {
	belaScope { |scopeChannel|
		^BelaScope.monitorBus(scopeChannel, index, numChannels, rate: rate);
	}
}

+ Function {
	belaScope { |scopeChannel, numChannels = 1, target, outbus = 0, fadeTime = 0.02, addAction = \addToHead, args|
		var synth  = this.play(target, outbus, fadeTime, addAction, args);
		var monitor = BelaScope.monitorBus(scopeChannel, outbus, numChannels, target);
		^synth.onFree { if(monitor.notNil) { monitor.free } };
	}
}

+ Server {
	belaScope { |scopeChannel, index = 0, numChannels|
		numChannels = numChannels ?? { if (index == 0) { options.numOutputBusChannels } { 2 } };
		^Bus(\audio, index, numChannels, this).belaScope(scopeChannel);
	}
}
