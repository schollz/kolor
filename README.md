# כל אור

every light in sequence.

![title](/docs/title.jpg)

this script is born out an exploration of sampler drum machines. its not just a drum machine though - you can load in any one-hit samples and sequence them. i've bought and returned drum machines because i found them always lacking something. in this one i try to include the things that i want and not much more. some things i've included are:

- parameter locks with lots of parameters (volume, pitch, lpf, hpf, sample start/end, retrig, probability).
- every parameter has an lfo.
- the lfo of each parameter has an lfo.
- pattern chaining is easy and can be done probabilistically (markov chaining)
- as little menu-diving as possible (the parameter scaling is really the only menu to dive into)
- works with any non-grid norns script

the last one is my real goal. i've written a number of norns scripts and none of them use grid. ideally this script can be added to any non-grid script to instantly allow it to have a working drum/sample sequencer.

the grid is divided into sections. its easiest to understand the sections looking at the pictures, rather than writing about them. essentially there are six sections - patterning (top half of grid), a scale bar (middle), stop/record/play buttons (left), parameters and effects (middle top), sample selection (left), and pattern selection (right).



## Quickstart

![at a glance](./docs/glance.jpg)

![track](./docs/track.jpg)

![sample](./docs/sample.jpg)

![effect](./docs/effect.jpg)

![lfo](./docs/lfo.jpg)

![cue](./docs/cue.jpg)
