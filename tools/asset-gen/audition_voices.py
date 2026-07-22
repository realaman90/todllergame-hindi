#!/usr/bin/env python3
"""
Voice audition kit: render one fixed Hindi audition script across
candidate ElevenLabs voices, and build out/audition/audition.html for a
side-by-side founder listen. Decides whether a curated TTS voice can
supersede ADR-003 (native recording) — or confirms recording stands.

Usage:
    python audition_voices.py            # workspace voices + hi search
    python audition_voices.py --limit 8
"""

import argparse
import html
import sys
from pathlib import Path

from elevenlabs import ElevenLabs

from config import ELEVENLABS_API_KEY, OUT_DIR

if not ELEVENLABS_API_KEY:
    print("ERROR: ELEVENLABS_API_KEY not set in .env")
    sys.exit(1)

client = ElevenLabs(api_key=ELEVENLABS_API_KEY)

AUDITION_DIR = OUT_DIR / "audition"

# The audition script: phonetically hard words + character host lines.
# Nasals (आँख, मुँह, पांच), the khargosh cluster, retroflexes, and the
# "parrot-host energy" lines that carry the app's personality.
SCRIPT = {
    "words": "आँख … मुँह … खरगोश … पाँच … घड़ी … बत्तख",
    "intro": "नमस्ते! मेरा नाम मिठू है! चलो, साथ में खेलें!",
    "praise": "शाबाश! बहुत बढ़िया! वाह!",
    "prompt": "कौन सा बड़ा है? यह कहाँ है? क्या ग़ायब है?",
}

# The incumbent (Noorie) always auditions.
KNOWN = {"U05hO0X5Y4TnTclUk0k7": "Noorie (current placeholder)"}


def candidate_voices(limit: int):
    # Hindi-native library voices FIRST — workspace premades are English
    # and audition Hindi with the known accent flaw.
    out = dict(KNOWN)
    try:
        shared = client.voices.get_shared(page_size=30, language="hi")

        def score(v):
            labels = " ".join(
                str(x) for x in [getattr(v, "descriptive", ""),
                                 getattr(v, "age", ""),
                                 getattr(v, "gender", "")]).lower()
            pts = 0
            for good, w in [("pleasant", 3), ("upbeat", 3), ("warm", 3),
                            ("young", 2), ("modulated", 1), ("calm", 1),
                            ("female", 1)]:
                if good in labels:
                    pts += w
            for bad in ["serious", "corporate", "meditation",
                        "devotional", "thriller"]:
                if bad in labels:
                    pts -= 2
            return -pts

        for v in sorted(shared.voices, key=score):
            if len(out) >= limit:
                break
            try:
                client.voices.add_sharing_voice(
                    public_user_id=v.public_owner_id,
                    voice_id=v.voice_id,
                    new_name=f"audition_{v.name}"[:40],
                )
            except Exception:
                pass  # already added or not addable — try TTS anyway
            out.setdefault(v.voice_id, f"{v.name} (hi library)")
    except Exception as e:
        print(f"  shared voice search failed: {e}")
    return out


def render(voice_id: str, name: str):
    vdir = AUDITION_DIR / voice_id
    vdir.mkdir(parents=True, exist_ok=True)
    for slug, text in SCRIPT.items():
        path = vdir / f"{slug}.mp3"
        if path.exists():
            print(f"  SKIP {name}/{slug}")
            continue
        print(f"  Rendering {name}/{slug} ...")
        try:
            audio = client.text_to_speech.convert(
                voice_id=voice_id,
                text=text,
                model_id="eleven_multilingual_v2",
                voice_settings={
                    "stability": 0.5,
                    "similarity_boost": 0.8,
                    "style": 0.6,
                },
            )
            with open(path, "wb") as f:
                for chunk in audio:
                    f.write(chunk)
        except Exception as e:
            print(f"  ERROR {name}/{slug}: {e}")
            return False
    return True


def build_page(voices: dict):
    rows = []
    for vid, name in voices.items():
        vdir = AUDITION_DIR / vid
        if not any(vdir.glob("*.mp3")):
            continue
        cells = "".join(
            f'<td><audio controls preload="none" src="{vid}/{slug}.mp3">'
            f"</audio></td>"
            for slug in SCRIPT
        )
        rows.append(
            f"<tr><th>{html.escape(name)}<br>"
            f'<span class="vid">{vid}</span></th>{cells}</tr>'
        )
    heads = "".join(f"<th>{html.escape(k)}</th>" for k in SCRIPT)
    page = f"""<!doctype html><meta charset="utf-8">
<title>Voice audition — Mithu & Friends</title>
<style>
body{{font-family:system-ui;background:#FBF3E6;margin:24px;color:#333}}
h1{{color:#0D4F4A}}table{{border-collapse:collapse;width:100%}}
th,td{{padding:10px;border-bottom:1px solid #e5d9c4;text-align:left}}
audio{{width:230px}}.vid{{font-size:11px;color:#999;font-weight:normal}}
p{{max-width:70ch}}
</style>
<h1>Voice audition</h1>
<p>Same script per voice: hard words (nasals, खरगोश cluster), the intro,
praise, and game prompts. Listen for: native pronunciation, warmth,
child-appropriate energy, consistency across lines. Note issues per
voice — the winner (or none) decides whether ADR-003 stands.</p>
<table><tr><th>Voice</th>{heads}</tr>{"".join(rows)}</table>"""
    (AUDITION_DIR / "audition.html").write_text(page)
    print(f"\nWrote {AUDITION_DIR / 'audition.html'}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=6)
    args = ap.parse_args()
    voices = candidate_voices(args.limit)
    print(f"Auditioning {len(voices)} voices: {list(voices.values())}")
    ok = {vid: n for vid, n in voices.items() if render(vid, n)}
    build_page(ok)


if __name__ == "__main__":
    main()
