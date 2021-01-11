# כל אור

every light in sequence.

![title](/docs/title.jpg)

this script is born out an exploration of sampler sequencers. i drew inspiration from the op-z and model:samples (though i don't own these i was inspired by how i think they are supposed to work). i had five goals making this sample sequencer:

1. works easily with any non-grid norns script. i've made a lot of scripts and i want to plug in a grid and use it immediately as a drum machine without much code injection. to meet this goal, the norns screen actually does very little to control this script.
2. trigger-specific parameter locks with lots of parameters (volume, pitch, filters, sample positions, probability, etc.) with lfos for all of them. and an lfo for the lfo's, because why not.
3. easy pattern chaining and probabilistic chaining for automatically adding variation (markov chaining).
4. as little menu-diving as possible, with very few "hold" buttons or "mode" screens. (have to do my best given 128 white lights...)
5. stereo samples! because uncorrelated noise in both ears sounds awesome.

at the end i was able to only compromise on a few things.

### known bugs

- retrig doesn't work (yet). there are a couple ways to implement it but i'm still waiting for an easy way.
- delay doesn't work (yet). still need to work out supercollider buses.


### at a glance

the grid is divided into sections. its easiest to understand the sections looking at the pictures, rather than writing about them. essentially there are six sections - patterning (top half of grid), a scale bar (middle), stop/record/play buttons (left), parameters and effects (middle top), sample selection (left), and pattern selection (right).

![at a glance](./docs/glance.jpg)

![track](./docs/track.jpg)

![sample](./docs/sample.jpg)

![effect](./docs/effect.jpg)

![lfo](./docs/lfo.jpg)

![cue](./docs/cue.jpg)
