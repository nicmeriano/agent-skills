#!/usr/bin/env bash
set -euo pipefail

# install.sh - Install agent skills from a remote manifest
# Usage: curl -fsSL https://raw.githubusercontent.com/nicmeriano/agent-skills/main/install.sh | bash -s -- -y
#    or: npx agent-skills (interactive)

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
Usage: curl -fsSL .../install.sh | bash -s -- [options]
   or: npx agent-skills (interactive mode with skill picker)

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
  curl -fsSL .../install.sh | bash -s -- -y       # Install all with defaults
  ./install.sh --dry-run                           # Preview what would be installed
  ./install.sh -a "claude-code,cursor"             # Install for multiple agents
  npx agent-skills                                 # Interactive skill picker
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

# Prompt for options if interactive
if [[ "$NON_INTERACTIVE" == false && "$DRY_RUN" == false ]]; then
  read -r -p "Scope: [global]/project? " scope_input
  if [[ -n "$scope_input" ]]; then
    SCOPE="$scope_input"
  fi

  read -r -p "Agents [claude-code]: " agents_input
  if [[ -n "$agents_input" ]]; then
    AGENTS="$agents_input"
  fi

  read -r -p "Method: [symlink]/copy? " method_input
  if [[ -n "$method_input" ]]; then
    METHOD="$method_input"
  fi

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

echo "Installing $SKILLS_COUNT skill(s) from $MANIFEST..."
if [[ "$DRY_RUN" == true ]]; then
  echo "(dry run - no changes will be made)"
fi
echo ""

# Install each skill
SUCCEEDED=0
FAILED=0
FAILED_SKILLS=""

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
    LABEL="$SOURCE"
    if [[ -n "$SKILL_NAME" ]]; then
      SKILL_FLAG="--skill $SKILL_NAME"
      LABEL="$SOURCE :: $SKILL_NAME"
    fi
  fi

  INDEX=$((i + 1))

  # Build command
  CMD="npx -y skills add $SOURCE --yes $SCOPE_FLAG $AGENT_FLAGS $METHOD_FLAG $SKILL_FLAG"
  CMD=$(echo "$CMD" | tr -s ' ')

  if [[ "$DRY_RUN" == true ]]; then
    echo "[$INDEX/$SKILLS_COUNT] $LABEL"
    echo "  → $CMD"
  else
    printf "[$INDEX/$SKILLS_COUNT] $LABEL ... "
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
  echo "Dry run complete. $SKILLS_COUNT skill(s) would be installed."
else
  echo "Done! $SUCCEEDED/$SKILLS_COUNT skill(s) installed successfully."
  if [[ "$FAILED" -gt 0 ]]; then
    echo "$FAILED skill(s) failed:"
    echo -e "$FAILED_SKILLS"
  fi
fi
