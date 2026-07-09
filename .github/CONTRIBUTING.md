# Issues

* We try to keep the list of open issues to a reasonably low number of things that we have active plans to work on. Usually this means they're part of a project mySociety has funding for. Other issues usually get closed as "not planned". This doesn't mean they're undesirable or invalid, but just that we can't commit to working on them in the near future. We still comment on these issues (e.g. to record new thoughts/ideas/context), and others are welcome to work on them and propose fixes/pull requests etc.
* Larger funded or strategic work should use a parent issue with small subissues. Each subissue should be narrow enough to close with one focused pull request.
* For bot resilience, security, platform, or operational work, do not accept known risk as "low risk". Findings should be fixed, verified as false positives, mitigated with a tested control, or converted into a blocking follow-up before the subissue is closed.
* Where possible, describe the harness for the issue: the feedforward guide that should steer the work and the feedback sensor that will verify it. Examples include specs, plans, runbooks, tests, linters, scanners, type checks, benchmarks, logs, or metrics.

# Pull Requests

* It's assumed that Pull Requests in a draft state are still being worked on, so won't actively be reviewed. You're more than welcome to @mention someone to request specific feedback though.
* Once Pull Requests are ready to review, mark them as "Ready for review" using GitHub's button for this. We can't promise timelines for review as sometimes our capacity can be quite stretched, but we'll try to provide feedback as soon as we can.
* Keep pull requests small. A pull request should normally close one subissue and avoid mixing policy, tooling, runtime behavior, rollout, and documentation unless the subissue explicitly requires that combination.
* Pull requests should identify scope boundaries, verification evidence, rollback path for operational changes, and any updated harness guides or sensors.
