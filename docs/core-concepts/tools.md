# Tools

Tools are the actions an agent can perform. Each tool implements the `IToolProvider` interface and is registered in the `ToolRegistry`.

## Tool Categories

### GitLab Tools

| Tool | Name | Description |
|------|------|-------------|
| `GitLabSearchTool` | `gitlab_search` | Search code across repositories |
| `GitLabFileTool` | `gitlab_file` | Read file contents from any branch |
| `GitLabDiffTool` | `gitlab_diff` | Fetch MR diffs |
| `GitLabMRTool` | `gitlab_mr` | Get MR metadata (title, description, reviewers) |
| `GitLabCommentTool` | `gitlab_comment` | Post inline and general comments on MRs |
| `GitLabWriteTool` | `gitlab_write` | Create or update files in GitLab |

### GitHub Tools

| Tool | Name | Description |
|------|------|-------------|
| `GitHubSearchTool` | `github_search` | Search code across repositories |
| `GitHubFileTool` | `github_file` | Read file contents from any branch |
| `GitHubDiffTool` | `github_diff` | Fetch MR diffs |
| `GitHubMRTool` | `github_mr` | Get MR metadata (title, description, reviewers) |
| `GitHubCommentTool` | `github_comment` | Post inline and general comments on MRs |
| `GitHubWriteTool` | `github_write` | Create or update files in GitHub |

### Jira Tools

| Tool | Name | Description |
|------|------|-------------|
| `JiraTool` | `fetch_jira_ticket` | Fetch ticket details |
| `JiraTreeTool` | `fetch_jira_ticket_tree` | Fetch linked stories and subtasks |
| `JiraSearchTool` | `jira_search` | Search tickets via JQL |
| `JiraWriteTool` | `jira_write` | Update tickets (comments, transitions, story points) |
| `JsmRequestTool` | `create_jsm_request` | Create JSM service requests |

### Git Tools

| Tool | Name | Description |
|------|------|-------------|
| `GitCommandTool` | `run_git` | Safe read-only git commands (log, diff, branch, etc.) |
| `ParseBranchDiffTool` | `parse_branch_diff` | Extract and analyze diffs between branches |

### File Tools

| Tool | Name | Description |
|------|------|-------------|
| `LocalTools` | `read_file`, `grep`, `list_directory` | Read files, search content, list directories |
| `EditFileTool` | `edit_file` | In-place file editing |
| `WriteFileTool` | `write_file` | Create new files |

### Agent Tools

| Tool | Name | Description |
|------|------|-------------|
| `SpawnAgentTool` | `spawn_agent` | Delegate tasks to child agents |
| `SkillTool` | `read_skill` | Load and execute skills from `.agents/skills/` |
| `QuestionTool` | `ask_user` | Ask the user a clarifying question |

### Web Tools

| Tool | Name | Description |
|------|------|-------------|
| `BrowserTool` | `browser` | Headless MS Edge browser control |
| `WebFetchTool` | `web_fetch` | Fetch and parse web pages |
| `ConfluenceTool` | `confluence_search` | Search and read Confluence pages |

### Session Tools

| Tool | Name | Description |
|------|------|-------------|
| `SessionReadTool` | `session_read` | Read persistent user session data |
| `SessionSendTool` | `session_send` | Write to persistent user sessions |
| `TodoTool` | `todo` | Manage task/todo lists |

### Custom Tools

User-authored TypeScript tools compiled server-side with security validation. See [Custom Tools](/docs/customization/custom-tools).

## Tool Security

The `run_git` tool only allows **whitelisted subcommands**:

```
log, diff, show, status, branch, tag, shortlog, describe,
rev-parse, rev-list, ls-files, ls-tree, cat-file, name-rev,
merge-base, diff-tree, whatchanged, fetch
```

Destructive flags (`--hard`, `--force`, `-f`) are always blocked.

Custom tools are sandboxed — the compiler blocks access to filesystem, child processes, node built-ins, `eval()`, and runtime APIs.

## Adding a New Tool

```typescript
import type { IToolProvider, ToolDeclaration, ToolResult } from '../IToolProvider.ts';

export class MyTool implements IToolProvider {
    readonly name = 'my_tool';
    readonly declaration: ToolDeclaration = {
        name: 'my_tool',
        description: 'What this tool does',
        parameters: {
            type: 'object',
            properties: {
                myArg: { type: 'string', description: 'Argument description' }
            },
            required: ['myArg']
        }
    };

    async execute(args: Record<string, unknown>): Promise<ToolResult> {
        return { output: `Result for ${args.myArg}` };
    }
}
```

Then register it in the DI container and add it to `INTENT_TOOL_MAP` in `ToolRegistry.ts`.
