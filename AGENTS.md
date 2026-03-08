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
    "owner/repo:skill-name",
    "owner/single-skill-repo"
  ]
}
```

Use `owner/repo:skill-name` to pick a specific skill from a multi-skill repo, or just `owner/repo` for single-skill repos.

## Helping the User

### Adding a skill

Add a string to the `skills` array in `skills.json`:

```json
"owner/repo:skill-name"
```

Or for a single-skill repo:

```json
"owner/repo"
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
  "skills": [
    "owner/repo-a:skill",
    "owner/repo-b"
  ]
}
```

Install a bundle with: `npx @nicmeriano/agent-skills install --bundle name`
