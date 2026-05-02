"""Deterministic seed-data generator for iLearnIt Firestore.

Outputs:
  sample_data/instructors.json  — 10 instructor docs (Map id → fields)
  sample_data/courses.json      — 100 course docs    (Map id → fields)

Distribution
  guitar : 4 instructors → 35 courses
  piano  : 3 instructors → 35 courses
  violin : 3 instructors → 30 courses
"""
from __future__ import annotations

import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

random.seed(20260502)  # reproducible

OUT_DIR = Path("/sessions/eager-gallant-turing/mnt/ilearnit/sample_data")
OUT_DIR.mkdir(parents=True, exist_ok=True)


# ── Instructors ───────────────────────────────────────────────────────
INSTRUCTORS = [
    # Guitar (4)
    {
        "id": "ins_001",
        "name": "Antonio Vela",
        "instrument": "guitar",
        "bio": "Spanish-classical guitarist trained at the Royal Conservatory of Madrid. "
               "Specializes in Tárrega, Sor, and the Andalusian repertoire.",
        "specialties": ["spanish-classical", "fingerstyle", "tárrega", "sor"],
        "yearsExperience": 22,
        "country": "Spain",
    },
    {
        "id": "ins_002",
        "name": "Helena Rojas",
        "instrument": "guitar",
        "bio": "Flamenco-trained classical guitarist; bridges the rasgueado technique "
               "with the standard concert repertoire.",
        "specialties": ["flamenco-classical", "rasgueado", "rhythm", "improvisation"],
        "yearsExperience": 15,
        "country": "Argentina",
    },
    {
        "id": "ins_003",
        "name": "Marcus Reinhardt",
        "instrument": "guitar",
        "bio": "Concert guitarist and pedagogue with a focus on sight-reading, "
               "scales, and the Bach lute suites transcribed for guitar.",
        "specialties": ["sight-reading", "bach", "technique", "pedagogy"],
        "yearsExperience": 28,
        "country": "Germany",
    },
    {
        "id": "ins_004",
        "name": "Yuki Tanaka",
        "instrument": "guitar",
        "bio": "Lutenist and Renaissance specialist whose courses bring period "
               "ornamentation into the modern guitarist's toolkit.",
        "specialties": ["lute", "renaissance", "ornamentation", "early-music"],
        "yearsExperience": 18,
        "country": "Japan",
    },

    # Piano (3)
    {
        "id": "ins_005",
        "name": "Sofia Ackermann",
        "instrument": "piano",
        "bio": "Romantic-era pianist whose performances of Chopin and Schumann "
               "have earned her invitations to the Verbier and Lucerne festivals.",
        "specialties": ["chopin", "schumann", "romantic", "phrasing"],
        "yearsExperience": 24,
        "country": "Austria",
    },
    {
        "id": "ins_006",
        "name": "Daniel Voss",
        "instrument": "piano",
        "bio": "Baroque keyboardist focused on Bach's Well-Tempered Clavier and "
               "the Goldberg Variations, with deep interpretive analyses.",
        "specialties": ["bach", "baroque", "counterpoint", "fugue"],
        "yearsExperience": 30,
        "country": "Netherlands",
    },
    {
        "id": "ins_007",
        "name": "Isabela Moreau",
        "instrument": "piano",
        "bio": "Liszt and late-Romantic specialist; teaches the choreography of "
               "virtuosic technique without sacrificing musicality.",
        "specialties": ["liszt", "virtuoso", "technique", "pedaling"],
        "yearsExperience": 19,
        "country": "France",
    },

    # Violin (3)
    {
        "id": "ins_008",
        "name": "Ekaterina Volkova",
        "instrument": "violin",
        "bio": "Russian-school violinist; her interpretations of Tchaikovsky and "
               "Shostakovich have been called definitive by critics.",
        "specialties": ["russian-school", "tchaikovsky", "shostakovich", "vibrato"],
        "yearsExperience": 26,
        "country": "Russia",
    },
    {
        "id": "ins_009",
        "name": "Lucas Ferreira",
        "instrument": "violin",
        "bio": "Baroque violinist who plays on a 1742 Goffriller; lectures on "
               "historically informed performance practice.",
        "specialties": ["baroque", "vivaldi", "corelli", "historically-informed"],
        "yearsExperience": 21,
        "country": "Portugal",
    },
    {
        "id": "ins_010",
        "name": "Aria Kapoor",
        "instrument": "violin",
        "bio": "Contemporary classical specialist; premieres new works while "
               "teaching the bridge from etudes to commissioned repertoire.",
        "specialties": ["contemporary", "etudes", "extended-technique", "premieres"],
        "yearsExperience": 13,
        "country": "United Kingdom",
    },
]

# Group by instrument for course assignment.
BY_INSTRUMENT: dict[str, list[dict]] = {"guitar": [], "piano": [], "violin": []}
for ins in INSTRUCTORS:
    BY_INSTRUMENT[ins["instrument"]].append(ins)


# ── Course title generators ───────────────────────────────────────────
GUITAR_TOPICS = [
    "Classical Guitar Foundations",
    "Spanish Guitar Repertoire",
    "Fingerstyle Mastery",
    "Bach Lute Suites for Guitar",
    "Sight-Reading the Romantic Era",
    "Tárrega Recuerdos Step-by-Step",
    "Renaissance Lute on Modern Guitar",
    "Flamenco-Classical Rasgueado",
    "Right-Hand Technique Lab",
    "Sor Studies in Depth",
    "Villa-Lobos Preludes Decoded",
    "Building Concert-Ready Phrasing",
    "Tone Production for Concert Guitar",
    "Chord-Melody Architecture",
    "Stage Presence & Memorization",
]

PIANO_TOPICS = [
    "Bach: The Well-Tempered Clavier",
    "Chopin Nocturnes Interpretation",
    "Beethoven Sonatas — Early Period",
    "Beethoven Sonatas — Late Period",
    "Liszt Transcendental Études",
    "Schumann's Carnaval",
    "Bach Inventions & Sinfonias",
    "Goldberg Variations Lecture Series",
    "Pedaling for Romantic Repertoire",
    "Mozart Concerto Cadenzas",
    "Voicing Polyphony at the Piano",
    "Hand Independence Drills",
    "Memorization for Concert Pianists",
    "Phrasing the Long Romantic Line",
    "Practice Strategies for Virtuoso Works",
]

VIOLIN_TOPICS = [
    "Bach Sonatas & Partitas",
    "Vivaldi Four Seasons Decoded",
    "Tchaikovsky Concerto Workshop",
    "Paganini Caprices Foundations",
    "Etudes for Concert Violin",
    "Russian School Vibrato Lab",
    "Baroque Bowing Techniques",
    "Historically Informed Ornamentation",
    "Mendelssohn Concerto Step-by-Step",
    "Shostakovich Preludes & Fugues for Violin",
    "Corelli Sonatas — Period Approach",
    "Contemporary Premieres: From Score to Stage",
    "Extended Techniques for Modern Repertoire",
    "Spiccato & Sautillé Mastery",
    "Building a Recital Program",
]

TITLE_BANK = {
    "guitar": GUITAR_TOPICS,
    "piano": PIANO_TOPICS,
    "violin": VIOLIN_TOPICS,
}

LEVEL_SUFFIX = {
    "beginner": "— Beginner",
    "intermediate": "— Intermediate",
    "advanced": "— Advanced",
}

LEVEL_TAG_BANK = {
    "guitar": ["technique", "repertoire", "theory", "fingerstyle", "right-hand",
               "left-hand", "sight-reading", "interpretation", "phrasing", "tone"],
    "piano": ["technique", "repertoire", "theory", "pedaling", "phrasing",
             "hand-independence", "voicing", "interpretation", "memorization",
             "counterpoint"],
    "violin": ["technique", "repertoire", "bowing", "vibrato", "intonation",
               "phrasing", "interpretation", "spiccato", "ornamentation", "etudes"],
}

SUMMARY_TEMPLATES = [
    "A {level}-level course on {focus}. {weeks} weeks of structured lessons, "
    "exercises, and curated repertoire — with downloadable PDFs.",
    "Build a deep working understanding of {focus}. Designed for the "
    "{level} student, with weekly practice plans and graded exercises.",
    "From first principles to performance — {focus}, taught at a {level} "
    "level over {weeks} progressive lessons.",
    "{level_capitalized} students will work through {focus} with annotated "
    "scores, slow-tempo demonstrations, and instructor feedback prompts.",
    "Strengthen your {focus} with this {level} course. Includes practice "
    "logs, listening guides, and recital-prep checklists.",
]

THUMB_PATTERNS = {
    "guitar": "https://images.ilearnit.app/guitar/{n:03}.jpg",
    "piano":  "https://images.ilearnit.app/piano/{n:03}.jpg",
    "violin": "https://images.ilearnit.app/violin/{n:03}.jpg",
}


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def generate_course(idx: int, instrument: str, instructor: dict) -> tuple[str, dict]:
    """Returns (doc_id, fields) for a single course."""
    course_id = f"course_{idx:03}"

    # Topic + level → title
    topic = random.choice(TITLE_BANK[instrument])
    level = random.choices(
        ["beginner", "intermediate", "advanced"],
        weights=[40, 35, 25],
        k=1,
    )[0]
    title = f"{topic} {LEVEL_SUFFIX[level]}"

    # Tags
    tag_pool = LEVEL_TAG_BANK[instrument]
    tags = random.sample(tag_pool, k=random.randint(3, 5))
    tags.append(level)

    # Summary
    summary_focus_pool = [t for t in tags if t not in {level}][:2]
    summary_focus = " and ".join(summary_focus_pool) if summary_focus_pool else topic.lower()
    weeks = random.randint(4, 12)
    summary = random.choice(SUMMARY_TEMPLATES).format(
        level=level,
        level_capitalized=level.capitalize(),
        focus=summary_focus,
        weeks=weeks,
    )

    # Numbers
    lesson_count = random.randint(8, 36)
    duration_minutes = lesson_count * random.randint(10, 22)
    rating = round(random.uniform(3.8, 5.0), 2)
    enrollment = random.randint(120, 6800)
    is_featured = random.random() < 0.12  # ~12% featured

    # Date — anywhere in the last 24 months
    days_ago = random.randint(1, 720)
    published_at = datetime.now(timezone.utc) - timedelta(
        days=days_ago,
        hours=random.randint(0, 23),
        minutes=random.randint(0, 59),
    )

    fields = {
        "id": course_id,
        "title": title,
        "summary": summary,
        "thumbnailUrl": THUMB_PATTERNS[instrument].format(n=idx),
        "category": instrument,
        "level": level,
        "instructorId": instructor["id"],
        "instructorName": instructor["name"],
        "lessonCount": lesson_count,
        "enrollmentCount": enrollment,
        "rating": rating,
        "durationMinutes": duration_minutes,
        "isFeatured": is_featured,
        "tags": tags,
        # ISO string — converted to Firestore Timestamp by the seed script.
        "publishedAt": iso(published_at),
    }
    return course_id, fields


def generate_courses() -> dict[str, dict]:
    counts = {"guitar": 35, "piano": 35, "violin": 30}
    courses: dict[str, dict] = {}
    idx = 1

    for instrument, total in counts.items():
        instructors = BY_INSTRUMENT[instrument]
        # Spread courses across instructors round-robin then jitter a few.
        for i in range(total):
            instructor = instructors[i % len(instructors)]
            doc_id, fields = generate_course(idx, instrument, instructor)
            courses[doc_id] = fields
            idx += 1
    return courses


def generate_instructors() -> dict[str, dict]:
    out: dict[str, dict] = {}
    for ins in INSTRUCTORS:
        out[ins["id"]] = {
            "id": ins["id"],
            "name": ins["name"],
            "primaryInstrument": ins["instrument"],
            "bio": ins["bio"],
            "specialties": ins["specialties"],
            "yearsExperience": ins["yearsExperience"],
            "country": ins["country"],
            "photoUrl": f"https://images.ilearnit.app/instructors/{ins['id']}.jpg",
            "rating": round(random.uniform(4.4, 5.0), 2),
            "studentCount": random.randint(800, 18000),
            "joinedAt": iso(
                datetime(2022, 1, 1, tzinfo=timezone.utc)
                + timedelta(days=random.randint(0, 900)),
            ),
        }
    return out


def main() -> None:
    instructors = generate_instructors()
    courses = generate_courses()

    # Decorate courses with featured-course IDs back on each instructor.
    for ins_id, ins in instructors.items():
        ins["featuredCourseIds"] = [
            cid for cid, c in courses.items()
            if c["instructorId"] == ins_id and c["isFeatured"]
        ]

    (OUT_DIR / "instructors.json").write_text(
        json.dumps(instructors, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (OUT_DIR / "courses.json").write_text(
        json.dumps(courses, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    # Print a quick distribution summary.
    by_cat: dict[str, int] = {}
    by_level: dict[str, int] = {}
    featured = 0
    for c in courses.values():
        by_cat[c["category"]] = by_cat.get(c["category"], 0) + 1
        by_level[c["level"]] = by_level.get(c["level"], 0) + 1
        featured += 1 if c["isFeatured"] else 0

    print(f"Wrote {len(instructors)} instructors and {len(courses)} courses.")
    print(f"  by category : {by_cat}")
    print(f"  by level    : {by_level}")
    print(f"  featured    : {featured}")
    print(f"Output: {OUT_DIR}")


if __name__ == "__main__":
    main()
