# Agent Skills

A collection of shareable skills for AI coding agents, with a registry system for managing remote skills from [skills.sh](https://skills.sh).

## Installation

```bash
npx skills add nicomeriano/agent-skills
```

This installs all skills from this repository, including the `skills-manager` for managing additional remote skills.

## Skills Included

### skills-manager

Manage your skills registry - add, remove, update, and sync skills from any GitHub repository.

**Commands:**
- **Add a skill**: "add skill vercel-labs/agent-skills react-best-practices"
- **Remove a skill**: "remove skill react-best-practices"
- **Update skills**: "update skills" or "update skill react-best-practices"
- **List skills**: "list skills"
- **Sync skills**: "sync skills" (installs all skills from registry)

## Using the Skills Registry

The `skills-registry.json` file tracks remote skills you've added. When you set up a new machine:

1. Clone this repository
2. Run `npx skills add nicomeriano/agent-skills` to install the skills-manager
3. Ask your AI agent to "sync skills from registry"

The agent will read your registry and install all tracked skills.

## Adding Your Own Skills

1. Fork this repository
2. Add new skills under `skills/<skill-name>/SKILL.md`
3. Optionally add scripts under `skills/<skill-name>/scripts/`
4. Update the README to document your skills

## Registry Format

```json
{
  "skills": {
    "skill-name": {
      "source": "owner/repo",
      "path": "skills/skill-name",
      "version": "abc1234",
      "installedAt": "2025-01-21T00:00:00Z"
    }
  }
}
```
