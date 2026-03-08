#!/usr/bin/env bash
set -euo pipefail

# install.sh - Install agent skills from a remote manifest
# Usage: curl -fsSL https://raw.githubusercontent.com/nicmeriano/agent-skills/main/install.sh | bash
#    or: ./install.sh [options]

# ── Configure for your fork ──────────────────────────────────────────
REPO="nicmeriano/agent-skills"
BRANCH="main"
# ─────────────────────────────────────────────────────────────────────

BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
MANIFEST="skills.json"
SCOPE="global"
AGENTS="claude-code"
METHOD="symlink"
DRY_RUN=false
NON_INTERACTIVE=false

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]
   or: curl -fsSL https://raw.githubusercontent.com/REPO/BRANCH/install.sh | bash -s -- [options]

Install agent skills from a remote manifest hosted on GitHub.

Options:
  -y                  Non-interactive, use defaults
  -g                  Global scope (default)
  -p                  Project scope
  -a AGENTS           Comma-separated agents (default: claude-code)
  --copy              Copy instead of symlink
  --dry-run           Show what would be installed without installing
  --bundle NAME       Use a bundle instead of skills.json (e.g., --bundle frontend)
  -h, --help          Show this help message

Examples:
  ./install.sh                          # Interactive: pick skills, configure options
  ./install.sh -y                       # Install with defaults (global, claude-code, symlink)
  ./install.sh --bundle frontend        # Install from bundles/frontend.json
  ./install.sh --dry-run                # Preview what would be installed
  ./install.sh -a "claude-code,cursor"  # Install for multiple agents

Dependencies:
  Required: jq, npx
  Interactive mode: gum (brew install gum)
USAGE
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    -y) NON_INTERACTIVE=true; shift ;;
    -g) SCOPE="global"; shift ;;
    -p) SCOPE="project"; shift ;;
    -a) AGENTS="$2"; shift 2 ;;
    --copy) METHOD="copy"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --bundle) MANIFEST="bundles/$2.json"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Check dependencies
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  echo "Install it with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

if ! command -v npx &>/dev/null; then
  echo "Error: npx is required but not installed."
  echo "Install Node.js from https://nodejs.org"
  exit 1
fi

if [[ "$NON_INTERACTIVE" == false && "$DRY_RUN" == false ]]; then
  if ! command -v gum &>/dev/null; then
    echo "Error: gum is required for interactive mode."
    echo "Install it with: brew install gum (macOS) or see https://github.com/charmbracelet/gum"
    echo "Or use -y for non-interactive mode with defaults."
    exit 1
  fi
fi

# Fetch manifest from GitHub
MANIFEST_URL="$BASE_URL/$MANIFEST"
echo "Fetching $MANIFEST from $REPO..."

MANIFEST_CONTENT=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null) || {
  echo "Error: Could not fetch manifest from $MANIFEST_URL"
  echo "Check that the file exists and the repository is public."
  exit 1
}

# Read skills from manifest
SKILLS_COUNT=$(echo "$MANIFEST_CONTENT" | jq '.skills | length')

if [[ "$SKILLS_COUNT" -eq 0 ]]; then
  echo "No skills to install. Add skills to $MANIFEST first."
  exit 0
fi

# Build skill labels for display
SKILL_LABELS=()
SKILL_SOURCES=()
SKILL_FLAGS=()

for i in $(seq 0 $((SKILLS_COUNT - 1))); do
  ENTRY_TYPE=$(echo "$MANIFEST_CONTENT" | jq -r ".skills[$i] | type")

  if [[ "$ENTRY_TYPE" == "string" ]]; then
    SOURCE=$(echo "$MANIFEST_CONTENT" | jq -r ".skills[$i]")
    SKILL_FLAG=""
    LABEL="$SOURCE"
  else
    SOURCE=$(echo "$MANIFEST_CONTENT" | jq -r ".skills[$i].source")
    SKILL_NAME=$(echo "$MANIFEST_CONTENT" | jq -r ".skills[$i].skill // empty")
    SKILL_FLAG=""
    if [[ -n "$SKILL_NAME" ]]; then
      SKILL_FLAG="--skill $SKILL_NAME"
      LABEL="$SOURCE :: $SKILL_NAME"
    else
      LABEL="$SOURCE"
    fi
  fi

  SKILL_LABELS+=("$LABEL")
  SKILL_SOURCES+=("$SOURCE")
  SKILL_FLAGS+=("$SKILL_FLAG")
done

# ── Interactive skill picker ─────────────────────────────────────────
SELECTED_INDICES=()

if [[ "$NON_INTERACTIVE" == false && "$DRY_RUN" == false ]]; then
  # Build comma-separated list of all labels for pre-selection
  ALL_LABELS_CSV=""
  for label in "${SKILL_LABELS[@]}"; do
    if [[ -n "$ALL_LABELS_CSV" ]]; then
      ALL_LABELS_CSV="$ALL_LABELS_CSV,$label"
    else
      ALL_LABELS_CSV="$label"
    fi
  done

  echo ""
  SELECTED=$(gum choose --no-limit \
    --header "Select skills to install:" \
    --selected="$ALL_LABELS_CSV" \
    "${SKILL_LABELS[@]}") || {
    echo "No skills selected. Exiting."
    exit 0
  }

  # Map selected labels back to indices
  while IFS= read -r selected_label; do
    for i in $(seq 0 $((SKILLS_COUNT - 1))); do
      if [[ "${SKILL_LABELS[$i]}" == "$selected_label" ]]; then
        SELECTED_INDICES+=("$i")
      fi
    done
  done <<< "$SELECTED"
else
  # Non-interactive or dry-run: select all
  for i in $(seq 0 $((SKILLS_COUNT - 1))); do
    SELECTED_INDICES+=("$i")
  done
fi

SELECTED_COUNT=${#SELECTED_INDICES[@]}

if [[ "$SELECTED_COUNT" -eq 0 ]]; then
  echo "No skills selected. Exiting."
  exit 0
fi

# ── Interactive options ──────────────────────────────────────────────
if [[ "$NON_INTERACTIVE" == false && "$DRY_RUN" == false ]]; then
  echo ""
  SCOPE=$(gum choose --header "Scope:" "global" "project")
  METHOD=$(gum choose --header "Method:" "symlink" "copy")
  AGENTS=$(gum input --header "Agents:" --value "claude-code")
  echo ""
fi

# Build scope flag
SCOPE_FLAG=""
if [[ "$SCOPE" == "global" ]]; then
  SCOPE_FLAG="--global"
fi

# Build method flag
METHOD_FLAG=""
if [[ "$METHOD" == "copy" ]]; then
  METHOD_FLAG="--copy"
fi

# Build agent flags
AGENT_FLAGS=""
IFS=',' read -ra AGENT_LIST <<< "$AGENTS"
for agent in "${AGENT_LIST[@]}"; do
  AGENT_FLAGS="$AGENT_FLAGS --agent $agent"
done

# ── Install ──────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == false ]]; then
  echo "Installing $SELECTED_COUNT skill(s) from $MANIFEST..."
else
  echo "Installing $SELECTED_COUNT skill(s) from $MANIFEST..."
  echo "(dry run - no changes will be made)"
fi
echo ""

SUCCEEDED=0
FAILED=0
FAILED_SKILLS=""
CURRENT=0

for i in "${SELECTED_INDICES[@]}"; do
  CURRENT=$((CURRENT + 1))
  SOURCE="${SKILL_SOURCES[$i]}"
  SKILL_FLAG="${SKILL_FLAGS[$i]}"
  LABEL="${SKILL_LABELS[$i]}"

  # Build command
  CMD="npx -y skills add $SOURCE --yes $SCOPE_FLAG $AGENT_FLAGS $METHOD_FLAG $SKILL_FLAG"
  CMD=$(echo "$CMD" | tr -s ' ')

  if [[ "$DRY_RUN" == true ]]; then
    echo "[$CURRENT/$SELECTED_COUNT] $LABEL"
    echo "  → $CMD"
  elif [[ "$NON_INTERACTIVE" == false ]]; then
    # Interactive: use gum spin for a spinner
    if gum spin --title "[$CURRENT/$SELECTED_COUNT] $LABEL" -- \
      bash -c "$CMD &>/dev/null"; then
      SUCCEEDED=$((SUCCEEDED + 1))
      echo "[$CURRENT/$SELECTED_COUNT] $LABEL ... done"
    else
      FAILED=$((FAILED + 1))
      FAILED_SKILLS="$FAILED_SKILLS  - $LABEL\n"
      echo "[$CURRENT/$SELECTED_COUNT] $LABEL ... failed"
    fi
  else
    # Non-interactive: simple progress line
    printf "[$CURRENT/$SELECTED_COUNT] $LABEL ... "
    if eval "$CMD" &>/dev/null; then
      SUCCEEDED=$((SUCCEEDED + 1))
      echo "done"
    else
      FAILED=$((FAILED + 1))
      FAILED_SKILLS="$FAILED_SKILLS  - $LABEL\n"
      echo "failed"
    fi
  fi
done

# Summary
echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. $SELECTED_COUNT skill(s) would be installed."
else
  echo "Done! $SUCCEEDED/$SELECTED_COUNT skill(s) installed successfully."
  if [[ "$FAILED" -gt 0 ]]; then
    echo "$FAILED skill(s) failed:"
    echo -e "$FAILED_SKILLS"
  fi
fi
