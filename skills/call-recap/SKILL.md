---
name: call-recap
description: >-
  Recaps a sales call and drafts the follow up from it using the Clearskies Customer
  Context Graph. Use when the user says "recap that call", "what happened on the call
  with <company>", "summarize this recording <url>", "draft a follow up from that
  call", or "write the follow up email". Identify the call by a pasted Scratchpad
  recording URL, or by company name to find the most recent recorded call. Produces a
  recap of decisions, objections, and open commitments, plus a ready to send follow up
  draft addressed to the right people.
---

# Call Recap

Recap a sales call and draft its follow up, sourced from the Clearskies Customer Context
Graph (call transcripts and deal stakeholders). Clearskies has no tool that sends email;
the follow up is always a draft for the user to send themselves.

## Prerequisites

- Requires the Clearskies MCP server from this plugin's `mcp.json` and a signed in
  Clearskies workspace with at least one connected data source.
- Pass `context` on every tool call below except `scratchpad_resolve_link` and
  `object_get_fields_schema`:
  `{"goal": "<what you are doing and why>", "useCaseCategory": "<a suggested value, e.g. call_summary or follow_up_email>"}`.
  It is analytics only and does not change results.
- Omit `conversation_id` on the first tool call of the session, then pass back the value
  the server returned on every later call.
- Every tool here spends tenant credits. If the server replies "this workspace is out of
  credits; an admin must add credits before this tool can be used again", stop and tell
  the user an admin must add credits. Do not retry.
- Outreach is always drafted, never sent. Do not claim an email was sent.

## Input

Either a pasted Scratchpad recording URL, or a company name plus which call is meant
(most recent, or a specific date or topic).

## Workflow

1. **If the user pasted a URL**, always start here. Call `scratchpad_resolve_link` with
   the `url` (matches `*.scratchpad.com/recordings/{id}` or
   `*.scratchpad.com/p/recordings/{id}`, no `context` argument). It returns an
   `eventId`, skip to step 3.
2. **Otherwise find the call.** Call `accounts_list` with `search` set to the company
   name, `searchIntent: "contains"`, `itemsPerPage: 10` to get the `accountId`. Then call
   `events_list` with `filters` scoping `internal.accounts` to that account (call
   `object_get_fields_schema` with `objectType: "event"` first to confirm the fieldId
   and operator), `hasCall: true`, `transcriptStatus: "completed"`, `endTime` set to now,
   `orderDir: "desc"`, `itemsPerPage: 10`. Present a numbered shortlist when more than one
   call could match and stop for the user to pick.
3. **Read the transcript.** Call `events_get_contents` with the chosen `eventIds` (up to
   20 per call). For meetings, `content.meeting.calls` is a list because one meeting can
   have multiple linked recordings; inspect each and pick the one relevant to this
   request.
4. **Optional, only when drafting the follow up.** Both `events_list` (step 2) and
   `events_get_contents` (step 3) return an `entities` array on each event, which
   includes any linked deal with an LLM-inferred confidence score; if several deals are
   linked, take the highest confidence one. Call `deal_get_people` with that `dealId` to
   decide who the email is addressed to. Read the `links` array before assigning a
   role: a `salesforce` or `hubspot` link is a recorded CRM fact at confidence 1.0, an
   `llm` link is inferred and carries the model's own confidence score. If no deal is
   linked, address the draft to the call's attendees instead.
5. **Write the recap, then the draft.** State plainly that this is a draft, never an
   already sent email.

## Output Format

### Recap

- **Decided**: what was agreed or decided on the call.
- **Objections raised**: each with how it was handled, if it was.
- **Commitments**: what we promised and what they promised, each with an owner and a
  date if one was given.
- **Open questions**: what is still unresolved.

### Draft Follow Up

A subject line and a ready to paste body, addressed to the people from step 4, each
commitment referenced by name.

> This is a draft. Clearskies has no tool to send it; send it yourself once reviewed.

### Suggested CRM Updates

Plain text suggestions only. This skill does not write to the CRM.
