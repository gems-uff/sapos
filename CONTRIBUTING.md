# Contributing to SAPOS

Is this your first time contributing here? Try some [good first issues](https://github.com/gems-uff/sapos/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22good%20first%20issue%22) to start. But remember to post your intended solution in the issue to discuss with the team before starting coding.

If you want to contribute to our project and **DO NOT BELONG TO THE MAIN TEAM**, follow these steps:

1. Fork the repo
2. Implement and test your code
3. Submit a pull request

If you **DO BELONG TO THE MAIN TEAM**, just follow steps below.

## Branching model

We use one branch per issue. Every issue gets its own branch named after it (for example, `issue_123`), whether it is a bug fix, a dependency update, or a new feature. All of them are based on _main_.

The _main_ branch is the baseline and is always stable: every release, corrective or evolutive, is cut from it.

The lifecycle of a branch is:

1. Create `issue_NNN` from _main_.
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
