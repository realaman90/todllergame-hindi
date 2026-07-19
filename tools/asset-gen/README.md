# tools/asset-gen

Dev-time asset generation scripts for concept art and placeholder audio.
None of this ships in the app binary (ADR-002 Kids Category compliance).

## Setup

```bash
cd tools/asset-gen
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

Ensure `.env` at repo root has `GOOGLE_API_KEY` and `ELEVENLABS_API_KEY` set
(see `.env.example`).

## Usage

```bash
# Generate all images (characters + scenes + object art)
python gen_images.py

# Generate specific category
python gen_images.py --only characters
python gen_images.py --only scenes
python gen_images.py --only objects

# Generate all audio (songs + instrumentals + SFX + placeholder voiceover)
python gen_audio.py

# Generate specific category
python gen_audio.py --only songs
python gen_audio.py --only instrumentals
python gen_audio.py --only sfx
python gen_audio.py --only voiceover
```

## Output

All generated files go to `out/` (git-ignored). Structure:

```
out/
  images/
    characters/     — character sheets (mithu.png, gauri.png, laddoo.png)
    scenes/         — scene backgrounds (ghar.png, bageecha.png, parivaar.png)
    objects/        — per-word art (house_paani.png, farm_gaay.png, etc.)
  audio/
    songs/          — .mp3 + .txt lyrics side by side
    instrumentals/  — theme + ambient loops
    sfx/            — tap_pop, sticker_earned, celebration
    placeholder/    — DEV ONLY TTS voiceover (NOT for shipping, ADR-003)
```

## Important notes

- **Voiceover is placeholder only.** Shipped word audio must be a real native
  speaker per ADR-003. The `placeholder/` subfolder exists purely for dev
  builds before the recording session.
- **Songs are v2-roadmap content** generated early as ready assets. Do not
  build a music mode into any app plans without explicit sign-off.
- Style prompts are derived from `docs/design/mockups/v1.1-cast-and-screens.html`.
- Filenames match the slug convention in `docs/design/curriculum.md`.
