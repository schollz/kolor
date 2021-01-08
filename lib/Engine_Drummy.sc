// Engine_Drummy

// Inherit methods from CroneEngine
Engine_Drummy : CroneEngine {

	var <sample1;
	var  sample1Buffer;
	var <sample2;
	var  sample2Buffer;
	var <sample3;
	var  sample3Buffer;
	var <sample4;
	var  sample4Buffer;

	*new { arg context, doneCallback;
		// Return the object from the superclass (CroneEngine) .new method
		^super.new(context, doneCallback);
	}

	alloc {

		sample1Buffer = Buffer.read(context.server,"/home/we/dust/code/drummy/samples/silence.wav");
		sample1 = {
			arg amp=0.5, amplag=0.02, t_trig=0;
			PlayBuf.ar(2,sample1Buffer,BufRateScale.kr(sample1Buffer),trigger:t_trig,loop:0)*Lag.ar(K2A.ar(amp), amplag)
		}.play(target: context.xg);

		sample2Buffer = Buffer.read(context.server,"/home/we/dust/code/drummy/samples/silence.wav");
		sample2 = {
			arg amp=0.5, amplag=0.02, t_trig=0;
			PlayBuf.ar(2,sample2Buffer,BufRateScale.kr(sample2Buffer),trigger:t_trig,loop:0)*Lag.ar(K2A.ar(amp), amplag)
		}.play(target: context.xg);

		sample3Buffer = Buffer.read(context.server,"/home/we/dust/code/drummy/samples/silence.wav");
		sample3 = {
			arg amp=0.5, amplag=0.02, t_trig=0;
			PlayBuf.ar(2,sample3Buffer,BufRateScale.kr(sample3Buffer),trigger:t_trig,loop:0)*Lag.ar(K2A.ar(amp), amplag)
		}.play(target: context.xg);

		sample4Buffer = Buffer.read(context.server,"/home/we/dust/code/drummy/samples/silence.wav");
		sample4 = {
			arg amp=0.5, amplag=0.02, t_trig=0;
			PlayBuf.ar(2,sample4Buffer,BufRateScale.kr(sample4Buffer),trigger:t_trig,loop:0)*Lag.ar(K2A.ar(amp), amplag)
		}.play(target: context.xg);

		this.addCommand("sample1file","s", { arg msg;
			sample1Buffer.free;
			sample1Buffer = Buffer.read(context.server,msg[1]);
		});

		this.addCommand("sample1play","f", { arg msg;
			sample1.set(\t_trig,1);
		});

		this.addCommand("sample2file","s", { arg msg;
			sample2Buffer.free;
			sample2Buffer = Buffer.read(context.server,msg[1]);
		});

		this.addCommand("sample2play","f", { arg msg;
			sample2.set(\t_trig,1);
		});

		this.addCommand("sample3file","s", { arg msg;
			sample3Buffer.free;
			sample3Buffer = Buffer.read(context.server,msg[1]);
		});

		this.addCommand("sample3play","f", { arg msg;
			sample3.set(\t_trig,1);
		});

		this.addCommand("sample4file","s", { arg msg;
			sample4Buffer.free;
			sample4Buffer = Buffer.read(context.server,msg[1]);
		});

		this.addCommand("sample4play","f", { arg msg;
			sample4.set(\t_trig,1);
		});

	}

	free {
		sample1.free;
		sample1Buffer.free;
		sample2.free;
		sample2Buffer.free;
		sample3.free;
		sample3Buffer.free;
		sample4.free;
		sample4Buffer.free;
	}
}
