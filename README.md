# FretNout
*Navigate your fretboard like a sonic astronaut*

### **Mission**

A SuperCollider-powered guitar learning toolkit for explorers of chords, scales, modes, arpeggios, cadences, etc. No sheet music required — just curiosity and a pick.

---

## Tools

### _cadenceator_

**Mission:** Generate chord sequences
- Randomly picks a tonic (root chord)
- Builds harmonically rich progressions

Use cases:
- Practice chord changes
- Composition sparks

### _modulation_game_
**Mission:** Generate dynamic backing tracks
- Creates rhythmic grooves + minimalist basslines
- Holds defined tonalities for solo practice

Use cases:
- Scale navigation
- modulation drills
- improvisation

Inspired by the modulation game (see the book of Miles Okazaki "Fundamentals of Guitar", p.18)

## How to Pilot This Rocket

Clone repo into SuperCollider's Extensions folder:

```bash
git  clone  https://github.com/deniskolokol/fretnout
```

Launch SuperCollider and run:

```supercollider
// In SC IDE:
include("modulation_game_GUI.scd");
```
⚠️ Required: SuperCollider 3.12+

## Future
- _arpeggiatorio_ - arpeggio trainer
- _viscaleron_ - fretboard visualizer

"No liftoff without a tonic!"
– FretNout Mission Log

Contribute? Open a PR or issue!

Found a black hole? Report issues [here](https://github.com/deniskolokol/fretnout/issues) 