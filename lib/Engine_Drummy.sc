// Engine_Drummy

// Inherit methods from CroneEngine
Engine_Drummy : CroneEngine {

	var sampleBuff;
	var samplerPlayer;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		sampleBuff = Array.fill(6, { arg i; 
			Buffer.read(context.server, "/home/we/dust/code/drummy/samples/shaker1.wav"); 
		});

		(0..5).do({arg i; 
			SynthDef("player"++i,{ arg amp=0.0, t_trig=0, pan=0;
				var snd,bufsnd;
				bufsnd = PlayBuf.ar(2, sampleBuff[i], BufRateScale.kr(sampleBuff[i]),trigger:t_trig);
				snd = Mix.ar([
					Pan2.ar(bufsnd[0],-1+(2*pan),amp),
					Pan2.ar(bufsnd[1],1+(2*pan),amp),
				]);
				Out.ar(0,snd)
			}).add;	
		});

		samplerPlayer = Array.fill(6,{arg i;
			Synth("player"++i,[\bufnum:sampleBuff[i]], target:context.xg);
		});

		this.addCommand("samplefile","is", { arg msg;
			// lua is sending 1-index
			sampleBuff[msg[1]-1].free;
			sampleBuff[msg[1]-1] = Buffer.read(context.server,msg[2]);
		});

		this.addCommand("play","iff", { arg msg;
			// lua is sending 1-index
			samplerPlayer[msg[1]-1].set(\t_trig,1,\amp,msg[2],\pan,msg[3]);
		});

	}

	free {
		sampleBuff.free;
		samplerPlayer.free;
	}
}
