#!/usr/bin/env node

import * as p from "@clack/prompts";
import { execSync } from "node:child_process";

// ── Config ──────────────────────────────────────────────────────────
const REPO = "nicmeriano/agent-skills";
const BRANCH = "main";
const BASE_URL = `https://raw.githubusercontent.com/${REPO}/${BRANCH}`;

// ── Parse args ──────────────────────────────────────────────────────
const args = process.argv.slice(2);
const flags = {
  yes: false,
  dryRun: false,
  scope: "global",
  agents: "claude-code",
  method: "symlink",
  manifest: "skills.json",
};

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "-y":
      flags.yes = true;
      break;
    case "-g":
      flags.scope = "global";
      break;
    case "-p":
      flags.scope = "project";
      break;
    case "-a":
      flags.agents = args[++i];
      break;
    case "--copy":
      flags.method = "copy";
      break;
    case "--dry-run":
      flags.dryRun = true;
      break;
    case "--bundle":
      flags.manifest = `bundles/${args[++i]}.json`;
      break;
    case "-h":
    case "--help":
      console.log(`Usage: npx agent-skills [options]

Install agent skills from a remote manifest.

Options:
  -y                  Non-interactive, use defaults
  -g                  Global scope (default)
  -p                  Project scope
  -a AGENTS           Comma-separated agents (default: claude-code)
  --copy              Copy instead of symlink
  --dry-run           Show what would be installed
  --bundle NAME       Use a bundle (e.g., --bundle frontend)
  -h, --help          Show this help`);
      process.exit(0);
  }
}

// ── Fetch manifest ──────────────────────────────────────────────────
const manifestUrl = `${BASE_URL}/${flags.manifest}`;

p.intro("agent-skills");

const s = p.spinner();
s.start(`Fetching ${flags.manifest} from ${REPO}`);

let manifest;
try {
  const res = await fetch(manifestUrl);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  manifest = await res.json();
} catch {
  s.stop(`Failed to fetch ${flags.manifest}`);
  p.cancel("Could not fetch manifest. Check that the repo is public.");
  process.exit(1);
}

s.stop(`Fetched ${flags.manifest} from ${REPO}`);

const skills = manifest.skills ?? [];
if (skills.length === 0) {
  p.cancel("No skills found in manifest.");
  process.exit(0);
}

// ── Build skill list ────────────────────────────────────────────────
const skillEntries = skills.map((entry) => {
  if (typeof entry === "string") {
    return { source: entry, skill: null, label: entry };
  }
  const label = entry.skill
    ? `${entry.source} :: ${entry.skill}`
    : entry.source;
  return { source: entry.source, skill: entry.skill ?? null, label };
});

// ── Interactive skill picker ────────────────────────────────────────
let selected = skillEntries;

if (!flags.yes && !flags.dryRun) {
  const picked = await p.multiselect({
    message: "Select skills to install:",
    options: skillEntries.map((e, i) => ({
      value: i,
      label: e.label,
    })),
    initialValues: skillEntries.map((_, i) => i),
    required: true,
  });

  if (p.isCancel(picked)) {
    p.cancel("Cancelled.");
    process.exit(0);
  }

  selected = picked.map((i) => skillEntries[i]);
}

// ── Interactive options ─────────────────────────────────────────────
if (!flags.yes && !flags.dryRun) {
  const options = await p.group({
    scope: () =>
      p.select({
        message: "Scope:",
        options: [
          { value: "global", label: "global" },
          { value: "project", label: "project" },
        ],
        initialValue: flags.scope,
      }),
    method: () =>
      p.select({
        message: "Method:",
        options: [
          { value: "symlink", label: "symlink" },
          { value: "copy", label: "copy" },
        ],
        initialValue: flags.method,
      }),
    agents: () =>
      p.text({
        message: "Agents:",
        initialValue: flags.agents,
        validate: (v) => (!v ? "At least one agent is required" : undefined),
      }),
  });

  if (p.isCancel(options)) {
    p.cancel("Cancelled.");
    process.exit(0);
  }

  flags.scope = options.scope;
  flags.method = options.method;
  flags.agents = options.agents;
}

// ── Build flags ─────────────────────────────────────────────────────
function buildCmd(entry) {
  const parts = ["npx", "-y", "skills", "add", entry.source, "--yes"];

  if (flags.scope === "global") parts.push("--global");
  if (flags.method === "copy") parts.push("--copy");

  for (const agent of flags.agents.split(",")) {
    parts.push("--agent", agent.trim());
  }

  if (entry.skill) {
    parts.push("--skill", entry.skill);
  }

  return parts.join(" ");
}

// ── Install ─────────────────────────────────────────────────────────
const total = selected.length;
let succeeded = 0;
const failed = [];

if (flags.dryRun) {
  p.note(
    selected.map((e) => `${e.label}\n  → ${buildCmd(e)}`).join("\n\n"),
    `Dry run — ${total} skill(s)`
  );
} else {
  for (let i = 0; i < total; i++) {
    const entry = selected[i];
    const cmd = buildCmd(entry);
    const prefix = `[${i + 1}/${total}]`;

    s.start(`${prefix} ${entry.label}`);

    try {
      execSync(cmd, { stdio: "pipe", timeout: 120_000 });
      succeeded++;
      s.stop(`${prefix} ${entry.label} — done`);
    } catch {
      failed.push(entry.label);
      s.stop(`${prefix} ${entry.label} — failed`);
    }
  }
}

// ── Summary ─────────────────────────────────────────────────────────
if (flags.dryRun) {
  p.outro(`${total} skill(s) would be installed.`);
} else if (failed.length === 0) {
  p.outro(`${succeeded}/${total} skill(s) installed successfully.`);
} else {
  p.log.warn(`${failed.length} skill(s) failed:\n${failed.map((f) => `  - ${f}`).join("\n")}`);
  p.outro(`${succeeded}/${total} skill(s) installed successfully.`);
}
