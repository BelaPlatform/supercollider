BelaServerOptions {

	classvar defaultValues;

	*initClass {
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
		)
	}

	*asOptionsString { | opts |
		o = " -J " ++ this.getOpt(\numAnalogInChannels);
		o = o ++ " -K " ++ this.getOpt(\numAnalogOutChannels);
		o = o ++ " -G " ++ this.getOpt(\numDigitalChannels);
		o = o ++ " -Q " ++ this.getOpt(\headphoneLevel);
		o = o ++ " -X " ++ this.getOpt(\pgaGainLeft);
		o = o ++ " -Y " ++ this.getOpt(\pgaGainRight);
		o = o ++ " -s " ++ this.getOpt(\speakerMuted);
		o = o ++ " -x " ++ this.getOpt(\dacLevel);
		o = o ++ " -y " ++ this.getOpt(\adcLevel);
		o = o ++ " -g " ++ this.getOpt(\numMultiplexChannels);
		o = o ++ " -T " ++ this.getOpt(\belaPRU);
		o = o ++ " -O " ++ this.getOpt(\belaMaxScopeChannels);
	}

	*getOpt { |serverOptions, optionName|
		serverOptions.instVarGet(optionName) ? this.defaultValues[optionName];
	}

}

