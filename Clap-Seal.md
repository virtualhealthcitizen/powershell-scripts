# Clap seal

A clapping ASCII seal and the standing ovation it earns. The seal claps, the
crowd notices, and an APPLAUSE-O-METER fills. As the hype climbs the show
escalates through tiers -- warming up -> BIG APPLAUSE -> STANDING OVATION ->
*** ENCORE!!! *** -- with rising clap pitch, accelerating tempo, colour-cycling,
raining confetti, floating crowd reactions (BRAVO! / 10/10 / GOAT), and
starstruck eyes. Hit the target (or peak the meter) and the seal takes a bow
under a confetti cannon. Everything composites onto a per-cell canvas, so
confetti falls *in front of* the seal and you can line up a whole clapping
chorus.

```powershell
.\Clap-Seal.ps1                       # clap forever, press Q (or Ctrl+C) to stop
.\Clap-Seal.ps1 -Claps 20 -Seals 3    # a three-seal chorus, 20 claps then the bow
.\Clap-Seal.ps1 -DelayMs 150 -Silent  # faster, no beeps or fireworks
.\Clap-Seal.ps1 -NoConfetti           # skip the confetti cannon
.\Clap-Seal.ps1 -Storyboard -Seed 7   # static escalation montage to stdout
```
