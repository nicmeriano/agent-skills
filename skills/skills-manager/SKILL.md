---
name: skills-manager
description: Manage agent skills registry - add, remove, update, and sync skills from skills.sh. Use when user wants to: (1) add/install a new skill from GitHub, (2) update skills to latest versions, (3) remove skills, (4) list installed skills, (5) sync skills on a new machine. Triggers on "add skill", "install skill", "update skills", "remove skill", "list skills", "sync skills", "skill registry".
---

# Skills Manager

Manage your agent skills registry. This skill helps you add, remove, update, and sync skills from GitHub repositories using the skills.sh ecosystem.

## Registry Format

The `skills-registry.json` file at the repository root tracks all remote skills:

```json
{
  "skills": {
    "skill-name": {
      "source": "owner/repo",
      "path": "skills/skill-name",
      "version": "commit-sha",
      "installedAt": "2025-01-21T00:00:00Z"
    }
  }
}
```

## Commands

### Add a Skill

Add a skill from a GitHub repository to your registry and install it locally.

```bash
# Add skill from repo root
./skills/skills-manager/scripts/add.sh owner/repo

# Add skill from specific path
./skills/skills-manager/scripts/add.sh owner/repo skills/skill-name
```

**User phrases**: "add skill", "install skill", "get skill"

### Remove a Skill

Remove a skill from your registry.

```bash
./skills/skills-manager/scripts/remove.sh skill-name
```

**User phrases**: "remove skill", "delete skill", "uninstall skill"

### Update Skills

Update one or all skills to their latest versions.

```bash
# Update all skills
./skills/skills-manager/scripts/update.sh

# Update specific skill
./skills/skills-manager/scripts/update.sh skill-name
```

**User phrases**: "update skills", "update skill", "upgrade skills"

### List Skills

Show all registered skills with their versions and status.

```bash
./skills/skills-manager/scripts/list.sh
```

**User phrases**: "list skills", "show skills", "what skills"

### Sync Skills

Install all skills from the registry. Use this when setting up a new machine or after cloning your repository.

```bash
./skills/skills-manager/scripts/sync.sh
```

**User phrases**: "sync skills", "install all skills", "sync registry"

## How It Works

1. **Adding**: The script fetches skill info from GitHub, adds an entry to `skills-registry.json`, and runs `npx skills add` to install locally
2. **Removing**: Removes the entry from the registry (local skill files remain until manually deleted)
3. **Updating**: Checks for newer commits, updates the registry version, and reinstalls
4. **Syncing**: Reads the registry and installs each skill via `npx skills add`

## Requirements

- `jq` for JSON manipulation
- `curl` for GitHub API calls
- `npx` for skills CLI

## Example Workflow

```bash
# Add a React best practices skill
./skills/skills-manager/scripts/add.sh vercel-labs/agent-skills skills/react-best-practices

# Check what's installed
./skills/skills-manager/scripts/list.sh

# Later, update everything
./skills/skills-manager/scripts/update.sh

# On a new machine, sync from registry
./skills/skills-manager/scripts/sync.sh
```
