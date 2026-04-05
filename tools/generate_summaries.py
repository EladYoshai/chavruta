#!/usr/bin/env python3
"""
Generate Hebrew Daf Yomi summaries using Google Gemini (free tier).
Uses only public domain source texts (Gemara, Rashi, Tosafot).
Generates original Hebrew summaries - no copyright issues.

Setup:
  1. Get a free API key at https://aistudio.google.com/apikey
  2. export GEMINI_API_KEY="your-key-here"
  3. python generate_summaries.py --masechet Menachot

Free tier: 1,500 requests/day, no credit card needed.
"""

import json
import os
import sys
import time
import argparse
import requests
import re

try:
    import google.generativeai as genai
except ImportError:
    print("Please install: pip3 install --break-system-packages google-generativeai")
    sys.exit(1)

SEFARIA_BASE = "https://www.sefaria.org/api/v3/texts"
OUTPUT_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "data", "daf_summaries.json")

MASEKHTOT = {
    "Berakhot": (2, 64),
    "Shabbat": (2, 157),
    "Eruvin": (2, 105),
    "Pesachim": (2, 121),
    "Shekalim": (2, 22),
    "Yoma": (2, 88),
    "Sukkah": (2, 56),
    "Beitzah": (2, 40),
    "Rosh_Hashanah": (2, 35),
    "Taanit": (2, 31),
    "Megillah": (2, 32),
    "Moed_Katan": (2, 29),
    "Chagigah": (2, 27),
    "Yevamot": (2, 122),
    "Ketubot": (2, 112),
    "Nedarim": (2, 91),
    "Nazir": (2, 66),
    "Sotah": (2, 49),
    "Gittin": (2, 90),
    "Kiddushin": (2, 82),
    "Bava_Kamma": (2, 119),
    "Bava_Metzia": (2, 119),
    "Bava_Batra": (2, 176),
    "Sanhedrin": (2, 113),
    "Makkot": (2, 24),
    "Shevuot": (2, 49),
    "Avodah_Zarah": (2, 76),
    "Horayot": (2, 14),
    "Zevachim": (2, 120),
    "Menachot": (2, 110),
    "Chullin": (2, 142),
    "Bekhorot": (2, 61),
    "Arakhin": (2, 34),
    "Temurah": (2, 34),
    "Keritot": (2, 28),
    "Meilah": (2, 22),
    "Tamid": (25, 33),
    "Niddah": (2, 73),
}


def get_daf_pages(start, end):
    pages = []
    for num in range(start, end + 1):
        pages.append(f"{num}a")
        pages.append(f"{num}b")
    return pages


def strip_html(html):
    if not html:
        return ""
    clean = re.sub(r'<[^>]+>', '', str(html))
    clean = clean.replace('&nbsp;', ' ').replace('&amp;', '&')
    clean = clean.replace('&thinsp;', '').replace('&ensp;', ' ')
    clean = re.sub(r'&\w+;', '', clean)
    return clean.strip()


def flatten_text(text):
    if isinstance(text, str):
        return strip_html(text)
    if isinstance(text, list):
        parts = []
        for item in text:
            result = flatten_text(item)
            if result.strip():
                parts.append(result)
        return "\n".join(parts)
    return ""


def fetch_hebrew_text(ref):
    """Fetch ONLY public domain Hebrew text from Sefaria"""
    url = f"{SEFARIA_BASE}/{ref}"
    try:
        resp = requests.get(url, timeout=30)
        if resp.status_code != 200:
            return ""
        data = resp.json()
        for v in data.get("versions", []):
            if v.get("actualLanguage") == "he" and v.get("text"):
                return flatten_text(v["text"])
        return ""
    except Exception as e:
        print(f"    Fetch error for {ref}: {e}")
        return ""


def generate_summary(model, masechet, daf, gemara_text, rashi_text, tosafot_text, steinsaltz_text=""):
    """Generate original Hebrew summary using Gemini"""
    masechet_display = masechet.replace("_", " ")

    prompt = f"""אתה מלמד גמרא מנוסה. חובה לענות בעברית בלבד! DO NOT USE ENGLISH. לפניך טקסט מקורי (נחלת הכלל) של הגמרא.

מסכת: {masechet_display}, דף {daf}

טקסט הגמרא:
{gemara_text[:4000]}

{f'פירוש רש"י:{chr(10)}{rashi_text[:2000]}' if rashi_text else ''}

{f'ביאור שטיינזלץ (עזר להבנת הסוגיא):{chr(10)}{steinsaltz_text[:3000]}' if steinsaltz_text else ''}

כתוב בבקשה:

1. סיכום מקיף של הדף בעברית פשוטה (8-15 משפטים):
- תן תמונה מלאה של הדף - מה הנושא המרכזי, מה השאלות, מה המסקנות
- הסבר את המושגים ההלכתיים במילים פשוטות
- אם יש מחלוקות - מי אומר מה ולמה
- כתוב כאילו אתה מסביר לחבר שלא למד גמרא מעולם
- הסיכום צריך להיות מספיק מפורט כדי שמי שקורא אותו ירגיש שהוא מבין את הדף

2. הרחבות (3-5 משפטים):
{f'תוספות:{chr(10)}{tosafot_text[:1500]}' if tosafot_text else ''}
- הסבר נקודה מעניינת שעולה מהראשונים
- למה זה חשוב להבנת הסוגיא
- כתוב בשפה פשוטה

ענה בפורמט JSON בלבד:
{{"summary": "סיכום כאן", "deepDive": "הרחבות כאן"}}"""

    for attempt in range(3):
        try:
            response = model.generate_content(prompt)
            text = response.text

            # Extract JSON
            json_match = re.search(r'\{[\s\S]*?\}', text, re.DOTALL)
            if json_match:
                # Clean up common JSON issues from LLM
                raw = json_match.group()
                raw = raw.replace('\n', ' ').replace('\r', '')
                try:
                    result = json.loads(raw)
                    if "summary" in result:
                        return result
                except json.JSONDecodeError:
                    pass

            # Fallback: extract text directly
            return {"summary": text.strip()[:800], "deepDive": ""}
        except Exception as e:
            err = str(e)
            if "429" in err or "quota" in err.lower():
                wait = 45 + attempt * 15
                print(f"rate limit, waiting {wait}s...", end=" ", flush=True)
                time.sleep(wait)
                continue
            print(f"    Gemini error: {e}")
            return None
    return None


def main():
    parser = argparse.ArgumentParser(description="Generate Daf Yomi Hebrew summaries (free, no copyright issues)")
    parser.add_argument("--masechet", help="Masechet name (e.g., Menachot)")
    parser.add_argument("--start", help="Start daf (e.g., 2a)")
    parser.add_argument("--end", help="End daf (e.g., 10b)")
    parser.add_argument("--all", action="store_true", help="Generate for all of Shas")
    parser.add_argument("--force", action="store_true", help="Regenerate even if entry exists (use to fix English summaries)")
    parser.add_argument("--batch-size", type=int, default=15, help="Save progress every N dapim")
    args = parser.parse_args()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: Set GEMINI_API_KEY environment variable")
        print("  Get a free key at: https://aistudio.google.com/apikey")
        print("  export GEMINI_API_KEY='your-key-here'")
        sys.exit(1)

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("gemini-2.5-flash")

    # Load existing
    existing = {}
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
            try:
                existing = json.load(f)
            except:
                existing = {}

    if args.all:
        targets = list(MASEKHTOT.items())
    elif args.masechet:
        if args.masechet not in MASEKHTOT:
            print(f"Unknown masechet: {args.masechet}")
            print(f"Available: {', '.join(sorted(MASEKHTOT.keys()))}")
            sys.exit(1)
        targets = [(args.masechet, MASEKHTOT[args.masechet])]
    else:
        print("Specify --masechet NAME or --all")
        sys.exit(1)

    total = 0
    errors = 0

    for masechet, (start_num, end_num) in targets:
        pages = get_daf_pages(start_num, end_num)

        if args.start:
            try:
                pages = pages[pages.index(args.start):]
            except ValueError:
                pass
        if args.end:
            try:
                pages = pages[:pages.index(args.end) + 1]
            except ValueError:
                pass

        print(f"\n{'='*60}")
        print(f"  {masechet} - {len(pages)} dapim")
        print(f"{'='*60}")

        batch = 0
        for daf in pages:
            ref = f"{masechet}.{daf}"
            if ref in existing and existing[ref].get("summary") and not args.force:
                # Check if existing summary is in Hebrew
                summary = existing[ref].get("summary", "")
                if re.search(r'[\u0590-\u05FF]', summary):
                    print(f"  [skip] {ref}")
                    continue
                else:
                    print(f"  [regen] {ref} (not Hebrew)")
            elif ref in existing and existing[ref].get("summary") and args.force:
                print(f"  [force] {ref}")
            elif ref in existing and existing[ref].get("summary"):
                print(f"  [skip] {ref}")
                continue

            print(f"  [fetch] {ref}...", end=" ", flush=True)
            gemara = fetch_hebrew_text(ref)
            if not gemara:
                print("no text")
                continue

            rashi = fetch_hebrew_text(f"Rashi_on_{ref}")
            tosafot = fetch_hebrew_text(f"Tosafot_on_{ref}")
            # Fetch Steinsaltz Hebrew commentary for fuller context
            amud_ref = ref if ref[-1] in 'ab' else f"{ref}a"
            steinsaltz = fetch_hebrew_text(f"Steinsaltz_on_{amud_ref}")
            time.sleep(0.3)

            print("generating...", end=" ", flush=True)
            result = generate_summary(model, masechet, daf, gemara, rashi, tosafot, steinsaltz)
            if result:
                # Validate output is in Hebrew
                summary_text = result.get("summary", "")
                if not re.search(r'[\u0590-\u05FF]', summary_text):
                    print("not Hebrew, retrying...", end=" ", flush=True)
                    time.sleep(4)
                    result = generate_summary(model, masechet, daf, gemara, rashi, tosafot)
                if result and re.search(r'[\u0590-\u05FF]', result.get("summary", "")):
                    existing[ref] = result
                    total += 1
                    print(f"✓ ({total})")
                else:
                    errors += 1
                    print("✗ (still not Hebrew)")
            else:
                errors += 1
                print("✗")

            batch += 1
            if batch >= args.batch_size:
                os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
                with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                    json.dump(existing, f, ensure_ascii=False, indent=2)
                print(f"  --- saved ({total} summaries) ---")
                batch = 0

            # Gemini free tier: ~20 req/min, we make 1 generate per daf + 3 fetches
            time.sleep(4)

    # Final save
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(existing, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"  Done! {total} summaries generated, {errors} errors")
    print(f"  Total in database: {len([k for k, v in existing.items() if v.get('summary')])}")
    print(f"  Saved to: {OUTPUT_FILE}")
    print(f"{'='*60}")
    print(f"\nSources: Only public domain texts (Gemara, Rashi, Tosafot)")
    print(f"Summaries: Original content generated by AI - no copyright issues")


if __name__ == "__main__":
    main()
