# Agent Skills

Dotfiles for AI agents. A portable manifest of agent skills that can be installed on any machine.

## Quick Start

1. Fork this repository
2. Edit `skills.json` to list the skills you want:
   ```json
   {
     "skills": [
       "nicmeriano/agent-skills",
       "other-author/cool-skill"
     ]
   }
   ```
3. Install on any machine:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/nicmeriano/agent-skills/main/install.sh | bash -s -- -y
   ```

Browse available skills at [skills.sh](https://skills.sh).

## Manifest Format

`skills.json` lists the skills you want installed. Entries can be:

- **String** — shorthand for a single-skill repo: `"owner/repo"`
- **Object** — when you need to pick a specific skill from a multi-skill repo:
  ```json
  {
    "source": "org/multi-skill-repo",
    "skill": "specific-skill-name"
  }
  ```

You can include your own repo to install your custom skills alongside third-party ones.

## Bundles

Bundles are alternate manifests for grouped presets. Store them in `bundles/`:

```bash
curl -fsSL https://raw.githubusercontent.com/nicmeriano/agent-skills/main/install.sh | bash -s -- --bundle frontend -y
```

Same format as `skills.json`, with an optional `description` field.

## Install Options

```bash
# Run directly
./install.sh -y                       # Non-interactive, use defaults
./install.sh --bundle frontend        # Install from bundles/frontend.json
./install.sh --dry-run                # Preview what would be installed
./install.sh -a "claude-code,cursor"  # Specify agents
./install.sh --copy                   # Copy instead of symlink
./install.sh -p                       # Project scope instead of global

# Run remotely (no clone needed)
curl -fsSL .../install.sh | bash -s -- -y
curl -fsSL .../install.sh | bash -s -- --bundle frontend -y
curl -fsSL .../install.sh | bash -s -- --dry-run
```

**Defaults** (when using `-y` or pressing enter on prompts): global scope, claude-code agent, symlink method.

## Custom Skills

Author your own skills by adding them under `skills/<skill-name>/SKILL.md`. Include your repo in `skills.json` to install them alongside everything else.

## Forking

1. Fork this repo
2. Update `REPO` at the top of `install.sh` to your GitHub username/repo
3. Edit `skills.json` with your preferred skills
4. Update the curl URLs in this README
