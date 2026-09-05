---
name: customer-health
description: >-
  Spots renewal and churn risk for a customer account using the Clearskies Customer
  Context Graph. Use when the user says "is <company> at risk", "churn risk",
  "renewal risk", "how healthy is <company>", or "which accounts have gone quiet".
  Identify the account by name or domain. Produces a risk verdict with reasoning, a
  signals table, renewal exposure, open support tickets, the current engagement gap,
  and concrete actions to take this week.
---

# Customer Health

Spot renewal and churn risk for an account, sourced from the Clearskies Customer Context
Graph (support tickets, engagement history, and open deals).

## Prerequisites

- Requires the Clearskies MCP server from this plugin's `mcp.json` and a signed in
  Clearskies workspace with at least one connected data source.
- Pass `context` on every tool call below except `object_get_fields_schema`:
  `{"goal": "<what you are doing and why>", "useCaseCategory": "<a suggested value, e.g. renewal_risk>"}`.
  It is analytics only and does not change results.
- Omit `conversation_id` on the first tool call of the session, then pass back the value
  the server returned on every later call.
- Every tool here spends tenant credits. If the server replies "this workspace is out of
  credits; an admin must add credits before this tool can be used again", stop and tell
  the user an admin must add credits. Do not retry.
- Field level change history (step 7) needs an account flag not every workspace has; the
  tool itself returns a clear rejection when it is off.
- Do not call `github_activities_list`. It filters only by assignee email or GitHub
  login, has no account link, and reports internal engineering activity, not a customer
  signal.

## Input

The user names an account by company name or domain.

## Workflow

1. **Resolve the account.** Call `accounts_list` with `search` set to the company name or
   domain, `searchIntent: "contains"`, `itemsPerPage: 10`. On several close matches,
   present a shortlist and stop rather than guessing.
2. **Discover the event fields.** Call `object_get_fields_schema` with
   `objectType: "event"` to get the exact fieldIds and valid operators for
   `internal.accounts` and `internal.type`. Mandatory before steps 3 and 4.
3. **Tickets for this account.** Call `events_list` with `filters` scoping
   `internal.accounts` to the account and `internal.type` equal to `support_ticket`,
   `endTime` set to now, `orderDir: "desc"`, `itemsPerPage: 50`. This is the only
   account scoped path to this account's tickets.
4. **Engagement cadence.** Call `events_list` with `filters` scoping `internal.accounts`
   to the account and `internal.type` limited to meetings and emails, `endTime` set to
   now, `orderDir: "desc"`, `itemsPerPage: 50`. Compute the last touch date and the size
   of the current gap.
5. **Renewal exposure.** Call `account_get_deals` with `itemsPerPage: 25` for close
   dates, amounts, and stages.
6. **Optional workspace wide staleness sweep.** Call `support_tickets_list` with
   `openOnly: true` and `updatedBefore` set N days back. This tool has no account
   argument, its rows are workspace wide, so match them back to this account by name or
   domain before using them. Use it only to answer "which tickets are going stale
   workspace wide", never present its raw output as this account's ticket list, that is
   step 3's job.
7. **Optional field drift.** Call `find_record_changes` with `objectType: "account"` and
   `ids: ["<accountId>"]` for field level drift. If it replies "change history is not
   enabled for this workspace", drop this section, say so once, and continue without
   retrying.
8. **Score and report.**

## Output Format

### Risk Verdict

One of low, watch, or at risk, with one line of reasoning.

### Signals

| Signal | Evidence | Source |
|--------|----------|--------|

### Renewal Exposure

Amount and close date of the deal(s) at stake.

### Open Tickets

| Ticket | State | Age |
|--------|-------|-----|

### Engagement Gap

Last touch date and the number of days since.

### Do This Week

3 concrete actions.
