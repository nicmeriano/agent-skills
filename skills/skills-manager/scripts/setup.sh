#!/bin/bash
# Set up an agent-skills repository
# Usage: setup.sh [path]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_deps

# Determine target path
TARGET_PATH="${1:-$(pwd)/agent-skills}"

# Expand ~ if present
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"

# Convert to absolute path
TARGET_PATH="$(cd "$(dirname "$TARGET_PATH")" 2>/dev/null && pwd)/$(basename "$TARGET_PATH")" || TARGET_PATH="$1"

echo "Setting up agent-skills repository at: $TARGET_PATH"
echo ""

# Check if already exists
if [ -d "$TARGET_PATH" ]; then
    if [ -f "$TARGET_PATH/skills-registry.json" ]; then
        echo "Repository already exists at $TARGET_PATH"
        save_config "$TARGET_PATH"
        echo "Done!"
        exit 0
    else
        echo "Directory exists but is not an agent-skills repo."
        echo "Creating structure inside existing directory..."
    fi
else
    echo "Creating directory..."
    mkdir -p "$TARGET_PATH"
fi

# Create structure
mkdir -p "$TARGET_PATH/skills"

# Create skills-registry.json
cat > "$TARGET_PATH/skills-registry.json" << 'EOF'
{
  "skills": {}
}
EOF

# Create README.md
cat > "$TARGET_PATH/README.md" << 'EOF'
# Agent Skills

My personal collection of agent skills and saved skill registry.

## Structure

- `skills/` - Authored and cloned skills
- `skills-registry.json` - Saved/bookmarked remote skills

## Usage

Install skills-manager to manage this repository:

```bash
npx skills add nicmeriano/agent-skills --agent claude-code --yes
```

Then use commands like:
- "save skill" - Bookmark a remote skill
- "clone skill" - Copy a skill to customize
- "install skills" - Install all saved skills
- "list skills" - Show saved skills

## Saved Skills

See `skills-registry.json` for the list of saved remote skills.
EOF

# Create AGENTS.md
cat > "$TARGET_PATH/AGENTS.md" << 'EOF'
# Agent Guide

This repository contains agent skills and a registry of saved remote skills.

## Directory Structure

- `skills/` - Contains skill directories, each with a SKILL.md
- `skills-registry.json` - JSON file tracking saved remote skills

## Working with Skills

Each skill in `skills/` has:
- `SKILL.md` - Required skill definition with YAML frontmatter
- `scripts/` - Optional executable scripts

## Registry Format

```json
{
  "skills": {
    "skill-name": {
      "source": "owner/repo",
      "path": "skills/skill-name",
      "savedAt": "ISO-8601-timestamp"
    }
  }
}
```
EOF

# Create .gitignore
cat > "$TARGET_PATH/.gitignore" << 'EOF'
.DS_Store
node_modules/
*.log
EOF

# Initialize git if not already
if [ ! -d "$TARGET_PATH/.git" ]; then
    echo "Initializing git repository..."
    git -C "$TARGET_PATH" init
fi

# Save config
save_config "$TARGET_PATH"

echo ""
echo "Agent-skills repository created!"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET_PATH"
echo "  2. git remote add origin <your-github-repo-url>"
echo "  3. git add . && git commit -m 'Initial commit'"
echo "  4. git push -u origin main"
