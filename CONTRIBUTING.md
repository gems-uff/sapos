# Contributing to SAPOS

Is this your first time contributing here? Try some [good first issues](https://github.com/gems-uff/sapos/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22good%20first%20issue%22) to start. But remember to agree on your solution in the issue before starting to code — see [Before coding](#before-coding-agree-on-the-solution-in-the-issue).

If you want to contribute to our project and **DO NOT BELONG TO THE MAIN TEAM**, follow these steps:

1. Agree on the solution in the issue (see [Before coding](#before-coding-agree-on-the-solution-in-the-issue))
2. Fork the repo
3. Implement and test your code
4. Submit a pull request

If you **DO BELONG TO THE MAIN TEAM**, just follow steps below.

## Before coding: agree on the solution in the issue

An issue usually starts as a pain — something slow, confusing or missing — not
as a solution. Implementing straight from it means guessing rules that nobody
has written down yet, and every wrong guess comes back as rework during the
review, when it is most expensive to change.

So before creating a branch, refine the solution in the issue itself:

1. Write your proposal as a comment: what changes, for whom, and how it behaves
   outside the happy path.
2. If the change has a screen, attach a mock — a sketch or an annotated
   screenshot that shows the layout and the messages the user will read.
3. List the open questions, especially the product decisions: what happens to
   invalid input, whether an operation applies in part or all-or-nothing, what
   the user is told afterwards.
4. Start coding only when the maintainer agrees that the requirement is closed.

Decisions taken later, during the review or the homologation, also go back to
the issue as a comment. The specification lives in one place, and the pull
request implements what is written there.

A large issue can be split while it is refined: a part whose solution is closed
can be implemented while the others are still under discussion.

## Branching model

We use one branch per issue. Every issue gets its own branch named after it (for example, `issue_123`), whether it is a bug fix, a dependency update, or a new feature. All of them are based on _main_.

The _main_ branch is the baseline and is always stable: every release, corrective or evolutive, is cut from it.

The lifecycle of a branch is:

1. Once the solution is agreed in the issue, create `issue_NNN` from _main_.
2. Implement and test.
3. Merge _main_ into `issue_NNN` and test again, so the branch is up to date.
4. Open a pull request for the maintainer to review.
5. The maintainer merges `issue_NNN` into _main_. Because of step 3 this is a fast-forward.
6. The maintainer tags the new release on _main_.

Steps 5 and 6 are done by the maintainer only, after reviewing the pull request.

**Security issues are the exception.** Do not open a public issue for a vulnerability: describing it publicly exposes the attack before the fix is released. Work on a branch created directly from _main_, with a generic description, and release it like any other fix.

## Commit messages

Start the subject with `Issue #NNN: `, using the number of the branch's issue.
GitHub turns the number into a link, and the subject is what shows up in the
commit list and in `git log --oneline`. After the prefix, keep the subject
around 60 characters, in the imperative mood and with no trailing period, and
use the body to explain why the change was needed:

```
Issue #655: Distinguish semester without schedule from access denied

The controller raised CanCan::AccessDenied when no ClassSchedule existed for
the requested term. A student who simply arrived before the calendar was
registered was accused of an intrusion attempt.
```

A commit that belongs to no issue — a convention, a skill, infrastructure —
goes without the prefix.

Reference the issue with the prefix alone. Do not write `Fixes #NNN` or
`Closes #NNN`: GitHub closes the issue as soon as such a commit reaches _main_,
and closing is decided during the release, separately from labelling. An issue
delivered in part gets the version label and stays open.

## Testing

A contribution is ready when the whole suite is green:

```bash
bundle exec rspec
```

It takes around 12 minutes. The suite runs on SQLite, while production runs on
MariaDB — see `AGENTS.md` for the cases where that difference matters.

## Installing

See [Quick install](https://github.com/gems-uff/sapos/wiki/Quick-install) in the
wiki for the development setup, and
[Explained quick install for production](https://github.com/gems-uff/sapos/wiki/Explained-quick-install-for-production)
for the production one.
