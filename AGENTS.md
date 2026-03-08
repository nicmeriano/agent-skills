# Agent Guide

## Repo Structure

```
skills.json       # Manifest of skills to install (fetched from GitHub)
install.sh        # Bash installer for curl | bash (non-interactive)
cli/              # Node.js CLI for interactive installs (npx agent-skills)
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
# Interactive (skill picker + options)
npx agent-skills

# Non-interactive (no clone needed)
curl -fsSL https://raw.githubusercontent.com/nicmeriano/agent-skills/main/install.sh | bash -s -- -y

# Preview
npx agent-skills --dry-run
./install.sh --dry-run
```

### Creating a bundle

Create a new JSON file in `bundles/` with the same format as `skills.json`, plus an optional `description` field:

```json
{
  "description": "Frontend development skills",
  "skills": ["owner/repo-a", "owner/repo-b"]
}
```

Install a bundle with: `./install.sh --bundle name`
