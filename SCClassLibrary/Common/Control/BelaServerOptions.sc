BelaServerOptions {

	classvar defaultValues;

	*initDefaults {
		defaultValues = IdentityDictionary.newFrom(
			(
				numAnalogInChannels: 2,
				numAnalogOutChannels: 2,
				numDigitalChannels: 16,
				headphoneLevel: -6,
				pgaGainLeft: 10,
				pgaGainRight: 10,
				speakerMuted: 0,
				dacLevel: 0,
				adcLevel: 0,
				numMultiplexChannels: 0,
				belaPRU: 1,
				belaMaxScopeChannels: 0
			)
		);
		^defaultValues;
	}

	*addBelaOptions { |serverOptions|
		var belaOpts = (defaultValues ?? { this.initDefaults }).copy;
		belaOpts.keys.do { |optName|
			serverOptions.addUniqueMethod(optName) { belaOpts[optName] };
			serverOptions.addUniqueMethod(optName.asSetter) { |self, newValue|
				belaOpts[optName] = newValue
			};
		}
	}

	*asOptionsString { |serverOptions|
		var o = " -J " ++ this.getOpt(serverOptions, \numAnalogInChannels);
		o = o ++ " -K " ++ this.getOpt(serverOptions, \numAnalogOutChannels);
		o = o ++ " -G " ++ this.getOpt(serverOptions, \numDigitalChannels);
		o = o ++ " -Q " ++ this.getOpt(serverOptions, \headphoneLevel);
		o = o ++ " -X " ++ this.getOpt(serverOptions, \pgaGainLeft);
		o = o ++ " -Y " ++ this.getOpt(serverOptions, \pgaGainRight);
		o = o ++ " -A " ++ this.getOpt(serverOptions, \speakerMuted);
		o = o ++ " -x " ++ this.getOpt(serverOptions, \dacLevel);
		o = o ++ " -y " ++ this.getOpt(serverOptions, \adcLevel);
		o = o ++ " -g " ++ this.getOpt(serverOptions, \numMultiplexChannels);
		o = o ++ " -T " ++ this.getOpt(serverOptions, \belaPRU);
		o = o ++ " -E " ++ this.getOpt(serverOptions, \belaMaxScopeChannels);
		^o;
	}

	*getOpt { |serverOptions, optionName|
		^(serverOptions.perform(optionName) ? defaultValues[optionName]);
	}

}
