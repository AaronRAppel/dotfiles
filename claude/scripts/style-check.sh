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

msg = data.get("last_assistant_message") or ""
if not msg.strip():
    raise SystemExit(0)

# Fenced code blocks are quoted material, not prose — exclude them from the checks.
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

bold = len(re.findall(r"\*\*[^*\n]+\*\*", prose))
if bold > 6:
    violations.append(
        f"- Rule 4: {bold} bolded spans. Default to none; one per section at most."
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
