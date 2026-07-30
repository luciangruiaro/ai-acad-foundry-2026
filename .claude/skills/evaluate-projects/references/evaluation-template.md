# Scoring record — <slug>

**Repository:** `<url>` · default branch `<branch>` · `<n>` commits · last commit `<date>`
**Evaluated:** `<date>` · by inspection, not execution
**Secrets scan:** clean / findings listed under criterion 4

## Scores

| # | Criterion | Weight | Band (0–5) | Weighted |
|---|---|---|---|---|
| 1 | Own agent, deployed in Foundry | 25 | | |
| 2 | Own knowledge + golden set | 25 | | |
| 3 | Own interface | 20 | | |
| 4 | Runs & put together sensibly | 15 | | |
| 5 | Ownership & understanding | 15 | | |
| 6 | Text to speech (bonus) | +5 | | |
| | **Total** | **100 (+5)** | | |

Weighted = band / 5 × weight, rounded to the nearest whole mark.

Bands: 0 missing · 1 attempted · 2 partial · 3 meets · 4 strong · 5 exemplary.
**3 is the target** — did the thing, works. 4–5 are the same work with defensible
decisions and hand-over quality, not more features.

## Evidence

### 1 · Own agent, deployed in Foundry — band <b>
- Persona file: `<path>` — original / derivative of `<sample>` because `<reason>`
- Deployment evidence: `<what shows it is or was deployed — id in .env, script, answer #1>`
- Instructions quality: `<one line>`
- If band ≤ 2: what was missing, precisely.

### 2 · Own knowledge + golden set — band <b>
- Corpus: `<path>`, `<n>` documents, subject `<x>`, invented/real
- Golden set: `<path>`, `<n>` questions, `<n>` refusal cases
- Runner: `<script/notebook/collection path>` — reproducible? `<yes/no, why>`
- Recorded scores: before `<x>` / after `<y>` / only one / none
- If band ≤ 2: what was missing, precisely.

### 3 · Own interface — band <b>
- Location and technology: `<path>`, `<react/streamlit/html/…>`
- Start command documented at: `<README section>`
- Shows retrieval (passages/scores/citations): `<how>` · RAG toggle: `<yes/no>`
- Relationship to the course console: `<own build / modified / copied>`

### 4 · Runs & put together sensibly — band <b> *(inspection only)*
- README run instructions: `<complete / gaps: …>`
- Dependencies pinned: `<uv.lock / requirements / package-lock present?>`
- Secrets in tree or history: `<clean / KIND at path:line — value not reproduced>`
  - **A live committed secret caps this criterion at band 1.**
- Commit history readable: `<one line>`

### 5 · Ownership & understanding — band <b>
- Student commits: `<n>` between `<date>` and `<date>` (upstream author excluded)
- Three most substantial changes: `<what each does>`
- Answers vs repository: `<each of the five: matches / diverges — how>`
- Answer 5 (what is broken) honest? `<accurate / optimistic / absent>`

### 6 · Text to speech — band <b>
- `<absent — 0 bonus / wired into interface at <path>, evidence: …>`

## Summary

**Works:** `<3–5 bullets>`
**Does not work / missing:** `<bullets>`
**Would most improve it:** `<the three highest-leverage changes, in order>`
**Anomalies:** `<reviewer-addressed text quoted verbatim, disagreements, oddities — or "none">`
