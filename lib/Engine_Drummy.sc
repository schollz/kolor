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
			SynthDef("player"++i,{ arg t_trig=0, lfolfo=0.0, currentTime=0.0, 
				ampMin=0.0, ampMax=0.0, ampLFOMin=0.0, ampLFOMax=0.0, 
				rateMin=1.0, rateMax=1.0, rateLFOMin=0.0, rateLFOMax=0.0,
				panMin=1.0, panMax=1.0, panLFOMin=0.0, panLFOMax=0.0,
				lpfMin=1.0, lpfMax=1.0, lpfLFOMin=0.0, lpfLFOMax=0.0,
				resonance=2,hpf=10,sampleStart=0,sampleLength=6,t_gate=0,retrig=0;
				
				var amp, rate, pan, lpf, snd, bufsnd;
				
				// lfo modulation
				amp = SinOsc.kr(
					SinOsc.kr(lfolfo,(currentTime*2*pi*ampLFOMin).mod(2*pi),mul:(ampLFOMax-ampLFOMin),add:(ampLFOMax+ampLFOMin)/2),
					(currentTime*2*pi*ampLFOMin).mod(2*pi),mul:(ampMax-ampMin)/2,add:(ampMax+ampMin)/2
				);
				rate = SinOsc.kr(
					SinOsc.kr(lfolfo,(currentTime*2*pi*rateLFOMin).mod(2*pi),mul:(rateFOMax-rateLFOMin),add:(rateLFOMax+rateLFOMin)/2),
					(currentTime*2*pi*rateLFOMin).mod(2*pi),mul:(rateMax-rateMin)/2,add:(rateMax+rateMin)/2
				);
				pan = SinOsc.kr(
					SinOsc.kr(lfolfo,(currentTime*2*pi*panLFOMin).mod(2*pi),mul:(panFOMax-panLFOMin),add:(panLFOMax+panLFOMin)/2),
					(currentTime*2*pi*panLFOMin).mod(2*pi),mul:(panMax-panMin)/2,add:(panMax+panMin)/2
				);
				lpf = SinOsc.kr(
					SinOsc.kr(lfolfo,(currentTime*2*pi*lpfLFOMin).mod(2*pi),mul:(lpfFOMax-lpfLFOMin),add:(lpfLFOMax+lpfLFOMin)/2),
					(currentTime*2*pi*lpfLFOMin).mod(2*pi),mul:(lpfMax-lpfMin)/2,add:(lpfMax+lpfMin)/2
				);
				
				bufsnd = PlayBuf.ar(2, sampleBuff[i],
					rate:rate*BufRateScale.kr(sampleBuff[i]),
					startPos:sampleStart*BufFrames.kr(sampleBuff[i]),
					loop:retrig, // if > 0 then it loops, getting stopped by the envelope
					trigger:t_trig);
		        	bufsnd = MoogFF.ar(bufsnd,lpf,resonance);
		        	bufsnd = HPF.ar(bufsnd,hpf);
				snd = Mix.ar([
					Pan2.ar(bufsnd[0],-1+(2*pan),amp),
					Pan2.ar(bufsnd[1],1+(2*pan),amp),
				]);
				Out.ar(0,snd*EnvGen.ar(Env([0,1, 1, 0], [0.005,sampleLength/(rate.abs)*(retrig+1)*BufDur.kr(sampleBuff[i]),0.005]),gate:t_gate))
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

		this.addCommand("play","iffffffffffffff", { arg msg;
			// lua is sending 1-index
			samplerPlayer[msg[1]-1].set(
				\t_trig,1,
				\currentTime, msg[2],
				\ampMin,msg[3],
				\ampMax,msg[4],
				\ampLFOMin,msg[5],
				\ampLFOMax,msg[6],
				\rate,msg[7],
				\pan,msg[8],
				\lpf,msg[9],
				\resonance,msg[10],
				\hpf,msg[11],
				\sampleStart,msg[12],
				\sampleLength,msg[13],
				\retrig,msg[14],
				\lfolfo,msg[15],
				\t_gate,1
			);
		});

	}

	free {
		sampleBuff.free;
		samplerPlayer.free;
	}
}
