# Agent Guide for agent-skills Repository

This document provides guidance for AI agents working with this repository.

## Repository Purpose

This repository hosts shareable agent skills and includes a registry system for tracking remote skills from GitHub repositories.

## Skill Structure

Each skill lives in its own directory under `skills/`:

```
skills/<skill-name>/
├── SKILL.md           # Required - skill definition with YAML frontmatter
└── scripts/           # Optional - executable scripts the skill can use
    └── *.sh
```

### SKILL.md Format

Every skill must have a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description. Include trigger phrases for when this skill should activate.
---

# Skill Name

Detailed instructions, usage examples, and documentation.
```

The `description` field should include keywords and phrases that help identify when to use the skill.

## Skills Registry

The `skills-registry.json` file tracks remote skills installed via the skills-manager:

```json
{
  "skills": {
    "skill-name": {
      "source": "owner/repo",
      "path": "skills/skill-name",
      "version": "commit-sha",
      "installedAt": "ISO-8601-timestamp"
    }
  }
}
```

## Working with skills-manager

When users ask to manage skills, use the skills-manager skill located at `skills/skills-manager/`.

### Available Commands

| User Request | Action |
|-------------|--------|
| "add skill owner/repo [path]" | Run `scripts/add.sh` |
| "remove skill name" | Run `scripts/remove.sh` |
| "update skills" | Run `scripts/update.sh` |
| "list skills" | Run `scripts/list.sh` |
| "sync skills" | Run `scripts/sync.sh` |

### Script Execution

Scripts are bash files that use `jq` for JSON manipulation. When executing:

1. Run from the repository root directory
2. Pass arguments as positional parameters
3. Scripts will update `skills-registry.json` and call `npx skills` as needed

## Best Practices

1. **Skill Naming**: Use lowercase, hyphenated names (e.g., `react-best-practices`)
2. **Descriptions**: Include common trigger phrases users might say
3. **Scripts**: Keep scripts focused and idempotent when possible
4. **Registry**: Never manually edit `skills-registry.json` - use skills-manager
5. **Commits**: When modifying skills, use descriptive commit messages

## File Locations

- **Registry**: `/skills-registry.json`
- **Skills**: `/skills/<skill-name>/SKILL.md`
- **Scripts**: `/skills/<skill-name>/scripts/*.sh`
