---
type: Design
title: Level roadmap — 25 flash-card scene/word sets
description: Founder ask 2026-07-21 — 20-30 more explore ("flash card") levels. Phased by vocabulary cost, since every word needs a native recording (ADR-003).
tags: [design, curriculum, levels, roadmap]
timestamp: 2026-07-21
status: plan — each phase's words enter curriculum.md before its recording session
---

# Level Roadmap — Explore (सीखो) Levels

MVP ships 3 levels (Ghar 16, Bageecha 14, Parivaar 25 = 55 words). Each
new level is a scene JSON + background + object art (generation pipeline
is ready) + **recorded words** — audio is the only expensive unit, so
phases batch levels per recording session (~80-120 words each).

| # | Level | Words (est.) | Sample vocabulary |
|---|---|---|---|
| **Phase A — everyday world (next recording session)** ||||
| 4 | रसोई (Kitchen) | 12 | चम्मच, थाली, गिलास, कटोरी, चाकू, तवा… |
| 5 | फल (Fruits) | 12 | अंगूर, संतरा, अनार, पपीता, तरबूज़… |
| 6 | सब्ज़ी (Vegetables) | 12 | आलू, टमाटर, प्याज़, गाजर, मटर, भिंडी… |
| 7 | कपड़े (Clothes) | 12 | कमीज़, जूते, टोपी, मोज़े, फ्रॉक… |
| 8 | खिलौने (Toys) | 10 | गेंद, गुड़िया, ब्लॉक, झूला, साइकिल… |
| 9 | रंग (Colors, full) | 8 | नीला, गुलाबी, काला, सफ़ेद, नारंगी… (+MVP 3) |
| 10 | गिनती ११-२० (Counting 11-20) | 10 | ग्यारह … बीस |
| **Phase B — nature & town** ||||
| 11 | जंगल (Wild animals) | 12 | शेर, बंदर, भालू, हिरण, लोमड़ी, साँप… |
| 12 | पक्षी (Birds) | 10 | तोता, कौआ, मोर, चिड़िया, उल्लू… |
| 13 | कीड़े (Bugs & tiny things) | 8 | तितली, चींटी, मधुमक्खी, केंचुआ… |
| 14 | समुंदर (Sea) | 10 | मछली, केकड़ा, कछुआ, सीप, तारा… |
| 15 | मौसम (Weather) | 8 | बारिश, बादल, धूप, हवा, बर्फ़… |
| 16 | गाड़ी (Vehicles) | 12 | बस, रेल, हवाई जहाज़, नाव, ट्रक, रिक्शा… |
| 17 | बाज़ार (Market — already stubbed in curriculum) | 12 | दुकान, पैसे, झोला, तराज़ू… |
| **Phase C — self & concepts** ||||
| 18 | शरीर 2 (Body, detailed) | 10 | कंधा, घुटना, पेट, उँगली, कोहनी… |
| 19 | भावनाएँ (Feelings) | 8 | खुश, उदास, गुस्सा, डर, हँसी… |
| 20 | आकार (Shapes) | 8 | गोल, तिकोना, चौकोर, तारा, दिल… |
| 21 | उल्टा (Opposites) | 10 | बड़ा-छोटा, ऊपर-नीचे, अंदर-बाहर, गरम-ठंडा… |
| 22 | काम (Action words) | 12 | खाना, पीना, सोना, दौड़ना, कूदना, नहाना… |
| 23 | स्कूल (School) | 10 | किताब, पेंसिल, बस्ता, कुर्सी… |
| **Phase D — culture & celebration (kept warm, not cliché)** ||||
| 24 | त्योहार (Festivals) | 10 | दीया, पतंग, मिठाई, रंगोली, तोहफ़ा… |
| 25 | संगीत (Music & sounds) | 8 | ढोल, घंटी, बाँसुरी, ताली… |
| 26 | दिन-रात (Day & night routine) | 10 | सुबह, रात, चाँद, तारे, सपना… |
| 27 | घर के लोग 2 (Extended family) | 8 | नानी, नाना, चाचा, मौसी, दोस्त… |
| 28 | बगीचा 2 (Garden deep-dive) | 8 | पत्ता, मिट्टी, बीज, तितली, घास… |

**Total: ~250 new words across 25 levels.** Every level reuses the same
engine (scene JSON + subset rotation + puzzles) — zero new code per
level; cost is art generation (hours) + native recording (per phase).
Multi-language note (ADR-007): each level's word list is re-authored per
language pack, art is shared.
