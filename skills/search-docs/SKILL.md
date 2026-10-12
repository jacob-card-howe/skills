---
name: search-docs
description: Search through locally stored documentation scraped via /scrape-docs. Fast, zero-token-waste alternative to browsing docs online.
allowed-tools: Grep, Glob, Read
argument-hint: "<search query> [--domain example.com]"
---

Search the local documentation store at `~/.claude/docs/` for content matching the user's query.

## Process

1. **Parse the query** from `$ARGUMENTS`. If `--domain <domain>` is specified, restrict search to that domain's directory.

2. **Search with Grep**:
   - Use `Grep` with the search pattern against `~/.claude/docs/`
   - Use `output_mode: "content"` with `-C 5` for surrounding context
   - If the query has multiple words, try the full phrase first, then fall back to individual key terms

3. **Present results**:
   - Show matching lines with file paths and line numbers
   - Group results by source document
   - Include the source URL from the file header (first line: `# Source: <url>`)
   - Keep output concise — show the most relevant matches first, max 10 results unless the user asks for more

4. **If no results found**:
   - List available domains/files with `Glob` on `~/.claude/docs/**/*.md`
   - Suggest the user scrape the relevant docs with `/scrape-docs <url>`

## Example Output

```
## Results for "resource limits" (3 matches)

### kubernetes.io/docs_concepts_containers.md
Source: https://kubernetes.io/docs/concepts/containers/
Lines 45-52:
  > Resource limits define the maximum CPU and memory a container can use.
  > spec.containers[].resources.limits.cpu: "500m"
  > spec.containers[].resources.limits.memory: "128Mi"

### docs.example.com/helm-values.md
Source: https://docs.example.com/helm-values
Lines 112-115:
  > resources:
  >   limits: { cpu: 1, memory: 512Mi }
```
