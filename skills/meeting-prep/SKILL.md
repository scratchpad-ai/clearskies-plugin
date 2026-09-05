---
name: meeting-prep
description: >-
  Prepares a decision ready brief for an upcoming sales call, demo, QBR, or renewal
  using the Clearskies Customer Context Graph. Use when the user says "prep me for a
  call with <company>", "prep me for my next meeting", "what should I know for my
  2pm", or asks what to cover on an upcoming customer meeting. Identify the meeting by
  company name or domain, or name no company and let the skill pick it from the
  upcoming calendar. Produces a TL;DR with a recommended opener, the buying committee
  and each person's source backed role, open threads from the last conversation,
  ranked talking points, discovery questions, a 30 minute agenda, and what not to do.
---

# Meeting Prep

Produce a tight, decision ready brief for an upcoming sales meeting, sourced from the
Clearskies Customer Context Graph (CRM records, calls, emails, and calendar).

## Prerequisites

- Requires the Clearskies MCP server from this plugin's `mcp.json` and a signed in
  Clearskies workspace with at least one connected data source.
- Pass `context` on every tool call below except `object_get_fields_schema`:
  `{"goal": "<what you are doing and why>", "useCaseCategory": "<a suggested value, e.g. call_summary>"}`.
  It is analytics only and does not change results.
- Omit `conversation_id` on the first tool call of the session, then pass back the value
  the server returned on every later call.
- Every tool here spends tenant credits. If the server replies "this workspace is out of
  credits; an admin must add credits before this tool can be used again", stop and tell
  the user an admin must add credits. Do not retry.

## Input

The user names a company (name or domain), or names no company at all and asks to be
prepped for "my next meeting" or "my 2pm". Optional: a description of the meeting's
purpose and stakes, richer context produces a sharper brief.

## Workflow

0. **Pick the meeting, only when no company was named.** Call `calendar_get_upcoming`
   with `minutesAhead: 0` and `minutesWindow` sized to the ask (1440 for "today", 10080
   for "this week", max 43200). Present a numbered shortlist of time, title, and
   attendees, and stop for the user to pick before spending credits on research. If it
   returns nothing, say so and ask for a company name instead. Each event carries its own
   `accountIds`; once the user picks one, carry that id forward into step 1 as `ids`
   rather than guessing a company name from an attendee's email domain. If the picked
   event has no `accountIds`, fall back to a company name or domain from the meeting
   title or attendees.
1. **Resolve the account.** If step 0 supplied an id, call `accounts_list` with
   `ids: ["<accountId>"]`. Otherwise call `accounts_list` with `search` set to the
   company name or domain, `searchIntent: "contains"`, `itemsPerPage: 10` (search matches
   both account names and domains). If the user gave a Salesforce ID instead, use
   `externalIds: [{"type": "salesforce", "objectType": "account", "externalId": "<id>"}]`.
   On several close matches, present a shortlist and stop rather than guessing.
2. **Get the deal in play.** Call `account_get_deals` with the `accountId` and
   `itemsPerPage: 25` (its default is 10, too low for most pipelines). Pick the open
   deal that matches the meeting; if several are open, ask which one if it isn't obvious.
3. **Map the buying committee.** Call `deal_get_people` with the `dealId`. Read the
   `links` array on each person before asserting a role: a `salesforce` or `hubspot` link
   is a recorded CRM fact at confidence 1.0 (and Salesforce marks `isPrimary`), while an
   `llm` link is inferred from call, email, and Slack content and carries the model's own
   confidence score from 0 to 1. Sources often disagree; attribute each role to its
   source rather than merging them. An empty result means no source has linked anyone to
   this deal yet, it is not evidence the deal has no stakeholders.
4. **Pull the last conversations.** Call `events_list` with `query` set to the meeting
   purpose (if known), `filters` scoping `internal.accounts` to the resolved account
   (call `object_get_fields_schema` with `objectType: "event"` first to confirm the
   fieldId and operator), `endTime` set to now so future scheduled meetings are excluded,
   `orderDir: "desc"`, `hasCall: true`, `transcriptStatus: "completed"`,
   `itemsPerPage: 10`. If step 1 found no account at all, fall back to `events_search`
   with just `query` (omit `entities`, it is optional) and `eventTypes: ["meeting"]` for
   a broader semantic search.
5. **Read the transcripts.** Call `events_get_contents` with up to 3 `eventIds` from step
   4 (the hard cap is 20 per call). For meetings, `content.meeting.calls` is a list
   because one meeting can have multiple linked recordings; inspect each and pick the one
   relevant to this account.
6. **Synthesize.** Decide what makes the brief. Classify each attendee's posture (cold,
   warm but dormant, active, or hostile) from the buying committee data and the
   transcripts. Rank talking points by relevance to the meeting purpose. Write the TL;DR
   last, after the rest is drafted.

## Output Format

### TL;DR

> **Meeting purpose**: [one line, or "general meeting prep" if none was given].
>
> **Top 3 to know walking in**:
> 1. [Most decision relevant fact]
> 2. [Second]
> 3. [Third]
>
> **Carrying over from last time** (if conversation data exists): 1-2 open threads or
> promised follow ups from prior calls, each with the source meeting.
>
> **Open with**: "[Single recommended opening line, calibrated to attendee posture]"

### Buying Committee

One row per person, from `deal_get_people`.

| Name | Title | Role | Source | Confidence |
|------|-------|------|--------|------------|
| | | | CRM / inferred | |

### Prior Conversations

Omit this section if no conversation data was available.

- **Recent themes**: what has actually been discussed across the last few calls.
- **Open threads**: what is still hanging, with the source meeting cited.
- **Commitments**: what we promised and what they promised, if surfaced.

### Talking Points (3 to 5)

Ranked by relevance to the meeting purpose, each tied to a specific surfaced fact.

1. **[Topic]**: [why to raise it, with a source tag like transcript, CRM, or deal data]
2. ...

### Discovery Questions (3 to 5)

Specific, anchored in a concrete fact from the brief, not generic.

### Suggested Agenda (~30 min)

- **(0-5) Open**: [specific opener, calibrated to attendee posture]
- **(5-15) Explore**: [primary discovery thread]
- **(15-25) Develop**: [secondary thread]
- **(25-30) Close**: [specific desired next step]

### What Not To Do

1 to 3 specific failure modes for this meeting, each with why it would backfire.
