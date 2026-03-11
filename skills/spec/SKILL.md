---
name: spec
description: >
  Generate Symphony-style technical specification documents optimized for AI agent consumption.
  Use when the user invokes /spec, asks to "write a spec", "create a technical specification",
  "spec out a feature", or needs a detailed implementation-ready specification for any project,
  feature, service, or system. Produces structured specs with concrete field definitions,
  pseudocode, test matrices, and implementation checklists using RFC 2119 keywords.
---

# Spec Generator

Produce Symphony-style technical specifications optimized for agentic consumption. Specs use imperative voice, concrete values, RFC 2119 keywords, tables, pseudocode, and implementation checklists — no filler.

## Workflow

1. Call `EnterPlanMode` immediately upon invocation
2. Use plan mode's built-in workflow to explore the codebase (if one exists) and gather requirements via `AskUserQuestion`
3. Write the spec as the plan file content, using the format and sections defined below
4. The user iterates by rejecting `ExitPlanMode` — revise the spec and re-propose
5. After exiting plan mode, copy the plan file content to `./SPEC.md` in the working directory
   - If `SPEC.md` already exists, use `SPEC-<name>.md` where `<name>` is a short kebab-case identifier
6. Inform the user of the output file path

## Question Categories

During plan mode, use `AskUserQuestion` to gather requirements. Focus on these categories as relevant — skip categories that are obvious or not applicable:

- **What**: Core functionality, inputs, outputs, key operations
- **Why**: Problem being solved, motivation, who benefits
- **Scope boundaries**: What is explicitly out of scope
- **Constraints**: Performance targets, technology choices, compatibility requirements, budget/timeline
- **Integration points**: External systems, APIs, data sources, authentication
- **Failure behavior**: What happens when things go wrong, retry policies, degradation modes
- **Existing context**: Related systems, prior art, code that already exists

Ask 3-5 focused questions per round. Do not ask about things that can be reasonably inferred or decided during implementation.

## Scope Classification

Classify the project scope to determine which sections to include:

| Scope  | Heuristic                                                    | Example                                |
|--------|--------------------------------------------------------------|----------------------------------------|
| Small  | Single file/script, < 500 LOC, no external integrations     | CSV-to-JSON converter, CLI utility     |
| Medium | Multiple files/modules, 1-3 integrations, single service    | Webhook relay, REST API, worker service|
| Large  | Multi-service, complex state, multiple integration points   | Distributed pipeline, platform feature |

## Section Catalog

Include sections based on scope. Number sections sequentially (only included sections get numbers). Read `references/example.md` before writing to calibrate style and concreteness.

### Always Include (all scopes)

**Problem Statement** — 2-4 sentences. What problem exists, why current solutions are insufficient, who is affected. No solution details.

**Goals & Non-Goals** — Goals use MUST/SHOULD/MAY with measurable criteria. Non-goals use "Will NOT" with explicit exclusions. 4-8 goals, 2-4 non-goals typical.

**Domain Model** — Table format: Entity | Field | Type | Default | Description. Define every entity, enum value, and relationship. For Small scope, a simplified model or type definitions are acceptable.

**Implementation Checklist** — Numbered imperative steps in dependency order. Each step is a verifiable unit of work. Include test steps inline. This is the section an implementing agent follows — make it unambiguous.

### Include for Medium+ Scope

**System Overview** — Component list with responsibilities. For Medium: list modules/packages. For Large: include a text-based architecture description showing component relationships.

**Workflow / Sequence** — Numbered steps for each primary operation. Include decision points, error branches, and return values. Use sub-steps (a, b, c) for parallel or conditional paths.

**State Management** — State enum with valid transitions table: Current State | Event | Next State | Side Effect. Include initial state and terminal states.

**Failure Model** — Table format: Failure | Detection | Recovery. Cover infrastructure failures, upstream/downstream errors, data corruption, and resource exhaustion.

**Test Matrix** — Table format: Scenario | Input | Expected Output | Verify. Cover happy path, edge cases, error cases, and performance benchmarks.

### Include for Large Scope or When Relevant

**Configuration** — Table format: Key | Type | Default | Description | Validation. Include environment variables, feature flags, and tuning parameters.

**Scheduling / Timing** — Cron expressions, SLAs, timeout values, rate limits, batch intervals. Use tables.

**Integration Protocol** — Per-integration: endpoint, auth method, request/response format, error codes, rate limits. Use tables or structured blocks.

**Observability** — Metrics (name, type, labels), log events (level, fields), alerts (condition, severity, action). Use tables.

**Security Model** — Authentication method, authorization rules, data classification, encryption requirements, audit events.

**Reference Algorithms** — Pseudocode for complex logic. Use language-agnostic pseudocode with clear variable names. Include complexity annotations.

**Migration / Rollout** — Phased rollout plan, feature flag strategy, rollback procedure, data migration steps.

## Writing Style Rules

1. **Imperative voice**: "Send request to endpoint" not "The system sends a request"
2. **RFC 2119 keywords**: Use MUST, SHOULD, MAY, MUST NOT precisely — MUST means mandatory, SHOULD means recommended with exceptions, MAY means optional
3. **Concrete values**: "Retry 5 times with 1s base backoff" not "retry with reasonable backoff"
4. **Tables for structured data**: Field definitions, error catalogs, state transitions, config — always tables
5. **Pseudocode for logic**: Complex algorithms, decision trees, retry logic — use pseudocode, not prose
6. **No filler**: Every sentence adds information. No "This section describes...", no "It is important to note that...", no restating the obvious
7. **Numbered sequences**: Workflows and procedures use numbered steps, not bullets
8. **Explicit over implicit**: State defaults, units, formats, and constraints. "timeout: 30s" not "timeout: reasonable"

## Spec Document Header

Begin every spec with this header format:

```
# <Title> — Technical Specification

| Field   | Value              |
|---------|--------------------|
| Date    | YYYY-MM-DD         |
| Scope   | Small/Medium/Large |
```

## Output and Finalization

After the user approves and exits plan mode:

1. Read the plan file content
2. Write to `./SPEC.md` in the current working directory
3. If `./SPEC.md` already exists, write to `./SPEC-<name>.md` where `<name>` is derived from the spec title (kebab-case, max 3 words)
4. Tell the user: the output path, the scope classification, and the number of sections included

## Edge Cases

- **No codebase**: Skip codebase exploration. Focus questions on requirements and constraints. Spec is still valid.
- **Existing feature / refactor**: Reference actual file paths, function names, and current behavior in the spec. The spec describes the target state.
- **User provides a document or plan**: Use it as primary input. Ask clarifying questions only for gaps. Do not re-ask what the document already answers.
- **Tiny scope** (single function, config change): Use Small scope but further reduce — Problem Statement + Goals + Implementation Checklist may be sufficient. Use judgment.
- **User wants to iterate**: They can reject `ExitPlanMode` to continue editing. The plan file is the living draft.
