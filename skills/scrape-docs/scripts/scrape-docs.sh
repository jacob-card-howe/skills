#!/bin/bash
# Scrapes a URL to clean text and stores it in ~/.claude/docs/<domain>/<slug>.md
# Uses only macOS built-in tools: curl + textutil + sed
set -euo pipefail

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "Usage: scrape-docs.sh <url>" >&2
  exit 1
fi

# Extract domain and path slug for storage (-E for extended regex on macOS)
DOMAIN=$(echo "$URL" | sed -E 's|https?://||' | cut -d'/' -f1)
PATH_SLUG=$(echo "$URL" | sed -E 's|https?://[^/]*/||; s|[?#].*||; s|/$||; s|/|_|g; s|[^a-zA-Z0-9_.-]||g')
[ -z "$PATH_SLUG" ] && PATH_SLUG="index"

DOCS_DIR="$HOME/.claude/docs/$DOMAIN"
mkdir -p "$DOCS_DIR"
OUTPUT_FILE="$DOCS_DIR/$PATH_SLUG.md"

TMPFILE=$(mktemp)
TMPFILE2=$(mktemp)
trap "rm -f $TMPFILE $TMPFILE2" EXIT

# Fetch the page
curl -sL --max-time 30 -A "Mozilla/5.0" "$URL" > "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
  echo "ERROR: Failed to fetch $URL" >&2
  exit 1
fi

# Phase 1: Strip non-content HTML elements before textutil conversion
# Remove script, style, nav, header, footer, aside, and svg blocks
sed -E '
  # Remove common boilerplate tags and their contents (handles multi-line via loop)
  s/<script[^>]*>.*<\/script>//gi
  s/<style[^>]*>.*<\/style>//gi
  s/<noscript[^>]*>.*<\/noscript>//gi
' "$TMPFILE" > "$TMPFILE2"

# Use perl (macOS built-in) for multi-line tag removal — sed can't span lines
perl -0777 -pe '
  s/<script[^>]*>.*?<\/script>//gsi;
  s/<style[^>]*>.*?<\/style>//gsi;
  s/<noscript[^>]*>.*?<\/noscript>//gsi;
  s/<nav[^>]*>.*?<\/nav>//gsi;
  s/<header[^>]*>.*?<\/header>//gsi;
  s/<footer[^>]*>.*?<\/footer>//gsi;
  s/<aside[^>]*>.*?<\/aside>//gsi;
  s/<svg[^>]*>.*?<\/svg>//gsi;
  s/<!--.*?-->//gs;
' "$TMPFILE2" > "$TMPFILE"

# Phase 2: Convert cleaned HTML to plain text using textutil
{
  echo "# Source: $URL"
  echo "# Scraped: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  textutil -stdin -format html -convert txt -stdout < "$TMPFILE" 2>/dev/null | \
    # Collapse runs of 3+ blank lines to 1
    perl -0777 -pe 's/\n{3,}/\n\n/g' | \
    # Trim trailing whitespace per line
    sed 's/[[:space:]]*$//' | \
    # Remove lines that are just bullet chars or whitespace
    sed -E '/^[[:space:]]*[•◦▪▸►‣⁃·][[:space:]]*$/d'
} > "$OUTPUT_FILE"

# Report
SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
echo "$OUTPUT_FILE ($LINES lines, ${SIZE} bytes)"
