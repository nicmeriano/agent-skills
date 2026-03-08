# Agent Guide

## Repo Structure

```
skills.json       # Manifest of skills to install (fetched from GitHub)
cli/              # Node.js CLI (npx @nicmeriano/agent-skills install)
bundles/          # Grouped presets (same format as skills.json)
skills/           # Local custom skills
```

## skills.json Format

```json
{
  "skills": [
    "owner/repo",
    {
      "source": "org/multi-skill-repo",
      "skill": "specific-skill-name"
    }
  ]
}
```

Entries can be strings (shorthand) or objects (when selecting a specific skill from a multi-skill repo). The user's own repo can be listed to install custom skills.

## Helping the User

### Adding a skill

Add a string or object entry to the `skills` array in `skills.json`:

```json
"owner/repo"
```

Or for a specific skill within a repo:

```json
{
  "source": "owner/repo",
  "skill": "skill-name"
}
```

### Removing a skill

Remove the entry from the `skills` array in `skills.json`.

### Running install

```bash
# Interactive (pick bundle, select skills, configure options)
npx @nicmeriano/agent-skills install

# Non-interactive
npx @nicmeriano/agent-skills install -y

# Preview
npx @nicmeriano/agent-skills install --dry-run
```

### Creating a bundle

Create a new JSON file in `bundles/` with the same format as `skills.json`, plus an optional `description` field:

```json
{
  "description": "Frontend development skills",
  "skills": ["owner/repo-a", "owner/repo-b"]
}
```

Install a bundle with: `npx @nicmeriano/agent-skills install --bundle name`
