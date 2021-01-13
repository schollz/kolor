# כל אור

every light in sequence.

this script is born out an exploration of sampler sequencers. i drew inspiration from the op-z and model:samples (though i don't own these i was inspired by how i think they are supposed to work). i had five goals making this sample sequencer:

1. works easily with any non-grid norns script. i've made a lot of scripts and i want to plug in a grid and use it immediately as a drum machine without much code injection. to meet this goal, the norns screen actually does very little to control this script.
2. trigger-specific parameter locks with lots of parameters (volume, pitch, filters, sample positions, probability, etc.) with lfos for all of them. and an lfo for the lfo's, because why not.
3. easy pattern chaining and probabilistic chaining for automatically adding variation (markov chaining).
4. as little menu-diving as possible, with very few "hold" buttons or "mode" screens. (have to do my best given 128 white lights...)
5. stereo samples! because uncorrelated noise in both ears sounds awesome.

at the end i was able to only compromise on a few things.

### add to your favorite script

as long as your norns script does not use the grid, you can add *kolor* to it. just edit the script file and add these two lines:

```lua
kolor = include("lib/kolor")
kolor:new()
```

## license

mit
