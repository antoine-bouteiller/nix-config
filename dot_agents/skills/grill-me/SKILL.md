---
name: grill-me
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_ without guessing at answers you haven't heard yet.

Each round opens with a **survey**: the fact-finding the frontier needs from the environment (filesystem, tools, docs). Dispatch the sub-agents, let every one report, and fold their findings into the tree — a fact can settle a question, kill it, or split it. The round's questions start once the survey is complete, so every question you put to the user is grounded in what the environment already answered.

Then ask the whole frontier, one question at a time, each with your recommended answer. Prefer the `ask_user` tool where it exists: one call per question, your recommendation first in the options list. Without it, write each question as:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Wait for the user's answers before the next round.

Each round the user answers reshapes the tree — settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's: anything you could look up yourself belongs in the survey. The _decisions_ are the user's — put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
