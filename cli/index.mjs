#!/usr/bin/env node

import * as p from "@clack/prompts";
import { execSync } from "node:child_process";

// ── Config ──────────────────────────────────────────────────────────
const REPO = "nicmeriano/agent-skills";
const BRANCH = "main";
const BASE_URL = `https://raw.githubusercontent.com/${REPO}/${BRANCH}`;
const API_URL = `https://api.github.com/repos/${REPO}/contents/bundles?ref=${BRANCH}`;

// ── Parse args ──────────────────────────────────────────────────────
const args = process.argv.slice(2);
const subcommand = args[0] === "install" ? args.shift() : null;

const flags = {
  yes: false,
  dryRun: false,
  scope: "global",
  agents: "claude-code",
  method: "symlink",
  bundle: null,
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
      flags.bundle = args[++i];
      break;
    case "-h":
    case "--help":
      console.log(`Usage: npx @nicmeriano/agent-skills install [options]

Install agent skills from a remote manifest.

Options:
  -y                  Non-interactive, use defaults
  -g                  Global scope (default)
  -p                  Project scope
  -a AGENTS           Comma-separated agents (default: claude-code)
  --copy              Copy instead of symlink
  --dry-run           Show what would be installed
  --bundle NAME       Install from a specific bundle
  -h, --help          Show this help

Examples:
  npx @nicmeriano/agent-skills install              # Interactive
  npx @nicmeriano/agent-skills install -y           # All skills, defaults
  npx @nicmeriano/agent-skills install --bundle frontend
  npx @nicmeriano/agent-skills install --dry-run`);
      process.exit(0);
  }
}

// ── Helpers ─────────────────────────────────────────────────────────
async function fetchJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function parseSkills(manifest) {
  return (manifest.skills ?? []).map((entry) => {
    if (typeof entry === "string") {
      return { source: entry, skill: null, label: entry };
    }
    const label = entry.skill
      ? `${entry.source} :: ${entry.skill}`
      : entry.source;
    return { source: entry.source, skill: entry.skill ?? null, label };
  });
}

function buildCmd(entry) {
  const parts = ["npx", "-y", "skills", "add", entry.source, "--yes"];
  if (flags.scope === "global") parts.push("--global");
  if (flags.method === "copy") parts.push("--copy");
  for (const agent of flags.agents.split(",")) {
    parts.push("--agent", agent.trim());
  }
  if (entry.skill) parts.push("--skill", entry.skill);
  return parts.join(" ");
}

function cancel(msg = "Cancelled.") {
  p.cancel(msg);
  process.exit(0);
}

// ── Main ────────────────────────────────────────────────────────────
p.intro("agent-skills");
const s = p.spinner();

// ── 1. Discover bundles ─────────────────────────────────────────────
let bundleNames = [];

if (!flags.bundle && !flags.yes) {
  s.start("Discovering bundles");
  try {
    const contents = await fetchJSON(API_URL);
    bundleNames = contents
      .filter((f) => f.name.endsWith(".json"))
      .map((f) => f.name.replace(/\.json$/, ""));
    s.stop(`Found ${bundleNames.length} bundle(s)`);
  } catch {
    s.stop("No bundles found");
  }
}

// ── 2. Pick bundle (interactive) ────────────────────────────────────
let manifestPath = "skills.json";

if (!flags.yes && !flags.dryRun && !flags.bundle) {
  const bundleOptions = [
    { value: null, label: "All skills", hint: "skills.json" },
    ...bundleNames.map((name) => ({
      value: name,
      label: name,
      hint: `bundles/${name}.json`,
    })),
  ];

  if (bundleOptions.length > 1) {
    const picked = await p.select({
      message: "Install from:",
      options: bundleOptions,
    });
    if (p.isCancel(picked)) cancel();
    if (picked) manifestPath = `bundles/${picked}.json`;
  }
} else if (flags.bundle) {
  manifestPath = `bundles/${flags.bundle}.json`;
}

// ── 3. Fetch manifest ───────────────────────────────────────────────
s.start(`Fetching ${manifestPath}`);

let skillEntries;
try {
  const manifest = await fetchJSON(`${BASE_URL}/${manifestPath}`);
  skillEntries = parseSkills(manifest);
} catch {
  s.stop(`Failed to fetch ${manifestPath}`);
  cancel("Could not fetch manifest. Check that the repo is public.");
}

if (skillEntries.length === 0) {
  s.stop("No skills found");
  cancel("Manifest is empty.");
}

s.stop(`${skillEntries.length} skill(s) available`);

// ── 4. Pick skills (interactive) ────────────────────────────────────
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

  if (p.isCancel(picked)) cancel();
  selected = picked.map((i) => skillEntries[i]);
}

// ── 5. Configure options (interactive) ──────────────────────────────
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

  if (p.isCancel(options)) cancel();
  flags.scope = options.scope;
  flags.method = options.method;
  flags.agents = options.agents;
}

// ── 6. Install ──────────────────────────────────────────────────────
const total = selected.length;
let succeeded = 0;
const failed = [];

if (flags.dryRun) {
  p.note(
    selected.map((e) => `${e.label}\n  → ${buildCmd(e)}`).join("\n\n"),
    `Dry run — ${total} skill(s)`
  );
} else {
  s.start(`[1/${total}] ${selected[0].label}`);

  for (let i = 0; i < total; i++) {
    const entry = selected[i];
    const cmd = buildCmd(entry);
    const prefix = `[${i + 1}/${total}]`;

    s.message = `${prefix} ${entry.label}`;

    try {
      execSync(cmd, { stdio: "pipe", timeout: 120_000 });
      succeeded++;
    } catch {
      failed.push(entry.label);
    }
  }

  if (failed.length === 0) {
    s.stop(`${succeeded}/${total} skill(s) installed`);
  } else {
    s.stop(`${succeeded}/${total} installed, ${failed.length} failed`);
  }
}

// ── 7. Summary ──────────────────────────────────────────────────────
if (flags.dryRun) {
  p.outro(`${total} skill(s) would be installed.`);
} else if (failed.length > 0) {
  p.log.warn(
    `Failed:\n${failed.map((f) => `  - ${f}`).join("\n")}`
  );
  p.outro(`${succeeded}/${total} skill(s) installed.`);
} else {
  p.outro(`All ${total} skill(s) installed successfully.`);
}
