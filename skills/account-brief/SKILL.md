---
name: account-brief
description: >-
  Researches a customer or prospect account before an outreach or a call using the
  Clearskies Customer Context Graph. Use when the user says "research <company> before
  I reach out", "what do we know about <company>", "give me a brief on <company>", or
  asks who the stakeholders are at an account. Identify the account by name or domain.
  Produces a headline, an account snapshot, open deals, stakeholders with each
  person's source backed role, recent activity, what is unresolved, and a recommended
  next step.
---

# Account Brief

Research an account before reaching out, sourced from the Clearskies Customer Context
Graph (CRM records, contacts, deals, and recent activity).

## Prerequisites

- Requires the Clearskies MCP server from this plugin's `mcp.json` and a signed in
  Clearskies workspace with at least one connected data source.
- Pass `context` on every tool call below except `object_get_fields_schema`:
  `{"goal": "<what you are doing and why>", "useCaseCategory": "<a suggested value, e.g. account_research>"}`.
  It is analytics only and does not change results.
- Omit `conversation_id` on the first tool call of the session, then pass back the value
  the server returned on every later call.
- Every tool here spends tenant credits. If the server replies "this workspace is out of
  credits; an admin must add credits before this tool can be used again", stop and tell
  the user an admin must add credits. Do not retry.
- Field level change history (step 5) needs an account flag not every workspace has; the
  tool itself returns a clear rejection when it is off.

## Input

The user names an account by company name or domain.

## Workflow

1. **Resolve the account.** Call `accounts_list` with `search` set to the company name or
   domain, `searchIntent: "contains"`, `itemsPerPage: 10`. Search matches both account
   names and domains. On several close matches, present a shortlist and stop rather than
   guessing.
2. **Discover the event fields.** Call `object_get_fields_schema` with
   `objectType: "event"` to get the fieldId and operator for `internal.accounts`.
   Mandatory before the `events_list` call below.
3. **Fan out on the resolved `accountId`.** These three calls need nothing but the id and
   the fieldId from step 2, run them together:
   - `account_get_contacts` with `itemsPerPage: 50`.
   - `account_get_deals` with `itemsPerPage: 25` (its default is 10, too low for most
     pipelines).
   - `events_list` with `filters` scoping `internal.accounts` to the account, `endTime`
     set to now, `orderDir: "desc"`, `itemsPerPage: 20`.
4. **Read what is unresolved.** Call `events_get_contents` with up to 3 `eventIds` from
   step 3 (the hard cap is 20 per call) to quote the specific open item rather than
   guessing from a title.
5. **Optional, only if the user asks what changed.** Call `find_record_changes` with
   `objectType: "deal"`, `ids` set to the deal ids from step 3, and `from` 30 days back.
   If it replies "change history is not enabled for this workspace", drop this section,
   say so once, and continue without retrying.
6. **Synthesize.**

## Output Format

### Headline

3 lines: who this account is, the state of the relationship, and the single most
important thing to know right now.

### Account Snapshot

| Field | Value |
|-------|-------|
| Industry | |
| Domain | |
| Owner | |

### Open Deals

| Deal | Stage | Amount | Close Date | Owner |
|------|-------|--------|------------|-------|

### Stakeholders

| Name | Title | Notes |
|------|-------|-------|

### Recent Activity

Last touch date, the gap since, and 3 to 5 bullets on what happened, each citing its
source event.

### What Is Unresolved

Open threads or questions from the transcripts and emails in step 4, quoted rather than
paraphrased where possible.

### Recommended Next Step

One concrete, specific action.
