BelaScope {

	classvar <serverScopes;
	var <server, <bus, <node;

	// public interface

	*scope { |channelOffset, signals, server|
		server ?? {
			var servers = serverScopes.keys.asArray;
			server = servers.first;
			if(servers.size > 1) {
				warn("BelaScope: server not specified, using '%', but more options are available")
			}
		};
		server = server ? Server.default;
		^this.getInstance(server).scope(channelOffset, signals);
	}

	scope { |channelOffset, signals|

		var ugens = this.class.prInputAsAudioRateUGens(signals);

		if(ugens.notNil and: this.prIsValidScopeChannel(channelOffset, signals)) {
			BelaScopeOut.ar(channelOffset, ugens);
		};

		^signals;
	}

	*monitorBus { |channelOffset, busindex, numChannels, target, rate = \audio|
		var server, belaScope;
		target = target.asTarget;
		server = target.server;
		belaScope = this.getInstance(server);
		if(belaScope.prIsValidScopeChannel(channelOffset, busindex+(0..numChannels))) {
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
	}

	// instance creation

	*initClass {
		serverScopes = IdentityDictionary[];
	}

	*new { |server|
		^this.getInstance(server);
	}

	*getInstance { |server|
		server = server ? Server.default;
		serverScopes[server] ?? {
			serverScopes[server] = super.newCopyArgs(server).init;
		}
		^serverScopes[server];
	}

	init {
		if(this.maxChannels <= 0) {
			Error(
				"BelaScope: can't instantiate on server '%' because its option belaMaxScopeChannels is %"
				.format(server, this.maxChannels)
			).throw;
		};
	}

	maxChannels { ^this.server.options.belaMaxScopeChannels }

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

	prIsValidScopeChannel { |channelOffset, signals=#[]|
		if(channelOffset.isNumber.not) {
			warn("BelaScope: channel offset must be a number, but (%) is provided.".format(channelOffset));
			^false;
		};
		if(channelOffset < 0) {
			warn("BelaScope: channel offset must be a positive number, but (%) is provided.".format(channelOffset));
			^false;
		};
		if(channelOffset + signals.asArray.size > this.maxChannels){
			warn(
				"BelaScope: can't scope this signal to scope channel (%), max number of channels (%) exceeded.\nSignal: %"
				.format(channelOffset, this.maxChannels, signals)
			);
			^false;
		};
		^true;
	}
}

+ UGen {
	belaScope { |scopeChannel, server|
		^BelaScope.scope(scopeChannel, this, server)
	}
}

+ Array {
	belaScope { |scopeChannel, server|
		^BelaScope.scope(scopeChannel, this, server)
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