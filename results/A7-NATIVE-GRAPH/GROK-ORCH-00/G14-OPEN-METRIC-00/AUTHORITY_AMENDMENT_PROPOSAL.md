# AUTHORITY AMENDMENT PROPOSAL — M10 only

**Not applied.** Checklist text is unchanged. This file is a human decision, not a tick.

## Why this exists

`14_FINAL_ACCEPTANCE_CHECKLIST.md` Memory box:

```text
- [ ] 800k scale reports bytes/query and candidates/query.
```

G14-OPEN-METRIC-00 **must not** close that box by writing “Native V1 exam is 20-fact, so N/A.”
That would be a silent scope change after the run.

HS-13 still says: an 800k-episode system cannot claim sparse retrieval without recording
candidates/query and DDR bytes/query. M9 on this SoC already PASSes “no hidden 800k full scan”
because the C9 exam uses K=8 + 32 BRAM slots — that is **not** an 800k scale report.

## Two legal options (human picks one)

### Option A — KEEP_OPEN (default until amended)

Leave M10 **OPEN_METRIC**. Native V1 does not have a measured 800k-episode
bytes/query or candidates/query. Do not claim 800k runtime. Do not N/A the box.

Next work (later, not this bit): a scale ladder experiment that reports both
numbers at 800k, or an explicit decision that 800k is out of Native V1.

### Option B — AMEND_CHECKLIST (only with director sign-off)

Replace M10 wording with something that matches the **actual final design**,
for example:

```text
- [ ] Native V1 reports candidates/query and DDR bytes/query at the
      shipped working-set scale (20-fact / 32 BRAM slots / K=8).
- [ ] 800k-episode scale is a post-V1 ladder. It is not a Native V1
      runtime claim. HS-13 still forbids advertising 800k sparse
      retrieval until that ladder reports bytes/query and candidates/query.
```

Then re-tick M10 against the **new** wording with its own artifact.
Do not rewrite history of this gate.

## This gate’s action

```text
M10_BOX_TICK              = OPEN
M10_SILENT_NA             = REFUSED
CHECKLIST_TEXT_EDITED     = NO
HUMAN_DECISION_REQUIRED   = YES
```
