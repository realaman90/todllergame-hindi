#!/usr/bin/env python3
"""
Build out/review.html — a single-page local gallery of everything in out/,
for the parent curation pass. Uses relative paths; open it from out/ in a
browser. Re-run any time after regenerating assets.
"""

import html
from pathlib import Path

from config import CHARACTERS, OUT_DIR, SCENES, SONGS, WORDS

REVIEW = OUT_DIR / "review.html"


def img_card(rel: str, title: str, sub: str = "") -> str:
    return (
        f'<figure><img src="{rel}" loading="lazy">'
        f"<figcaption><b>{html.escape(title)}</b>"
        + (f"<br><span>{html.escape(sub)}</span>" if sub else "")
        + "</figcaption></figure>"
    )


def audio_card(rel: str, title: str, sub: str = "", lyrics: str = "") -> str:
    out = (
        f'<div class="au"><b>{html.escape(title)}</b>'
        + (f" <span>{html.escape(sub)}</span>" if sub else "")
        + f'<br><audio controls preload="none" src="{rel}"></audio>'
    )
    if lyrics:
        out += (
            "<details><summary>lyrics</summary>"
            f"<pre>{html.escape(lyrics)}</pre></details>"
        )
    return out + "</div>"


def main():
    parts = [
        """<!doctype html><meta charset="utf-8">
<title>Asset review — Chalo Ghar Ghoome</title>
<style>
body{font-family:system-ui;background:#FBF3E6;color:#333;margin:0;padding:24px;max-width:1200px;margin:auto}
h1{color:#0D4F4A}h2{color:#C4680F;border-bottom:2px solid #F2871F;padding-bottom:4px;margin-top:40px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:14px}
figure{margin:0;background:#fff;border-radius:10px;padding:8px;box-shadow:0 2px 6px rgba(0,0,0,.08)}
img{width:100%;border-radius:6px}figcaption{font-size:13px;margin-top:6px}
figcaption span{color:#888;font-size:12px}
.au{background:#fff;border-radius:10px;padding:10px 14px;margin:8px 0;box-shadow:0 2px 6px rgba(0,0,0,.08)}
.au span{color:#888;font-size:12px}audio{width:100%;margin-top:6px}
pre{white-space:pre-wrap;font-size:13px;background:#FBF3E6;padding:10px;border-radius:6px}
.warn{background:#F2A0B2;border-radius:8px;padding:10px 14px;font-size:14px}
.cols{display:grid;grid-template-columns:1fr 1fr;gap:8px}
</style>
<h1>Asset review — Chalo Ghar Ghoome</h1>
<p>Everything generated so far. Curate: note keepers, flag regenerations.</p>"""
    ]

    # Mascot
    parts.append("<h2>Mascot (ADR-008 — approved canon)</h2><div class='grid'>")
    for p in sorted((OUT_DIR / "images/mascot").glob("*.png")):
        parts.append(img_card(f"images/mascot/{p.name}", p.stem))
    parts.append("</div>")

    # Characters
    parts.append("<h2>Characters</h2><div class='grid'>")
    for p in sorted((OUT_DIR / "images/characters").glob("*.png")):
        info = CHARACTERS.get(p.stem)
        sub = f"{info['hindi']} — {info['role']}" if info else "on-model sheet"
        parts.append(img_card(f"images/characters/{p.name}", p.stem, sub))
    parts.append("</div>")

    # Scenes
    parts.append("<h2>Scene backgrounds</h2><div class='grid'>")
    for p in sorted((OUT_DIR / "images/scenes").glob("*.png")):
        info = SCENES.get(p.stem)
        parts.append(
            img_card(f"images/scenes/{p.name}", info["name"] if info else p.stem)
        )
    parts.append("</div>")

    # Objects, grouped by scene
    for scene_key, scene in SCENES.items():
        parts.append(f"<h2>Objects — {html.escape(scene['name'])}</h2><div class='grid'>")
        for slug, w in WORDS.items():
            if w["scene"] != scene_key:
                continue
            p = OUT_DIR / f"images/objects/{slug}.png"
            if p.exists():
                parts.append(
                    img_card(
                        f"images/objects/{slug}.png",
                        f"{w['hindi']} ({w['english']})",
                        slug,
                    )
                )
        parts.append("</div>")

    # Songs
    parts.append("<h2>Songs (ship-candidates — v2 roadmap)</h2>")
    for p in sorted((OUT_DIR / "audio/songs").glob("*.mp3")):
        lyr = OUT_DIR / f"audio/songs/{p.stem}_lyrics.txt"
        lyrics = lyr.read_text(encoding="utf-8") if lyr.exists() else ""
        base = p.stem.replace("_lyria", "").replace("_v2_rhyme", "")
        info = SONGS.get(base)
        backend = "Lyria 3" if "_lyria" in p.stem else "ElevenLabs"
        kind = "rhyme translation" if "_v2_rhyme" in p.stem else "original"
        sub = f"{kind} — {backend}"
        title = info["title"] if info else p.stem
        parts.append(audio_card(f"audio/songs/{p.name}", title, sub, lyrics))

    # Instrumentals + SFX
    parts.append("<h2>Instrumental loops</h2>")
    for p in sorted((OUT_DIR / "audio/instrumentals").glob("*.mp3")):
        parts.append(audio_card(f"audio/instrumentals/{p.name}", p.stem))
    parts.append("<h2>SFX</h2>")
    for p in sorted((OUT_DIR / "audio/sfx").glob("*.mp3")):
        parts.append(audio_card(f"audio/sfx/{p.name}", p.stem))

    # Placeholder VO
    parts.append(
        "<h2>Placeholder word voiceover</h2>"
        "<p class='warn'>DEV ONLY — ships as real native-speaker recordings "
        "per ADR-003. Voice: Noorie (ElevenLabs). Standard + slow take per "
        "word.</p>"
    )
    for scene_key, scene in SCENES.items():
        parts.append(f"<h3>{html.escape(scene['name'])}</h3><div class='cols'>")
        for slug, w in WORDS.items():
            if w["scene"] != scene_key:
                continue
            std = OUT_DIR / f"audio/placeholder/{slug}.mp3"
            slow = OUT_DIR / f"audio/placeholder/{slug}_slow.mp3"
            if std.exists():
                parts.append(
                    audio_card(
                        f"audio/placeholder/{slug}.mp3",
                        f"{w['hindi']} ({w['english']})",
                        "standard",
                    )
                )
            if slow.exists():
                parts.append(
                    audio_card(
                        f"audio/placeholder/{slug}_slow.mp3",
                        f"{w['hindi']}",
                        "slow take",
                    )
                )
        parts.append("</div>")

    REVIEW.write_text("\n".join(parts), encoding="utf-8")
    print(f"Wrote {REVIEW}")


if __name__ == "__main__":
    main()
