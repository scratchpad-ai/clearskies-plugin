---
name: pipeline-review
description: >-
  Reviews a deal or the whole pipeline for risk and forecast health using the
  Clearskies Customer Context Graph. Use when the user says "review my pipeline",
  "rank my open deals by risk", "what needs attention today", or "how is my quarter
  tracking". Scopes to the current user's owned deals by default. Produces a quarter
  at a glance summary, a ranked list of deals that need attention with the evidence
  for each, slipping deals, deals that have gone quiet, and recommended actions.
---

# Pipeline Review

Review open deals for risk, sourced from the Clearskies Customer Context Graph (CRM
records and recent activity).

## Prerequisites

- Requires the Clearskies MCP server from this plugin's `mcp.json` and a signed in
  Clearskies workspace with at least one connected data source.
- Pass `context` on every tool call below except `identity_get` and
  `object_get_fields_schema`:
  `{"goal": "<what you are doing and why>", "useCaseCategory": "<a suggested value, e.g. pipeline_review>"}`.
  It is analytics only and does not change results.
- Omit `conversation_id` on the first tool call of the session, then pass back the value
  the server returned on every later call.
- Every tool here spends tenant credits except `identity_get`. If the server replies
  "this workspace is out of credits; an admin must add credits before this tool can be
  used again", stop and tell the user an admin must add credits. Do not retry.
- Field level change history (step 5) needs an account flag not every workspace has; the
  tool itself returns a clear rejection when it is off.

## Input

The user asks to review their pipeline, a specific deal, or the whole quarter's
forecast. Default to the current user's owned deals unless told otherwise.

## Workflow

0. **Confirm scope.** Call `identity_get` (no `context` argument, no credits) to confirm
   which user and workspace are in scope before spending credits on the rest.
1. **Discover the fields.** Call `object_get_fields_schema` with `objectType: "deal"`.
   This step is mandatory: any `filters[].fieldId` you use below must be a fieldId whose
   `validFilters` list is non-empty, the operator must come from that same list, and
   stage picklist values come from `enumValues`. Never guess a fieldId.
2. **List the deals.** Call `deals_list` with `ownedByMe: true`, `filters` for open
   stages and a close date inside the relevant quarter, `itemsPerPage: 100`, and
   `fieldIds` narrowed to what the output needs. If `ownedByMe` returns an error, relay
   that message to the user and do not retry without it.
3. **Aggregate the pipeline.** Call `records_aggregate` with `objectType: "deal"`, the
   same `filters` as step 2, `groupBy` set to the stage fieldId, and
   `metrics: [{"function": "sum", "fieldId": "<amount fieldId>"}]`. `groupBy` caps at 100
   groups and `metrics` at 5 entries.
4. **Optional trend.** A second `records_aggregate` call with
   `timeBucket: {"fieldId": "<close date fieldId>", "interval": "week", "from": "...", "to": "..."}`
   and `valueField` set to the stage picklist fieldId. A bucketed call cannot also pass
   `groupBy` or `metrics`, so this is a separate call. Keep the window to 200 buckets or
   fewer.
5. **Optional slippage.** Call `find_record_changes` with `objectType: "deal"`, `ids` set
   to the top deal ids from step 2, `from` 30 days back, and `fieldId` set to the close
   date or stage field. If it replies "change history is not enabled for this
   workspace", drop this section, say so once, and continue without retrying.
6. **Optional staleness.** Call `object_get_fields_schema` with `objectType: "event"` to
   get the fieldId and operator for `internal.deals` (a separate object type from the
   `deal` schema discovered in step 1). Then call `events_list` per deal with `filters`
   scoping `internal.deals` to that deal id, `endTime` set to now, `orderDir: "desc"`,
   `itemsPerPage: 5`, to find the last touch. Deal links here are LLM inferred and each
   event reports its own confidence score; treat a low confidence link as weak evidence.
7. **Rank and report.**

## Output Format

### Quarter At A Glance

Deal count, total value, and a breakdown by stage from step 3.

### Deals That Need Attention Today

Ranked table: deal, stage, amount, risk reason, and the evidence behind that reason.

| Deal | Stage | Amount | Risk Reason | Evidence |
|------|-------|--------|-------------|----------|

### Slipping

From step 5, close date or stage changes in the last 30 days. If change history is off
for this workspace, say so here instead of a table.

### Gone Quiet

From step 6, deals with no activity in the last 14+ days, with the day gap for each.

### Recommended Actions

One line per flagged deal, a specific next step.
