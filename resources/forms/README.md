# Project submission form — field list

The form itself lives in Google Forms. This file is the record of its questions, so the
next cohort's form can be rebuilt without reverse-engineering the old one.

| # | Question | Type | Required |
|---|---|---|---|
| 1 | Full name | Short answer | yes |
| 2 | Email | Short answer, email validation | yes |
| 3 | Git repository URL | Short answer, URL validation | yes |
| 4 | Your `.env`, secrets replaced by `REDACTED` | File upload | yes |
| 5 | Where you were when the module started | Grid: 3 rows × 5 columns | yes |
| 6 | For each area, what did this module actually give you? | Grid: 3 rows × 4 columns | yes |
| 7 | How much material was covered, for the time available? | Multiple choice, 5 options | yes |
| 8 | About your project — five questions | Paragraph (questions in the description) | yes |
| 9 | What are your main learnings from this module? | Paragraph | yes |
| 10 | Any feedback about the module | Paragraph | no |
| 11 | LinkedIn profile | Short answer, URL validation | no |
| 12 | What would you most like to learn next? | Paragraph | yes |
| 13 | How useful was this module to you? | Linear scale 1–5 | yes |

**Q3 help text:** make the repository public, or keep it private and add `@luciangruiaro`
as a collaborator — otherwise it cannot be reviewed. Check the link in a private browser
window before pasting: that is what a reviewer sees.

**Q4 help text:** replace the value of every line whose name ends in `_KEY`, `_SECRET` or
`_PASSWORD` with `REDACTED`; leave the names and every other value intact. A submission
containing a live key is returned, and the key has to be rotated.

**Q5 rows:** Object-oriented Python · Machine learning and generative AI concepts ·
Microsoft Foundry and Azure.
**Q5 columns:** Nothing at all · Heard of it · Some basics · Confident · I could teach it.

**Q6 rows:** same three.
**Q6 columns:** Nothing new · Decent · Good · I managed to apply it.

**Q7 options:** Too little — I wanted considerably more · A little light — there was room
for more · About right · A little heavy — I kept up, but only just · Too much — I could
not keep up.

**Q8:** the five project questions live in
[`docs/assignments/project.md`](../../docs/assignments/project.md) — copy them into the
question description verbatim, so the assignment page and the form never drift apart.

**Settings:** allow response editing · progress bar on · *Collect email addresses* off
(Q2 asks explicitly; both on yields two email columns that disagree). File upload
requires a Google Workspace owner and forces respondents to sign in to Google.
