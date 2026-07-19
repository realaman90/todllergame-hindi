#!/usr/bin/env python3
"""
Image generation script using OpenAI's gpt-image-2 model.
Generates character sheets, scene backgrounds, and object art for all
curriculum words in the paper-cutout style defined by the mockup.

Usage:
    python gen_images.py                  # generate all
    python gen_images.py --only characters
    python gen_images.py --only scenes
    python gen_images.py --only objects
    python gen_images.py --only objects --words house_paani,farm_gaay
"""

import argparse
import base64
import sys
import time
from pathlib import Path

from openai import OpenAI

from config import (
    CHARACTERS,
    OPENAI_API_KEY,
    OUT_DIR,
    PALETTE,
    SCENES,
    STYLE_PREFIX,
    WORDS,
)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

if not OPENAI_API_KEY:
    print("ERROR: OPENAI_API_KEY not set in .env")
    sys.exit(1)

client = OpenAI(api_key=OPENAI_API_KEY)

MODEL = "gpt-image-2"

IMAGES_DIR = OUT_DIR / "images"
CHAR_DIR = IMAGES_DIR / "characters"
SCENE_DIR = IMAGES_DIR / "scenes"
OBJ_DIR = IMAGES_DIR / "objects"
MASCOT_DIR = IMAGES_DIR / "mascot"


def ensure_dirs():
    for d in [CHAR_DIR, SCENE_DIR, OBJ_DIR, MASCOT_DIR]:
        d.mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Generation helpers
# ---------------------------------------------------------------------------

def generate_image(prompt: str, output_path: Path, size: str = "1024x1024"):
    """Generate a single image and save it as PNG."""
    if output_path.exists():
        print(f"  SKIP (exists): {output_path.name}")
        return

    print(f"  Generating: {output_path.name} ...")
    try:
        response = client.images.generate(
            model=MODEL,
            prompt=prompt,
            size=size,
            quality="high",
        )

        # gpt-image-2 returns base64 by default
        image_data = response.data[0].b64_json
        if image_data:
            output_path.write_bytes(base64.b64decode(image_data))
            print(f"  OK: {output_path.name}")
        elif response.data[0].url:
            # Fallback to URL download
            import httpx
            img_bytes = httpx.get(response.data[0].url).content
            output_path.write_bytes(img_bytes)
            print(f"  OK: {output_path.name}")
        else:
            print(f"  WARN: No image returned for {output_path.name}")

    except Exception as e:
        print(f"  ERROR ({output_path.name}): {e}")

    # Rate limiting
    time.sleep(2)


# ---------------------------------------------------------------------------
# Character sheets
# ---------------------------------------------------------------------------

def generate_characters():
    """Generate character sheet images for the 3 cast members."""
    print("\n=== CHARACTERS ===")
    for slug, char in CHARACTERS.items():
        prompt = (
            f"{STYLE_PREFIX}"
            f"Character design sheet showing multiple poses of {char['name']} "
            f"the {char['species']}. {char['description']} "
            f"Show 4 poses: front-facing, side view, waving/greeting, and sleeping/resting. "
            f"White background with subtle paper texture. "
            f"Consistent proportions across all poses. "
            f"Designed for a toddler audience — extra round, extra cute."
        )
        generate_image(prompt, CHAR_DIR / f"{slug}.png", size="1536x1024")


# ---------------------------------------------------------------------------
# Scene backgrounds
# ---------------------------------------------------------------------------

def generate_scenes():
    """Generate scene background images for the 3 MVP scenes."""
    print("\n=== SCENES ===")
    for slug, scene in SCENES.items():
        color = PALETTE.get(scene["color_theme"], PALETTE["marigold"])
        prompt = (
            f"{STYLE_PREFIX}"
            f"Full scene background for a toddler game: {scene['description']} "
            f"This scene's dominant accent colour is {scene['color_theme']} ({color}). "
            f"Wide establishing shot, no characters in the foreground — "
            f"just the environment with spots where tappable objects can be placed. "
            f"Portrait orientation (mobile phone screen), "
            f"layered paper depth, soft shadows between layers."
        )
        # Portrait for mobile screens
        generate_image(prompt, SCENE_DIR / f"{slug}.png", size="1024x1536")


# ---------------------------------------------------------------------------
# Object art (per-word tappable items)
# ---------------------------------------------------------------------------

OBJECT_PROMPTS = {
    "water": "a glass of water, clear with slight blue tint",
    "milk": "a glass of white milk",
    "chair": "a small wooden chair",
    "table": "a low wooden table",
    "bed": "a cozy bed with a colourful blanket",
    "pillow": "a soft puffy pillow",
    "door": "a wooden door, slightly ajar",
    "window": "a window with sunlight coming through",
    "soap": "a bar of soap with bubbles",
    "clock": "a round wall clock with simple numbers",
    "flatbread": "a round golden roti/chapati",
    "rice": "a bowl of white rice",
    "lentils": "a bowl of yellow dal/lentils",
    "apple": "a red apple",
    "banana": "a yellow banana",
    "mango": "a ripe yellow-orange mango",
    "cow": "a gentle Indian cow with a garland",
    "goat": "a friendly white goat",
    "hen": "a brown and red hen",
    "dog": "a golden-brown friendly puppy",
    "cat": "a striped cat, sitting",
    "elephant": "a baby elephant, cute and round",
    "duck": "a white duck with orange bill",
    "rabbit": "a soft grey rabbit with long ears",
    "flower": "a bright colourful flower, marigold-like",
    "tree": "a green leafy tree with brown trunk",
    "sun": "a warm smiling sun with rays",
    "red": "a red flower petal",
    "yellow": "a yellow sunflower",
    "green": "a green leaf",
    "mother": "a kind Indian mother in a saree, warm smile",
    "father": "a friendly Indian father, kurta, warm smile",
    "grandmother": "a loving Indian grandmother (dadi) in a saree",
    "grandfather": "a kind Indian grandfather (dada) with spectacles",
    "brother": "a young Indian boy (bhai), smiling",
    "sister": "a young Indian girl (bahan), smiling",
    "baby": "a cute Indian baby wrapped in a blanket",
    "eye": "a friendly cartoon eye",
    "nose": "a simple cartoon nose",
    "mouth": "a smiling cartoon mouth",
    "ear": "a cartoon ear shape",
    "hand": "a small child's hand, open palm",
    "foot": "a small child's foot",
    "head": "a child's face/head outline, smiling",
    "hair": "a head with black hair flowing",
    "one": "the number 1 with one finger held up",
    "two": "the number 2 with two fingers held up",
    "three": "the number 3 with three fingers held up",
    "four": "the number 4 with four fingers held up",
    "five": "the number 5 with an open palm",
    "six": "the number 6 with six dots arranged",
    "seven": "the number 7 with seven dots arranged",
    "eight": "the number 8 with eight dots arranged",
    "nine": "the number 9 with nine dots arranged",
    "ten": "the number 10 with two open palms",
}


def generate_objects(filter_words: list[str] | None = None):
    """Generate individual object art for each curriculum word."""
    print("\n=== OBJECTS ===")
    words_to_generate = WORDS
    if filter_words:
        words_to_generate = {k: v for k, v in WORDS.items() if k in filter_words}

    for slug, word in words_to_generate.items():
        obj_desc = OBJECT_PROMPTS.get(word["english"], word["english"])
        prompt = (
            f"{STYLE_PREFIX}"
            f"Single isolated object on a clean white background: {obj_desc}. "
            f"Paper-cutout style with visible paper layers and soft edges. "
            f"Simple, recognizable, designed for a 3-year-old to identify. "
            f"No text, no labels. Centered in frame."
        )
        generate_image(prompt, OBJ_DIR / f"{slug}.png")


# ---------------------------------------------------------------------------
# Mascot concept explorations (brand-level treatment of the host character)
# ---------------------------------------------------------------------------

MITHU_CORE = (
    "Mithu the parrot: small friendly Indian parakeet, bright mehndi-green "
    "body (#5C8A3A), marigold-orange crest feathers (#F2871F) as his "
    "signature silhouette hook, peacock-teal and kumkum-pink layered wing "
    "feathers, round black eyes with white highlight, small coral curved "
    "beak, extra round and cute toddler-friendly proportions (big head, "
    "small body). "
)

MASCOT_CONCEPTS = {
    "mithu_hero": {
        "size": "1024x1024",
        "prompt": (
            "Brand mascot hero illustration. "
            + MITHU_CORE
            + "One single confident signature pose: wings spread wide in a "
            "warm welcoming gesture, head slightly tilted, joyful open-beak "
            "smile. Instantly recognizable silhouette. Centered, large in "
            "frame, subtle warm cream paper background with a soft "
            "marigold-glow circle behind him."
        ),
    },
    "mithu_icon": {
        "size": "1024x1024",
        "prompt": (
            "Mobile app icon design. "
            + MITHU_CORE
            + "Face-forward head-and-shoulders crop, filling most of the "
            "square frame, bold and readable at small sizes. Warm cream "
            "background (#FBF3E6) with a simple marigold arc. No text. "
            "Rounded-square app icon composition."
        ),
    },
    "mithu_expressions": {
        "size": "1536x1024",
        "prompt": (
            "Character expression sheet, 6 heads in a 3x2 grid. "
            + MITHU_CORE
            + "Six distinct expressions: happy greeting, curious listening "
            "(head tilted, one eye wide), celebrating (beak open wide, "
            "crest up), gentle encouraging smile, sleepy (eyes closed), "
            "giggling. Same character design in all six, consistent "
            "proportions. Plain warm paper background, no text."
        ),
    },
    "alt_peacock_hero": {
        "size": "1024x1024",
        "prompt": (
            "Brand mascot hero illustration — ALTERNATIVE concept: a baby "
            "peacock chick mascot for a toddler Hindi learning game. Round "
            "chubby peacock-teal body (#146F69), tiny fan of layered tail "
            "feathers in marigold (#F2871F), mehndi green (#5C8A3A) and "
            "kumkum pink (#E1516B) paper layers, small crest of three dot "
            "feathers, huge friendly eyes, toddler proportions (big head, "
            "small body). Welcoming pose with tail fan spread. Warm cream "
            "paper background with a soft glow circle."
        ),
    },
}


def generate_mascot():
    """Generate mascot concept explorations (Mithu elevation + alternative)."""
    print("\n=== MASCOT CONCEPTS ===")
    for slug, concept in MASCOT_CONCEPTS.items():
        prompt = f"{STYLE_PREFIX}{concept['prompt']}"
        generate_image(prompt, MASCOT_DIR / f"{slug}.png", size=concept["size"])


# Canonical mascot reference (ADR-008). On-model art is generated via
# image EDITING from this reference, never fresh text prompts — text
# prompts drift the design (crest shape varied across the concept batch).
MITHU_CANON = MASCOT_DIR / "mithu_hero.png"


def generate_mithu_onmodel():
    """Regenerate Mithu's character sheet on-model from the canonical ref."""
    print("\n=== MITHU ON-MODEL CHARACTER SHEET ===")
    if not MITHU_CANON.exists():
        print(f"  ERROR: canonical reference missing: {MITHU_CANON}")
        print("  Run --only mascot first.")
        return

    output_path = CHAR_DIR / "mithu_v2_onmodel.png"
    if output_path.exists():
        print(f"  SKIP (exists): {output_path.name}")
        return

    prompt = (
        "Using this exact character design — same three-lobe marigold "
        "crest, same mehndi-green body, same peacock-teal and kumkum-pink "
        "layered wing feathers, same face and proportions — create a "
        "character sheet showing this identical parrot in 4 poses on a "
        "plain warm cream paper background: front-facing standing, side "
        "view, waving/greeting with one wing, and sleeping curled up. "
        "Keep the paper-cutout layered style. No text."
    )

    print(f"  Editing from canon: {output_path.name} ...")
    try:
        with open(MITHU_CANON, "rb") as ref:
            response = client.images.edit(
                model=MODEL,
                image=ref,
                prompt=prompt,
                size="1536x1024",
            )
        image_data = response.data[0].b64_json
        if image_data:
            output_path.write_bytes(base64.b64decode(image_data))
            print(f"  OK: {output_path.name}")
        else:
            print(f"  WARN: no image returned")
    except Exception as e:
        print(f"  ERROR ({output_path.name}): {e}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Generate game art with OpenAI gpt-image-2")
    parser.add_argument(
        "--only",
        choices=["characters", "scenes", "objects", "mascot", "mithu-onmodel"],
        help="Generate only one category",
    )
    parser.add_argument(
        "--words",
        type=str,
        default="",
        help="Comma-separated word slugs to generate (objects only)",
    )
    args = parser.parse_args()

    ensure_dirs()

    filter_words = [w.strip() for w in args.words.split(",") if w.strip()] or None

    if args.only is None or args.only == "characters":
        generate_characters()
    if args.only is None or args.only == "scenes":
        generate_scenes()
    if args.only is None or args.only == "objects":
        generate_objects(filter_words)
    if args.only == "mascot":
        # Mascot concepts are explorations — run explicitly, not in "all"
        generate_mascot()
    if args.only == "mithu-onmodel":
        generate_mithu_onmodel()

    print("\nDone! Check out/images/ for results.")


if __name__ == "__main__":
    main()
