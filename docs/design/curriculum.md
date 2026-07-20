---
type: Design
title: Curriculum — scene/word list
description: MVP content plan for each scene, structured as the recording script for the native-speaker voiceover session.
tags: [design, curriculum, content]
timestamp: 2026-07-18
status: draft — ready for parent/native-speaker review before recording
---

# Curriculum — Scene/Word List

Status: **first full draft.** This is the document that must be reviewed
and finalized before the voiceover recording session (ADR-003 —
re-recording is expensive). Word choice, exact spellings, and regional
preference (e.g., which grandparent terms) should get a native-speaker
pass before locking.

Columns: Hindi word (Devanagari), transliteration, English gloss,
recording note (tone/emphasis), audio filename convention.

**MVP total: 55 words** across 3 scenes (revised from the ~40 estimate in
`../product/SPEC.md`/`ROADMAP.md` once the real list was drafted — see
"Open items" below; those docs should be updated to match once this list
is locked).

## Recording session — general notes

- Default tone for every word: warm, unhurried, slightly playful —
  not a flat dictionary read.
- **Every word gets two takes:** a standard-pace take and a slower,
  slightly-elongated repeat take (per `../design/interaction-patterns.md`
  — tap once for standard, tap again for the slow repeat).
  Filenames: `<scene>_<slug>.mp3` (standard) and `<scene>_<slug>_slow.mp3`.
  Row-level "Recording note" only calls out exceptions to the default.
- Record in a consistent, quiet environment in one or two sessions to
  keep timbre/energy consistent across the whole word set — inconsistent
  recording sessions are noticeable to toddlers even if not to adults.

## Scene: Ghar (House)

### Household objects

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| पानी | paani | water | | `house_paani.mp3` |
| दूध | doodh | milk | | `house_doodh.mp3` |
| कुर्सी | kursi | chair | | `house_kursi.mp3` |
| मेज़ | mez | table | | `house_mez.mp3` |
| बिस्तर | bistar | bed | | `house_bistar.mp3` |
| तकिया | takiya | pillow | | `house_takiya.mp3` |
| दरवाज़ा | darwaza | door | | `house_darwaza.mp3` |
| खिड़की | khidki | window | | `house_khidki.mp3` |
| साबुन | saabun | soap | | `house_saabun.mp3` |
| घड़ी | ghadi | clock | | `house_ghadi.mp3` |

### Common foods (kitchen corner)

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| रोटी | roti | flatbread | | `house_roti.mp3` |
| चावल | chawal | rice | | `house_chawal.mp3` |
| दाल | daal | lentils | | `house_daal.mp3` |
| सेब | seb | apple | | `house_seb.mp3` |
| केला | kela | banana | | `house_kela.mp3` |
| आम | aam | mango | | `house_aam.mp3` |

Scene total: 16 words.

## Scene: Bageecha (Farm)

### Animals

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| गाय | gaay | cow | | `farm_gaay.mp3` |
| बकरी | bakri | goat | | `farm_bakri.mp3` |
| मुर्गी | murgi | hen | | `farm_murgi.mp3` |
| कुत्ता | kutta | dog | | `farm_kutta.mp3` |
| बिल्ली | billi | cat | | `farm_billi.mp3` |
| हाथी | haathi | elephant | | `farm_haathi.mp3` |
| बत्तख | batakh | duck | | `farm_batakh.mp3` |
| खरगोश | khargosh | rabbit | slow down on the "gh" cluster — easy to slur | `farm_khargosh.mp3` |

### Nature & colors

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| फूल | phool | flower | | `farm_phool.mp3` |
| पेड़ | ped | tree | | `farm_ped.mp3` |
| सूरज | sooraj | sun | | `farm_sooraj.mp3` |
| लाल | laal | red | shown as a red flower's color | `farm_laal.mp3` |
| पीला | peela | yellow | shown as the sun's/a flower's color | `farm_peela.mp3` |
| हरा | hara | green | shown as grass/leaf color | `farm_hara.mp3` |

Scene total: 14 words.

## Scene: Parivaar (Family)

### Family members

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| माँ | maa | mother | | `family_maa.mp3` |
| पापा | papa | father | | `family_papa.mp3` |
| दादी | dadi | grandmother (paternal) | see open item below re: maternal terms | `family_dadi.mp3` |
| दादा | dada | grandfather (paternal) | see open item below re: maternal terms | `family_dada.mp3` |
| भाई | bhai | brother | | `family_bhai.mp3` |
| बहन | bahan | sister | | `family_bahan.mp3` |
| बच्चा | baccha | baby / child | | `family_baccha.mp3` |

### Body parts

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| आँख | aankh | eye | nasal "aa" — don't flatten it | `family_aankh.mp3` |
| नाक | naak | nose | | `family_naak.mp3` |
| मुँह | munh | mouth | nasal — don't flatten it | `family_munh.mp3` |
| कान | kaan | ear | | `family_kaan.mp3` |
| हाथ | haath | hand | | `family_haath.mp3` |
| पैर | pair | foot | | `family_pair.mp3` |
| सिर | sir | head | | `family_sir.mp3` |
| बाल | baal | hair | | `family_baal.mp3` |

### Counting corner (1–10)

**Design note (open item):** this doesn't fit the single-tap
"tap-object-hear-word" loop the rest of the curriculum uses — counting
wants a sequential tap interaction (e.g., tap 10 fingers/dots in order),
not a scattered scene. Flag for `../specs/tbd/app-shell-and-scene-engine.md`
when it's written: numbers may need their own small interaction spec
rather than reusing the generic scene-object tap.

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| एक | ek | one | | `family_ek.mp3` |
| दो | do | two | | `family_do.mp3` |
| तीन | teen | three | | `family_teen.mp3` |
| चार | chaar | four | | `family_chaar.mp3` |
| पांच | paanch | five | nasal — don't flatten it | `family_paanch.mp3` |
| छह | chhah | six | | `family_chhah.mp3` |
| सात | saat | seven | | `family_saat.mp3` |
| आठ | aath | eight | | `family_aath.mp3` |
| नौ | nau | nine | | `family_nau.mp3` |
| दस | das | ten | | `family_das.mp3` |

Scene total: 25 words (7 family + 8 body parts + 10 numbers).

## Mithu's host lines (added 2026-07-20)

Mithu is the only character who speaks language (ADR-008; Gauri/Laddoo
make animal sounds only). These lines are part of the recording session
script — record them in a brighter, more playful register than the word
takes: that register difference IS the character. Voice casting: founder,
"parrot-host" energy.

| Devanagari | Transliteration | Used when | Audio file |
|---|---|---|---|
| नमस्ते! चलो घर घूमें! | namaste! chalo ghar ghoomein! | app open / home greeting | `mithu_greeting.mp3` |
| यह है घर! | yeh hai ghar! | entering Ghar | `mithu_welcome_house.mp3` |
| यह है बगीचा! | yeh hai bageecha! | entering Bageecha | `mithu_welcome_farm.mp3` |
| यह है परिवार! | yeh hai parivaar! | entering Parivaar | `mithu_welcome_family.mp3` |
| कहाँ है? | kahaan hai? | find-it prompt, played right after the target word (word + this = "___ कहाँ है?") | `mithu_kahaan_hai.mp3` |
| शाबाश! | shabash! | praise (random pick) | `mithu_shabash.mp3` |
| वाह! | wah! | praise (random pick) | `mithu_wah.mp3` |
| बहुत बढ़िया! | bahut badhiya! | praise (random pick) | `mithu_badhiya.mp3` |
| नया स्टिकर मिला! | naya sticker mila! | sticker earned | `mithu_sticker.mp3` |

Same two-take rule does NOT apply (no slow takes needed for host lines).
Placeholder TTS versions exist for dev builds only (ADR-003).

## Scene: Bazaar — v1.1

_Not started._

## Scene: Sharir (Body) — v1.1

_Not started. Note: body parts already appear in Parivaar above for MVP —
when this scene is designed, decide whether it absorbs/expands that list
or covers different content (e.g., more detailed parts, health routines)
to avoid duplication._

## Open items — resolve before recording

- **Grandparent terms:** this draft uses only दादी/दादा (paternal). Many
  families use नानी/नाना (maternal) as much or more. Decide: add both
  pairs (4 words instead of 2), or pick based on which side of the family
  is more present in her daily life.
- **Numbers interaction:** see the design note under "Counting corner"
  above — needs an interaction decision, not just a word list.
- **Word count vs. SPEC/ROADMAP:** those docs currently say "~40 words";
  this draft lands at 55. Update the estimate there once this list is
  locked (small edit, not a scope change — the content itself matches
  what ROADMAP already specified: animals, colors, family, numbers 1–10,
  body parts, common foods).
- **Native-speaker review pass:** spellings/word choices above are a
  first draft, not yet reviewed by a native speaker for regional
  naturalness (e.g., मेज़ vs. टेबल, छह vs. छः).

## Conventions for filling this in

- One row per word/object that will appear as a tappable target in a
  scene.
- Every row needs both the standard-pace and the slow-repeat take
  recorded (per `../product/SPEC.md`'s tap-again-to-repeat interaction) —
  note this per-row if a word needs special handling.
- Keep the audio filename convention stable — the app's asset loader will
  key off `<scene>_<slug>.mp3`.
- Do not start MVP recording until all three MVP scene tables are fully
  populated and reviewed. (House/Farm/Family are now populated — see
  "Open items" for what still needs review before recording.)
