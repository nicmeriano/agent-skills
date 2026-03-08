# Spec Writing Guide & Example

## Writing Rules

### Voice & Language

- Use imperative/infinitive form: "Send webhook" not "The system sends a webhook"
- Use RFC 2119 keywords precisely: MUST, SHOULD, MAY, MUST NOT
- Every sentence adds information — no filler, no preamble, no "This section describes..."
- Prefer concrete values over vague language

**Bad:** "The system should handle errors gracefully and provide appropriate feedback to users."
**Good:** "On delivery failure, retry with exponential backoff: 1s, 2s, 4s, 8s, 16s. After 5 failures, mark endpoint as `CIRCUIT_OPEN`. Alert via `webhook.circuit_open` event."

**Bad:** "The retry mechanism uses a reasonable delay between attempts."
**Good:** "Retry delay: `min(base_delay * 2^attempt, max_delay)` where `base_delay=1s`, `max_delay=60s`."

**Bad:** "Users can configure various settings to customize behavior."
**Good:** "Configuration fields: `max_retries` (int, default 5), `timeout_ms` (int, default 30000), `batch_size` (int, default 100)."

### Structure Patterns

- Use tables for structured data (field definitions, error catalogs, state transitions)
- Use numbered sequences for workflows and implementation steps
- Use pseudocode for complex logic (not prose descriptions)
- Use bullet lists sparingly — prefer tables when items have multiple attributes

---

## Example Spec: Webhook Relay Service

> Condensed example showing key sections and style. A real spec would expand each section.

### 1. Problem Statement

Third-party services (Stripe, GitHub, Twilio) send webhooks to a single endpoint. Internal consumers each need filtered subsets of these events with independent retry and delivery guarantees. No existing solution provides fan-out with per-consumer delivery tracking.

### 2. Goals & Non-Goals

**Goals:**
- MUST receive webhooks from N providers and fan out to M internal consumers
- MUST guarantee at-least-once delivery per consumer
- MUST support per-consumer event filtering by event type glob pattern
- SHOULD sustain 500 events/sec with p99 latency < 200ms for ingest

**Non-Goals:**
- Will NOT transform webhook payloads (consumers receive raw provider payloads)
- Will NOT provide a UI for consumer management (API-only)
- Will NOT support outbound webhooks to external services

### 3. Domain Model

| Entity       | Field          | Type            | Default  | Description                          |
|-------------|----------------|-----------------|----------|--------------------------------------|
| Provider    | id             | UUID            | auto     | Unique provider identifier           |
| Provider    | signing_secret | string          | required | HMAC secret for signature validation |
| Consumer    | id             | UUID            | auto     | Unique consumer identifier           |
| Consumer    | endpoint_url   | string          | required | HTTPS delivery target                |
| Consumer    | filter_pattern | string          | `*`      | Glob pattern matching event types    |
| Consumer    | max_retries    | int             | 5        | Max delivery attempts before DLQ     |
| Delivery    | id             | UUID            | auto     | Unique delivery attempt identifier   |
| Delivery    | status         | enum            | PENDING  | PENDING, DELIVERED, FAILED, DLQ      |
| Delivery    | attempt_count  | int             | 0        | Current retry count                  |

### 4. Ingest Workflow

1. Receive POST at `/ingest/{provider_id}`
2. Validate HMAC signature using provider's `signing_secret`
3. Parse event type from provider-specific header or payload field
4. Persist raw event to `events` table with status `RECEIVED`
5. For each consumer where `filter_pattern` matches event type:
   a. Create `Delivery` record with status `PENDING`
   b. Enqueue delivery job to worker pool
6. Return `202 Accepted` with event ID

### 5. Failure Model

| Failure              | Detection                        | Recovery                                           |
|---------------------|----------------------------------|----------------------------------------------------|
| Invalid signature   | HMAC mismatch                    | Return 401, log provider ID, do not persist        |
| Consumer timeout    | No response within 30s           | Retry with backoff: 1s, 2s, 4s, 8s, 16s           |
| Consumer 5xx        | HTTP status >= 500               | Same retry policy as timeout                       |
| Consumer 4xx        | HTTP status 400-499              | Mark FAILED immediately, no retry (client error)   |
| Max retries reached | `attempt_count >= max_retries`   | Move to DLQ, emit `delivery.dlq` event             |
| Database unavailable| Connection pool exhausted        | Return 503 to provider (provider retries)          |

### 6. Implementation Checklist

1. Create database schema: `providers`, `consumers`, `events`, `deliveries` tables
2. Implement provider signature validation (HMAC-SHA256)
3. Build ingest endpoint with event persistence and fan-out
4. Implement delivery worker with retry and backoff logic
5. Add DLQ handling and `delivery.dlq` event emission
6. Create consumer CRUD API endpoints
7. Add health check endpoint returning queue depth and error rates
8. Write integration tests: valid delivery, retry exhaustion, signature rejection
9. Load test: sustain 500 events/sec with 10 consumers, verify p99 < 200ms
