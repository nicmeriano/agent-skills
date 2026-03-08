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
   npx @nicmeriano/agent-skills install
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
npx @nicmeriano/agent-skills install --bundle frontend
```

Same format as `skills.json`, with an optional `description` field.

## Install Options

```bash
npx @nicmeriano/agent-skills install              # Interactive: pick bundle, skills, configure
npx @nicmeriano/agent-skills install -y           # All skills with defaults
npx @nicmeriano/agent-skills install --bundle frontend
npx @nicmeriano/agent-skills install --dry-run    # Preview what would be installed
npx @nicmeriano/agent-skills install -a "claude-code,cursor"
npx @nicmeriano/agent-skills install --copy       # Copy instead of symlink
npx @nicmeriano/agent-skills install -p           # Project scope instead of global
```

**Defaults** (when using `-y`): global scope, claude-code agent, symlink method.

## Dependencies

Node.js 18+ (no other dependencies).

## Custom Skills

Author your own skills by adding them under `skills/<skill-name>/SKILL.md`. Include your repo in `skills.json` to install them alongside everything else.

## Forking

1. Fork this repo
2. Update `REPO` in `cli/index.mjs` to your GitHub username/repo
3. Publish to npm under your own scope
4. Edit `skills.json` with your preferred skills
