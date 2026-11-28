#!/usr/bin/env python3
"""Always-on mic level dot (gray when muted); size and brightness follow input level."""
import array, math, subprocess, sys, time

IGNORE = ("pavucontrol", "PulseAudio Volume Control", "micmeter")
RATE, CHUNK = 16000, 1600  # 100 ms of s16 mono


def out(s):
    print(s, flush=True)


def recording():
    try:
        txt = subprocess.run(["pactl", "list", "source-outputs"], capture_output=True, text=True).stdout
    except OSError:
        return False
    for block in txt.split("Source Output #")[1:]:
        if "Corked: no" in block and not any(f'application.name = "{n}"' in block for n in IGNORE) \
                and 'media.name = "Peak detect"' not in block:
            return True
    return False


def render(level):
    lo, hi = (0x6b, 0x45, 0x10), (0xff, 0x9f, 0x0a)
    c = "".join(f"{round(a + (b - a) * level):02x}" for a, b in zip(lo, hi))
    glyph = "∙" if level < 0.15 else "•" if level < 0.4 else "●" if level < 0.7 else "⬤"
    return f"%{{F#{c}}}{glyph}%{{F-}}"


def muted():
    r = subprocess.run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"], capture_output=True, text=True).stdout
    return "yes" in r


GRAY = "%{F#666666}∙%{F-}"

while True:
    if muted():
        out(GRAY)
        time.sleep(1)
        continue
    p = subprocess.Popen(
        ["parec", "--device=@DEFAULT_SOURCE@", "--format=s16le", f"--rate={RATE}", "--channels=1",
         "--latency-msec=50", "--client-name=micmeter"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    try:
        n = 0
        smooth = 0.0
        while True:
            data = p.stdout.read(CHUNK * 2)
            if not data:
                break
            s = array.array("h", data[: len(data) // 2 * 2])
            rms = math.sqrt(sum(x * x for x in s) / max(len(s), 1))
            db = 20 * math.log10(rms / 32768) if rms > 0 else -90
            lvl = min(max((db + 60) / 40, 0.0), 1.0)
            smooth = lvl if lvl > smooth else smooth * 0.7 + lvl * 0.3
            out(render(smooth))
            n += 1
            if n % 5 == 0 and muted():
                break
    finally:
        p.kill()
        p.wait()
        time.sleep(0.2)
