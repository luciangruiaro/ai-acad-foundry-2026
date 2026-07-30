# Feedback template — participant

Second person, technical, specific. The core is the two bullet lists — objectively
good, objectively not — every bullet tied to a file or a fact, never to an impression.
Criticism always arrives with its fix. Read next to their own code, so vagueness is
useless. One page.

---

## Your project — feedback

Hi `<first name>`,

Thank you for the submission. Your project was reviewed against the published rubric,
working from your repository and your five answers.

**Overall: `<weighted total>` / 100`<, plus <b> bonus>`.**

### Objectively good

`<3–6 bullets. Each one names the thing and its location or evidence, e.g.:
- Your golden set (goldens/questions.json) includes three questions the corpus cannot
  answer, and your runner records the refusals — that is testing, not demonstrating.
- The persona (app/agents/personas/<x>.json) changes behaviour measurably: the same
  question answers differently and the style rules explain exactly why.
- Before/after retrieval scores (6/12 → 10/12) with the change that caused it named in
  your answer 2 — the single most course-relevant thing in the submission.>`

### Objectively not

`<2–5 bullets. Each: the fact → where → the fix. Facts, not judgements, e.g.:
- The README's run command fails on a clean clone: it references a file that is not
  committed (<path>). Fix: commit it or correct the command.
- <path> swallows every exception with a bare except — a wrong Azure key currently
  looks identical to an empty corpus. Fix: catch the specific error and surface it.
- Answer 2 reports a golden-set score, but no runner exists in the repository. If it
  lives on your machine, it never reached the remote.>`

`<If an innovative idea exists, one short paragraph: name it, say why it is genuinely
an idea rather than a feature, and what it would take to push it further. If B3 was
awarded, say so.>`

### What would most improve it

`<The top three changes, in order of leverage, each one actionable this week.>`

### One thing to keep doing

`<A habit visible in the work worth reinforcing — measuring before tuning, honest
answer 5, small described commits, refusal cases in the golden set.>`

If any of this reads wrong — especially if you think the review missed evidence that is
in the repository — reply and say where to look. The review is built on what is
actually there, so pointing at a path is enough to reopen it.

`<sign-off>`
