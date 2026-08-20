#!/bin/bash
# Stop hook: inspects the turn's final assistant message for checklist violations and
# records them for inject-contract.sh to feed back on the next turn. Never blocks.

# stdin holds the hook payload; the python source arrives by heredoc, so hand the
# payload over through the environment rather than letting the heredoc shadow it.
HOOK_INPUT=$(cat)
export HOOK_INPUT

VIOLATIONS="$HOME/.claude/style-violations.txt" python3 <<'PY'
import json, os, re

try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    raise SystemExit(0)


def last_assistant_text(payload):
    """The Stop payload carries transcript_path, not the message itself.

    Earlier revisions read a `last_assistant_message` key that the payload does not
    define, so every run exited silently or reported against whatever happened to be
    there. Read the transcript instead and fall back to the old key only if some future
    payload starts supplying it.
    """
    direct = payload.get("last_assistant_message")
    if isinstance(direct, str) and direct.strip():
        return direct

    path = payload.get("transcript_path")
    if not path or not os.path.exists(path):
        return ""

    # JSONL, one event per line, oldest first. Walk backwards to the newest assistant
    # turn and concatenate its text blocks; tool_use blocks carry no prose.
    try:
        with open(path, errors="replace") as fh:
            lines = fh.readlines()
    except OSError:
        return ""

    for line in reversed(lines):
        line = line.strip()
        if not line:
            continue
        try:
            evt = json.loads(line)
        except ValueError:
            continue
        msg = evt.get("message")
        if not isinstance(msg, dict) or msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts = [
                b.get("text", "")
                for b in content
                if isinstance(b, dict) and b.get("type") == "text"
            ]
            text = "\n".join(p for p in parts if p.strip())
            if text.strip():
                return text
    return ""


msg = last_assistant_text(data)
if not msg.strip():
    raise SystemExit(0)

# Fenced code blocks are quoted material, not prose — exclude them from the checks.
# Prompts and command blocks are the main reason a long response can be legitimate.
prose = re.sub(r"```.*?```", "", msg, flags=re.DOTALL)
lines = [ln.strip() for ln in prose.splitlines() if ln.strip()]
if not lines:
    raise SystemExit(0)

OPENERS = ("great", "certainly", "sure", "let me", "i'll ", "i will ",
           "based on my", "you're absolutely right", "you are absolutely right")
POSTAMBLE = ("let me know if", "feel free to", "hope this helps",
             "if you'd like me to", "if you want me to")
# Keep these non-overlapping — "worth noting" rather than both "it's worth noting" and
# "worth noting that", which would report one phrase twice.
FILLER = ("worth noting", "essentially", "basically", "due to the fact that")

# Rule 2 has no natural unit, so use prose words excluding code. These are ceilings for
# a *typical* turn, not hard limits: a genuine multi-step procedure or a set of findings
# can exceed them, which is why the message says "justify" rather than "cut".
WORD_SOFT_CAP = 220
WORD_HARD_CAP = 400

violations = []

first = lines[0].lower()
if any(first.startswith(o) for o in OPENERS):
    violations.append(
        f'- Rule 1: opened with filler ("{lines[0][:60]}"). Lead with the answer.'
    )

# Scan the tail rather than whole lines: a closer is as often the last sentence of a
# paragraph as it is a paragraph of its own.
tail = "\n".join(lines[-2:])[-240:].lower()
closer = next((p for p in POSTAMBLE if p in tail), None)
if closer:
    violations.append(
        f'- Rule 3: closed with postamble ("{closer}..."). Stop at the substance.'
    )

words = len(prose.split())
if words > WORD_HARD_CAP:
    violations.append(
        f"- Rule 2: {words} words of prose (excluding code). Well past the ~{WORD_SOFT_CAP} "
        "a normal turn needs — cut to the decision and its reason."
    )
elif words > WORD_SOFT_CAP:
    violations.append(
        f"- Rule 2: {words} words of prose (excluding code), over the ~{WORD_SOFT_CAP} "
        "guide. Justify the length or cut it."
    )

# Rule 4 says one per section, so anything past a small handful is drift. The old
# threshold of 6 let a heavily-bolded response through untouched.
bold = len(re.findall(r"\*\*[^*\n]+\*\*", prose))
if bold > 2:
    violations.append(
        f"- Rule 4: {bold} bolded spans. Default to none; one per section at most."
    )

# Rule 5: structure has to earn itself. Bullets are the usual offender — a list of three
# short items is a sentence. Tables are exempt; they are called out as legitimate.
bullets = [ln for ln in lines if re.match(r"^([-*+]|\d+\.)\s", ln)]
if bullets and len(bullets) <= 3 and not any(ln.startswith("|") for ln in lines):
    violations.append(
        f"- Rule 5: {len(bullets)} bullets. Three or fewer items is prose, not a list."
    )

headers = [ln for ln in lines if re.match(r"^#{1,6}\s", ln)]
if headers and words < 150:
    violations.append(
        f"- Rule 5: {len(headers)} header(s) on a {words}-word answer. Headers need a "
        "response long enough to navigate."
    )

found = sorted({f for f in FILLER if f in prose.lower()})
# Belt and braces for future additions: if one match contains another, keep the longer.
found = [f for f in found if not any(f != g and f in g for g in found)]
if found:
    violations.append("- Filler phrases, cut them — " + ", ".join(f'"{f}"' for f in found))

# Truncate every time, including the clean case: the file describes the most recent
# response only, so a clean turn is what clears the previous turn's violations.
with open(os.environ["VIOLATIONS"], "w") as fh:
    if violations:
        fh.write("\n".join(violations) + "\n")
PY

exit 0
