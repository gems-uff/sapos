# Security Policy

## Reporting a vulnerability

Please **do not open a public issue, pull request or discussion** about a
vulnerability. Listing the problem in public exposes every installation
before a fix exists.

Report it privately through GitHub instead:
[Report a vulnerability](https://github.com/gems-uff/sapos/security/advisories/new),
also available under the **Security** tab of this repository. Only the
maintainers see the report. It is private, not anonymous: you need a GitHub
account, and the maintainers will see which account sent it.

A useful report includes:

- the version or commit where you found the problem;
- the role the attacker needs (no login, student, professor, staff, and so on);
- the steps or the request that reproduce it, and what happens;
- the impact you expect: what can be read, written or disrupted.

SAPOS installations hold real student data. Test on your own installation
(see [Quick-install](https://github.com/gems-uff/sapos/wiki/Quick-install)),
not on an installation run by someone else.

## What happens next

We confirm the problem, fix it on `main` and publish a release soon after the
fix is merged, without waiting for other work. The fix is published with a
generic description, and the details stay in the private advisory until
installations have had the chance to upgrade. If you want, we credit you in
the advisory.

## Supported versions

Only the [latest release](https://github.com/gems-uff/sapos/releases/latest)
receives security fixes. To upgrade an installation, see
[Upgrading to a new release](https://github.com/gems-uff/sapos/wiki/Upgrading-to-a-new-release).

## Dependencies

A vulnerability in a gem that SAPOS uses belongs to that gem's maintainers;
please report it to them. If it reaches SAPOS in a way that SAPOS can
mitigate on its own, report it here as well.
