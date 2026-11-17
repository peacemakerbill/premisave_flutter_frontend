#!/usr/bin/env python3
"""Writes the two call sounds into assets/sounds: the ringtone people hear when a call comes in, and the ringback
tone the caller hears while the other phone rings. Plain sine tones with a soft attack and decay, 16-bit mono.

    python3 tool/call_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freqs, seconds, gain=0.32, attack=0.012, release=0.12, decay=0.0):
    n = int(RATE * seconds)
    out = []
    for i in range(n):
        t = i / RATE
        env = min(1.0, t / attack) * min(1.0, (seconds - t) / release)
        if decay:
            env *= math.exp(-decay * t)
        s = sum(math.sin(2 * math.pi * f * t) for f in freqs) / len(freqs)
        out.append(gain * env * s)
    return out


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def save(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in samples))


# Incoming: two rising chimes, twice, then a pause. 4 seconds, loops cleanly.
chime = tone([659.25, 1318.5], 0.42, decay=3.2) + tone([880.0, 1760.0], 0.62, decay=2.6)
ring = chime + silence(0.18) + chime + silence(4.0 - 2 * (0.42 + 0.62) - 0.18)
save("ringtone.wav", ring)

# Outgoing: the familiar double tone, 1.2 seconds on and 2.8 off.
ringback = tone([440.0, 480.0], 1.2, gain=0.22, attack=0.03, release=0.05) + silence(2.8)
save("ringback.wav", ringback)

# A short soft sound when someone joins or leaves.
save("join.wav", tone([587.33, 880.0], 0.22, gain=0.25, decay=5.0))
save("leave.wav", tone([880.0, 587.33], 0.22, gain=0.25, decay=5.0))
