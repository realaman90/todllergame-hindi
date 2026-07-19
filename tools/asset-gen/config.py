"""
Shared configuration for asset generation scripts.
Style constants derived from docs/design/mockups/v1.1-cast-and-screens.html.
Curriculum data from docs/design/curriculum.md.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env from repo root
_REPO_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(_REPO_ROOT / ".env")

# Accept both spellings — the local .env uses OPEN_AI_API_KEY
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "") or os.environ.get("OPEN_AI_API_KEY", "")
ELEVENLABS_API_KEY = os.environ.get("ELEVENLABS_API_KEY", "")
# Gemini API key — Lyria 3 music generation (ADR-009)
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY", "")

OUT_DIR = Path(__file__).parent / "out"

# ---------------------------------------------------------------------------
# Style guide — derived from mockup v1.1
# ---------------------------------------------------------------------------

PALETTE = {
    "paper": "#FBF3E6",
    "paper2": "#F1E3C9",
    "marigold": "#F2871F",
    "marigold_deep": "#C4680F",
    "peacock": "#146F69",
    "peacock_deep": "#0D4F4A",
    "mehndi": "#5C8A3A",
    "mehndi_deep": "#3F6427",
    "kumkum": "#E1516B",
    "kumkum_deep": "#B93752",
}

# Visual style description for Imagen prompts
STYLE_PREFIX = (
    "Paper-cutout illustration style for a toddler Hindi learning app. "
    "Warm, handmade aesthetic with soft edges and visible paper texture. "
    "Colour palette inspired by Indian material culture: "
    "marigold orange (#F2871F), peacock teal (#146F69), "
    "mehndi green (#5C8A3A), kumkum pink (#E1516B), "
    "on a warm cream paper background (#FBF3E6). "
    "Friendly, rounded shapes. No text or UI elements in the image. "
    "Child-safe, gentle, joyful. "
)

# ---------------------------------------------------------------------------
# Characters
# ---------------------------------------------------------------------------

CHARACTERS = {
    "mithu": {
        "name": "Mithu",
        "hindi": "मिठू",
        "species": "parrot",
        "role": "host/narrator",
        "color_accent": "mehndi green with marigold crest",
        "description": (
            "A small, friendly Indian parrot (parakeet shape). "
            "Bright mehndi-green body, marigold-orange crest feathers, "
            "round black eyes with white highlight, tiny curved beak. "
            "Wears no clothing. Cheerful, slightly mischievous expression. "
            "Paper-cutout style with visible layered paper edges."
        ),
    },
    "gauri": {
        "name": "Gauri",
        "hindi": "गौरी",
        "species": "cow",
        "role": "Bageecha companion",
        "color_accent": "cream body with marigold garland",
        "description": (
            "A gentle Indian cow, cream/off-white body with soft brown patches. "
            "Wears a small marigold flower garland around her neck. "
            "Large kind eyes, small curved horns, friendly expression. "
            "Slightly chubby, toddler-proportioned (big head, small body). "
            "Paper-cutout style with visible layered paper edges."
        ),
    },
    "laddoo": {
        "name": "Laddoo",
        "hindi": "लड्डू",
        "species": "puppy",
        "role": "Ghar companion",
        "color_accent": "warm golden-brown like a laddoo sweet",
        "description": (
            "A small, round Indian street puppy (pariah dog shape). "
            "Warm golden-brown fur colour like a laddoo sweet. "
            "Floppy ears, big round eyes, always looks sleepy or happy. "
            "Curled tail, stubby legs. Often napping or wagging. "
            "Paper-cutout style with visible layered paper edges."
        ),
    },
}

# ---------------------------------------------------------------------------
# Scenes
# ---------------------------------------------------------------------------

SCENES = {
    "ghar": {
        "name": "Ghar (House)",
        "hindi": "घर",
        "color_theme": "marigold",
        "description": (
            "Interior of a warm Indian home. Terracotta floor tiles, "
            "cream walls with paper texture. A wooden door, a window with "
            "sunlight streaming in. Simple furniture: a low table (mez), "
            "a chair (kursi), a bed (bistar) with a pillow (takiya). "
            "A clock on the wall. Kitchen corner visible with roti, "
            "dal, fruits. Laddoo the pup naps by the door. "
            "Warm marigold tones dominate. Paper-cutout layered style."
        ),
    },
    "bageecha": {
        "name": "Bageecha (Farm/Garden)",
        "hindi": "बगीचा",
        "color_theme": "mehndi",
        "description": (
            "A lush Indian farm/garden scene. Green grass, a large tree (ped), "
            "colourful flowers (phool). Sun (sooraj) in the sky. "
            "Animals scattered: Gauri the cow, a goat (bakri), hen (murgi), "
            "duck (batakh), rabbit (khargosh). A small pond edge. "
            "Mehndi green and peacock teal dominate with pops of "
            "marigold (sun) and kumkum (flowers). Paper-cutout layered style."
        ),
    },
    "parivaar": {
        "name": "Parivaar (Family)",
        "hindi": "परिवार",
        "color_theme": "kumkum",
        "description": (
            "A cozy Indian family room / courtyard. Family members gathered: "
            "mother (maa), father (papa), grandparents (dadi, dada), "
            "siblings (bhai, bahan), a baby (baccha). "
            "Warm kumkum pink and marigold tones. "
            "A rangoli pattern on the floor. Cushions and a low seat. "
            "Mithu the parrot perched nearby. Paper-cutout layered style."
        ),
    },
}

# ---------------------------------------------------------------------------
# Curriculum word list (from docs/design/curriculum.md)
# ---------------------------------------------------------------------------

WORDS = {
    # Scene: Ghar — Household objects
    "house_paani": {"hindi": "पानी", "english": "water", "scene": "ghar"},
    "house_doodh": {"hindi": "दूध", "english": "milk", "scene": "ghar"},
    "house_kursi": {"hindi": "कुर्सी", "english": "chair", "scene": "ghar"},
    "house_mez": {"hindi": "मेज़", "english": "table", "scene": "ghar"},
    "house_bistar": {"hindi": "बिस्तर", "english": "bed", "scene": "ghar"},
    "house_takiya": {"hindi": "तकिया", "english": "pillow", "scene": "ghar"},
    "house_darwaza": {"hindi": "दरवाज़ा", "english": "door", "scene": "ghar"},
    "house_khidki": {"hindi": "खिड़की", "english": "window", "scene": "ghar"},
    "house_saabun": {"hindi": "साबुन", "english": "soap", "scene": "ghar"},
    "house_ghadi": {"hindi": "घड़ी", "english": "clock", "scene": "ghar"},
    # Scene: Ghar — Common foods
    "house_roti": {"hindi": "रोटी", "english": "flatbread", "scene": "ghar"},
    "house_chawal": {"hindi": "चावल", "english": "rice", "scene": "ghar"},
    "house_daal": {"hindi": "दाल", "english": "lentils", "scene": "ghar"},
    "house_seb": {"hindi": "सेब", "english": "apple", "scene": "ghar"},
    "house_kela": {"hindi": "केला", "english": "banana", "scene": "ghar"},
    "house_aam": {"hindi": "आम", "english": "mango", "scene": "ghar"},
    # Scene: Bageecha — Animals
    "farm_gaay": {"hindi": "गाय", "english": "cow", "scene": "bageecha"},
    "farm_bakri": {"hindi": "बकरी", "english": "goat", "scene": "bageecha"},
    "farm_murgi": {"hindi": "मुर्गी", "english": "hen", "scene": "bageecha"},
    "farm_kutta": {"hindi": "कुत्ता", "english": "dog", "scene": "bageecha"},
    "farm_billi": {"hindi": "बिल्ली", "english": "cat", "scene": "bageecha"},
    "farm_haathi": {"hindi": "हाथी", "english": "elephant", "scene": "bageecha"},
    "farm_batakh": {"hindi": "बत्तख", "english": "duck", "scene": "bageecha"},
    "farm_khargosh": {"hindi": "खरगोश", "english": "rabbit", "scene": "bageecha"},
    # Scene: Bageecha — Nature & colors
    "farm_phool": {"hindi": "फूल", "english": "flower", "scene": "bageecha"},
    "farm_ped": {"hindi": "पेड़", "english": "tree", "scene": "bageecha"},
    "farm_sooraj": {"hindi": "सूरज", "english": "sun", "scene": "bageecha"},
    "farm_laal": {"hindi": "लाल", "english": "red", "scene": "bageecha"},
    "farm_peela": {"hindi": "पीला", "english": "yellow", "scene": "bageecha"},
    "farm_hara": {"hindi": "हरा", "english": "green", "scene": "bageecha"},
    # Scene: Parivaar — Family members
    "family_maa": {"hindi": "माँ", "english": "mother", "scene": "parivaar"},
    "family_papa": {"hindi": "पापा", "english": "father", "scene": "parivaar"},
    "family_dadi": {"hindi": "दादी", "english": "grandmother", "scene": "parivaar"},
    "family_dada": {"hindi": "दादा", "english": "grandfather", "scene": "parivaar"},
    "family_bhai": {"hindi": "भाई", "english": "brother", "scene": "parivaar"},
    "family_bahan": {"hindi": "बहन", "english": "sister", "scene": "parivaar"},
    "family_baccha": {"hindi": "बच्चा", "english": "baby", "scene": "parivaar"},
    # Scene: Parivaar — Body parts
    "family_aankh": {"hindi": "आँख", "english": "eye", "scene": "parivaar"},
    "family_naak": {"hindi": "नाक", "english": "nose", "scene": "parivaar"},
    "family_munh": {"hindi": "मुँह", "english": "mouth", "scene": "parivaar"},
    "family_kaan": {"hindi": "कान", "english": "ear", "scene": "parivaar"},
    "family_haath": {"hindi": "हाथ", "english": "hand", "scene": "parivaar"},
    "family_pair": {"hindi": "पैर", "english": "foot", "scene": "parivaar"},
    "family_sir": {"hindi": "सिर", "english": "head", "scene": "parivaar"},
    "family_baal": {"hindi": "बाल", "english": "hair", "scene": "parivaar"},
    # Scene: Parivaar — Counting 1-10
    "family_ek": {"hindi": "एक", "english": "one", "scene": "parivaar"},
    "family_do": {"hindi": "दो", "english": "two", "scene": "parivaar"},
    "family_teen": {"hindi": "तीन", "english": "three", "scene": "parivaar"},
    "family_chaar": {"hindi": "चार", "english": "four", "scene": "parivaar"},
    "family_paanch": {"hindi": "पांच", "english": "five", "scene": "parivaar"},
    "family_chhah": {"hindi": "छह", "english": "six", "scene": "parivaar"},
    "family_saat": {"hindi": "सात", "english": "seven", "scene": "parivaar"},
    "family_aath": {"hindi": "आठ", "english": "eight", "scene": "parivaar"},
    "family_nau": {"hindi": "नौ", "english": "nine", "scene": "parivaar"},
    "family_das": {"hindi": "दस", "english": "ten", "scene": "parivaar"},
}

# ---------------------------------------------------------------------------
# Song definitions (v2-roadmap content, generated early as ready assets)
# ---------------------------------------------------------------------------

SONGS = {
    "counting": {
        "title": "Ek Do Teen (Counting Song)",
        "description": "A gentle counting song from 1-10 in Hindi",
        "tempo": "slow",
        "instrumentation": "warm Indian — soft tabla, harmonium drone, gentle flute",
        "lyrics_hint": (
            "Simple repetitive structure using: "
            "ek, do, teen, chaar, paanch, chhah, saat, aath, nau, das. "
            "Each number repeated twice with a gentle melodic phrase between."
        ),
    },
    "animals": {
        "title": "Jaanwar Geet (Animal Song)",
        "description": "A playful song naming farm animals",
        "tempo": "slow-medium",
        "instrumentation": "warm Indian — dholak rhythm, sitar pluck, flute melody",
        "lyrics_hint": (
            "Simple repetitive structure using: "
            "gaay, bakri, murgi, kutta, billi, haathi, batakh, khargosh. "
            "Each animal name with its sound or movement described simply."
        ),
    },
    "family": {
        "title": "Mera Parivaar (My Family Song)",
        "description": "A warm song about family members",
        "tempo": "slow",
        "instrumentation": "warm Indian — gentle harmonium, soft tabla, tanpura drone",
        "lyrics_hint": (
            "Simple repetitive structure using: "
            "maa, papa, dadi, dada, bhai, bahan. "
            "Each family member introduced lovingly with a short phrase."
        ),
    },
    # Rhyme-translation songs (no v1 original — famous public-domain
    # melodies adapted into curriculum-vocabulary Hindi)
    "sooraj": {
        "title": "Pyaare Sooraj (Sun Song)",
        "description": "A gentle lullaby about the sun and colours",
        "tempo": "slow",
        "instrumentation": "warm Indian — music-box glockenspiel feel, soft harmonium, gentle flute",
        "lyrics_hint": "Twinkle-Twinkle-style lullaby using sooraj, peela, laal, hara, phool, ped.",
    },
    "sharir": {
        "title": "Sir Haath Pair (Body Parts Song)",
        "description": "A bouncy action song naming body parts",
        "tempo": "medium, playful",
        "instrumentation": "warm Indian — bouncy dholak, harmonium, playful flute",
        "lyrics_hint": "Head-shoulders-style action song using sir, haath, pair, aankh, kaan, naak, munh, baal.",
    },
}

# ---------------------------------------------------------------------------
# Instrumental/ambient loops
# ---------------------------------------------------------------------------

INSTRUMENTALS = {
    "theme": {
        "title": "Main Theme Loop",
        "description": "Gentle main menu / home screen theme",
        "mood": "warm, welcoming, calm, slightly playful",
        "instrumentation": "soft harmonium, light tabla, gentle flute, tanpura drone",
        "duration_seconds": 60,
    },
    "ghar_ambient": {
        "title": "Ghar Ambient Loop",
        "description": "House scene background — cozy indoor atmosphere",
        "mood": "cozy, safe, quiet, domestic warmth",
        "instrumentation": "soft harmonium drone, occasional wind chime, very gentle tabla",
        "duration_seconds": 90,
    },
    "bageecha_ambient": {
        "title": "Bageecha Ambient Loop",
        "description": "Farm/garden scene — nature and gentle outdoors",
        "mood": "open air, gentle nature, birds, peaceful",
        "instrumentation": "bamboo flute, soft bird sounds, light sitar plucks, breeze texture",
        "duration_seconds": 90,
    },
    "parivaar_ambient": {
        "title": "Parivaar Ambient Loop",
        "description": "Family scene — warm togetherness",
        "mood": "loving, gentle, warm family gathering",
        "instrumentation": "tanpura drone, soft harmonium, very light tabla, occasional bells",
        "duration_seconds": 90,
    },
}

# ---------------------------------------------------------------------------
# SFX definitions
# ---------------------------------------------------------------------------

SFX = {
    "tap_pop": {
        "description": "A soft, satisfying pop when tapping an object — like tapping paper",
        "duration_seconds": 1,
    },
    "sticker_earned": {
        "description": "A gentle, bright chime for earning a sticker — warm bell + sparkle",
        "duration_seconds": 2,
    },
    "celebration": {
        "description": "A soft celebration burst — gentle confetti/sparkle, not overwhelming",
        "duration_seconds": 3,
    },
}
