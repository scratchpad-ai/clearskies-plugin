# Clearskies

Bring the revenue context already connected to Clearskies into Claude, ChatGPT (Codex), Cursor, and
any other Agent Plugins client. Research accounts and deals, prepare for meetings, recap calls,
review pipeline risk, find evidence across customer interactions, and build reliable RevOps
workflows without switching between systems.

Depending on your Clearskies connections and sync settings, available context can include CRM
records, meetings, call transcripts, email, calendar events, Slack threads, support tickets, and
GitHub activity.

This repository is an [Agent Plugins 1.0.0](https://agent-plugins.org) package. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the repository layout and how to change it.

## Get started

### 1. Install the plugin

#### Claude

1. In Claude, go to **Customize** and select **Plugins**.
2. Click **Add**.
3. Select **Add marketplace**.
4. Paste this repository:

```text
github.com/scratchpad-ai/clearskies-plugin
```

5. Open **Clearskies** from the new marketplace and install it.

#### ChatGPT (Codex)

1. In ChatGPT, open the **Plugins** page.
2. Click the arrow next to **Create**.
3. Select **Add marketplace**.
4. Paste this repository:

```text
github.com/scratchpad-ai/clearskies-plugin
```

5. Open **Clearskies** from the new marketplace and install it.

#### Cursor

Open **Settings**, then **Plugins**, search for **Clearskies**, and select **Install**. Cursor 3.13
or newer is required.

To run it locally instead:

```bash
git clone git@github.com:scratchpad-ai/clearskies-plugin.git
mkdir -p ~/.cursor/plugins/local
ln -s "$(pwd)/clearskies-plugin" ~/.cursor/plugins/local/clearskies
```

Then run **Developer: Reload Window** from the command palette. Teams and Enterprise workspaces need
`Allow Local Plugin Imports` enabled first.

#### Other Agent Plugins clients

VS Code, GitHub Copilot, Kiro, and the other clients listed at
[agent-plugins.org/compatible-clients](https://agent-plugins.org/compatible-clients) load this
package directly from the repository root. Follow each client's own install steps.

### 2. Sign in

A browser window opens for sign in. Pick Google or Microsoft. There is no client ID, secret, or
token to paste, and the plugin does not store your credentials.

### 3. Ask a revenue question

You can ask naturally. For example:

- "Research Acme Corp before my call tomorrow: stakeholders, deal status, and what is unresolved."
- "Prep me for my next meeting: pull the last call, the open items, and suggest an agenda."
- "Review my pipeline and rank open deals by risk. Which one needs attention today?"
- "Recap that call with Acme and draft the follow up."
- "Is Acme at risk of churning?"
- "What changed in this deal over the last 30 days?"
- "Build a workflow that posts a Slack summary after customer calls."
- "Keep the Opportunity Next Steps field updated from relevant meetings."

## Available skills

| Skill | Use it for |
| --- | --- |
| [`account-brief`](skills/account-brief/SKILL.md) | Researching an account before outreach: snapshot, open deals, stakeholders, recent activity, and a next step. |
| [`meeting-prep`](skills/meeting-prep/SKILL.md) | A decision ready brief for an upcoming call, demo, QBR, or renewal, with an agenda and talking points. |
| [`pipeline-review`](skills/pipeline-review/SKILL.md) | Ranking open deals by risk, spotting slipping or quiet deals, and checking forecast health. |
| [`call-recap`](skills/call-recap/SKILL.md) | Recapping a call and drafting the follow up from decisions, objections, and open commitments. |
| [`customer-health`](skills/customer-health/SKILL.md) | Renewal and churn risk from engagement history, open support tickets, and engagement gaps. |
| [`use-clearskies-revenue-data`](skills/use-clearskies-revenue-data/SKILL.md) | Open ended CRM and interaction questions that the focused skills above do not cover. |
| [`clearskies-workflow-builder`](skills/clearskies-workflow-builder/SKILL.md) | Creating, changing, testing, troubleshooting, and publishing revenue workflows. |
| [`ai-update-salesforce-field`](skills/ai-update-salesforce-field/SKILL.md) | Keeping a chosen Salesforce field up to date from relevant meeting content. |

You do not need to remember skill names. Describe the outcome you want and your agent will pick the
right skill. The explicit names are useful when you want to invoke one directly.

## Your data sources live in Clearskies

This plugin points at a single MCP server. Salesforce, Gong, Scratchpad, Google, Microsoft, and
Slack are connected inside your Clearskies account, not in local MCP configuration. Manage those
connections from the Clearskies workspace settings.

## Working safely

- Results reflect the systems, objects, fields, and history your team has chosen to synchronize.
  "Not found" may mean the information is not synchronized, not that it is missing from the source
  system.
- Clearskies reads only the customer-interaction content needed to answer the question you asked.
- Outreach is always drafted, never sent.
- Workflow changes are drafted, validated, and tested before publication. A live workflow is never
  published or edited without your explicit approval.
- Builder actions (workflows and agents) require workspace admin access.
- Field level change history needs an account flag that not every workspace has.
- Data tools use tenant credits. A workspace that is out of credit gets a refusal instead of an
  answer.

## Support and privacy

- Support: support@clearskies.cc
- Privacy policy: https://www.clearskies.cc/privacy-policy
- MCP server documentation: https://www.clearskies.cc/docs/building-with-clearskies/mcp-server

Licensed under the [MIT License](LICENSE).
