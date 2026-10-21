# Skills

A shared, version-controlled collection of personal skills for **Pi** and **Claude Code**.
The canonical files live in `skills/`. Both tools use per-skill symlinks to those files.
`pstack/` is a separate, Pi-only fork of an upstream skill collection.

```text
skills/<name>/                  ← canonical instructions and supporting files
~/.pi/agent/skills/<name>        → <repository>/skills/<name>
~/.claude/skills/<name>          → <repository>/skills/<name>

pstack/skills/<name>/           ← Pi-adapted fork of cursor/plugins → pstack
~/.pi/agent/skills/pstack        → <repository>/pstack/skills     (Pi only, never Claude)
pstack/agents/<agent>.md         ← Pi subagent definitions
~/.pi/agent/agents/<agent>.md    → <repository>/pstack/agents/<agent>.md
```

Editing through either tool edits this repository. There is no copy/sync step.
The tool directories themselves remain ordinary directories, so Claude's account-managed
`synced/` subtree stays outside this repository and outside Pi.

## Shared skills

Imported from the existing local installations. All 12 are linked into both tools.
“Explicit only” means `disable-model-invocation: true` is preserved: invoke the
skill yourself rather than expecting automatic selection.

| Skill | Purpose | Imported from | Requirements / notes |
| --- | --- | --- | --- |
| [changelog](skills/changelog/SKILL.md) | Generate categorized changelogs between Git refs, with optional GitHub links. | Claude local | Git and repository history; optional GitHub repository name. |
| [diff](skills/diff/SKILL.md) | Read-only review of staged or unstaged changes for correctness, security, and accidental artifacts. | Claude local | Git working tree. |
| [eli5](skills/eli5/SKILL.md) | Explain a topic to a novice using a self-contained HTML file, large visuals, and short captions. | Pi local | Explicit only; writes `eli5-<topic>.html`; no external libraries. |
| [grilling](skills/grilling/SKILL.md) | Stress-test a plan through a dependency-aware decision tree and successive interview rounds. | Pi local | Explicit only; no implementation until shared understanding is confirmed. |
| [impeccable](skills/impeccable/SKILL.md) | Design, critique, and improve frontend UX, accessibility, typography, layout, and visual craft. | Pi local | Skill declares 4.2.0; includes references, data, launchers, and browser scripts. See engine notes below. |
| [k8s-debug](skills/k8s-debug/SKILL.md) | Read-only Kubernetes triage: status, describe, logs, events, and likely root causes. | Claude local | `kubectl`, cluster access, and the intended context/namespace. |
| [pr-review](skills/pr-review/SKILL.md) | Advisory GitHub PR review covering security, correctness, breaking changes, and CI. | Claude local | Authenticated `gh`; does not submit a review or approve on GitHub. |
| [scrape-docs](skills/scrape-docs/SKILL.md) | Save documentation pages locally for later searches. | Claude local | Bundled [scraper](skills/scrape-docs/scripts/scrape-docs.sh); macOS `textutil`, `curl`, Perl, and shell utilities. Keeps data in `~/.claude/docs/` even when invoked from Pi. |
| [search-docs](skills/search-docs/SKILL.md) | Search saved documentation and return relevant passages and source URLs. | Claude local | Uses the same `~/.claude/docs/` store as scrape-docs. |
| [typesafe-ai](skills/typesafe-ai/SKILL.md) | Build typed AI judgments for routing, ranking, extraction, verification, and interactive experiences. | Pi local | Explicit only; retrieve current TypeSafe docs; API credentials are needed for integrations, not stored here. |
| [validate-helm](skills/validate-helm/SKILL.md) | Render a Helm app's chart and inspect output for errors and unexpected values. | Claude local | `helm`, repository `appsets/<app>.yaml` and values files; updates the local Helm repository cache. |
| [web-perf](skills/web-perf/SKILL.md) | Audit loading/interaction performance, Core Web Vitals, and Lighthouse issues. | Pi local | Browser/performance tools for measured traces; source/network analysis can proceed without them. |

### Portability and provenance

- Whole skill directories were imported, retaining scripts, data, references,
  permissions, and license metadata. The original local files—not newer plugin
  copies—are the starting point for this repository.
- The only instruction change during import was making scrape-docs invoke its
  newly bundled script relative to its loaded skill directory. The original
  `~/.claude/scripts/scrape-docs.sh` is left untouched.
- These are shared instructions, not identical tool environments. Some Claude-origin
  skills use `$ARGUMENTS` and Claude tool names such as Grep, Glob, or WebFetch.
  Pi passes explicit skill arguments as a user request; use Pi's available equivalent
  tools. Claude-specific frontmatter does not install those tools in Pi.
- Impeccable resolves its launcher using the loaded skill base directory; its
  `.pi/skills/...` paths are fallbacks, not a requirement to relocate this repository.
- Licenses remain those of the individual skills. Impeccable’s upstream
  [Apache 2.0 license](skills/impeccable/LICENSE) and the bundled modern-screenshot
  [MIT license](skills/impeccable/scripts/modern-screenshot.LICENSE) are included,
  alongside TypeSafe’s existing license. There is no blanket license here granting
  additional rights to third-party material.

### Impeccable engine

The imported platform binary in `skills/impeccable/scripts/bin/` remains on this
machine but is ignored by Git. The launcher, `VERSION`, supporting data, and scripts
are version-controlled. On a fresh machine the launcher can download its pinned
engine into `~/.impeccable/`, verifying the release checksum, or use a compatible
engine configured via `IMPECCABLE_BIN`. First use may need network access.

## pstack

[`pstack/`](pstack/UPSTREAM.md) is a fork of [cursor/plugins → pstack](https://github.com/cursor/plugins/tree/main/pstack)
by Lauren Tan, MIT licensed, vendored at v0.15.29. It is a workflow collection rather than a
single skill: `poteto-mode` routes a task to one of 23 playbooks, which call 24 one-rule
principle skills and about 30 other skills as their steps need them.

**It is Pi-only.** The 55 skills name Pi's tools (`subagent`, `ask_user`), Pi's agents
(`poteto-agent`, `delegate`, `scout`), and Pi's config paths. They would mislead Claude, so
`link-skills.sh` never links them into `~/.claude`.

**It is operator-invoked only.** All 55 skills set `disable-model-invocation: true`, so Pi
filters them out of the system prompt entirely. The model cannot see or select them; each
runs only when you type `/skill:<name>`. Keep that field on any skill you add here.

Start with `/skill:poteto-mode`, or `/skill:setup-pstack` to choose the model each role
runs on. `pstack/UPSTREAM.md` records the upstream commit, every Cursor-to-Pi substitution,
the Cursor features that are `Skipped in Pi.`, and the known gaps. The two subagents are
`poteto-agent` for delegates and `comment-sicko` for read-only comment review.

`pstack/skills/poteto-mode/scripts/` keeps upstream's Bun tooling unchanged. `watch-pr`
needs `gh`, and the `orch` and `check-plan` tests need `bun`.

## Install or relink

Run from any working directory:

```sh
bash /path/to/skills/link-skills.sh
```

The installer:

1. Validates that each directory under `skills/` has a `SKILL.md` before changing links.
2. Creates each tool's skills directory if necessary.
3. Leaves already-correct links alone.
4. Moves conflicting entries, including stale or broken symlinks, into a unique
   `skills-backup.<timestamp>.<suffix>/` directory beside the tool's skills directory.
5. Creates absolute symlinks to each canonical skill, printing link and backup paths.
6. Links `pstack/skills` and each `pstack/agents/*.md` into Pi only, skipping Claude.
   It validates `pstack/skills/poteto-mode/SKILL.md` before changing those links.

Backups are outside the repository. The installer does not delete originals,
change either tool's settings, remove unrelated skills, or modify Claude sync.
It is repeatable, but not transactional: if an OS/filesystem error interrupts it,
inspect the printed backup path and rerun or restore the affected entry.
Run it while neither tool is installing/updating local skills.

Use Pi's `/reload` after linking or changing skills. Start a new Claude Code session
and inspect its `/skills` or command menu. Invoke `/skill:<name>` in Pi or
`/<name>` in Claude. Moving this repository requires rerunning the installer to
replace the old absolute links.

## Add or update a skill

Both global instruction files—`~/.pi/agent/AGENTS.md` and `~/.claude/CLAUDE.md`—
direct agents to create/import personal skills here, update this README, run the
link installer, and check for sensitive material. This is an agent workflow rule,
not a filesystem watcher: manual installs still need importing/relinking. Managed
package/plugin skills and account-synced skills remain excluded unless explicitly migrated.

A skill meant for Pi only can live under `pstack/` instead, which keeps it out of Claude.
Since `pstack/` is a fork of someone else's work rather than ours, prefer adding our own
skills under `skills/`, and treat `pstack/UPSTREAM.md` as the place to record what we
changed and how to re-sync.

1. Add `skills/<name>/SKILL.md`, using a matching lowercase, hyphenated frontmatter
   `name` and a meaningful `description`. Do not use Claude's reserved names
   `synced` or `anthropic-skills`.
2. Keep required scripts/references/assets inside that directory and resolve paths
   relative to the loaded skill directory. Do not put credentials or runtime output here.
3. Add or update its row in this README.
4. Run `bash link-skills.sh`, reload/restart the tools, and check Git's diff.

Both tools now read the same instructions. Updating a symlinked skill with an
external installer may overwrite the canonical files or replace the link; inspect
`git diff` afterward and rerun the link installer if necessary.
Removing a skill directory does not remove its installed links automatically;
remove only the matching symlinks in both tool directories when intentionally retiring it.

## Roll back

For any replaced original, use the corresponding printed backup directory:

```sh
# Example for a skill that originally existed in Pi:
link="$HOME/.pi/agent/skills/<name>"
backup="$HOME/.pi/agent/skills-backup.<timestamp>.<suffix>"
[ -L "$link" ] && unlink "$link"
mv "$backup/<name>" "$link"
```

For a skill newly added to a tool, unlink that tool's symlink only; there is no
original entry to restore. For a full rollback, restore the original 5 Pi skills
and 7 Claude skills from their respective backups, and unlink the other newly
added skills. Leave unrelated entries and Claude's `synced/` directory alone.

## Checks

```sh
bash -n link-skills.sh
bash -n skills/scrape-docs/scripts/scrape-docs.sh
python3 -m unittest discover -s tests
```

The test uses a temporary HOME and repository: verifies both tools' links,
original-directory and broken-link backups, preservation of Claude sync,
repeat-run idempotence, paths with spaces, and preflight rejection of a missing
`SKILL.md`. It does not run the skills, call cloud services, or test model behavior.

## Publication safety

The initial public-safety review scanned all 68 publishable files, including
bundled JavaScript and data, for common credential/token formats, private keys,
credential assignments, URL credentials, personal absolute paths, email addresses,
and private IPv4 addresses. No matches were found. Matches for generic words such
as “secrets” referred to security guidance, not stored credentials.

Global tool settings, account-sync content, backups, scraped documentation,
and the local platform executable are not included. This README does disclose
installed tools, skill names, and versions. The scan is a snapshot, not a guarantee
against every secret format; review future imports before publishing. Missing
Impeccable and modern-screenshot license texts were included before publication;
this basic attribution check is not an exhaustive legal review.

## Externally managed installed skills

Inventory taken from Pi package manifests, Claude's user plugin settings and
installed plugin registry, and the Claude account-sync cache at migration time.
These skills are documented below but **not copied into this repository or relinked**.
Package/plugin/account updates remain responsible for them. Presence in an installed
package is not proof that a skill is advertised automatically: invocation flags,
resource filters, and session context can affect availability.

Claude plugin commands are namespaced as `/<plugin>:<skill>`, so both local and
plugin versions of Impeccable, TypeSafe, and web-perf remain available. Overlapping
versions can advertise overlapping guidance; use the local unprefixed command to
explicitly select this repository's copy. The local `/grilling` wins the short name;
its account-synced counterpart remains available under its qualified sync name.

Pi also has pi-web-access, SoL-Pi, and a curated themes package configured; those
installations contribute no additional enabled skill directories to this inventory.
The theme adaptation skill is explicitly excluded in Pi settings. The Compound
Engineering plugin listed below is installed for a separate project, not globally
enabled in Claude's user settings. Built-in skills and uninspected project-local
skill directories are outside this personal-installation inventory.

### Pi package: Ponytail (5.1.0)

| Skill | Purpose |
| --- | --- |
| `ponytail` | Lazy senior dev mode: the smallest change that fully solves the task, and a reply a busy human understands in one read. |
| `ponytail-audit` | Quality audit of a whole repo: bugs, security holes, what breaks under real load, risky code without tests, slow paths, and what to delete, merge or split. |
| `ponytail-debt` | List every `shortcut:` comment (and older `ponytail:` ones) as a debt ledger. |
| `ponytail-gain` | Show ponytail's measured savings (code, cost, speed) from the benchmark. |
| `ponytail-help` | Quick reference for ponytail levels, skills and commands. |
| `ponytail-review` | Quality review of a change: is the logic right, is it safe, does it hold under real load, is risky code tested, is it fast enough, and is every line needed. |

### Pi package: pi-subagents (0.77.0)

| Skill | Purpose |
| --- | --- |
| `council-mode` | Run a bounded supervisor-mediated advisor council. |
| `pi-subagents` | Technical guidance for operator-requested delegation to builtin or custom subagents: bounded handoffs, parallel review, scripted workflows, async work, forked context, isolation, and coordinated execution. |

### Pi package: pi-ask-user (0.16.0)

| Skill | Purpose |
| --- | --- |
| `ask-user` | You MUST use this before high-stakes architectural decisions, irreversible changes, or when requirements are ambiguous. |

### Claude plugin: ponytail@ponytail (4.8.4; user-enabled)

| Skill | Purpose |
| --- | --- |
| `ponytail` | Forces the laziest solution that actually works, simplest, shortest, most minimal. |
| `ponytail-audit` | Whole-repo audit for over-engineering. |
| `ponytail-debt` | Harvest every `ponytail:` comment in the codebase into a debt ledger, so the deliberate shortcuts and deferrals ponytail leaves behind get tracked instead of rotting into "later means never". |
| `ponytail-gain` | Show ponytail's measured impact as a compact scoreboard: less code, less cost, more speed, from the benchmark medians. |
| `ponytail-help` | Quick-reference card for all ponytail modes, skills, and commands. |
| `ponytail-review` | Code review focused exclusively on over-engineering. |

### Claude plugin: impeccable@impeccable (4.3.1; user-enabled)

| Skill | Purpose |
| --- | --- |
| `impeccable` | Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. |

### Claude plugin: stripe@claude-plugins-official (0.10.3; user-enabled)

| Skill | Purpose |
| --- | --- |
| `connect-recommend` | Recommend Stripe Connect configurations, payment flows, onboarding, and connected-account responsibilities. |
| `connect-required-verification-information` | Explain and compare Stripe Connect verification, onboarding, KYC, and account-information requirements. |
| `metronome` | Guides Metronome usage-based billing integration decisions — event ingestion (single and batch, idempotency, billable metrics), contract design (rate cards, overrides, dimensional pricing, products), invoicing lifecycle (grace periods, finalization, Stripe sync), credit and commit management (prepaid, postpaid, thresholds, auto-recharge), and Stripe integration (arrears invoicing, tax providers, line item limits). |
| `stripe-apps` | Build, modify, and review Stripe Apps and their integrations. |
| `stripe-best-practices` | Choose Stripe APIs and integration patterns across payments, subscriptions, Connect, tax, Treasury, and security. |
| `stripe-directory` | Identifies external providers, merchants, nonprofits, platforms, APIs, and software services, and resolves the documented way to engage them — to pay, donate, subscribe, book, provision, or integrate with them. |
| `stripe-docs` | Use when the user or agent needs to read, search, or look up Stripe documentation or API reference. |
| `stripe-pay` | Helps users send funds to another Stripe business, transfer money to a Stripe Profile handle or network ID, or ask whether an agent can pay a Stripe business. |
| `stripe-projects` | Use when the user wants to provision infrastructure or third-party services using Stripe Projects. |
| `upgrade-stripe` | Guide for upgrading Stripe API versions and SDKs |

### Claude plugin: cloudflare@cloudflare (1.0.0; user-enabled)

| Skill | Purpose |
| --- | --- |
| `agents-sdk` | Build, debug, or review Cloudflare Agents SDK applications using the agents package. |
| `cloudflare` | Discover and choose Cloudflare products for apps, APIs, AI agents, storage, networking, and security. |
| `cloudflare-email-service` | Implement or troubleshoot Cloudflare Email Sending and Email Routing integrations and their delivery configuration. |
| `cloudflare-one` | Design, configure, troubleshoot, or review Cloudflare One Zero Trust and SASE deployments. |
| `cloudflare-one-migrations` | Assess and plan migrations from existing VPN, SWG, or SASE platforms to Cloudflare One, including policy mapping, parity gaps, and rollout. |
| `durable-objects` | Build, debug, or review Cloudflare Durable Objects code for persistent state and coordination. |
| `nextjs-on-cloudflare` | Build, migrate, and deploy Next.js apps on Cloudflare Workers with vinext. |
| `sandbox-migrate-to-next` | Migrate Cloudflare Sandbox apps from stable @cloudflare/sandbox to @cloudflare/sandbox@next (SDK 1.0 preview). |
| `sandbox-next` | Build or maintain Cloudflare Sandbox apps on @cloudflare/sandbox@next (SDK 1.0 preview). |
| `sandbox-stable` | Build or maintain Cloudflare Sandbox apps on the stable @cloudflare/sandbox package. |
| `turnstile-spin` | Set up, repair, or migrate to Cloudflare Turnstile bot verification in an existing frontend and backend, including server-side Siteverify. |
| `web-perf` | Audit, diagnose, or optimize website loading and interaction performance, Core Web Vitals, and Lighthouse performance scores. |
| `workers-best-practices` | Cloudflare Workers best practices for production applications. |
| `wrangler` | Run or troubleshoot Wrangler CLI commands and configure Worker projects for local development, deployment, and Cloudflare resource management. |

### Claude plugin: typesafe@typesafe-ai (0.5.7; user-enabled)

| Skill | Purpose |
| --- | --- |
| `typesafe-ai` | Build AI-powered software with TypeSafe: small units of AI intelligence you can use like programming primitives. |

### Claude plugin: compound-engineering@compound-engineering-plugin (3.30.3; project-scoped installation; not globally enabled)

| Skill | Purpose |
| --- | --- |
| `ce-babysit-pr` | Babysits an open GitHub PR until merge-ready. |
| `ce-bakeoff` | Develop independent competing solutions to a defined brief, compare them, and synthesize a winning approach. |
| `ce-brainstorm` | Explore vague or ambitious ideas into a right-sized requirements-only unified plan. |
| `ce-code-review` | Review a named diff or PR for bugs, regressions, tests, and standards. |
| `ce-commit` | Create a git commit with a clear, value-communicating message. |
| `ce-commit-push-pr` | Commit, push, and open a PR. |
| `ce-compound` | Document a solved problem as a durable repo learning. |
| `ce-compound-refresh` | Refresh the repo's captured learnings against the current codebase. |
| `ce-debug` | Diagnosis loop for bugs and failing behavior. |
| `ce-doc-review` | Review requirements, plans, or specs with role-specific lenses. |
| `ce-dogfood` | Hands-off, diff-scoped browser QA of the active branch: maps user flows, drives a real browser, autonomously fixes small breakages with regression tests and commits, judges experience against product personas, and writes a durable dogfood report. |
| `ce-explain` | Explain how and why something has its current shape, or what happened over a window of work, grounded in evidence. |
| `ce-handoff` | Create a session handoff for another agent, or resume, find, and read any user-selected continuity source. |
| `ce-ideate` | Generate and evaluate grounded ideas. |
| `ce-noslop` | Rewrite, check, or draft prose so it carries no AI writing tells, reads plainly on the first read, and keeps every source fact. |
| `ce-optimize` | Optimize a named target with a measured loop: attribute a workload's cost, or score variants and keep winners. |
| `ce-plan` | Create structured plans for multi-step work, including software and non-software tasks. |
| `ce-polish` | Polish a working feature through user-directed live browser feedback. |
| `ce-pov` | Judge a supplied subject against the project's evidence and constraints. |
| `ce-product-pulse` | Generate time-windowed product pulse reports from configured signals. |
| `ce-promote` | Draft launch or promotion copy for a shipped feature. |
| `ce-proof` | Publish, read, comment on, or edit markdown in Proof. |
| `ce-prototype` | Build a throwaway prototype to answer how something should work, feel, or read. |
| `ce-resolve-pr-feedback` | Judge PR feedback centrally, apply valid fixes, and complete review conversations with publication verified. |
| `ce-retune` | Retune a skill corpus for a new model, measurement-first: mine the run archive for a baseline, establish a noise floor, audit the corpus adversarially, then cut in measured passes until a pre-registered bar clears. |
| `ce-riffrec-feedback-analysis` | Analyze recorded product feedback into evidence for bugs and requirements. |
| `ce-setup` | Check Compound Engineering health and repo-local config, or scaffold a Compound Pack with `pack:<id>`. |
| `ce-simplify-code` | Simplify settled, recently changed code for clarity, reuse, quality, and efficiency while preserving behavior. |
| `ce-strategy` | Create or update STRATEGY.md. |
| `ce-sweep` | Sweep configured feedback sources (Slack, GitHub Issues; email experimental) for new items: acknowledge at source, analyze recordings, verify fixes merged to main, and emit an `lfg`-ready plan. |
| `ce-test-browser` | Run browser tests for pages affected by the current branch or PR. |
| `ce-test-xcode` | Test iOS apps in a simulator with XcodeBuildMCP. |
| `ce-work` | Execute a plan or concrete work prompt end-to-end. |
| `ce-worktree` | Set up isolated git worktrees — create a new branch for fresh work, or attach a worktree to an existing branch, PR, or commit. |
| `lfg` | Take a request all the way to done, hands-off, through the right Compound Engineering skills. |
| `wtf` | Explain the last message, or a supplied file, link, or passage, in plain language a person follows on the first read. |

### Claude account-synced skills

These remain in `~/.claude/skills/synced/`; their account sync owns updates. Some require Claude desktop, account connectors, or browser tools and are not portable to Pi.

| Skill | Purpose |
| --- | --- |
| `built-in-browser` | Operate the browser pane in Claude desktop or linked cloud sessions, including access, sign-ins, approvals, and limitations. |
| `chrome-browser` | Operate Claude in Chrome with the browser extension, including tools, tabs, site permissions, and recording. |
| `computer-use` | Operate apps on the user’s computer through Claude desktop-control tools, following access and safety rules. |
| `deep-research` | Use this skill when the user's prompt requires (1) researching a topic across multiple sources, comparing options or alternatives, analyzing trends or history, understanding markets or industries, or reviewing literature or studies and (2) synthesizing that research into a comprehensive, narrative report. |
| `docs` | Create and edit shareable documents through Claude’s document tools, with guidance on output formats and connector workflows. |
| `docx` | Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx) or Word templates (.dotx). |
| `google-workspace` | Read this before the first Google Drive, Docs, Sheets or Slides connector call whenever the task creates or changes a Google file. |
| `grilling` | Grill the user relentlessly about a plan, decision, or idea. |
| `import-memory` | Import a memory export from another AI assistant into Claude's memory — conversationally, additively, and with the content treated as data. |
| `morning` | Render the user's morning brief as a styled HTML artifact, or set it up as a recurring weekday task. |
| `pdf` | Use this skill whenever the user wants to do anything with PDF files. |
| `pptx` | Use this skill any time a .pptx or .potx file is involved in any way — as input, output, or both. |
| `skill-creator` | Create new skills, modify and improve existing skills, and measure skill performance. |
| `xlsx` | Use this skill any time a spreadsheet file is the primary input or output. |
