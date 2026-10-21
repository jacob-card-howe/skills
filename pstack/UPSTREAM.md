# pstack, adapted for Pi

This directory is a fork of [cursor/plugins → pstack](https://github.com/cursor/plugins/tree/main/pstack)
by Lauren Tan (poteto), MIT licensed. The `LICENSE` beside this file is upstream's.

```text
upstream   github.com/cursor/plugins, path pstack/
version    0.15.29
commit     190d28736eff128ec94f502a22c7fe0c4b56cd37 (2026-10-20)
forked     2026-10-21
skills     55 of 56
```

## What is here

| Path | Contents |
| --- | --- |
| `skills/` | The 55 skills, adapted to Pi. Each is a directory with `SKILL.md`. |
| `agents/` | `poteto-agent` and `comment-sicko`, as Pi subagent definitions. |
| `LICENSE` | Upstream MIT license. |

`skills/poteto-mode/scripts/` keeps upstream's tooling unchanged: `orch/`, `watch-pr/`,
`check-plan.mjs`, and `worktree-audit.sh`. `watch-pr` needs `gh`; `orch` and the Bun
tests need `bun`. Nothing in them is Cursor-specific.

## Not vendored

| Upstream path | Why |
| --- | --- |
| `skills/make-bot-ui/` | Wakes a Grok Bot over a webhook, with a Tailscale handoff. Foreign infrastructure with no Pi equivalent. |
| `automations/benny/` | Cursor Automations pack. Upstream never registers it as skills. |
| `docs/`, `assets/`, `README.md` | Prose documentation, not agent instructions. Skill links point at the upstream GitHub URLs instead. |
| `.cursor-plugin/`, `plugin.json` | Cursor plugin manifests. Pi loads this directory directly. |

## How it loads in Pi

`link-skills.sh` at the repository root creates one symlink,
`~/.pi/agent/skills/pstack → <repo>/pstack/skills`, plus one per file in `agents/` into
`~/.pi/agent/agents/`. Pi discovers skills recursively and follows symlinked directories,
so every skill under `pstack/skills/` registers by the `name` in its own frontmatter.

Nothing links into `~/.claude`. These skills name Pi's tools, agents, and config paths, so
they would mislead Claude.

**All 55 skills set `disable-model-invocation: true`, and that is a hard requirement here.**
Pi filters disabled skills out of the system prompt entirely, so the model cannot see or
select any of them. Every pstack skill runs only when the operator types `/skill:<name>`.
If you add or re-import a skill, keep that field, or it re-enters automatic selection.

## What changed from upstream

Frontmatter, tool names, and paths, plus the Cursor-only steps. The reasoning, the
playbooks, and the principles are upstream's, unchanged.

| Cursor | Pi here |
| --- | --- |
| `Task` tool, `subagent_type` | `subagent` tool, `agent:` |
| `subagent_type: poteto-agent` | `agent: "poteto-agent"` |
| `generalPurpose`, `readonly: false` | `agent: "delegate"` |
| `generalPurpose`, `readonly: true` | `agent: "scout"`, brief says "do not edit files" |
| `run_in_background: true` | `async: true` |
| `environment: "cloud"`, `cloud_base_branch` | `worktree: true`, and the branch named in the brief |
| `AskQuestion` | the `ask_user` tool |
| `/name` | `/skill:name` |
| Model slugs, e.g. `grok-4.7-xhigh-fast`, `claude-opus-5-5-xhigh`, plus `-fast` speeds | An exact `provider/id` with an optional `:level` suffix, from `~/.pi/agent/pstack-models.md` |
| `~/.cursor/rules/pstack-models.mdc`, `alwaysApply: true` | `~/.pi/agent/pstack-models.md`, plain Markdown |
| `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.pi/agent/sessions/<slug>/*.jsonl` |
| `.cursor/skills/`, `~/.cursor/skills/` | `.pi/skills/`, `~/.pi/agent/skills/` |
| `icon:`, `color:`, `paths:` frontmatter | Dropped. Pi does not read them. |
| `../references/bugbot-triage.md` | `../references/bot-review-triage.md`, generalized to any review bot |

`setup-pstack` was rewritten. It reads `enabledModels`, `defaultModel`, and
`subagents.agentOverrides` out of `~/.pi/agent/settings.json`, seeds each role from that
configuration, asks for a reasoning budget through `ask_user`, and writes the role file.
A role with no line omits `model` and inherits the parent chat model. It also sets
`disable-model-invocation: true` on itself, which upstream does not.

### Cursor-only, marked `Skipped in Pi.`

`Bugbot` triage stays as guidance, generalized to any PR review bot. These do not:

| Cursor feature | Replacement |
| --- | --- |
| `deslop` skill, `/deslop` | None. `unslop` covers prose, `no-comments` covers comments. |
| `control-cli`, `control-ui` | A project-local `verify-*` skill from `create-verification-skill`. |
| `/loop` | A background watcher subagent, or a cadence and predicate named in the reply. `subagent({ action: "schedule" })` when a durable tick is wanted. |
| `create-skill` | `skills/poteto-mode/playbooks/authoring-a-skill.md`, plus Pi's `docs/skills.md`. |
| Bugbot, Automations, cloud agents, cloud-agent URLs | None. Autonomy runs as background subagents in git worktrees. |
| Custom Modes | None. Each task starts with `/skill:poteto-mode`. |

## Known gaps

- **Read-only children are not enforced.** Pi sets a child's tools per agent, not per
  launch, and no launch flag makes one read-only. `scout` carries `write`. The briefs say
  "do not edit files" and the playbooks check `git status` after, which is the same
  compromise upstream's Claude Code adapter documents. `comment-sicko` is enforced with a
  `tools:` allowlist that excludes `edit` and `write`.
- **No always-applied rule file.** Cursor and Claude Code both load an always-applied rules
  file, so upstream never had to say "read the models file". Pi has no equivalent that is
  safe to generate into (`AGENTS.md` is hand-maintained), so `poteto-mode`'s Subagents
  section and each routed skill read `~/.pi/agent/pstack-models.md` explicitly at their
  spawn site.
- **Subagent transcripts.** The playbooks that read a child's transcript use
  `subagent({ action: "status", options: { view: "transcript" } })` where possible. One
  `eval` line also names `~/.pi/agent/sessions/<slug>/<session-id>/<run-id>/run-0/session.jsonl`,
  which is Pi's current on-disk layout and may change.
- **Path-glob auto-attach.** Cursor's `paths:` frontmatter is gone, so
  `typescript-best-practices` no longer attaches itself to `.ts` files. It is
  invoke-only, like every other skill here.
- **Model diversity is opt-in.** Upstream hardcodes panel models so the seats disagree by
  default. Here a role with no line inherits the parent model, so a fresh install runs the
  arena, swarm, and interrogate panels on one model until `/skill:setup-pstack` sets them.

## Updating from upstream

```sh
cd /tmp && rm -rf cursor-plugins
git clone --depth 1 --filter=blob:none --sparse https://github.com/cursor/plugins.git cursor-plugins
cd cursor-plugins && git sparse-checkout set pstack
git log -1 --format='%H %cs'   # record in this file
diff -ru cursor-plugins/pstack/skills ~/Work/skills/pstack/skills
```

Then apply the same substitutions listed above to whatever changed, bump the version and
commit in this file, and re-run `bash ~/Work/skills/link-skills.sh`. Diffing is the point:
upstream is actively developed, and this fork only tracks it by hand.
