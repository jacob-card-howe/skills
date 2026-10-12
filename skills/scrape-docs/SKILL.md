---
name: scrape-docs
description: Scrape documentation from URLs and store locally for fast, token-efficient reference. Use when the user provides documentation URLs to save.
allowed-tools: Bash, Read, Write, Glob, Grep, WebFetch
argument-hint: "<url> [url2] [url3...]"
---

Scrape documentation from the provided URL(s) and store them in `~/.claude/docs/` for future grep-based lookups.

## Process

For each URL in `$ARGUMENTS`:

1. **Run the scrape script**:
   ```
   <skill-base-dir>/scripts/scrape-docs.sh <url>
   ```
   Resolve `<skill-base-dir>` to this skill's loaded directory in either Pi or Claude.
   The script fetches the page, converts HTML to clean text via `textutil` (macOS built-in), and saves to `~/.claude/docs/<domain>/<path-slug>.md`.

2. **Verify the output** — read the first 20 lines to confirm it captured real content (not a login wall, CAPTCHA, or empty page).

3. **If the script fails or content is poor**, fall back to WebFetch:
   - Fetch the URL with WebFetch using the prompt: "Extract the complete technical documentation content verbatim. Preserve all code examples, CLI commands, API references, configuration options, and parameter descriptions. Remove navigation, sidebars, footers, cookie banners, and marketing copy. Output clean markdown."
   - Write the result to `~/.claude/docs/<domain>/<path-slug>.md`

4. **Report what was saved**: file path, line count, and a 1-sentence summary of the content.

## Multi-page scraping

If the user provides a docs index page or asks to scrape "all of" a docs site:
- Scrape the index page first
- Extract internal links that point to subpages within the same docs section
- Scrape each subpage (up to 20 pages max unless the user says otherwise)
- Report the total number of pages scraped

## Storage Convention

```
~/.claude/docs/
├── docs.example.com/
│   ├── index.md
│   ├── api_reference.md
│   ├── getting-started.md
│   └── configuration_options.md
├── kubernetes.io/
│   └── docs_concepts_pods.md
```

After scraping, remind the user they can search stored docs with `/search-docs <query>`.
