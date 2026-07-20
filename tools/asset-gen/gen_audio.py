#!/usr/bin/env python3
"""
Audio generation script using ElevenLabs API.
Generates songs (via Eleven Music), instrumental loops, SFX (via sound effects),
and placeholder Hindi word voiceover (TTS — dev-only, NOT for shipping per ADR-003).

Usage:
    python gen_audio.py                    # generate all
    python gen_audio.py --only songs
    python gen_audio.py --only instrumentals
    python gen_audio.py --only sfx
    python gen_audio.py --only voiceover
"""

import argparse
import os
import sys
import time
from pathlib import Path

from elevenlabs import ElevenLabs

from config import (
    ELEVENLABS_API_KEY,
    GOOGLE_API_KEY,
    INSTRUMENTALS,
    OUT_DIR,
    SFX,
    SONGS,
    WORDS,
)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

if not ELEVENLABS_API_KEY:
    print("ERROR: ELEVENLABS_API_KEY not set in .env")
    sys.exit(1)

client = ElevenLabs(api_key=ELEVENLABS_API_KEY)

AUDIO_DIR = OUT_DIR / "audio"
SONGS_DIR = AUDIO_DIR / "songs"
INST_DIR = AUDIO_DIR / "instrumentals"
SFX_DIR = AUDIO_DIR / "sfx"
PLACEHOLDER_DIR = AUDIO_DIR / "placeholder"


def ensure_dirs():
    for d in [SONGS_DIR, INST_DIR, SFX_DIR, PLACEHOLDER_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def save_audio(audio_iter, output_path: Path):
    """Save audio from a generator/iterator to a file.

    Removes the partial file if streaming fails mid-write, so a rerun
    regenerates it instead of skipping a corrupt file.
    """
    try:
        with open(output_path, "wb") as f:
            for chunk in audio_iter:
                f.write(chunk)
    except Exception:
        output_path.unlink(missing_ok=True)
        raise


# ---------------------------------------------------------------------------
# Songs (Eleven Music API)
# ---------------------------------------------------------------------------

# Lyrics constraint: curriculum vocabulary only (docs/design/curriculum.md),
# plus animal sounds (moo/meh/etc.) and a tiny set of glue words, each flagged
# in the NOTE header of the saved .txt for parent review.
#
# Lyrics are in DEVANAGARI — the music model pronounces Latin-script Hindi
# with an English accent; Devanagari script forces native pronunciation.
SONG_LYRICS = {
    "counting": """\
NOTE FOR REVIEW — vocabulary sources:
  curriculum words: एक दो तीन चार पांच छह सात आठ नौ दस
  (ek do teen chaar paanch chhah saat aath nau das)
  non-curriculum glue: none — numbers only.

एक दो तीन, एक दो तीन
एक दो तीन चार पांच

छह सात आठ, छह सात आठ
छह सात आठ नौ दस

एक! दो! तीन! चार! पांच!
छह! सात! आठ! नौ! दस!

एक... दो... तीन... चार... पांच...
छह... सात... आठ... नौ... दस

एक दो तीन, एक दो तीन
एक दो तीन चार पांच
छह सात आठ नौ दस!
""",
    "animals": """\
NOTE FOR REVIEW — vocabulary sources:
  curriculum words: गाय बकरी मुर्गी कुत्ता बिल्ली हाथी बत्तख खरगोश
  (gaay bakri murgi kutta billi haathi batakh khargosh)
  animal sounds (not vocabulary): मू मेह कुक-डू-कू भौं म्याऊँ क्वैक
  non-curriculum glue: none — names and sounds only.

गाय गाय, मू मू मू
बकरी बकरी, मेह मेह मेह
मुर्गी मुर्गी, कुक-डू-कू
गाय, बकरी, मुर्गी!

कुत्ता कुत्ता, भौं भौं भौं
बिल्ली बिल्ली, म्याऊँ म्याऊँ
बत्तख बत्तख, क्वैक क्वैक क्वैक
कुत्ता, बिल्ली, बत्तख!

हाथी! हाथी! खरगोश! खरगोश!
गाय, बकरी, मुर्गी, कुत्ता
बिल्ली, हाथी, बत्तख, खरगोश!

मू मू! मेह मेह! कुक-डू-कू!
""",
    "family": """\
NOTE FOR REVIEW — vocabulary sources:
  curriculum words: माँ पापा दादी दादा भाई बहन बच्चा
  (maa papa dadi dada bhai bahan baccha)
  non-curriculum glue: मेरा/मेरी (my), और (and) — flagged for review.

माँ, मेरी माँ
पापा, मेरे पापा
माँ और पापा, माँ और पापा

दादी, मेरी दादी
दादा, मेरे दादा
दादी और दादा, दादी और दादा

भाई, मेरा भाई
बहन, मेरी बहन
भाई और बहन, भाई और बहन

माँ, पापा, दादी, दादा
भाई, बहन, और बच्चा!
माँ, पापा, दादी, दादा
भाई, बहन, और बच्चा!
""",
}


# v2: Hindi adaptations of famous public-domain nursery-rhyme structures
# (English + Swedish classics), still constrained to curriculum vocabulary
# plus flagged glue words. Generated ALONGSIDE v1 for A/B review.
SONG_LYRICS_V2 = {
    "counting": """\
NOTE FOR REVIEW — v2, adapted from "Ten Little Indians" (public-domain
melody/structure — count up, then back down).
  curriculum words: एक दो तीन चार पांच छह सात आठ नौ दस, बच्चा/बच्चे
  non-curriculum glue: प्यारे/प्यारा (dear/cute) — flagged for review.

एक दो तीन बच्चे
चार पांच छह बच्चे
सात आठ नौ बच्चे
दस प्यारे बच्चे!

दस नौ आठ बच्चे
सात छह पांच बच्चे
चार तीन दो बच्चे
एक प्यारा बच्चा!

एक दो तीन बच्चे
चार पांच छह बच्चे
सात आठ नौ बच्चे
दस प्यारे बच्चे!
""",
    "animals": """\
NOTE FOR REVIEW — v2, adapted from "Old MacDonald Had a Farm" (public-domain
structure; the bakri verse nods to the Swedish "Bä bä vita lamm").
  curriculum words: दादा, बगीचा (scene name), गाय बकरी मुर्गी कुत्ता
  animal sounds (not vocabulary): मू मेह कुक-डू-कू भौं, ई-आई-ई-आई-ओ
  non-curriculum glue: के / में / है (grammar particles) — flagged.

दादा के बगीचे में, ई-आई-ई-आई-ओ
बगीचे में है गाय, ई-आई-ई-आई-ओ
मू मू मू! मू मू मू!
दादा के बगीचे में, ई-आई-ई-आई-ओ

दादा के बगीचे में, ई-आई-ई-आई-ओ
बगीचे में है बकरी, ई-आई-ई-आई-ओ
मेह मेह मेह! मेह मेह मेह!
दादा के बगीचे में, ई-आई-ई-आई-ओ

दादा के बगीचे में, ई-आई-ई-आई-ओ
बगीचे में है मुर्गी, ई-आई-ई-आई-ओ
कुक-डू-कू! कुक-डू-कू!
दादा के बगीचे में, ई-आई-ई-आई-ओ

दादा के बगीचे में, ई-आई-ई-आई-ओ
बगीचे में है कुत्ता, ई-आई-ई-आई-ओ
भौं भौं भौं! भौं भौं भौं!
दादा के बगीचे में, ई-आई-ई-आई-ओ
""",
    "family": """\
NOTE FOR REVIEW — v2, adapted from "Finger Family" (public-domain
call-and-answer structure: "where are you? / here I am").
  curriculum words: माँ पापा दादी दादा भाई बहन बच्चा
  non-curriculum glue: कहाँ हो (where are you), मैं यहाँ (here I am),
  नमस्ते — flagged for review.

माँ माँ, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते माँ!

पापा पापा, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते पापा!

दादी दादी, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते दादी!

दादा दादा, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते दादा!

भाई भाई, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते भाई!

बहन बहन, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते बहन!

बच्चा बच्चा, कहाँ हो?
मैं यहाँ, मैं यहाँ!
नमस्ते बच्चा!
""",
    "sooraj": """\
NOTE FOR REVIEW — rhyme translation, adapted from "Twinkle Twinkle Little
Star" / Swedish "Blinka lilla stjärna" (same public-domain melody in both
household languages — star swapped for the curriculum's sun).
  curriculum words: सूरज पीला लाल हरा फूल पेड़
  (sooraj peela laal hara phool ped)
  non-curriculum glue: चमको (shine), प्यारे (dear), है (is), और (and) —
  flagged for review.

चमको चमको प्यारे सूरज
पीले पीले प्यारे सूरज

लाल है फूल, हरा है पेड़
पीला सूरज, ऊँचा पेड़

चमको चमको प्यारे सूरज
पीले पीले प्यारे सूरज
""",
    "sharir": """\
NOTE FOR REVIEW — rhyme translation, adapted from "Head, Shoulders, Knees
and Toes" (public-domain action-song structure; body parts limited to the
curriculum list — no knees/shoulders, so head-hands-feet carry the action).
  curriculum words: सिर हाथ पैर आँख कान नाक मुँह बाल
  (sir haath pair aankh kaan naak munh baal)
  non-curriculum glue: और (and) — flagged for review.

सिर, हाथ, पैर — हाथ, पैर!
सिर, हाथ, पैर — हाथ, पैर!

आँख और कान, और नाक और मुँह
सिर, हाथ, पैर — हाथ, पैर!

सिर, हाथ, पैर — हाथ, पैर!
सिर, हाथ, पैर — हाथ, पैर!

बाल भी! आँख भी! नाक भी! मुँह भी!
सिर, हाथ, पैर — हाथ, पैर!
""",
}

# Extra melody guidance per v2 song. Described structurally — naming the
# original English songs trips ElevenLabs' ToS/style-imitation filter
# (the animals song 400'd on a prompt that said "Old MacDonald").
SONG_V2_MELODY = {
    "counting": (
        "Simple ascending counting melody that steps up through the first "
        "phrase, then the same phrase mirrored counting back down."
    ),
    "animals": (
        "Cheerful farmyard verse structure: each verse names one animal, "
        "answered by its animal sound, with a repeated nonsense-syllable "
        "refrain ('ee-aai-ee-aai-o') between lines."
    ),
    "family": (
        "Gentle call-and-answer structure: a calling question phrase, an "
        "answering phrase, and a short greeting phrase, repeated for each "
        "family member."
    ),
    "sooraj": (
        "Classic gentle lullaby melody: a simple rising-then-falling "
        "phrase repeated in pairs, music-box twinkling feel, very soft "
        "and soothing — a bedtime song."
    ),
    "sharir": (
        "Bouncy sing-along action-song melody: short punchy phrases with "
        "a clear beat on each named word so a child can point along, "
        "repeating the same phrase pattern, slightly faster on the final "
        "repeat."
    ),
}


def _lyrics_body(text: str) -> str:
    """Lyrics without the review-note header (for the music prompt)."""
    if "\n\n" in text:
        return text.split("\n\n", 1)[1]
    return text


def _compose_song(slug: str, song: dict, lyrics: str, mp3_name: str,
                  melody_hint: str = ""):
    """Compose one song version via the Music API, with lyrics .txt beside it."""
    if not lyrics:
        return

    mp3_path = SONGS_DIR / mp3_name
    txt_path = SONGS_DIR / f"{mp3_path.stem}_lyrics.txt"

    txt_path.write_text(lyrics, encoding="utf-8")
    print(f"  Saved lyrics: {txt_path.name}")

    if mp3_path.exists():
        print(f"  SKIP (exists): {mp3_path.name}")
        return

    # Instrumentation leads the prompt — buried mid-prompt, the model
    # produced near-a-cappella vocals with no instruments.
    prompt = (
        f"A fully arranged children's song with rich instrumental backing "
        f"playing throughout — {song['instrumentation']} — with a short "
        f"instrumental intro before the vocals enter and a gentle "
        f"instrumental outro. The instruments accompany the singing from "
        f"start to finish; never a cappella. "
        f"({song['title']}) {song['description']}. "
        f"Tempo: {song['tempo']}. "
        f"{melody_hint} "
        f"Vocals: a native Hindi speaker — warm, soothing female voice with "
        f"natural Hindi pronunciation and prosody, like a mother singing a "
        f"lori (lullaby) to her child. No English accent. "
        f"Simple melody, very repetitive, easy for a 3-year-old to follow. "
        f"Sing exactly these Devanagari lyrics:\n\n{_lyrics_body(lyrics)}"
    )

    print(f"  Generating song: {mp3_path.name} ...")
    try:
        response = client.music.compose(
            prompt=prompt,
            music_length_ms=75_000,
        )
        save_audio(response, mp3_path)
        print(f"  OK: {mp3_path.name}")
    except Exception as e:
        print(f"  ERROR ({mp3_path.name}): {e}")
        print(f"  TIP: Check the ElevenLabs plan includes Eleven Music.")

    time.sleep(3)


# ---------------------------------------------------------------------------
# Lyria 3 backend (Gemini API) — primary music backend per ADR-009.
# Devanagari lyrics in the prompt produce native Hindi vocals; all output
# carries an inaudible SynthID watermark.
# ---------------------------------------------------------------------------

LYRIA_MODEL = "lyria-3-pro-preview"
_lyria_client = None


def _lyria():
    global _lyria_client
    if _lyria_client is None:
        from google import genai as google_genai
        if not GOOGLE_API_KEY:
            print("ERROR: GOOGLE_API_KEY not set in .env (needed for Lyria)")
            sys.exit(1)
        _lyria_client = google_genai.Client(api_key=GOOGLE_API_KEY)
    return _lyria_client


def _compose_song_lyria(slug: str, song: dict, lyrics: str, mp3_name: str,
                        melody_hint: str = ""):
    """Compose one song version via Lyria 3, with lyrics .txt beside it."""
    import base64 as b64

    if not lyrics:
        return

    mp3_path = SONGS_DIR / mp3_name
    txt_path = SONGS_DIR / f"{mp3_path.stem}_lyrics.txt"

    txt_path.write_text(lyrics, encoding="utf-8")
    print(f"  Saved lyrics: {txt_path.name}")

    if mp3_path.exists():
        print(f"  SKIP (exists): {mp3_path.name}")
        return

    prompt = (
        f"A Hindi children's song for toddlers, about 90 seconds long. "
        f"{song['description']}. "
        f"Full arrangement: {song['instrumentation']}, playing from a short "
        f"instrumental intro, behind all vocals, through a gentle outro. "
        f"Tempo: {song['tempo']}. {melody_hint} "
        f"Vocals: warm, soothing female voice, motherly, singing in Hindi "
        f"with natural native pronunciation. Simple repetitive melody a "
        f"3-year-old can follow.\n\n"
        f"[Verse] Sing exactly these lyrics:\n{_lyrics_body(lyrics)}"
    )

    print(f"  Generating (Lyria): {mp3_path.name} ...")
    try:
        interaction = _lyria().interactions.create(
            model=LYRIA_MODEL,
            input=prompt,
        )
        audio = getattr(interaction, "output_audio", None)
        if audio and getattr(audio, "data", None):
            mp3_path.write_bytes(b64.b64decode(audio.data))
            print(f"  OK: {mp3_path.name}")
        else:
            print(f"  WARN: no audio returned for {mp3_path.name}")
    except Exception as e:
        print(f"  ERROR ({mp3_path.name}): {e}")

    time.sleep(3)


def _compose_instrumental_lyria(slug: str, inst: dict):
    """Compose one instrumental loop via Lyria 3."""
    import base64 as b64

    mp3_path = INST_DIR / f"{slug}_lyria.mp3"
    if mp3_path.exists():
        print(f"  SKIP (exists): {mp3_path.name}")
        return

    prompt = (
        f"Instrumental music only — absolutely no vocals, no singing, no "
        f"humming. {inst['description']}. Mood: {inst['mood']}. "
        f"Instruments: {inst['instrumentation']}. About "
        f"{inst['duration_seconds']} seconds, designed to loop seamlessly "
        f"(end must flow back into the beginning). Calm toddler-game "
        f"background music, not overstimulating."
    )

    print(f"  Generating (Lyria): {mp3_path.name} ...")
    try:
        interaction = _lyria().interactions.create(
            model=LYRIA_MODEL,
            input=prompt,
        )
        audio = getattr(interaction, "output_audio", None)
        if audio and getattr(audio, "data", None):
            mp3_path.write_bytes(b64.b64decode(audio.data))
            print(f"  OK: {mp3_path.name}")
        else:
            print(f"  WARN: no audio returned for {mp3_path.name}")
    except Exception as e:
        print(f"  ERROR ({mp3_path.name}): {e}")

    time.sleep(3)


def generate_songs(backend: str = "lyria"):
    """Generate Hindi toddler songs.

    Backends: "lyria" (default, ADR-009) writes <name>_lyria.mp3;
    "elevenlabs" writes the original <name>.mp3 files. Both can coexist
    in out/ for A/B curation.

    Two versions per song either way:
      v1 (<slug>)          — original curriculum-vocab lyrics
      v2 (<slug>_v2_rhyme) — adaptation of a famous nursery rhyme
    """
    print(f"\n=== SONGS ({backend}) ===")
    for slug, song in SONGS.items():
        if backend == "lyria":
            _compose_song_lyria(slug, song, SONG_LYRICS.get(slug, ""),
                                f"{slug}_lyria.mp3")
            _compose_song_lyria(slug, song, SONG_LYRICS_V2.get(slug, ""),
                                f"{slug}_v2_rhyme_lyria.mp3",
                                SONG_V2_MELODY.get(slug, ""))
        else:
            _compose_song(slug, song, SONG_LYRICS.get(slug, ""), f"{slug}.mp3")
            _compose_song(
                slug, song, SONG_LYRICS_V2.get(slug, ""),
                f"{slug}_v2_rhyme.mp3", SONG_V2_MELODY.get(slug, ""),
            )


# ---------------------------------------------------------------------------
# Instrumental / ambient loops
# ---------------------------------------------------------------------------

def generate_instrumentals(backend: str = "lyria"):
    """Generate instrumental theme and ambient loops."""
    print(f"\n=== INSTRUMENTALS ({backend}) ===")
    if backend == "lyria":
        for slug, inst in INSTRUMENTALS.items():
            _compose_instrumental_lyria(slug, inst)
        return
    for slug, inst in INSTRUMENTALS.items():
        mp3_path = INST_DIR / f"{slug}.mp3"
        if mp3_path.exists():
            print(f"  SKIP (exists): {mp3_path.name}")
            continue

        prompt = (
            f"Instrumental music loop (no vocals, no singing, no lyrics). "
            f"{inst['description']}. "
            f"Mood: {inst['mood']}. "
            f"Instruments: {inst['instrumentation']}. "
            f"Suitable for a toddler game background. "
            f"Calm, not overstimulating. Should loop seamlessly."
        )

        print(f"  Generating: {mp3_path.name} ...")
        try:
            response = client.music.compose(
                prompt=prompt,
                music_length_ms=inst["duration_seconds"] * 1000,
            )
            save_audio(response, mp3_path)
            print(f"  OK: {mp3_path.name}")
        except Exception as e:
            print(f"  ERROR ({mp3_path.name}): {e}")

        time.sleep(3)


# ---------------------------------------------------------------------------
# SFX (Sound Effects)
# ---------------------------------------------------------------------------

def generate_sfx():
    """Generate UI sound effects."""
    print("\n=== SFX ===")
    for slug, sfx in SFX.items():
        mp3_path = SFX_DIR / f"{slug}.mp3"
        if mp3_path.exists():
            print(f"  SKIP (exists): {mp3_path.name}")
            continue

        prompt = (
            f"Short UI sound effect for a toddler game: {sfx['description']}. "
            f"Child-friendly, not startling. Gentle and satisfying."
        )

        print(f"  Generating: {mp3_path.name} ...")
        try:
            response = client.text_to_sound_effects.convert(
                text=prompt,
                duration_seconds=sfx["duration_seconds"],
            )
            save_audio(response, mp3_path)
            print(f"  OK: {mp3_path.name}")
        except Exception as e:
            print(f"  ERROR ({mp3_path.name}): {e}")

        time.sleep(2)


# ---------------------------------------------------------------------------
# Placeholder Hindi word voiceover (DEV ONLY — ADR-003)
# ---------------------------------------------------------------------------

# Hindi voice for placeholder VO. Default: "Noorie - Warm Conversational
# Support" (female, Hindi) from the shared library, added to the account.
# Override with ELEVENLABS_HINDI_VOICE_ID in .env if you prefer another.
DEFAULT_HINDI_VOICE_ID = "U05hO0X5Y4TnTclUk0k7"  # Noorie


def get_hindi_voice_id() -> str:
    """Return the Hindi voice to use for placeholder VO."""
    override = os.environ.get("ELEVENLABS_HINDI_VOICE_ID", "").strip()
    if override:
        print(f"  Using voice from ELEVENLABS_HINDI_VOICE_ID: {override}")
        return override
    print(f"  Using default Hindi voice: Noorie ({DEFAULT_HINDI_VOICE_ID})")
    return DEFAULT_HINDI_VOICE_ID


# Mithu's host lines (docs/design/curriculum.md "Mithu's host lines").
# Placeholder TTS, dev-only per ADR-003 — real takes come from the founder
# in a playful parrot-host register.
MITHU_LINES = {
    "mithu_intro_name": "नमस्ते! मेरा नाम मिठू है!",
    "mithu_intro_play": "चलो, साथ में खेलें!",
    "mithu_intro_choose": "एक दरवाज़ा चुनो!",
    "mithu_greeting": "नमस्ते! चलो खेलें!",
    "mithu_welcome_house": "चलो घर घूमें!",
    "mithu_welcome_farm": "चलो बगीचा घूमें!",
    "mithu_welcome_family": "चलो परिवार से मिलें!",
    "mithu_kahaan_hai": "कहाँ है?",
    "mithu_shabash": "शाबाश!",
    "mithu_wah": "वाह!",
    "mithu_badhiya": "बहुत बढ़िया!",
    "mithu_sticker": "नया स्टिकर मिला!",
    # Warm corrective + game-prompt lines (2026-07-20 game expansion)
    "mithu_yeh": "यह",
    "mithu_nahi_hai": "नहीं है!",
    "mithu_phir_se": "फिर से!",
    "mithu_alag_kaun": "अलग कौन है?",
    "mithu_konsa_bada": "कौन सा बड़ा है?",
    "mithu_konsa_chota": "कौन सा छोटा है?",
    "mithu_bada": "बड़ा!",
    "mithu_game_linematch": "रेखा मिलाओ!",
    "mithu_game_pairs": "जोड़ी मिलाओ!",
    "mithu_game_pattern": "पैटर्न पूरा करो!",
    "mithu_game_kulfi": "कुल्फी बनाओ!",
    "mithu_kulfi": "कुल्फी!",
    "mithu_daalo": "डालो!",
    "mithu_chota": "छोटा!",
}


def generate_mithu_lines():
    """Generate placeholder VO for Mithu's host lines (DEV ONLY, ADR-003)."""
    print("\n=== MITHU HOST LINES (placeholder, DEV ONLY) ===")
    voice_id = get_hindi_voice_id()
    for slug, text in MITHU_LINES.items():
        path = PLACEHOLDER_DIR / f"{slug}.mp3"
        if path.exists():
            print(f"  SKIP (exists): {path.name}")
            continue
        print(f"  Generating: {path.name} ({text}) ...")
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
            save_audio(audio, path)
            print(f"  OK: {path.name}")
        except Exception as e:
            print(f"  ERROR ({path.name}): {e}")
        time.sleep(1)


def generate_voiceover():
    """
    Generate placeholder TTS voiceover for all curriculum words.
    Two takes per word: standard pace and slow pace.

    OUTPUT: placeholder/ subfolder — DEV USE ONLY, not for shipping (ADR-003).
    """
    print("\n=== PLACEHOLDER VOICEOVER (DEV ONLY) ===")
    print("  NOTE: These are TTS placeholders. Shipped audio must be")
    print("        real native-speaker recordings per ADR-003.\n")

    voice_id = get_hindi_voice_id()

    for slug, word in WORDS.items():
        std_path = PLACEHOLDER_DIR / f"{slug}.mp3"
        slow_path = PLACEHOLDER_DIR / f"{slug}_slow.mp3"

        hindi_text = word["hindi"]

        # Standard pace
        if not std_path.exists():
            print(f"  Generating: {std_path.name} ({hindi_text}) ...")
            try:
                audio = client.text_to_speech.convert(
                    voice_id=voice_id,
                    text=hindi_text,
                    model_id="eleven_multilingual_v2",
                    voice_settings={
                        "stability": 0.7,
                        "similarity_boost": 0.8,
                        "style": 0.3,
                    },
                )
                save_audio(audio, std_path)
                print(f"  OK: {std_path.name}")
            except Exception as e:
                print(f"  ERROR ({std_path.name}): {e}")
            time.sleep(1)
        else:
            print(f"  SKIP (exists): {std_path.name}")

        # Slow pace — add ellipsis to encourage slower speech
        if not slow_path.exists():
            slow_text = f"... {hindi_text} ..."
            print(f"  Generating: {slow_path.name} ({hindi_text} slow) ...")
            try:
                audio = client.text_to_speech.convert(
                    voice_id=voice_id,
                    text=slow_text,
                    model_id="eleven_multilingual_v2",
                    voice_settings={
                        "stability": 0.85,
                        "similarity_boost": 0.8,
                        "style": 0.1,
                        "speed": 0.7,
                    },
                )
                save_audio(audio, slow_path)
                print(f"  OK: {slow_path.name}")
            except Exception as e:
                print(f"  ERROR ({slow_path.name}): {e}")
            time.sleep(1)
        else:
            print(f"  SKIP (exists): {slow_path.name}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Generate game audio with ElevenLabs")
    parser.add_argument(
        "--only",
        choices=["songs", "instrumentals", "sfx", "voiceover", "mithu"],
        help="Generate only one category",
    )
    parser.add_argument(
        "--backend",
        choices=["lyria", "elevenlabs"],
        default="lyria",
        help="Music backend for songs/instrumentals (default lyria, ADR-009; "
        "SFX and voiceover always use ElevenLabs)",
    )
    args = parser.parse_args()

    ensure_dirs()

    if args.only is None or args.only == "songs":
        generate_songs(args.backend)
    if args.only is None or args.only == "instrumentals":
        generate_instrumentals(args.backend)
    if args.only is None or args.only == "sfx":
        generate_sfx()
    if args.only is None or args.only == "voiceover":
        generate_voiceover()
    if args.only == "mithu":
        generate_mithu_lines()

    print("\nDone! Check out/audio/ for results.")
    if args.only is None or args.only == "voiceover":
        print("\nREMINDER: placeholder/ voiceover is DEV ONLY.")
        print("Shipped audio must be real native-speaker recordings (ADR-003).")


if __name__ == "__main__":
    main()
