# Final project — your own assistant, on your own knowledge

**Module:** AI Engineering on Azure · Libra Bank Academy
**Estimated effort:** 10–16 hours · **Difficulty:** this is the one that is evaluated
**Starting point:** the course repository, at whatever state you have it in
**Submission:** the Google Form — repository link, your redacted `.env`, and the written brief

This is not a new project. It is the course repository, taken over: the same backend, the
same endpoints, the same deployment story — but the knowledge is yours, the agent is
yours, the interface is yours, and the answers are measured against a set of questions
whose correct answers only you know.

That last part is the point. Anything can be made to *produce an answer*. What separates
a demo from a system is being able to say, with evidence, whether the answer was right.

---

## What you build

Four requirements. The first three are mandatory; the fourth earns bonus marks.

### 1 · Your own agent, deployed in Foundry

A persona you wrote, for a domain you chose, deployed to the Foundry Agent Service and
invocable from your application through `agent_mode=foundry`.

- The persona file is yours: instructions, style rules, temperature, and the decisions
  behind them. A renamed copy of `teller` is not a persona.
- It is deployed and it runs. `GET /agents` reports it, and `POST /ask` with
  `agent_mode=foundry` answers through it.
- You can explain what changes in the answers when it runs instead of the default —
  and you have an example of each to show.

### 2 · Your own knowledge, and a golden set to judge it

A corpus you assembled or invented, ingested through your own pipeline, plus a **golden
set**: questions paired with the answers you know to be correct.

- **At least 15 documents or document sections**, on one coherent subject. Invented is
  fine — preferred, even, because you then know every right answer. Real public documents
  are fine too. Somebody else's benchmark dataset is not.
- **At least 10 golden questions**, in a file in your repository, each with: the question,
  the correct answer, and which document it comes from.
- Include at least **two questions that should fail** — something the corpus genuinely
  does not cover — and record that refusing is the correct behaviour. A system that never
  says "I don't know" has not been tested, it has been demonstrated.
- **A way to run the golden set and get a number.** A script, a notebook, a Postman
  collection with tests — anything reproducible that reports how many questions were
  answered correctly. The number does not need to be high. It needs to be honest, and it
  needs to be *measured* rather than asserted.
- **Record the number twice**: once before you tuned anything, once after. What you
  changed between them, and whether it helped, is the most interesting paragraph in your
  submission.

### 3 · Your own interface

A user interface you built — or the course console, substantively improved: new
capability, not a restyle.

- It talks to your backend, and it makes the retrieval **visible** — the passages, the
  scores, or at minimum the citations. A chat box that hides the pipeline is a worse
  teaching tool than Swagger.
- It has the RAG toggle, so a demo can show the same question answered with and without
  grounding.
- It runs from a command written in your README, and it works on a clean clone.
- Any technology. React, plain HTML and fetch, Streamlit, Gradio, a Python TUI. The
  requirement is that it is yours and it works — not that it is impressive.

### 4 · Text to speech — optional, bonus

Answers read aloud through Azure Speech, wired into your interface. Worth up to **5 bonus
marks** on a 100-mark scale. Attempt it only when the three requirements above are done:
a polished voice on an unmeasured assistant scores worse than a plain one that is
measured.

---

## What you submit

| | |
|---|---|
| **Repository** | Public, **or** private with `@luciangruiaro` added as a collaborator. Check the link in a private browser window before you submit it — that is what a reviewer sees. |
| **`.env`** | With the value of every `*_KEY`, `*_SECRET` and `*_PASSWORD` line replaced by `REDACTED`. Names and all other values intact. A live key in a submission is an incident: it will be returned and you will have to rotate it. |
| **Written brief** | Your answers to the five questions below, in the form. Written by you or with your agent's help — as long as they match the repository. |
| **README** | How to run it, on a machine that has never seen it. This is read first and it is read literally. |

---

## About your project — five questions

These are answered in the submission form. Answer in your own words, or with your coding
agent's help — either is fine, and using one is not a disadvantage. What matters is that
your answers match what is actually in your repository. Around 150 words each; short and
specific beats long and general.

> **1. What did you build?** Describe it concretely: the agent persona you wrote and the
> domain it serves, the knowledge corpus and what it covers, and the interface — which
> technology you used, and how someone else starts it.
>
> **2. What did you measure, and what came out?** Where is your golden question set, how
> many questions does it hold, and how many of them should be refused? What score did you
> get? If you have a before and an after, give both numbers and say what you changed in
> between. If you never got to measuring, say so plainly — that is a more useful answer
> than an estimate.
>
> **3. Which parts are yours?** Your repository began as a fork of the course repo, so
> tell us what you added. Roughly how many commits are yours, over what period, and what
> are the three most substantial changes you made? Describe them by what they do, not by
> how many lines they touched. (`git log --author="<your name>"` will do most of this
> for you.)
>
> **4. How did you use AI while building this?** Which tools or agents, and for what —
> scaffolding, debugging, writing the corpus, documentation, something else? Leaning on
> AI heavily is expected and costs you nothing. Not being able to say what it produced
> does.
>
> **5. What is unfinished, broken, or would fail on a clean clone?** Be specific, and be
> unkind about your own work. This is the answer read most carefully. Naming your own
> rough edges is evidence that you understand your system; claiming everything works when
> it does not is the only answer here that costs marks.

---

## How it is evaluated

Every submission is reviewed against the same rubric, by a fresh reviewer with no memory
of the previous one, working only from your repository and your five answers. Each line
is scored **1–100** and weighted; bonuses are added on top.

| # | Criterion | Weight |
|---|---|---|
| 1 | Your agent, deployed in Foundry | 20 |
| 2 | Your knowledge, and the golden Q&A set | 20 |
| 3 | Engineering practice & mindset | 20 |
| 4 | Quality of your own code | 15 |
| 5 | The interface — your own, or real improvements to the course console | 15 |
| 6 | Design & architecture of what you added | 10 |
| B1 | Text to speech, wired in | up to +5 |
| B2 | Robust engineering beyond the course bar | up to +5 |
| B3 | Innovation & originality | up to +5 |

Weighted total = Σ score × weight / 100, out of **100**, plus up to **15** bonus.

The 1–100 line scores follow fixed anchors, so two reviewers land in the same range:

| Range | Meaning |
|---|---|
| 1–20 | Missing, or started and abandoned |
| 21–40 | Present but broken, or works only partly |
| 41–60 | Works, at the level of following the course steps |
| **61–75** | **Solidly meets the requirement — the target** |
| 76–90 | Strong: works, plus decisions the author can defend |
| 91–100 | Exemplary: could be handed to another engineer without explanation |

### What each criterion looks for

**1 · Your agent, deployed in Foundry (20).** A persona of your own authorship,
meaningfully different from the four samples. Evidence it is deployed and invocable —
not just a JSON file. An explanation, in your own words, of what its instructions change
about the answers.

**2 · Your knowledge, and the golden Q&A set (20).** A coherent corpus of your own. At
least ten golden questions with known answers, including questions that should be
refused. A reproducible way to run them and a recorded score. Best of all: a before and
after, with an account of what you changed.

**3 · Engineering practice & mindset (20).** The difference between engineering and
vibecoding, made visible: a clean clone plus your README plausibly gives a working
system; configuration lives in environment variables with no secrets in the history —
**a committed live key caps this line at 20**; dependencies are pinned; commits are
small, described, and yours; claims in your five answers match the repository; what is
measured is measured, and what is broken is named.

**4 · Quality of your own code (15).** Judged only on code you added or changed, not on
the course code you inherited. Readable names, functions that do one thing, no dead code
or commented-out experiments left behind, errors handled rather than swallowed, and
consistency with the codebase you built on. AI-generated code is fine — left unread and
unintegrated, it is not.

**5 · The interface (15).** Either your own build, in any technology, or **substantive
improvements to the course console** — new capability, not a restyle. In both cases:
started from a documented command, retrieval made visible (passages, scores or
citations), the RAG toggle present.

**6 · Design & architecture (10).** How your additions are shaped: separated concerns,
sensible boundaries, configuration over hard-coding, patterns used where they earn their
keep — and no cargo-cult abstraction where a function would do.

**B1 · Text to speech (+5).** Working and wired into your interface, not at the expense
of the core.

**B2 · Robust engineering beyond the bar (+5).** Things the course did not require but
real systems do: tests that run, deliberate error handling, logging that would help at
3 a.m., a CI check, structured evaluation beyond the golden set.

**B3 · Innovation & originality (+5).** An idea that is genuinely yours: an unexpected
corpus, a retrieval twist, an agent capability, an evaluation method, a UI concept.
Named in your feedback when it exists — reviewers are explicitly asked to look for it.

### What does not affect your mark

- How pretty the interface is.
- How high the golden-set score is. A measured 6/10 with a clear account of the four
  failures beats an unmeasured claim of perfection.
- How much AI wrote. Only whether you read, integrated and can explain it.
- Whether you attempted the bonuses.

---

## Suggested order

You have limited time, so spend it where the marks are.

1. **Get a clean clone running first.** If your repository does not start on another
   machine, nothing else is visible. Test it by cloning your own repo into a new folder.
2. **Write the corpus and the golden set before tuning anything.** You cannot tell whether
   a change helped without a baseline. Record the first score even though it is bad —
   *especially* because it is bad.
3. **Deploy the agent.** It is the shortest of the three requirements and the one most
   likely to hit an environment problem, so hit it early, not the night before.
4. **Then the interface.** It is the most visible and the most time-consuming, and it is
   worth fewer marks than the two above. Build the plain version, make it work, stop.
5. **Tune retrieval, re-run the golden set, record the second number.**
6. **Write the README as if you had never seen the project.** Then run the submission
   prompt and read what it says about section 5.
7. **Text to speech, if time is left.**

---

## If something blocks you

Bring the exact command and the exact error. A precise error message is diagnosable in
seconds; "it didn't work" is not.

And if you run out of time, submit what you have, with an honest brief. A partial project
with an accurate account of its state is a much better result than a silent one — and it
is a far better result than a complete-looking one that does not run.
