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
			SynthDef("player"++i,{ arg t_trig=0, amp=0.0,rate=1.0,pan=0,lpf=20000,resonance=2,hpf=10,sampleStart=0,sampleLength=6,t_gate=0;
				var snd,bufsnd;
				bufsnd = PlayBuf.ar(2, sampleBuff[i],
					rate:BufRateScale.kr(sampleBuff[i])*rate,
					startPos:BufSampleRate.kr(sampleBuff[i])*sampleStart,
					trigger:t_trig);
		        bufsnd = MoogFF.ar(bufsnd,lpf,resonance);
		        bufsnd = HPF.ar(bufsnd,hpf);
				snd = Mix.ar([
					Pan2.ar(bufsnd[0],-1+(2*pan),amp),
					Pan2.ar(bufsnd[1],1+(2*pan),amp),
				]);
				Out.ar(0,snd*EnvGen.ar(Env([0,1, 1, 0], [0.001,sampleLength,0.1]),gate:t_gate))
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

		this.addCommand("play","iffffffff", { arg msg;
			// lua is sending 1-index
			samplerPlayer[msg[1]-1].set(
				\t_trig,1,
				\amp,msg[2],
				\rate,msg[3],
				\pan,msg[4],
				\lpf,msg[5],
				\resonance,msg[6],
				\hpf,msg[7],
				\sampleStart,msg[8],
				\sampleLength,msg[9],
				\t_gate,1
			);
		});

	}

	free {
		sampleBuff.free;
		samplerPlayer.free;
	}
}
