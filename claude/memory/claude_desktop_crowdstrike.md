---
name: Claude desktop blocked by CrowdStrike Falcon
description: Claude desktop on this work Mac is blocked/throttled by CrowdStrike Falcon EDR. App freezes or fails to launch. Needs IT allowlist, not a Claude reinstall.
type: project
originSessionId: e8d9d96c-2ad6-4cf5-a173-a4b97e206eb3
---
As of 2026-05-07, Claude desktop on this machine cannot run reliably because Gusto's CrowdStrike Falcon endpoint security agent (`com.crowdstrike.falcon.Agent`) spikes to 100%+ CPU when Claude.app launches, and either freezes the UI or prevents Electron from starting. Observed signature:
- Launch attempt → CrowdStrike CPU jumps from ~10% to 100%+
- Claude desktop process either never appears or hangs the GUI
- main.log at `~/Library/Logs/Claude/main.log` shows no entries from the failed attempt
- Spotlight/mdworker is NOT the cause — exclusions are in place and mdworker stays under 20

**Why:** CrowdStrike scans the app's many sub-binaries (1715 sealed resources) on each launch and starves Claude of CPU/IO. This is enterprise EDR behavior, not a Claude bug. No Anthropic update will fix it.

**How to apply:** If user reports Claude desktop frozen, crashing, or won't launch — do NOT suggest reinstalling. The reinstall plan from 2026-05-07 was based on a stale empty-directory premise that was already invalid. Instead:
1. Confirm CrowdStrike is the culprit by checking `ps aux | grep falcon.Agent` for high CPU during launch
2. Direct user to file an IT ticket asking for `/Applications/Claude.app` (TeamIdentifier `Q6L2SF6YDW`, bundle ID `com.anthropic.claudefordesktop`) to be allowlisted in CrowdStrike
3. Existing Spotlight exclusions (5 paths including `/Applications/Claude.app`) and `.metadata_never_index` markers are correct and should NOT be removed
4. `~/Library/Application Support/Claude/` holds login/settings — preserve it; user can resume sessions once CrowdStrike is sorted
