# Issue tracker: GitHub

Issues and PRDs for this repository live as GitHub issues. Use the `gh` CLI for
all operations and infer the repository from `git remote -v`.

## Conventions

- Create an issue with `gh issue create`.
- Read an issue with `gh issue view <number> --comments`, including its labels.
- List issues with `gh issue list` using the state and label filters required by
  the workflow.
- Comment with `gh issue comment <number>`.
- Apply or remove labels with `gh issue edit <number>`.
- Close with `gh issue close <number>`.

GitHub shares one number space across issues and pull requests. Resolve an
ambiguous bare issue number by checking whether it is a pull request first.

## Pull requests as a triage surface

External pull requests are not an automatic triage surface. Explicitly named
pull requests may still be inspected when requested.

## Publishing and fetching work

When a skill says to publish to the issue tracker, create a GitHub issue. When
a skill says to fetch a relevant ticket, read the GitHub issue and its full
comment history.

## Wayfinding operations

For `/wayfinder`, represent the map as one GitHub issue and its tickets as
sub-issues. Use GitHub's native sub-issue and issue-dependency relationships
when available. If they are unavailable, use a task list on the map and a
`Blocked by:` line on child issues. Claim work by assigning the issue to the
current user.
