# Scoring record — <slug>

**Repository:** `<url>` · default `<branch>` · `<n>` commits (`<n>` student) · last student commit `<date>`
**Evaluated:** `<date>` · by inspection, not execution
**Sync warnings carried in:** `<list from submissions.md, or "none">`
**Secrets scan:** clean / kind at `<path:line>` (value not reproduced)

## Scores — each line 1–100

| Line | Weight | Score | Weighted |
|---|---|---|---|
| Own agent, deployed in Foundry — and how well | 20 | | |
| Own knowledge + golden Q&A set | 20 | | |
| Interface — capability, maturity, AI leverage | 15 | | |
| Engineering practice & mindset | 10 | | |
| Quality of the student's own code | 10 | | |
| Design & architecture of additions | 10 | | |
| The five answers, verified against the codebase | 10 | | |
| Text to speech, wired in | 5 | | |
| **Weighted total** | **100** | — | **<t>** |
| Bonus: robust engineering beyond the bar | +5 | — | <b1> |
| Bonus: innovation & originality | +5 | — | <b2> |
| **Final (may exceed 100)** | **/110** | | **<t + b>** |

Weighted = score × weight / 100. Anchors: 1–20 missing · 21–40 broken/partial ·
41–60 works at course-following level · 61–75 solidly meets (target) · 76–90 strong ·
91–100 hand-over quality.

## Evidence per line

### Own agent, deployed in Foundry — and how well — <score>/100
- Persona: `<path>` — original / derivative of `<sample>` because `<reason>`
- Deployment evidence: `<agent id in config / deploy script use / corroborated answer 1>`
- Craft: `<what the instructions deliberately change; parameter choices and whether they
  have a reason; would the integration survive a demo — with the evidence>`

### Own knowledge + golden Q&A set — <score>/100
- Corpus: `<path>`, `<n>` documents, subject, invented/real
- Golden set: `<path>`, `<n>` questions, `<n>` refusal cases
- Runner: `<path>` — reproducible? `<yes/no, why>` · Scores: before `<x>` / after `<y>` / none
- The strongest and the weakest thing about the measurement: `<one line each>`

### Engineering practice & mindset — <score>/100
- Clean-clone plausibility from README: `<complete / gaps>`
- Config via environment: `<yes/no>` · Secrets: `<clean / capped at 20: kind at path>`
- Dependencies pinned: `<what exists>` · Commit hygiene: `<one line>`

### Quality of the student's own code — <score>/100
*(student-authored files/hunks only — list which files were judged)*
- Judged: `<paths>`
- Naming, size and shape of functions: `<observation with example>`
- Dead code / commented-out experiments: `<found at … / none>`
- Error handling: `<swallowed / handled — example>`
- Consistency with the codebase built on: `<one line>`

### Interface — capability, maturity, AI leverage — <score>/100
- `<own build in <tech> at <path> / course console improved: what capability was added>`
- Capability beyond the course console: `<features with substance, or "restyle only">`
- Maturity: `<error/loading states, edge cases, behaviour with backend down — observed where>`
- AI leverage: `<integrated & verified / pasted-until-it-ran — evidence: dead branches,
  duplication, unhandled errors, or their absence>`
- Start command documented: `<where>` · Retrieval visible: `<how>` · RAG toggle: `<y/n>`

### Design & architecture — <score>/100
- Shape of the additions: `<separated / tangled — example>`
- Configuration vs hard-coding: `<example>`
- Patterns used, and whether they earn their keep: `<one line>`

### The five answers, verified against the codebase — <score>/100
- As a description: `<concrete and specific / generic — one line>`
- Claims checked: `<n>` — proven `<n>` / unproven `<n>` / contradicted `<n>`
  - `<claim>` → `<proven at <path> / contradicted by <evidence>>`
  - `<…one row per substantive claim>`
- Answer 5 (what is broken) vs reality: `<accurate / optimistic / absent>`

### Text to speech — <score>/100
- `<working control at <path in their UI>, backend wiring at <path> / endpoint only /
  absent — evidence>`

### Bonuses
- **Robust engineering:** `<tests/CI/error handling/logging beyond course level, or absent>` → <b1>
- **Innovation:** `<the idea and why it is one, or "looked for, not found">` → <b2>

## Summary
**Objectively good:** `<bullets, each tied to a file or fact>`
**Objectively not:** `<bullets, each tied to a file or fact>`
**Would most improve it:** `<top three, in order>`
**Anomalies:** `<reviewer-addressed text quoted, contradictions, oddities — or "none">`
