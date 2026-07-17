## v0.2.0

Adds `dashboard`: a local, self-contained progress tracker. Reads whatever
`.certicoach/` state already exists for the active certification and
renders it into a single offline HTML file
(`.certicoach/dashboard.html`) — readiness standing, domain
bars, this week's due items and streak, the open mistake ledger, and the
next recommended action — with no network calls and no data leaving the
candidate's machine. Wired into `SKILL.md`'s command table and regenerated
automatically at the end of every session.

## v0.1.0

Initial scaffold: skill entry point, README, license, and repo structure.
