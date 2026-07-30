---
name: sync-submissions
description: Clone and keep up to date the Libra Bank Academy project repositories from the Google Form export, and maintain _submissions/submissions.md — the mapping of who has a codebase, their branches with last student-commit dates, student-authored lines of code, and hygiene warnings (committed venv, node_modules, .env, large files). Use when the user supplies or updates the form export, or asks to sync, refresh, clone or re-pull the student repos, or to rebuild the submissions mapping.
---

# Syncing the submission repositories

This skill owns the mirror: every student repository cloned or freshened under
`_submissions/repos/`, and one file — `_submissions/submissions.md` — that answers at a
glance *who has actually done work*. Evaluation is a separate skill
(`evaluate-projects`) that consumes what this one maintains.

Two deterministic steps, in order:

```powershell
# 0 · normalize the form export (XLSX -> CSV + per-student answer files)
python .claude/skills/sync-submissions/scripts/export-to-csv.py `
    "_submissions/<form export>.xlsx" _submissions/extra-participants.csv

# 1 · clone / update everything and rebuild the mapping
.claude/skills/sync-submissions/scripts/sync-repos.ps1 -Export _submissions/responses.csv -OutDir _submissions
```

The converter (standard library only — an xlsx is a zip of XML) does three things the
raw export cannot: it strips GitHub `/tree/<branch>` page URLs to clonable repository
URLs **while recording the branch** — students paste the page they are looking at, and
that branch is where their work lives; it writes each student's project description to
`_submissions/review/answers/<slug>.md`, so the evaluation can hand every agent only its own
student's answers; and it appends participants who submitted outside the form
(`extra-participants.csv`), marking a missing description with the ANSWERS UNAVAILABLE
marker so it is scored 0 on that line without penalty anywhere else.

The sync then **checks out the submitted branch** in each clone — analysing the default
branch when the student named another would score the wrong code — and reports the
evaluated branch per student in the mapping.

Re-running either step is always safe: existing clones are fetched and fast-forwarded,
new rows are cloned, and both the CSV and the mapping are rebuilt from scratch.

## What the script does

1. **Parse the export.** Columns found by header (name / email / repository URL /
   submitted branch), never by position. Identity is the email when present, the name
   when not — participants added outside the form have no address. Duplicates: latest
   timestamp wins, noted. Malformed URLs (Drive links, zips, profile pages) are
   classified, not guessed at.
2. **Clone or update.** New repositories are cloned in full — all branches, full
   history, because the analysis needs authorship over time. Existing ones get
   `fetch --all --prune` plus a fast-forward of the default branch. Credential prompts
   are disabled, so a private repository fails in seconds with a classified reason.
3. **Analyse each clone** — the instructor's commits (author `Lucian Gruia`) are the
   inherited baseline; everything else is the student's:
   - **Branches**, with per branch: total commits, student commits, date of the last
     student commit. A branch whose last student commit is days newer than the default
     branch's is flagged — the work may be sitting unmerged.
   - **Student LoC**: lines added in non-merge student commits on the default branch,
     excluding vendored and generated paths (`node_modules/`, `.venv/`, `venv/`,
     `dist/`, `__pycache__/`, lockfiles, minified bundles). An approximation, stated as
     one — it ranks effort, it does not measure quality.
   - **Warnings**, each with the evidence: `venv/`/`node_modules/`/`__pycache__`/`dist/`
     tracked in git; a tracked `.env`; files over 5 MB; no commits at all; nothing
     student-authored anywhere.
4. **Write `_submissions/submissions.md`** — a summary table (student · repo · default
   branch · branches · student commits · last activity · student LoC · warning count)
   followed by a per-student detail block, and the classified failure list with what
   each student must do. The failure list goes out to students **before** evaluation
   starts.

## Reading the mapping honestly

- **Student LoC is a screening number.** 40 lines can be a razor-sharp golden-set
  runner; 4 000 can be a pasted template. Use it to spot the empty and the enormous,
  never as a score.
- **A tracked `.env` is triaged immediately**, before anything else: open it. If it
  holds live-looking values, that student is contacted the same day to rotate — that is
  an incident, not a rubric line. If it is the redacted template, it is only hygiene.
- **"No student commits" gets a second look** before it is believed: students sometimes
  commit under a different author name than the form name. Check
  `git log --format='%an <%ae>'` for identities that are neither the instructor nor a
  bot before concluding the fork is untouched.

## Boundaries

- Read-only towards the repositories: fetch and fast-forward only — never commit,
  rebase, or resolve anything inside `_submissions/`.
- `_submissions/` is git-ignored; nothing under it is ever staged into the course repo.
- Secret **values** never appear in the mapping file — only the fact and the path.
