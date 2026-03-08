#!/usr/bin/env node

import * as p from "@clack/prompts";
import { exec } from "node:child_process";

// ── Config ──────────────────────────────────────────────────────────
const REPO = "nicmeriano/agent-skills";
const BRANCH = "main";
const BASE_URL = `https://raw.githubusercontent.com/${REPO}/${BRANCH}`;
const API_URL = `https://api.github.com/repos/${REPO}/contents/bundles?ref=${BRANCH}`;

const AGENTS = [
  { value: "claude-code", label: "Claude Code" },
  { value: "cursor", label: "Cursor" },
  { value: "windsurf", label: "Windsurf" },
  { value: "cline", label: "Cline" },
  { value: "codex", label: "Codex" },
  { value: "github-copilot", label: "GitHub Copilot" },
  { value: "amp", label: "Amp" },
  { value: "gemini-cli", label: "Gemini CLI" },
  { value: "roo", label: "Roo Code" },
  { value: "kilo", label: "Kilo Code" },
  { value: "kiro-cli", label: "Kiro CLI" },
  { value: "opencode", label: "OpenCode" },
  { value: "goose", label: "Goose" },
  { value: "droid", label: "Droid" },
  { value: "trae", label: "Trae" },
  { value: "continue", label: "Continue" },
  { value: "junie", label: "Junie" },
];

// ── Parse args ──────────────────────────────────────────────────────
const args = process.argv.slice(2);
if (args[0] === "install") args.shift();

const flags = {
  yes: false,
  dryRun: false,
  scope: "global",
  agents: ["claude-code"],
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
      flags.agents = args[++i].split(",").map((a) => a.trim());
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
  npx @nicmeriano/agent-skills install
  npx @nicmeriano/agent-skills install -y
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
    const colonIdx = entry.indexOf(":");
    if (colonIdx === -1) {
      return { source: entry, skill: null, label: entry };
    }
    const source = entry.slice(0, colonIdx);
    const skill = entry.slice(colonIdx + 1);
    return { source, skill, label: entry };
  });
}

function buildCmd(entry) {
  const parts = ["npx", "-y", "skills", "add", entry.source, "--yes"];
  if (flags.scope === "global") parts.push("--global");
  if (flags.method === "copy") parts.push("--copy");
  for (const agent of flags.agents) {
    parts.push("--agent", agent);
  }
  if (entry.skill) parts.push("--skill", entry.skill);
  return parts.join(" ");
}

function run(cmd) {
  return new Promise((resolve, reject) => {
    exec(cmd, { timeout: 120_000 }, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
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

s.stop(`Fetched ${manifestPath}`);

// ── 4. Pick skills (interactive) ────────────────────────────────────
let selected = skillEntries;

if (!flags.yes && !flags.dryRun) {
  const picked = await p.multiselect({
    message: `Select skills to install (${skillEntries.length} available):`,
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
  const scope = await p.select({
    message: "Scope:",
    options: [
      { value: "global", label: "global" },
      { value: "project", label: "project" },
    ],
    initialValue: flags.scope,
  });
  if (p.isCancel(scope)) cancel();
  flags.scope = scope;

  const agents = await p.multiselect({
    message: "Agents:",
    options: AGENTS,
    initialValues: flags.agents,
    required: true,
  });
  if (p.isCancel(agents)) cancel();
  flags.agents = agents;

  const method = await p.select({
    message: "Method:",
    options: [
      { value: "symlink", label: "symlink" },
      { value: "copy", label: "copy" },
    ],
    initialValue: flags.method,
  });
  if (p.isCancel(method)) cancel();
  flags.method = method;
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

    s.message(`[${i + 1}/${total}] ${entry.label}`);

    try {
      await run(cmd);
      succeeded++;
    } catch {
      failed.push(entry.label);
    }
  }

  if (failed.length === 0) {
    s.stop(`All ${total} skill(s) installed successfully.`);
  } else {
    s.stop(`${succeeded}/${total} skill(s) installed.`);
    p.log.warn(
      `Failed:\n${failed.map((f) => `  - ${f}`).join("\n")}`
    );
  }
}

// ── 7. Outro ────────────────────────────────────────────────────────
if (flags.dryRun) {
  p.outro(`${total} skill(s) would be installed.`);
} else {
  p.outro("Done!");
}
