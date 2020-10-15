BelaScope {

	classvar <serverScopes;
	var <server, <bus, <node;

	*scope { |channelOffset, signals, server|
		var scope = serverScopes[server ? Server.default];
		if(scope.notNil) {
				^scope.scope(channelOffset, signals);
		} {
				// TODO: BelaScope needs to be initialized for server
				this.new(server).scope(channelOffset, signals)
		};
	}

	*initClass {
		serverScopes = IdentityDictionary[];
	}

	*new { |server|
		server = server ? Server.default;
		serverScopes[server] ?? {
			serverScopes[server] = super.newCopyArgs(server).init;
		}
		^serverScopes[server];
	}

	scope { |channelOffset, signals|

		var ugens = signals.asArray.collect{ |item|
				switch(item.rate)
					{ \audio }{ item } // pass
					{\control}{ K2A.ar(item) } // convert kr to ar
					{\scalar}{
						// convert numbers to ar UGens
						if(item.isNumber) { DC.ar(item) } { nil }
					}
					{ nil }
		};

		if(channelOffset + signals.size > this.maxChannels) {
				"BelaScope: can't scope this signal, max number of channels (%) exceeded.\nSignal: %"
				.format(this.maxChannels, signals).warn;
				^signals;
		};

		if( ugens.every(_.isUGen) ){
				^Out.ar(this.bus.index + channelOffset, ugens);
		} {
				"BelaScope: can't scope this signal, because not all of its elements are UGens.\nSignal: %"
				.format(signals).warn;
				^signals
		}
	}

	init {
		ServerBoot.add(this, this.server);
		ServerTree.add(this, this.server);
		if(this.server.serverRunning){
				this.doOnServerBoot;
				this.doOnServerTree;
		}
	}

	maxChannels { ^this.server.options.belaMaxScopeChannels }

	prReserveScopeBus {
		// TODO: check if bus is already reserved, or if maxChannels mismatch
		bus = Bus.audio(server, this.maxChannels);
	}

	prStartScope {
		// TODO: check if node is already in place and running
		node = { BelaScopeUGen.ar(this.bus, this.maxChannels); Silent.ar }.play(this.server, addAction: \addAfter);
	}
	
	doOnServerBoot { this.prReserveScopeBus }
	doOnServerTree { this.prStartScope }
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
