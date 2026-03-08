# Agent Skills

A portable manifest of skills for AI coding agents. Define your skills once, install them anywhere.

```bash
npx @nicmeriano/agent-skills install
```

Browse available skills at [skills.sh](https://skills.sh).

## How it works

`skills.json` defines which skills to install. Run the CLI and it walks you through selecting skills, picking agents (Claude Code, Cursor, Windsurf, etc.), and configuring install options.

```json
{
  "skills": [
    "anthropics/skills:frontend-design",
    "vercel-labs/agent-skills:vercel-react-best-practices",
    "ibelick/ui-skills"
  ]
}
```

Use `owner/repo:skill-name` to pick a specific skill from a multi-skill repo, or just `owner/repo` for single-skill repos.

## Options

```bash
npx @nicmeriano/agent-skills install              # Interactive
npx @nicmeriano/agent-skills install -y           # Non-interactive, defaults
npx @nicmeriano/agent-skills install --dry-run    # Preview without installing
npx @nicmeriano/agent-skills install --bundle frontend
npx @nicmeriano/agent-skills install -p           # Project scope (default: global)
npx @nicmeriano/agent-skills install --copy       # Copy instead of symlink
```

## Bundles

Group skills into presets under `bundles/`. Same format as `skills.json` with an optional `description` field.

```bash
npx @nicmeriano/agent-skills install --bundle frontend
```

## Custom skills

Add your own skills under `skills/<name>/SKILL.md` and include your repo in `skills.json` to install them alongside everything else.
