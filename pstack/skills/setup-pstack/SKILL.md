---
name: setup-pstack
description: Configure which models pstack uses per role, and at what reasoning budget. Detects the models enabled in your Pi settings, asks for a budget, and writes the role file every pstack run reads. Use for /skill:setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
disable-model-invocation: true
---

# Setup pstack

Write `~/.pi/agent/pstack-models.md`, the role file pstack reads at the start of a run.

## Steps

### 1. Detect available models

Read `~/.pi/agent/settings.json` and take `enabledModels`. Presence in `enabledModels` is the availability proof; do not perform an external provider-catalog lookup. Each entry is an exact `provider/id`, and some carry a suffix such as `:batch` or `:high`. Strip a trailing `:batch`. Keep the `provider/id` and its `:level` separate, because the level is what step 3 changes. An entry with a leading `~` is an alias, so leave it out of the detected set. Take `defaultModel` from the same file as the operator's code default, and `subagents.agentOverrides.<name>.model` for any role that names one. The aliases `inherit-parent` and `auto` are always valid even though they are not detected models.

### 2. Load current state

If `~/.pi/agent/pstack-models.md` already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from the defaults in step 5. A line whose role is not in step 5, such as `how critics`, is from a retired role. Drop it.

### 3. Seed, budget, and confirm

**(a) Seed each role.** On a first run, start from the operator's own configuration rather than inventing a policy. Use `defaultModel` for the code roles (`feature, refactoring`, `bug-fix`, `perf-issue`, `hillclimb`, `swarm workers`) and the explorer and investigator roles. Use `subagents.agentOverrides.oracle.model` for `judgment and prose` and `hardest tasks`, and `subagents.agentOverrides.reviewer.model` for the review panel roles, when those exist and are in the detected set. When a role has no source, use `inherit-parent`. On a re-run, keep any role whose value differs from what step 3(a) alone would produce.

**(b) Ask for a budget.** Use the `ask_user` tool over free text. Offer these four options with these exact labels, and name the current budget when the file records one. With no file, say that `large` matches the skill defaults.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(c) Apply it.** `unlimited`, `large`, `medium`, and `small` set the `:level` suffix of every detected model to `max`, `xhigh`, `high`, or `medium`. A model value carries at most one suffix, so replace the existing one. A role that already names a model outside the detected set keeps its level change and stays flagged in step 4. `inherit-parent` and `auto` do not change.

**(d) Show the roles and confirm.** Show every role with its model, marking any entry not in the detected set. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit-parent` and `auto` as options. Use the `ask_user` tool over free text. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena selects one value from it. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm. For the panels, prefer entries from different model families, because the point of the panel is that the seats disagree.

### 4. Validate

Every real model written must be in the detected set. `inherit-parent` and `auto` always pass. If a chosen model is not available, stop and ask again. Pi rejects an unknown or ambiguous model at launch with the closest registry ids, so never write a model you have not confirmed.

### 5. Write the role file

Write `~/.pi/agent/pstack-models.md` with no frontmatter, then the comment lines, the `# budget` line, and one line per role, using the same role labels poteto-mode and the routed skills use. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack role models. One line per role. Delete a line to fall back to that role's default.
# `inherit-parent` or `auto` as a value: the role omits `model` and runs on the parent chat model.
# A detected model may carry one `:level` suffix: off, minimal, low, medium, high, xhigh, max.
# budget: large (xhigh)
feature, refactoring: inherit-parent
bug-fix: inherit-parent
perf-issue: inherit-parent
hillclimb: inherit-parent
judgment and prose: inherit-parent
hardest tasks: inherit-parent
how explorer: inherit-parent
how explainer: inherit-parent
why investigators: inherit-parent
why synthesizer: inherit-parent
reflect tooling: inherit-parent
reflect judgment, divergent, synthesizer: inherit-parent
arena runners: inherit-parent
arena cross-judge pool: inherit-parent
swarm workers: inherit-parent
architect runners: inherit-parent
interrogate reviewers: inherit-parent
```

Never put the role lines in `~/.pi/agent/AGENTS.md` or a project `AGENTS.md`. Pi loads those into every session, and generated content there fights the operator's own edits.

A skill that a role line names reads it at its own spawn site. A role with no line, or a line reading `inherit-parent` or `auto`, omits `model` and inherits the parent chat model.

### 6. Confirm

Tell the user the role file was written, that every pstack run reads it at its start, and that re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /skill:create-verification-skill." On yes, invoke `/skill:create-verification-skill`. On no, move on without pushing.

Cursor's `control-ui` and `control-cli` are `Skipped in Pi.` A project-local verification skill is what replaces them here, so this offer matters more in Pi than it does upstream.

### 8. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /skill:create-formal-verification-skill." On yes, invoke `/skill:create-formal-verification-skill`. On no, move on without pushing.
